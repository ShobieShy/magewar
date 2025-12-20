## QuestData - Complete quest definition
## Contains objectives, rewards, prerequisites, and quest flow
class_name QuestData
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Quest Info")
@export var quest_id: String = ""
@export var quest_name: String = "Unnamed Quest"
@export var description: String = ""
@export var quest_giver: String = ""  ## NPC ID who gives this quest
@export var is_main_quest: bool = false
@export var chapter: int = 0  ## Story chapter (0 = side quest)

@export_group("Objectives")
@export var objectives: Array[QuestObjective] = []
@export var require_all_objectives: bool = true  ## False = any objective completes quest

@export_group("Prerequisites")
@export var required_level: int = 1
@export var required_quests: Array[String] = []  ## Quest IDs that must be completed
@export var required_items: Array[String] = []  ## Items needed to start (not consumed)
@export var required_location: String = ""  ## Must be discovered

@export_group("Rewards")
@export var reward_experience: int = 0
@export var reward_gold: int = 0
@export var reward_items: Array[String] = []  ## Item IDs to give
@export var reward_skill_points: int = 0
@export var unlock_location: String = ""  ## Location ID to unlock
@export var unlock_portal: String = ""  ## Fast travel portal to unlock

@export_group("Flow")
@export var auto_complete: bool = true  ## Complete automatically when objectives done
@export var turn_in_npc: String = ""  ## NPC to turn in to (empty = auto-complete)
@export var next_quest: String = ""  ## Quest ID to start after completion

@export_group("Dialogue")
@export var dialogue_on_accept: String = ""  ## Dialogue ID when accepting
@export var dialogue_on_progress: String = ""  ## Dialogue ID while in progress
@export var dialogue_on_complete: String = ""  ## Dialogue ID when turning in

# =============================================================================
# RUNTIME STATE
# =============================================================================

var state: Enums.QuestState = Enums.QuestState.LOCKED
var _runtime_objectives: Array[QuestObjective] = []

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize() -> void:
	## Create runtime copies of objectives
	_runtime_objectives.clear()
	for obj in objectives:
		var copy = obj.duplicate_objective()
		_runtime_objectives.append(copy)
	state = Enums.QuestState.LOCKED


func start() -> void:
	if state != Enums.QuestState.AVAILABLE:
		push_warning("Cannot start quest %s - not available" % quest_id)
		return
	
	state = Enums.QuestState.ACTIVE
	for obj in _runtime_objectives:
		obj.reset()

# =============================================================================
# OBJECTIVE ACCESS
# =============================================================================

func get_objectives() -> Array[QuestObjective]:
	return _runtime_objectives


func get_objective(objective_id: String) -> QuestObjective:
	for obj in _runtime_objectives:
		if obj.objective_id == objective_id:
			return obj
	return null


func get_objective_by_type(obj_type: Enums.ObjectiveType) -> Array[QuestObjective]:
	var result: Array[QuestObjective] = []
	for obj in _runtime_objectives:
		if obj.objective_type == obj_type:
			result.append(obj)
	return result

# =============================================================================
# PROGRESS TRACKING
# =============================================================================

func update_objective(objective_id: String, progress: int = 1) -> bool:
	## Update objective progress, returns true if quest is now complete
	if state != Enums.QuestState.ACTIVE:
		return false
	
	var obj = get_objective(objective_id)
	if obj:
		obj.add_progress(progress)
		return check_completion()
	return false


func set_objective_progress(objective_id: String, amount: int) -> bool:
	if state != Enums.QuestState.ACTIVE:
		return false
	
	var obj = get_objective(objective_id)
	if obj:
		obj.set_progress(amount)
		return check_completion()
	return false


func fail_objective(objective_id: String) -> void:
	var obj = get_objective(objective_id)
	if obj:
		obj.fail()
		# Check if quest should fail
		if not obj.is_optional:
			state = Enums.QuestState.FAILED


func check_completion() -> bool:
	## Returns true if quest should complete
	if state != Enums.QuestState.ACTIVE:
		return false
	
	var required_done = true
	var any_done = false
	
	for obj in _runtime_objectives:
		if obj.is_failed and not obj.is_optional:
			state = Enums.QuestState.FAILED
			return false
		
		if obj.is_completed:
			any_done = true
		elif not obj.is_optional:
			required_done = false
	
	var should_complete = require_all_objectives and required_done
	should_complete = should_complete or (not require_all_objectives and any_done)
	
	if should_complete and auto_complete and turn_in_npc.is_empty():
		complete()
		return true
	
	return should_complete


func complete() -> void:
	state = Enums.QuestState.COMPLETED


func fail() -> void:
	state = Enums.QuestState.FAILED


func is_ready_to_turn_in() -> bool:
	if state != Enums.QuestState.ACTIVE:
		return false
	
	# Check if completion conditions are met
	if require_all_objectives:
		for obj in _runtime_objectives:
			if not obj.is_completed and not obj.is_optional:
				return false
		return true
	else:
		for obj in _runtime_objectives:
			if obj.is_completed:
				return true
		return false

# =============================================================================
# PREREQUISITE CHECKING
# =============================================================================

func can_start(player_level: int, completed_quests: Array, discovered_locations: Array) -> bool:
	if player_level < required_level:
		return false
	
	for quest_id in required_quests:
		if quest_id not in completed_quests:
			return false
	
	if not required_location.is_empty():
		if required_location not in discovered_locations:
			return false
	
	# Item check handled separately (needs inventory access)
	return true


func check_availability(player_level: int, completed_quests: Array, discovered_locations: Array) -> void:
	if state == Enums.QuestState.LOCKED:
		if can_start(player_level, completed_quests, discovered_locations):
			state = Enums.QuestState.AVAILABLE

# =============================================================================
# DISPLAY
# =============================================================================

func get_progress_summary() -> String:
	var completed_count = 0
	var total_required = 0
	
	for obj in _runtime_objectives:
		if not obj.is_optional:
			total_required += 1
			if obj.is_completed:
				completed_count += 1
	
	return "%d / %d objectives" % [completed_count, total_required]


func get_tooltip() -> String:
	var tooltip = "[b]%s[/b]\n" % quest_name
	
	if is_main_quest:
		tooltip += "[color=gold]Main Quest - Chapter %d[/color]\n" % chapter
	else:
		tooltip += "[color=gray]Side Quest[/color]\n"
	
	tooltip += "\n%s\n" % description
	
	tooltip += "\n[u]Objectives:[/u]\n"
	for obj in _runtime_objectives:
		if not obj.is_hidden or obj.is_revealed:
			var icon = "[X]" if obj.is_completed else "[ ]"
			tooltip += "%s %s\n" % [icon, obj.get_display_text()]
	
	if reward_experience > 0 or reward_gold > 0 or reward_items.size() > 0:
		tooltip += "\n[u]Rewards:[/u]\n"
		if reward_experience > 0:
			tooltip += "- %d XP\n" % reward_experience
		if reward_gold > 0:
			tooltip += "- %d Gold\n" % reward_gold
		if reward_skill_points > 0:
			tooltip += "- %d Skill Points\n" % reward_skill_points
		for item_id in reward_items:
			tooltip += "- %s\n" % item_id
	
	return tooltip

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	var obj_data: Array = []
	for obj in _runtime_objectives:
		obj_data.append(obj.get_save_data())
	
	return {
		"quest_id": quest_id,
		"state": state,
		"objectives": obj_data
	}


func load_save_data(data: Dictionary) -> void:
	state = data.get("state", Enums.QuestState.LOCKED)
	
	var obj_data = data.get("objectives", [])
	for i in range(min(obj_data.size(), _runtime_objectives.size())):
		_runtime_objectives[i].load_save_data(obj_data[i])


func duplicate_quest() -> QuestData:
	var copy = duplicate(true) as QuestData
	copy.initialize()
	return copy
