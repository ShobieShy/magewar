## Skill Trainer NPC - Teaches and upgrades skills
## Provides access to the skill tree system
extends NPC

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var show_skill_tree_on_dialogue_end: bool = true

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	npc_name = "Skill Master"
	npc_id = "skill_trainer"
	interaction_prompt = "[E] Train with %s" % npc_name
	
	# Introduction dialogue
	dialogue_lines = [
		"Welcome, adventurer! I am a master of the arcane arts.",
		"I can teach you powerful skills to enhance your abilities.",
		"You currently have %d skill points to spend." % SaveManager.get_skill_points(),
		"Let me show you the available skills in the skill tree!"
	]
	
	super._ready()


# =============================================================================
# INTERACTION OVERRIDE
# =============================================================================

func _trigger_post_dialogue_actions() -> void:
	# Call parent implementation first
	super._trigger_post_dialogue_actions()
	
	# Open skill tree UI after dialogue
	if show_skill_tree_on_dialogue_end:
		_open_skill_tree_ui()


func _open_skill_tree_ui() -> void:
	# Get the current player from the scene
	var current_scene = get_tree().current_scene
	if current_scene == null:
		push_error("No current scene to get player from")
		return
	
	# Find player in the scene
	var player = _get_player_in_scene(current_scene)
	if player == null:
		push_error("Could not find player in scene")
		return
	
	# Try to open skill tree UI via GameManager or directly
	if GameManager and GameManager.has_method("open_skill_tree_ui"):
		GameManager.open_skill_tree_ui(player)
	elif SkillManager and SkillManager.has_method("open_skill_tree_ui"):
		SkillManager.open_skill_tree_ui(player)
	else:
		push_warning("Could not find method to open skill tree UI")


func _get_player_in_scene(scene: Node) -> Node:
	# Try to find a Player node in the scene
	if scene is Player:
		return scene
	
	for child in scene.get_children():
		if child is Player:
			return child
		var result = _get_player_in_scene(child)
		if result:
			return result
	
	return null
