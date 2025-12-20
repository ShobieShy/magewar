## QuestObjective - Single objective within a quest
## Supports multiple objective types for map-making flexibility
class_name QuestObjective
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Objective Info")
@export var objective_id: String = ""
@export var description: String = ""
@export var objective_type: Enums.ObjectiveType = Enums.ObjectiveType.KILL_ENEMY
@export var is_optional: bool = false
@export var is_hidden: bool = false  ## Don't show until triggered

@export_group("Target Configuration")
## For KILL_ENEMY: enemy type enum value
## For KILL_SPECIFIC, TALK_TO_NPC, DEFEAT_BOSS, ESCORT_NPC: specific entity ID
## For COLLECT_ITEM: item_id
## For DISCOVER_AREA, INTERACT_OBJECT: trigger/object ID
## For CUSTOM: callback method name
@export var target_id: String = ""
@export var target_count: int = 1  ## How many to kill/collect/etc.

@export_group("Location (Optional)")
@export var required_location: String = ""  ## Must be in this area
@export var location_radius: float = 0.0  ## 0 = anywhere in location

@export_group("Time Constraints")
@export var time_limit: float = 0.0  ## 0 = no time limit (for SURVIVE_TIME this is duration)
@export var fail_on_timeout: bool = false  ## If true, quest fails when time runs out

@export_group("Escort Settings (if ESCORT_NPC)")
@export var escort_destination: String = ""  ## Destination trigger ID
@export var escort_min_health_percent: float = 0.0  ## NPC must stay above this health %

# =============================================================================
# RUNTIME STATE (not saved in resource)
# =============================================================================

var current_count: int = 0
var is_completed: bool = false
var is_failed: bool = false
var time_remaining: float = 0.0
var is_revealed: bool = false  ## For hidden objectives

# =============================================================================
# METHODS
# =============================================================================

func reset() -> void:
	current_count = 0
	is_completed = false
	is_failed = false
	time_remaining = time_limit
	is_revealed = not is_hidden


func add_progress(amount: int = 1) -> bool:
	## Returns true if objective was just completed
	if is_completed or is_failed:
		return false
	
	current_count = min(current_count + amount, target_count)
	
	if current_count >= target_count:
		is_completed = true
		return true
	
	return false


func set_progress(amount: int) -> bool:
	## Set absolute progress, returns true if completed
	if is_completed or is_failed:
		return false
	
	current_count = clamp(amount, 0, target_count)
	
	if current_count >= target_count:
		is_completed = true
		return true
	
	return false


func fail() -> void:
	is_failed = true
	is_completed = false


func reveal() -> void:
	is_revealed = true


func get_progress_text() -> String:
	if is_hidden and not is_revealed:
		return "???"
	
	match objective_type:
		Enums.ObjectiveType.SURVIVE_TIME:
			if is_completed:
				return "Survived!"
			return "Survive: %.1fs remaining" % time_remaining
		Enums.ObjectiveType.ESCORT_NPC:
			if is_completed:
				return "Escort complete!"
			return "Escort in progress..."
		_:
			return "%d / %d" % [current_count, target_count]


func get_display_text() -> String:
	var prefix = ""
	if is_optional:
		prefix = "(Optional) "
	
	var status = ""
	if is_completed:
		status = " [DONE]"
	elif is_failed:
		status = " [FAILED]"
	
	return prefix + description + " - " + get_progress_text() + status


func get_save_data() -> Dictionary:
	return {
		"objective_id": objective_id,
		"current_count": current_count,
		"is_completed": is_completed,
		"is_failed": is_failed,
		"time_remaining": time_remaining,
		"is_revealed": is_revealed
	}


func load_save_data(data: Dictionary) -> void:
	current_count = data.get("current_count", 0)
	is_completed = data.get("is_completed", false)
	is_failed = data.get("is_failed", false)
	time_remaining = data.get("time_remaining", time_limit)
	is_revealed = data.get("is_revealed", not is_hidden)


func duplicate_objective() -> QuestObjective:
	var copy = duplicate(true) as QuestObjective
	copy.reset()
	return copy
