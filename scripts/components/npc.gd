## NPC - Non-player character with dialogue support
## Simple dialogue display with optional callbacks
class_name NPC
extends Interactable

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_started()
signal dialogue_ended()

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("NPC Info")
@export var npc_name: String = "NPC"
@export var npc_title: String = ""  # Optional title like "Shopkeeper"

@export_group("Dialogue")
@export var dialogue_lines: Array[String] = ["Hello, traveler."]
@export var dialogue_on_complete: String = ""  # Shown after one_time_only dialogue

@export_group("Actions")
@export var open_shop_on_dialogue_end: bool = false
@export var shop_id: String = ""  ## Shop to open (requires ShopManager registration)
@export var give_quest_id: String = ""
@export var complete_quest_id: String = ""

@export_group("NPC ID")
@export var npc_id: String = ""  ## Unique ID for quest tracking

# =============================================================================
# PROPERTIES
# =============================================================================

var _dialogue_box: Control = null
var _current_line_index: int = 0
var _in_dialogue: bool = false

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "[E] Talk to " + npc_name

# =============================================================================
# INTERACTION
# =============================================================================

func _perform_interaction(player: Node) -> void:
	if _in_dialogue:
		return
	
	# Start dialogue
	_start_dialogue(player)


func _start_dialogue(player: Node) -> void:
	_in_dialogue = true
	_current_line_index = 0
	dialogue_started.emit()
	
	# Pause player input
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(false)
	
	# Show dialogue box
	_show_dialogue_box()
	_show_current_line()


func _show_current_line() -> void:
	var lines = dialogue_lines if not (one_time_only and has_been_used) else [dialogue_on_complete] if dialogue_on_complete else dialogue_lines
	
	if _current_line_index >= lines.size():
		_end_dialogue()
		return
	
	var line = lines[_current_line_index]
	_update_dialogue_box(npc_name, line)


func _advance_dialogue() -> void:
	_current_line_index += 1
	_show_current_line()


func _end_dialogue() -> void:
	_in_dialogue = false
	_hide_dialogue_box()
	dialogue_ended.emit()
	
	# Mark as used for one-time dialogues
	if one_time_only:
		has_been_used = true
	
	# Re-enable player input
	for player in players_in_range:
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(true)
	
	# Trigger actions
	_trigger_post_dialogue_actions()


func _trigger_post_dialogue_actions() -> void:
	# Report to QuestManager that we talked to this NPC
	if not npc_id.is_empty():
		QuestManager.report_npc_talked(npc_id)
	
	# Give quest via QuestManager
	if give_quest_id and not give_quest_id.is_empty():
		QuestManager.start_quest(give_quest_id)
	
	# Complete quest via QuestManager
	if complete_quest_id and not complete_quest_id.is_empty():
		var quest = QuestManager.get_active_quest(complete_quest_id)
		if quest and quest.is_ready_to_turn_in():
			QuestManager.complete_quest(complete_quest_id)
	
	# Open shop
	if open_shop_on_dialogue_end:
		if shop_id.is_empty():
			push_warning("NPC %s has open_shop_on_dialogue_end but no shop_id" % npc_name)
		else:
			ShopManager.open_shop(shop_id)

# =============================================================================
# DIALOGUE BOX
# =============================================================================

func _show_dialogue_box() -> void:
	# Validate current scene exists
	var current_scene = get_tree().current_scene
	if current_scene == null:
		push_error("No current scene to show dialogue box")
		return
	
	# Try to find existing dialogue box
	_dialogue_box = current_scene.get_node_or_null("HUD/DialogueBox")
	
	if _dialogue_box == null:
		# Create a simple dialogue box
		_dialogue_box = _create_dialogue_box()
		if _dialogue_box == null:
			push_error("Failed to create dialogue box")
			return
		
		var hud = current_scene.get_node_or_null("HUD")
		if hud and is_instance_valid(hud):
			hud.add_child(_dialogue_box)
		else:
			current_scene.add_child(_dialogue_box)
	
	if _dialogue_box and is_instance_valid(_dialogue_box):
		_dialogue_box.visible = true


func _hide_dialogue_box() -> void:
	if _dialogue_box and is_instance_valid(_dialogue_box):
		_dialogue_box.visible = false


func _update_dialogue_box(speaker: String, text: String) -> void:
	if _dialogue_box == null or not is_instance_valid(_dialogue_box):
		push_warning("Dialogue box is null or invalid")
		return
	
	var speaker_label = _dialogue_box.get_node_or_null("Panel/VBox/SpeakerLabel")
	var text_label = _dialogue_box.get_node_or_null("Panel/VBox/TextLabel")
	
	# Safely update labels with null checks
	if speaker_label and is_instance_valid(speaker_label):
		speaker_label.text = speaker
	else:
		push_warning("Speaker label not found in dialogue box")
	
	if text_label and is_instance_valid(text_label):
		text_label.text = text
	else:
		push_warning("Text label not found in dialogue box")


func _create_dialogue_box() -> Control:
	var box = Control.new()
	box.name = "DialogueBox"
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_top = -150
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 100
	panel.offset_right = -100
	panel.offset_top = 20
	panel.offset_bottom = -20
	box.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	var speaker_label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(speaker_label)
	
	var text_label = Label.new()
	text_label.name = "TextLabel"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text_label)
	
	var continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.pressed.connect(_advance_dialogue)
	vbox.add_child(continue_button)
	
	return box

# =============================================================================
# INPUT OVERRIDE
# =============================================================================

func _input(event: InputEvent) -> void:
	if _in_dialogue:
		if event.is_action_pressed("interact") or event.is_action_pressed("primary_fire"):
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		return
	
	super._input(event)
