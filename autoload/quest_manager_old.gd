## QuestManager - Global quest tracking and progression
## Handles quest state, objective updates, and rewards
extends Node

# =============================================================================
# CO-OP INTEGRATION
# =============================================================================

## Track quest sharing state
var shared_quests: Dictionary = {}  ## quest_id -> Dictionary with sharing data

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func is_multiplayer() -> bool:
	## Check if currently in multiplayer mode
	return NetworkManager.network_mode != Enums.NetworkMode.OFFLINE

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================
# SIGNALS
# =============================================================================

signal quest_available(quest: QuestData)
signal quest_started(quest: QuestData)
signal quest_completed(quest: QuestData)
signal quest_failed(quest: QuestData)
signal objective_updated(quest: QuestData, objective: QuestObjective)
signal objective_completed(quest: QuestData, objective: QuestObjective)

# =============================================================================
# PROPERTIES
# =============================================================================

## All quest definitions (loaded from resources)
var _quest_database: Dictionary = {}  ## quest_id -> QuestData

## Active runtime quest instances
var _active_quests: Dictionary = {}  ## quest_id -> QuestData (runtime copy)

## Completed quest IDs (for quick lookup)
var _completed_quests: Array[String] = []

## Tracked quest for HUD display
var tracked_quest_id: String = ""

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Load quest database from resources
	_load_quest_database()
	



func _process(delta: float) -> void:
	# Update timed objectives
	_update_timed_objectives(delta)
	
	# Handle co-op quest sharing
	if is_multiplayer():
		_process_coop_sharing(delta)

# =============================================================================
# DATABASE MANAGEMENT
# =============================================================================

func _load_quest_database() -> void:
	## Load all quest resources from the quests folder
	var quest_path = "res://resources/quests/definitions/"
	var dir = DirAccess.open(quest_path)
	
	if dir == null:
		# Directory doesn't exist yet, that's okay
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var quest = load(quest_path + file_name) as QuestData
			if quest:
				register_quest(quest)
		file_name = dir.get_next()
	
	dir.list_dir_end()


func register_quest(quest: QuestData) -> void:
	## Register a quest in the database
	_quest_database[quest.quest_id] = quest


func get_quest_definition(quest_id: String) -> QuestData:
	return _quest_database.get(quest_id)

# =============================================================================
# QUEST STATE MANAGEMENT
# =============================================================================

func start_quest(quest_id: String) -> bool:
	if quest_id in _active_quests:
		push_warning("Quest already active: %s" % quest_id)
		return false
	
	if quest_id in _completed_quests:
		push_warning("Quest already completed: %s" % quest_id)
		return false
	
	var definition = _quest_database.get(quest_id)
	if definition == null:
		push_error("Quest not found: %s" % quest_id)
		return false
	
	# Create runtime copy
	var quest = definition.duplicate_quest()
	quest.state = Enums.QuestState.AVAILABLE
	quest.start()
	
	_active_quests[quest_id] = quest
	
	# Update SaveManager
	SaveManager.start_quest(quest_id)
	
	quest_started.emit(quest)
	
	# Auto-track if no quest tracked
	if tracked_quest_id.is_empty():
		tracked_quest_id = quest_id
	
	# Share quest with all players in multiplayer
	if is_multiplayer():
		_share_quest_with_party(quest_id)
	
	return true


func complete_quest(quest_id: String) -> void:
	var quest = _active_quests.get(quest_id)
	if quest == null:
		push_warning("Cannot complete - quest not active: %s" % quest_id)
		return
	
	quest.complete()
	
	# Give rewards
	_give_quest_rewards(quest)
	
	# Update tracking
	_active_quests.erase(quest_id)
	_completed_quests.append(quest_id)
	
	# Update SaveManager
	SaveManager.complete_quest(quest_id)
	
	quest_completed.emit(quest)
	
	# Start next quest if specified
	if not quest.next_quest.is_empty():
		# Check if next quest is available
		var next_def = _quest_database.get(quest.next_quest)
		if next_def:
			call_deferred("_check_quest_availability", quest.next_quest)
	
	# Clear tracked if this was tracked
	if tracked_quest_id == quest_id:
		tracked_quest_id = ""
		_auto_track_next_quest()


func fail_quest(quest_id: String) -> void:
	var quest = _active_quests.get(quest_id)
	if quest == null:
		return
	
	quest.fail()
	_active_quests.erase(quest_id)
	
	quest_failed.emit(quest)
	
	if tracked_quest_id == quest_id:
		tracked_quest_id = ""
		_auto_track_next_quest()


func abandon_quest(quest_id: String) -> void:
	## Player abandons quest (can restart later)
	var quest = _active_quests.get(quest_id)
	if quest == null:
		return
	
	_active_quests.erase(quest_id)
	
	# Remove from SaveManager active quests
	if quest_id in SaveManager.world_data.story_progress.quests_active:
		SaveManager.world_data.story_progress.quests_active.erase(quest_id)
	
	if tracked_quest_id == quest_id:
		tracked_quest_id = ""
		_auto_track_next_quest()

# =============================================================================
# OBJECTIVE UPDATES
# =============================================================================

func report_kill(enemy_type: Enums.EnemyType, enemy_id: String = "") -> void:
	## Called when an enemy is killed
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]

		for obj in quest.get_objectives():
			if obj.is_completed or obj.is_failed:
				continue

			match obj.objective_type:
				Enums.ObjectiveType.KILL_ENEMY:
					# Check if enemy type matches (target_id stores enum value as string)
					if str(enemy_type) == obj.target_id or obj.target_id.is_empty():
						_update_objective(quest, obj)

				Enums.ObjectiveType.KILL_SPECIFIC:
					if enemy_id == obj.target_id:
						_update_objective(quest, obj)

				Enums.ObjectiveType.DEFEAT_BOSS:
					if enemy_id == obj.target_id:
						_update_objective(quest, obj)

			# Share kill progress in co-op
			if is_multiplayer():
				_sync_objective_progress(quest_id, obj.objective_id, {"enemy_type": str(enemy_type), "enemy_id": enemy_id, "count": 1})


func report_item_collected(item_id: String, count: int = 1) -> void:
	## Called when an item is picked up
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]
		
		for obj in quest.get_objectives():
			if obj.is_completed or obj.is_failed:
				continue
			
			if obj.objective_type == Enums.ObjectiveType.COLLECT_ITEM:
				if obj.target_id == item_id:
					_update_objective(quest, obj, count)
					
					# Share collection progress in co-op
					if is_multiplayer():
						_sync_objective_progress(quest_id, obj.objective_id, {"item_id": item_id, "count": count})


func report_npc_talked(npc_id: String) -> void:
	## Called when player talks to an NPC
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]
		
		for obj in quest.get_objectives():
			if obj.is_completed or obj.is_failed:
				continue
			
			if obj.objective_type == Enums.ObjectiveType.TALK_TO_NPC:
				if obj.target_id == npc_id:
					_update_objective(quest, obj)


func report_area_entered(area_id: String) -> void:
	## Called when player enters a trigger area
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]
		
		for obj in quest.get_objectives():
			if obj.is_completed or obj.is_failed:
				continue
			
			if obj.objective_type == Enums.ObjectiveType.DISCOVER_AREA:
				if obj.target_id == area_id:
					_update_objective(quest, obj)


func report_object_interacted(object_id: String) -> void:
	## Called when player interacts with a quest object
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]
		
		for obj in quest.get_objectives():
			if obj.is_completed or obj.is_failed:
				continue
			
			if obj.objective_type == Enums.ObjectiveType.INTERACT_OBJECT:
				if obj.target_id == object_id:
					_update_objective(quest, obj)


func report_escort_progress(npc_id: String, reached_destination: bool, npc_died: bool = false) -> void:
	## Called for escort quest updates
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]
		
		for obj in quest.get_objectives():
			if obj.is_completed or obj.is_failed:
				continue
			
			if obj.objective_type == Enums.ObjectiveType.ESCORT_NPC:
				if obj.target_id == npc_id:
					if npc_died:
						obj.fail()
						objective_updated.emit(quest, obj)
						quest.check_completion()
					elif reached_destination:
						_update_objective(quest, obj)


func report_custom_objective(quest_id: String, objective_id: String, completed: bool = true) -> void:
	## For CUSTOM objective type - manual completion
	var quest = _active_quests.get(quest_id)
	if quest == null:
		return
	
	var obj = quest.get_objective(objective_id)
	if obj and obj.objective_type == Enums.ObjectiveType.CUSTOM:
		if completed:
			_update_objective(quest, obj)
		else:
			obj.fail()
			objective_updated.emit(quest, obj)


func _update_objective(quest: QuestData, obj: QuestObjective, amount: int = 1) -> void:
	var was_completed = obj.is_completed
	obj.add_progress(amount)
	
	objective_updated.emit(quest, obj)
	
	if obj.is_completed and not was_completed:
		objective_completed.emit(quest, obj)
	
	# Check if quest is complete
	if quest.check_completion():
		if quest.state == Enums.QuestState.COMPLETED:
			complete_quest(quest.quest_id)

# =============================================================================
# TIMED OBJECTIVES
# =============================================================================

func _update_timed_objectives(delta: float) -> void:
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]
		
		for obj in quest.get_objectives():
			if obj.is_completed or obj.is_failed:
				continue
			
			if obj.objective_type == Enums.ObjectiveType.SURVIVE_TIME:
				obj.time_remaining -= delta
				if obj.time_remaining <= 0:
					obj.time_remaining = 0
					_update_objective(quest, obj)
			
			elif obj.time_limit > 0 and obj.fail_on_timeout:
				obj.time_remaining -= delta
				if obj.time_remaining <= 0:
					obj.fail()
					objective_updated.emit(quest, obj)
					quest.check_completion()

# =============================================================================
# REWARDS
# =============================================================================

func _give_quest_rewards(quest: QuestData) -> void:
	if quest.reward_experience > 0:
		SaveManager.add_experience(quest.reward_experience)
	
	if quest.reward_gold > 0:
		SaveManager.add_gold(quest.reward_gold)
	
	if quest.reward_skill_points > 0:
		SaveManager.player_data.skill_points += quest.reward_skill_points
	
	# Items would need to be added to inventory
	# This requires integration with InventorySystem
	
	if not quest.unlock_location.is_empty():
		SaveManager.discover_location(quest.unlock_location)
	
	if not quest.unlock_portal.is_empty():
		if quest.unlock_portal not in SaveManager.world_data.unlocked_portals:
			SaveManager.world_data.unlocked_portals.append(quest.unlock_portal)

# =============================================================================
# CO-OP SHARING METHODS
# =============================================================================

func _share_quest_with_party(quest_id: String) -> void:
	## Share quest with all connected players
	if not NetworkManager.is_server:
		return
	
	var quest = _quest_database.get(quest_id)
	if quest == null:
		return
	
	# Mark as shared
	var share_data = {
		"id": quest_id,
		"name": quest.quest_name,
		"description": quest.description,
		"required_level": quest.required_level,
		"initiator": NetworkManager.local_peer_id
	}
	
	shared_quests[quest_id] = share_data
	
	# Broadcast to all clients
	if NetworkManager.is_server:
		_rpc_share_quest.rpc_id(1, quest_id, share_data)
	
	print("Quest shared with party: %s" % quest.quest_name)

# =============================================================================
# QUERY METHODS
# =============================================================================

func get_active_quests() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for quest in _active_quests.values():
		result.append(quest)
	return result


func get_active_quest(quest_id: String) -> QuestData:
	return _active_quests.get(quest_id)


func is_quest_active(quest_id: String) -> bool:
	return quest_id in _active_quests


func is_quest_completed(quest_id: String) -> bool:
	return quest_id in _completed_quests


func get_available_quests() -> Array[QuestData]:
	## Returns quests that can be started
	var result: Array[QuestData] = []
	var player_level = SaveManager.player_data.level
	var discovered = SaveManager.world_data.discovered_locations
	
	for quest_id in _quest_database:
		if quest_id in _active_quests or quest_id in _completed_quests:
			continue
		
		var quest = _quest_database[quest_id]
		if quest.can_start(player_level, _completed_quests, discovered):
			result.append(quest)
	
	return result


func get_tracked_quest() -> QuestData:
	if tracked_quest_id.is_empty():
		return null
	return _active_quests.get(tracked_quest_id)


func track_quest(quest_id: String) -> void:
	if quest_id in _active_quests:
		tracked_quest_id = quest_id


func _auto_track_next_quest() -> void:
	## Auto-track a main quest, or first available quest
	for quest_id in _active_quests:
		var quest = _active_quests[quest_id]
		if quest.is_main_quest:
			tracked_quest_id = quest_id
			return
	
	# No main quest, track first available
	if _active_quests.size() > 0:
		tracked_quest_id = _active_quests.keys()[0]


func _check_quest_availability(quest_id: String) -> void:
	var definition = _quest_database.get(quest_id)
	if definition == null:
		return
	
	var player_level = SaveManager.player_data.level
	var discovered = SaveManager.world_data.discovered_locations
	
	if definition.can_start(player_level, _completed_quests, discovered):
		quest_available.emit(definition)

# =============================================================================
# RPC METHODS (CO-OP)
# =============================================================================

@rpc("authority", "call_remote", "reliable")
func _rpc_share_quest(quest_id: String, share_data: Dictionary) -> void:
	## Client receives shared quest data
	shared_quests[quest_id] = share_data
	
	# Show UI prompt for accepting/declining
	print("Quest Share Prompt: %s" % share_data.get("name", "Unknown Quest"))
	
	# Auto-accept for now (in real implementation, show UI choice)
	start_quest(quest_id)

@rpc("authority", "call_remote", "reliable")
func _rpc_sync_objective(quest_id: String, objective_id: String, progress_data: Dictionary) -> void:
	## Client receives objective update
	var quest = _active_quests.get(quest_id)
	if quest:
		var objective = quest.get_objective(objective_id)
		if objective:
			_apply_progress_data(objective, progress_data)

@rpc("authority", "call_remote", "reliable")
func _rpc_quest_completed(quest_id: String, rewards: Dictionary) -> void:
	## Client receives quest completion notification
	print("Quest completed notification: %s" % quest_id)
	
	# Show rewards UI
	print("Quest Rewards:")
	print("  Experience: %d" % rewards.get("experience", 0))
	print("  Gold: %d" % rewards.get("gold", 0))

# =============================================================================
# SYNC METHODS
# =============================================================================

func _sync_objective_progress(quest_id: String, objective_id: String, progress_data: Dictionary) -> void:
	## Sync objective progress to all players
	if not NetworkManager.is_server:
		return
	
	# Update local quest manager
	var quest = _active_quests.get(quest_id)
	if quest:
		var objective = quest.get_objective(objective_id)
		if objective:
			# Apply progress based on data type
			_apply_progress_data(objective, progress_data)
	
	# Broadcast to all clients
	_rpc_sync_objective.rpc_id(1, quest_id, objective_id, progress_data)

func _apply_progress_data(objective: QuestObjective, progress_data: Dictionary) -> void:
	## Apply progress data based on objective type
	match objective.objective_type:
		Enums.ObjectiveType.KILL_ENEMY, Enums.ObjectiveType.KILL_SPECIFIC:
			if progress_data.has("count"):
				_update_objective(null, objective, progress_data.count)
		
		Enums.ObjectiveType.COLLECT_ITEM:
			if progress_data.has("count"):
				_update_objective(null, objective, progress_data.count)
		
		Enums.ObjectiveType.TALK_TO_NPC:
			_update_objective(null, objective, 1)
		
		Enums.ObjectiveType.DISCOVER_AREA:
			_update_objective(null, objective, 1)

# =============================================================================
# CO-OP SHARING METHODS
# =============================================================================

func _process_coop_sharing(delta: float) -> void:
	## Handle co-op specific quest sharing logic
	pass



# =============================================================================
# SAVE/LOAD
# =============================================================================

func get_save_data() -> Dictionary:
	var active_data: Dictionary = {}
	for quest_id in _active_quests:
		active_data[quest_id] = _active_quests[quest_id].get_save_data()
	
	return {
		"active_quests": active_data,
		"completed_quests": _completed_quests.duplicate(),
		"tracked_quest": tracked_quest_id,
		"shared_quests": shared_quests
	}


func load_save_data(data: Dictionary) -> void:
	_completed_quests.clear()
	_active_quests.clear()
	shared_quests.clear()
	
	_completed_quests = Array(data.get("completed_quests", []), TYPE_STRING, "", null)
	tracked_quest_id = data.get("tracked_quest", "")
	
	# Restore shared quests
	var shared_data = data.get("shared_quests", {})
	for quest_id in shared_data:
		shared_quests[quest_id] = shared_data[quest_id]
	
	# Restore active quests
	var active_data = data.get("active_quests", {})
	for quest_id in active_data:
		var definition = _quest_database.get(quest_id)
		if definition:
			var quest = definition.duplicate_quest()
			quest.load_save_data(active_data[quest_id])
			_active_quests[quest_id] = quest
