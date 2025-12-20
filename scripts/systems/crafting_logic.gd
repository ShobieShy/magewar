## CraftingLogic - Complete weapon crafting system
## Handles weapon creation from parts and gems with recipe discovery and achievements
class_name CraftingLogic
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal crafting_started(config: WeaponConfiguration)
signal crafting_completed(weapon: ItemData, success: bool)
signal crafting_failed(error: String)
signal recipe_discovered(recipe: CraftingRecipe)
signal achievement_unlocked(achievement: CraftingAchievement)

# =============================================================================
# PROPERTIES
# =============================================================================

# System references
var inventory_system: InventorySystem
var skill_manager: SkillManager

# Crafting configuration
@export var enable_crafting: bool = true
@export var base_crafting_time: float = 3.0
@export var max_crafting_time: float = 30.0

# Crafting state
var _is_crafting: bool = false
var _current_config: WeaponConfiguration = null
var _crafting_timer: Timer = null
var _crafting_start_time: float = 0.0

# Manager instances
var _recipe_manager: CraftingRecipeManager
var _achievement_manager: CraftingAchievementManager

# Difficulty multipliers
const DIFFICULTY_MULTIPLIERS: Dictionary = {
	"easy": 1.2,
	"normal": 1.0,
	"hard": 0.8,
	"expert": 0.6
}

# Crafting costs
const BASE_CRAFT_COST_PER_PART: int = 25
const GEM_CRAFT_COST_MULTIPLIER: float = 1.5

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Initialize managers
	_recipe_manager = CraftingRecipeManager.new()
	_achievement_manager = CraftingAchievementManager.new()
	add_child(_recipe_manager)
	add_child(_achievement_manager)
	
	# Connect manager signals
	_recipe_manager.recipe_discovered.connect(_on_recipe_discovered)
	_achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)
	
	# Initialize crafting timer
	_crafting_timer = Timer.new()
	_crafting_timer.timeout.connect(_on_crafting_timer_timeout)
	add_child(_crafting_timer)
	
	# Get system references
	inventory_system = get_node_or_null("/root/InventorySystem")
	skill_manager = get_node_or_null("/root/SkillManager")
	
	# Fallback if systems don't exist yet
	if not inventory_system:
		print("Warning: InventorySystem not found, using fallback")
		inventory_system = preload("res://scripts/systems/inventory_system.gd").new()
	
	if not skill_manager:
		print("Warning: SkillManager not found, using fallback")
		skill_manager = preload("res://autoload/skill_manager.gd").new()
	
	print("CraftingLogic system initialized")

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Start crafting with a weapon configuration
func start_crafting(config: WeaponConfiguration, player_level: int = 1) -> bool:
	if not enable_crafting:
		crafting_failed.emit("Crafting is disabled")
		return false
	
	if _is_crafting:
		crafting_failed.emit("Already crafting")
		return false
	
	if not config or not config.is_complete():
		crafting_failed.emit("Invalid configuration: Missing required parts")
		return false
	
	# Check player level requirement
	if player_level < config.weapon_level:
		crafting_failed.emit("Player level too low (requires %d)" % config.weapon_level)
		return false
	
	# Check if player has required materials
	if not _can_afford_crafting(config):
		crafting_failed.emit("Insufficient materials or gold")
		return false
	
	# Check inventory space
	if inventory_system and inventory_system.is_full():
		crafting_failed.emit("Inventory full")
		return false
	
	# Start crafting process
	_current_config = config
	_is_crafting = true
	_crafting_start_time = Time.get_time_dict_from_system().hour
	
	# Consume materials upfront
	_consume_materials(config)
	
	# Start crafting timer
	var craft_time = _calculate_final_craft_time(config, player_level)
	_crafting_timer.wait_time = craft_time
	_crafting_timer.start()
	
	crafting_started.emit(config)
	
	print("Started crafting %s (time: %.1fs)" % [config.weapon_name, craft_time])
	return true

## Cancel current crafting operation
func cancel_crafting() -> bool:
	if not _is_crafting:
		return false
	
	_is_crafting = false
	_crafting_timer.stop()
	
	# Return materials (simplified - in full implementation would track consumed materials)
	if _current_config:
		print("Cancelled crafting of %s" % _current_config.weapon_name)
		_current_config = null
	
	return true

## Check if crafting is in progress
func is_crafting() -> bool:
	return _is_crafting

## Get current crafting progress (0.0 to 1.0)
func get_crafting_progress() -> float:
	if not _is_crafting or not _crafting_timer:
		return 0.0
	
	if _crafting_timer.time_left <= 0:
		return 1.0
	
	var total_time = _crafting_timer.wait_time
	var elapsed = total_time - _crafting_timer.time_left
	
	return clamp(elapsed / total_time, 0.0, 1.0)

## Get crafting time remaining in seconds
func get_crafting_time_remaining() -> float:
	if not _is_crafting or not _crafting_timer:
		return 0.0
	
	return _crafting_timer.time_left

## Simulate crafting result (for preview/calculations)
func simulate_craft_result(config: WeaponConfiguration, player_level: int = 1) -> Dictionary:
	if not config:
		return {"success": false, "error": "Invalid configuration"}
	
	# Calculate final success chance with player modifiers
	var base_chance = config.success_chance
	var final_chance = _calculate_player_success_modifier(base_chance, player_level)
	
	return {
		"success": randf() < final_chance,
		"success_chance": final_chance,
		"craft_time": _calculate_final_craft_time(config, player_level),
		"craft_cost": _calculate_final_craft_cost(config),
		"weapon_level": config.weapon_level,
		"weapon_rarity": config.weapon_rarity
	}

# =============================================================================
# CRAFTING LOGIC
# =============================================================================

func _on_crafting_timer_timeout() -> void:
	if not _is_crafting or not _current_config:
		return
	
	# Get player level
	var player_level = 1
	if SaveManager and SaveManager.player_data:
		player_level = SaveManager.player_data.get("level", 1)
	
	# Calculate final success chance
	var base_chance = _current_config.success_chance
	var final_chance = _calculate_player_success_modifier(base_chance, player_level)
	
	# Roll for success
	var success = randf() < final_chance
	_is_crafting = false
	
	if success:
		# Create and add weapon
		var weapon = _create_weapon_from_config(_current_config, player_level)
		if weapon:
			# Add to inventory
			if inventory_system:
				var slot = inventory_system.add_item(weapon)
				if slot >= 0:
					# Process achievements and recipe discovery
					_process_crafting_success(weapon, _current_config, player_level)
					crafting_completed.emit(weapon, true)
				else:
					crafting_failed.emit("Inventory full when adding weapon")
			else:
				crafting_completed.emit(weapon, true)
		else:
			crafting_failed.emit("Failed to create weapon from configuration")
	else:
		crafting_failed.emit("Crafting failed - try again")
	
	_current_config = null

func _create_weapon_from_config(config: WeaponConfiguration, player_level: int) -> ItemData:
	## Create actual weapon item from configuration
	var weapon = ItemData.new()
	
	# Basic properties
	weapon.item_id = "crafted_" + config.weapon_name.to_lower().replace(" ", "_") + "_" + str(Time.get_unix_time_from_system())
	weapon.item_name = config.generate_weapon_name()
	weapon.description = config.generate_weapon_description()
	weapon.item_type = Enums.ItemType.EQUIPMENT
	weapon.rarity = config.weapon_rarity
	weapon.level_required = config.weapon_level
	
	# Calculate value
	weapon.base_value = _calculate_weapon_value(config)
	
	# Store crafting metadata
	weapon.set_meta("crafted", true)
	weapon.set_meta("crafting_date", Time.get_unix_time_from_system())
	weapon.set_meta("parts", _get_part_metadata(config))
	weapon.set_meta("gems", _get_gem_metadata(config))
	weapon.set_meta("stats", config.stats)
	
	# Register in item database
	ItemDatabase.register_item(weapon)
	
	return weapon

func _process_crafting_success(weapon: ItemData, config: WeaponConfiguration, player_level: int) -> void:
	# Process recipe discovery
	var discovered_recipe = _recipe_manager.process_crafting_attempt(config, player_level, _get_crafting_skill())
	if discovered_recipe:
		recipe_discovered.emit(discovered_recipe)
	
	# Process achievements
	var progressed_achievements = _achievement_manager.process_crafting_event(weapon, config, inventory_system)
	
	# Give crafting experience
	_give_crafting_experience(config)

func _get_crafting_skill() -> float:
	## Get player's crafting skill level
	if skill_manager:
		# This would interface with the actual skill system
		return skill_manager.get_skill_level("crafting")
	return 1.0

func _give_crafting_experience(config: WeaponConfiguration) -> void:
	## Award experience based on crafting complexity
	if not skill_manager:
		return
	
	var base_exp = 25
	var rarity_multiplier = Constants.RARITY_STAT_MULTIPLIERS.get(config.weapon_rarity, 1.0)
	var part_bonus = config.get_total_part_count() * 5
	var gem_bonus = config.gems.size() * 10
	
	var total_exp = int((base_exp + part_bonus + gem_bonus) * rarity_multiplier)
	skill_manager.add_experience(total_exp)

# =============================================================================
# CALCULATION METHODS
# =============================================================================

func _calculate_final_craft_time(config: WeaponConfiguration, player_level: int) -> float:
	## Calculate final crafting time with player modifiers
	var base_time = config.craft_time
	
	# Player skill reduces time
	var skill_bonus = _get_crafting_skill() * 0.05  # 5% reduction per skill point
	base_time *= (1.0 - min(skill_bonus, 0.5))  # Max 50% reduction
	
	# Difficulty modifier
	var difficulty_mult = DIFFICULTY_MULTIPLIERS.get(config.crafting_difficulty, 1.0)
	base_time *= difficulty_mult
	
	return clamp(base_time, 1.0, max_crafting_time)

func _calculate_final_craft_cost(config: WeaponConfiguration) -> int:
	## Calculate final gold cost with modifiers
	var base_cost = config.craft_cost
	
	# Player skill reduces cost
	var skill_bonus = _get_crafting_skill() * 0.02  # 2% reduction per skill point
	base_cost = int(base_cost * (1.0 - min(skill_bonus, 0.3)))  # Max 30% reduction
	
	return max(base_cost, 10)  # Minimum cost of 10 gold

func _calculate_player_success_modifier(base_chance: float, player_level: int) -> float:
	## Apply player level and skill bonuses to success chance
	var final_chance = base_chance
	
	# Level bonus (2% per level above weapon level)
	var level_diff = player_level - _current_config.weapon_level
	if level_diff > 0:
		final_chance += level_diff * 0.02
	
	# Crafting skill bonus (3% per skill point)
	var crafting_skill = _get_crafting_skill()
	final_chance += crafting_skill * 0.03
	
	# Luck perks or equipment could modify this here
	
	return clamp(final_chance, 0.1, 0.95)  # Between 10% and 95%

func _calculate_weapon_value(config: WeaponConfiguration) -> int:
	## Calculate weapon base value from parts and rarity
	var part_value = 0
	
	# Sum part values
	if config.head:
		part_value += config.head.get_value()
	if config.exterior:
		part_value += config.exterior.get_value()
	if config.interior:
		part_value += config.interior.get_value()
	if config.handle:
		part_value += config.handle.get_value()
	if config.charm:
		part_value += config.charm.get_value()
	
	# Add gem values
	for gem in config.gems:
		part_value += gem.get_value()
	
	# Apply rarity multiplier
	var rarity_mult = Constants.RARITY_STAT_MULTIPLIERS.get(config.weapon_rarity, 1.0)
	
	# Crafting bonus
	var crafting_bonus = 1.2
	
	return int(part_value * rarity_mult * crafting_bonus)

# =============================================================================
# VALIDATION AND REQUIREMENTS
# =============================================================================

func _can_afford_crafting(config: WeaponConfiguration) -> bool:
	## Check if player can afford the crafting cost
	var gold_cost = _calculate_final_craft_cost(config)
	var player_gold = 0
	if SaveManager and SaveManager.player_data:
		player_gold = SaveManager.player_data.get("gold", 0)
	
	if player_gold < gold_cost:
		return false
	
	# Check inventory for required parts (simplified check)
	return _has_required_materials(config)

func _has_required_materials(config: WeaponConfiguration) -> bool:
	## Check if player has all required materials in inventory
	if not inventory_system:
		return true  # Assume valid if no inventory system
	
	# Check each part
	var required_parts = [config.head, config.exterior, config.interior, config.handle, config.charm]
	for part in required_parts:
		if part and not inventory_system.has_item(part.item_id):
			return false
	
	# Check gems
	for gem in config.gems:
		if gem and not inventory_system.has_item(gem.item_id):
			return false
	
	return true

func _consume_materials(config: WeaponConfiguration) -> void:
	## Consume materials from inventory
	if not inventory_system:
		return
	
	# Deduct gold cost
	var gold_cost = _calculate_final_craft_cost(config)
	if SaveManager:
		SaveManager.add_gold(-gold_cost)
	
	# Remove parts
	var required_parts = [config.head, config.exterior, config.interior, config.handle, config.charm]
	for part in required_parts:
		if part:
			inventory_system.remove_item_by_id(part.item_id, 1)
	
	# Remove gems
	for gem in config.gems:
		if gem:
			inventory_system.remove_item_by_id(gem.item_id, 1)

# =============================================================================
# METADATA HELPERS
# =============================================================================

func _get_part_metadata(config: WeaponConfiguration) -> Dictionary:
	var metadata = {}
	
	if config.head:
		metadata["head"] = config.head.item_id
	if config.exterior:
		metadata["exterior"] = config.exterior.item_id
	if config.interior:
		metadata["interior"] = config.interior.item_id
	if config.handle:
		metadata["handle"] = config.handle.item_id
	if config.charm:
		metadata["charm"] = config.charm.item_id
	
	return metadata

func _get_gem_metadata(config: WeaponConfiguration) -> Array:
	var metadata = []
	
	for gem in config.gems:
		if gem:
			metadata.append(gem.item_id)
	
	return metadata

# =============================================================================
# MANAGER ACCESS
# =============================================================================

## Get recipe manager instance
func get_recipe_manager() -> CraftingRecipeManager:
	return _recipe_manager

## Get achievement manager instance
func get_achievement_manager() -> CraftingAchievementManager:
	return _achievement_manager

## Get crafting statistics
func get_crafting_stats() -> Dictionary:
	var recipe_stats = _recipe_manager.get_crafting_stats()
	var achievement_stats = _achievement_manager.get_achievement_stats()
	
	return {
		"is_crafting": _is_crafting,
		"current_progress": get_crafting_progress(),
		"time_remaining": get_crafting_time_remaining(),
		"recipe_stats": recipe_stats,
		"achievement_stats": achievement_stats
	}

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_recipe_discovered(recipe: CraftingRecipe) -> void:
	recipe_discovered.emit(recipe)
	print("Recipe Discovered: %s" % recipe.recipe_name)

func _on_achievement_unlocked(achievement: CraftingAchievement) -> void:
	achievement_unlocked.emit(achievement)
	print("Achievement Unlocked: %s" % achievement.achievement_name)

# =============================================================================
# DEBUGGING AND UTILITIES
# =============================================================================

## Debug function to create a test configuration
func create_test_configuration(weapon_type: String = "staff") -> WeaponConfiguration:
	var config = WeaponConfiguration.new()
	config.weapon_type = weapon_type
	
	# Add some test parts (this would use actual items from database)
	if weapon_type == "staff":
		config.weapon_level = 5
		config.weapon_rarity = Enums.Rarity.UNCOMMON
	else:
		config.weapon_level = 3
		config.weapon_rarity = Enums.Rarity.BASIC
	
	config._recalculate_stats()
	return config

## Print detailed crafting information
func debug_print_crafting_info(config: WeaponConfiguration) -> void:
	if not config:
		print("Cannot debug null configuration")
		return
	
	print("=== Crafting Debug Info ===")
	print("Weapon Type: %s" % config.weapon_type)
	print("Weapon Level: %d" % config.weapon_level)
	print("Weapon Rarity: %s" % Enums.Rarity.keys()[config.weapon_rarity])
	print("Total Parts: %d" % config.get_total_part_count())
	print("Total Gems: %d" % config.gems.size())
	print("Base Success Chance: %.1f%%" % (config.success_chance * 100))
	print("Craft Time: %.1fs" % config.craft_time)
	print("Craft Cost: %d gold" % config.craft_cost)
	
	if config.stats:
		print("\nWeapon Stats:")
		for key in config.stats:
			print("  %s: %s" % [key, config.stats[key]])
	
	print("========================")