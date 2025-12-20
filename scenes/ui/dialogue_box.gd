## DialogueBox - UI for displaying NPC dialogue
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal dialogue_advanced()
signal dialogue_closed()

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var speaker_label: Label = $Panel/MarginContainer/VBox/SpeakerLabel
@onready var text_label: Label = $Panel/MarginContainer/VBox/TextLabel
@onready var continue_hint: Label = $Panel/MarginContainer/VBox/ContinueHint

# =============================================================================
# PROPERTIES
# =============================================================================

var is_active: bool = false

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("primary_fire"):
		dialogue_advanced.emit()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	visible = true
	is_active = true


func close() -> void:
	visible = false
	is_active = false
	dialogue_closed.emit()


func set_speaker(speaker: String) -> void:
	speaker_label.text = speaker


func set_text(text: String) -> void:
	text_label.text = text


func set_continue_hint(hint: String) -> void:
	continue_hint.text = hint
