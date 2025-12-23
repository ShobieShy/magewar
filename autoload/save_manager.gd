## SaveManager - Persistent data save/load system
## Handles player saves (all players) and world saves (host only)
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal save_completed(success: bool)
signal load_completed(success: bool)
signal player_data_loaded(data: Dictionary)
signal world_data_loaded(data: Dictionary)
signal gold_changed(new_amount: int, delta: int)
signal level_up(new_level: int, skill_points: int)
signal stat_points_changed(new_amount: int)
signal stat_allocated(stat_type: int, new_value: int)
signal stat_deallocated(stat_type: int, new_value: int)
signal save_data_corrupted(data_type: String)  # Emitted if corrupted data is detected

# =============================================================================
# PROPERTIES
# =============================================================================

var player_data: Dictionary = {}
var world_data: Dictionary = {}
var settings_data: Dictionary = {}

var _auto_save_timer: Timer = null
var _is_saving: bool = false
var _save_validator: SaveValidator = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Initialize save validator
	_save_validator = SaveValidator.new()
	
	# Set up auto-save timer
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = Constants.AUTO_SAVE_INTERVAL
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)
	
	# Load settings on startup
	load_settings()
	
	# Load player data on startup
	load_player_data()
	load_world_data()

# =============================================================================
# SAVE OPERATIONS
# =============================================================================

func save_all() -> void:
	save_player_data()
	if GameManager.is_host:
		save_world_data()
	save_settings()


func force_save() -> void:
	"""Force immediate save (for testing/manual saves)"""
	print("Force saving all data...")
	save_all()


func save_player_data() -> void:
	if _is_saving:
		return

	# Update player_data from current runtime state before saving
	if GameManager and NetworkManager:
		var local_id = NetworkManager.local_peer_id
		var player_info = GameManager.get_player_info(local_id)
		
		if player_info and player_info.player_node:
			var player = player_info.player_node
			# Check if player has inventory property
			if "inventory" in player and player.inventory:
				var inv_save = player.inventory.get_save_data()
				
				# Update player_data with inventory state
				if inv_save.has("inventory"):
					player_data.inventory = inv_save.inventory
				if inv_save.has("equipment"):
					player_data.equipment = inv_save.equipment
				if inv_save.has("materials"):
					player_data.materials = inv_save.materials

	# Network synchronization - request save lock
	if get_node_or_null("/root/SaveNetworkManager") and NetworkManager and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE:
		if not get_node("/root/SaveNetworkManager").request_save_lock("player", multiplayer.get_unique_id()):
			# Lock not available, operation will be queued
			return

	_is_saving = true

	var save_dict = {
		"version": Constants.SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": player_data
	}

	var success = _save_to_file(Constants.PLAYER_SAVE_FILE, save_dict)

	# Network synchronization - broadcast save data
	if get_node_or_null("/root/SaveNetworkManager") and NetworkManager and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE and success:
		get_node("/root/SaveNetworkManager").synchronize_save_data("player", player_data, multiplayer.get_unique_id())

	_is_saving = false
	save_completed.emit(success)


func save_world_data() -> void:
	if not GameManager.is_host:
		push_warning("Only host can save world data")
		return

	# Network synchronization - request save lock (only for host)
	if get_node_or_null("/root/SaveNetworkManager") and NetworkManager and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE:
		if not get_node("/root/SaveNetworkManager").request_save_lock("world", multiplayer.get_unique_id()):
			# Lock not available, operation will be queued
			return

	var save_dict = {
		"version": Constants.SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"world": world_data
	}

	var success = _save_to_file(Constants.WORLD_SAVE_FILE, save_dict)

	# Network synchronization - broadcast world data (only host)
	if get_node_or_null("/root/SaveNetworkManager") and NetworkManager and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE and success:
		get_node("/root/SaveNetworkManager").synchronize_save_data("world", world_data, multiplayer.get_unique_id())

	if not success:
		push_error("Failed to save world data")


func save_settings() -> void:
	var config = ConfigFile.new()
	
	for section in settings_data.keys():
		for key in settings_data[section].keys():
			config.set_value(section, key, settings_data[section][key])
	
	var error = config.save(Constants.SETTINGS_FILE)
	if error != OK:
		push_error("Failed to save settings: ", error)

# =============================================================================
# LOAD OPERATIONS
# =============================================================================

func load_player_data() -> Dictionary:
	var data = _load_from_file(Constants.PLAYER_SAVE_FILE)
	
	if data.is_empty():
		player_data = _get_default_player_data()
	else:
		# Validate version
		if data.get("version", 0) != Constants.SAVE_VERSION:
			push_warning("Save version mismatch, migrating...")
			player_data = _migrate_player_data(data)
		else:
			var loaded_player = data.get("player", _get_default_player_data())
			
			# Validate loaded data
			var validation = _save_validator.validate_player_data(loaded_player)
			if not validation.valid:
				push_error("Save data validation failed, using defaults and sanitized data")
				save_data_corrupted.emit("player")
				# Sanitize and use the corrupted data with defaults
				loaded_player = _save_validator.sanitize_player_data(loaded_player)
			
			player_data = loaded_player
	# Fix string keys in allocated_stats (JSON conversion side-effect)
	if player_data.has("allocated_stats"):
		var fixed_stats = {}
		for key in player_data.allocated_stats:
			fixed_stats[int(key)] = player_data.allocated_stats[key]
		player_data.allocated_stats = fixed_stats
	# Ensure all required fields are present
	_ensure_required_player_fields()
	
	player_data_loaded.emit(player_data)
	load_completed.emit(not player_data.is_empty())
	
	# Initialize other systems from loaded data
	if SkillManager:
		SkillManager.initialize_from_save()
	
	return player_data


func load_world_data() -> Dictionary:
	var data = _load_from_file(Constants.WORLD_SAVE_FILE)
	
	if data.is_empty():
		world_data = _get_default_world_data()
	else:
		if data.get("version", 0) != Constants.SAVE_VERSION:
			push_warning("World save version mismatch, migrating...")
			world_data = _migrate_world_data(data)
		else:
			world_data = data.get("world", _get_default_world_data())
	
	# Ensure all required fields are present
	_ensure_required_world_fields()
	
	world_data_loaded.emit(world_data)
	return world_data


func load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(Constants.SETTINGS_FILE)
	
	if error != OK:
		settings_data = _get_default_settings()
		save_settings()
		return
	
	settings_data = {}
	for section in config.get_sections():
		settings_data[section] = {}
		for key in config.get_section_keys(section):
			settings_data[section][key] = config.get_value(section, key)
	
	# Ensure all required fields are present
	_ensure_required_settings_fields()

# =============================================================================
# DEFAULT DATA
# =============================================================================

func _get_default_player_data() -> Dictionary:
	return {
		"id": "player_1",  # Required by validation schema
		"name": "Mage",    # Required by validation schema
		"position": Vector3(0, 0, 0),  # Required by validation schema
		"rotation": 0.0,   # Required by validation schema
		"level": 1,
		"experience": 0,
		"gold": 0,
		"skill_points": 0,
		"unlocked_skills": [],
		"active_ability": "",  ## Currently equipped active ability skill_id
		"stats": {
			"max_health": Constants.DEFAULT_HEALTH,
			"max_magika": Constants.DEFAULT_MAGIKA,
			"max_stamina": Constants.DEFAULT_STAMINA,
			"health_regen": Constants.HEALTH_REGEN_RATE,
			"magika_regen": Constants.MAGIKA_REGEN_RATE,
			"stamina_regen": Constants.STAMINA_REGEN_RATE
		},
		"allocated_stats": {
			## Maps StatType -> int (points allocated to that stat)
			## Enums.StatType.HEALTH: 0, Enums.StatType.MAGIKA: 0, etc.
		},
		"unallocated_stat_points": 0,  ## Points available to spend (awarded per level)
		"stat_points_per_level": 3,    ## Customizable allocation budget per level
		"inventory": [],
		"equipment": {
			"head": null,
			"body": null,
			"belt": null,
			"feet": null,
			"weapon_primary": null,
			"weapon_secondary": null,
			"grimoire": null,
			"potion": null
		},
		"storage": [],  ## Persistent storage chest contents
		"unlocks": [],
		"achievements": []
	}


func _get_default_world_data() -> Dictionary:
	return {
		"story_progress": {
			"current_chapter": 0,
			"quests_completed": [],
			"quests_active": []
		},
		"dungeons_cleared": [],
		"bosses_defeated": [],
		"discovered_locations": ["starting_town"],
		"unlocked_portals": ["starting_town"],  # Fast travel portals
		"npc_states": {},
		"world_events": []
	}


func _get_default_settings() -> Dictionary:
	return {
		"audio": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"voice_volume": 1.0
		},
		"video": {
			"fullscreen": false,
			"vsync": true,
			"resolution_index": 0,
			"quality_preset": 2
		},
		"gameplay": {
			"mouse_sensitivity": Constants.MOUSE_SENSITIVITY,
			"invert_y": false,
			"friendly_fire": false,
			"show_damage_numbers": true
		},
		"controls": {
			# Input remapping would go here
		}
	}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

func _save_to_file(path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: ", path)
		return false
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("Saved data to: ", path)
	return true


func _load_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: ", path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse JSON: ", json.get_error_message())
		return {}
	
	return json.data

# =============================================================================
# DATA MIGRATION
# =============================================================================

func _migrate_player_data(old_data: Dictionary) -> Dictionary:
	# Handle version migrations here
	var new_data = _get_default_player_data()
	
	# Copy over compatible fields
	if old_data.has("player"):
		var old_player = old_data.player
		if old_player.has("level"):
			new_data.level = old_player.level
		if old_player.has("experience"):
			new_data.experience = old_player.experience
		if old_player.has("inventory"):
			new_data.inventory = old_player.inventory
	
	return new_data


func _migrate_world_data(old_data: Dictionary) -> Dictionary:
	var new_data = _get_default_world_data()
	
	if old_data.has("world"):
		var old_world = old_data.world
		if old_world.has("story_progress"):
			new_data.story_progress = old_world.story_progress
		if old_world.has("dungeons_cleared"):
			new_data.dungeons_cleared = old_world.dungeons_cleared
	
	return new_data

# =============================================================================
# DATA VALIDATION & FIELD INITIALIZATION
# =============================================================================

func _ensure_required_player_fields() -> void:
	"""Ensure all required fields exist in player_data with defaults"""
	var defaults = _get_default_player_data()
	for field_key in defaults.keys():
		if not player_data.has(field_key):
			player_data[field_key] = defaults[field_key]


func _ensure_required_world_fields() -> void:
	"""Ensure all required fields exist in world_data with defaults"""
	var defaults = _get_default_world_data()
	for field_key in defaults.keys():
		if not world_data.has(field_key):
			world_data[field_key] = defaults[field_key]


func _ensure_required_settings_fields() -> void:
	"""Ensure all required settings sections exist with defaults"""
	var defaults = _get_default_settings()
	for section in defaults.keys():
		if not settings_data.has(section):
			settings_data[section] = {}
		for key in defaults[section].keys():
			if not settings_data[section].has(key):
				settings_data[section][key] = defaults[section][key]

# =============================================================================
# PLAYER DATA HELPERS
# =============================================================================

func set_player_stat(stat_name: String, value: Variant) -> void:
	if player_data.has("stats"):
		player_data.stats[stat_name] = value


func get_player_stat(stat_name: String, default: Variant = 0) -> Variant:
	if player_data.has("stats"):
		return player_data.stats.get(stat_name, default)
	return default


func add_to_inventory(item_data: Dictionary) -> bool:
	if player_data.inventory.size() >= Constants.INVENTORY_SIZE:
		return false
	player_data.inventory.append(item_data)
	return true


func remove_from_inventory(index: int) -> Dictionary:
	if index < 0 or index >= player_data.inventory.size():
		return {}
	return player_data.inventory.pop_at(index)


func equip_item(slot: String, item_data: Dictionary) -> Dictionary:
	var old_item = player_data.equipment.get(slot)
	player_data.equipment[slot] = item_data
	return old_item if old_item else {}


func unequip_item(slot: String) -> Dictionary:
	var item = player_data.equipment.get(slot)
	player_data.equipment[slot] = null
	return item if item else {}


func add_experience(amount: int) -> bool:
	player_data.experience += amount
	# Check for level up (implement leveling curve)
	var leveled_up = _check_level_up()
	return leveled_up


func _check_level_up() -> bool:
	var exp_needed = _get_exp_for_level(player_data.level + 1)
	var leveled = false
	while player_data.experience >= exp_needed:
		player_data.level += 1
		player_data.skill_points += Constants.SKILL_POINTS_PER_LEVEL
		# Award stat points on level up
		var stat_points_awarded = player_data.get("stat_points_per_level", 3)
		player_data.unallocated_stat_points += stat_points_awarded
		leveled = true
		level_up.emit(player_data.level, Constants.SKILL_POINTS_PER_LEVEL)
		stat_points_changed.emit(player_data.unallocated_stat_points)
		exp_needed = _get_exp_for_level(player_data.level + 1)
	return leveled


func _get_exp_for_level(level: int) -> int:
	# Simple exponential curve
	return int(100 * pow(level, 1.5))


func get_exp_progress() -> Dictionary:
	## Returns current exp, exp needed for next level, and percentage
	var current = player_data.experience
	var needed = _get_exp_for_level(player_data.level + 1)
	var prev_needed = _get_exp_for_level(player_data.level) if player_data.level > 1 else 0
	var progress = float(current - prev_needed) / float(needed - prev_needed)
	return {
		"current": current,
		"needed": needed,
		"progress": clamp(progress, 0.0, 1.0),
		"level": player_data.level
	}


# =============================================================================
# GOLD HELPERS
# =============================================================================

func add_gold(amount: int) -> void:
	# var _old_gold = player_data.gold  # Reserved for logging/history
	player_data.gold += amount
	gold_changed.emit(player_data.gold, amount)


func remove_gold(amount: int) -> bool:
	## Returns false if not enough gold
	if player_data.gold < amount:
		return false
	# var _old_gold = player_data.gold  # Reserved for logging/history
	player_data.gold -= amount
	gold_changed.emit(player_data.gold, -amount)
	return true


func get_gold() -> int:
	return player_data.get("gold", 0)


func has_gold(amount: int) -> bool:
	return player_data.get("gold", 0) >= amount


# =============================================================================
# SKILL HELPERS
# =============================================================================

func get_skill_points() -> int:
	return player_data.get("skill_points", 0)


func use_skill_point() -> bool:
	if player_data.skill_points <= 0:
		return false
	player_data.skill_points -= 1
	return true


func unlock_skill(skill_id: String) -> bool:
	if skill_id in player_data.unlocked_skills:
		return false
	if not use_skill_point():
		return false
	player_data.unlocked_skills.append(skill_id)
	return true


func is_skill_unlocked(skill_id: String) -> bool:
	return skill_id in player_data.unlocked_skills


func get_unlocked_skills() -> Array:
	if player_data.has("unlocked_skills"):
		return player_data.unlocked_skills.duplicate()
	return []


func set_active_ability(skill_id: String) -> void:
	if player_data.has("active_ability"):
		player_data.active_ability = skill_id


func get_active_ability() -> String:
	if player_data.has("active_ability"):
		return player_data.active_ability
	return ""


# =============================================================================
# STAT ALLOCATION HELPERS
# =============================================================================

func allocate_stat_point(stat_type: Enums.StatType) -> bool:
	## Spend one unallocated stat point on a specific stat
	if player_data.get("unallocated_stat_points", 0) <= 0:
		return false
	
	if not player_data.has("allocated_stats"):
		player_data.allocated_stats = {}
	
	# Initialize stat if not present
	if stat_type not in player_data.allocated_stats:
		player_data.allocated_stats[stat_type] = 0
	
	# Allocate one point
	player_data.allocated_stats[stat_type] += 1
	player_data.unallocated_stat_points -= 1
	
	stat_allocated.emit(stat_type, player_data.allocated_stats[stat_type])
	stat_points_changed.emit(player_data.unallocated_stat_points)
	
	return true


func deallocate_stat_point(stat_type: Enums.StatType) -> bool:
	## Refund one allocated stat point
	if not player_data.has("allocated_stats"):
		player_data.allocated_stats = {}
	
	if stat_type not in player_data.allocated_stats or player_data.allocated_stats[stat_type] <= 0:
		return false
	
	# Deallocate one point
	player_data.allocated_stats[stat_type] -= 1
	player_data.unallocated_stat_points += 1
	
	stat_deallocated.emit(stat_type, player_data.allocated_stats[stat_type])
	stat_points_changed.emit(player_data.unallocated_stat_points)
	
	return true


func get_allocated_stat(stat_type: Enums.StatType) -> int:
	## Get the number of points allocated to a specific stat
	if not player_data.has("allocated_stats"):
		return 0
	if stat_type in player_data.allocated_stats:
		return player_data.allocated_stats[stat_type]
	
	# Fallback for string keys if conversion failed
	var string_key = str(int(stat_type))
	if string_key in player_data.allocated_stats:
		return player_data.allocated_stats[string_key]
	
	return 0


func get_allocated_stats() -> Dictionary:
	## Get all allocated stats
	return player_data.get("allocated_stats", {}).duplicate()


func get_available_stat_points() -> int:
	## Get number of unallocated stat points
	return player_data.get("unallocated_stat_points", 0)


func award_stat_points(amount: int) -> void:
	## Award stat points (typically on level up)
	player_data.unallocated_stat_points += amount
	stat_points_changed.emit(player_data.unallocated_stat_points)


# =============================================================================
# STORAGE HELPERS
# =============================================================================

func add_to_storage(item_data: Dictionary) -> bool:
	player_data.storage.append(item_data)
	return true


func remove_from_storage(index: int) -> Dictionary:
	if index < 0 or index >= player_data.storage.size():
		return {}
	return player_data.storage.pop_at(index)


func get_storage() -> Array:
	return player_data.storage

# =============================================================================
# WORLD DATA HELPERS
# =============================================================================

func complete_quest(quest_id: String) -> void:
	if quest_id in world_data.story_progress.quests_active:
		world_data.story_progress.quests_active.erase(quest_id)
	if quest_id not in world_data.story_progress.quests_completed:
		world_data.story_progress.quests_completed.append(quest_id)


func start_quest(quest_id: String) -> void:
	if quest_id not in world_data.story_progress.quests_active:
		if quest_id not in world_data.story_progress.quests_completed:
			world_data.story_progress.quests_active.append(quest_id)


func is_quest_completed(quest_id: String) -> bool:
	return quest_id in world_data.story_progress.quests_completed


func is_quest_active(quest_id: String) -> bool:
	return quest_id in world_data.story_progress.quests_active


func discover_location(location_id: String) -> void:
	if location_id not in world_data.discovered_locations:
		world_data.discovered_locations.append(location_id)


func mark_dungeon_cleared(dungeon_id: String) -> void:
	if dungeon_id not in world_data.dungeons_cleared:
		world_data.dungeons_cleared.append(dungeon_id)


func mark_boss_defeated(boss_id: String) -> void:
	if boss_id not in world_data.bosses_defeated:
		world_data.bosses_defeated.append(boss_id)

# =============================================================================
# GENERIC DATA ACCESS
# =============================================================================

func get_data(key: String, default: Variant = null, data_type: String = "world") -> Variant:
	"""Get arbitrary data by key from the specified data type"""
	var target_data: Dictionary

	match data_type:
		"player":
			target_data = player_data
		"world":
			target_data = world_data
		"settings":
			target_data = settings_data
		_:
			push_warning("Invalid data_type '%s' for get_data, using 'world'" % data_type)
			target_data = world_data

	if key in target_data:
		return target_data[key]
	return default


func set_data(key: String, value: Variant, data_type: String = "world") -> void:
	"""Set arbitrary data by key in the specified data type"""
	var target_data: Dictionary

	match data_type:
		"player":
			target_data = player_data
		"world":
			target_data = world_data
		"settings":
			target_data = settings_data
		_:
			push_warning("Invalid data_type '%s' for set_data, using 'world'" % data_type)
			target_data = world_data

	target_data[key] = value

# =============================================================================
# AUTO-SAVE
# =============================================================================

func start_auto_save() -> void:
	_auto_save_timer.start()


func stop_auto_save() -> void:
	_auto_save_timer.stop()


func _on_auto_save_timeout() -> void:
	if GameManager.current_state == Enums.GameState.PLAYING:
		save_all()
		print("Auto-save completed")

# =============================================================================
# CONVENIENCE ALIASES
# =============================================================================

## Convenience alias for save_all() - intuitive naming
func save_game() -> void:
	save_all()

## Convenience alias for load_player_data() - intuitive naming
func load_game() -> Dictionary:
	return load_player_data()
