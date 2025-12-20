## DialogueData - Resource for storing dialogue sequences
## Can be used for more complex dialogue trees in the future
class_name DialogueData
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var dialogue_id: String = ""
@export var speaker_name: String = ""
@export var lines: Array[String] = []

@export_group("Conditions")
@export var required_quest_complete: String = ""
@export var required_quest_active: String = ""
@export var required_item: String = ""

@export_group("Actions")
@export var start_quest: String = ""
@export var complete_quest: String = ""
@export var give_item: String = ""
@export var take_item: String = ""
@export var give_experience: int = 0

# =============================================================================
# METHODS
# =============================================================================

func can_play() -> bool:
	## Check if conditions are met to play this dialogue
	
	if required_quest_complete and not required_quest_complete.is_empty():
		if not SaveManager.is_quest_completed(required_quest_complete):
			return false
	
	if required_quest_active and not required_quest_active.is_empty():
		if not SaveManager.is_quest_active(required_quest_active):
			return false
	
	if required_item and not required_item.is_empty():
		if not SaveManager.has_item(required_item):
			return false
	
	return true


func execute_actions() -> void:
	## Execute post-dialogue actions
	
	if start_quest and not start_quest.is_empty():
		SaveManager.start_quest(start_quest)
	
	if complete_quest and not complete_quest.is_empty():
		SaveManager.complete_quest(complete_quest)
	
	if give_experience > 0:
		SaveManager.add_experience(give_experience)
	
	# Item giving/taking would require inventory system integration
