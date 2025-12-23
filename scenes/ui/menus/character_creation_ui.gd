## CharacterCreationUI - UI for creating a new character
extends Control

signal character_created(char_name: String, char_data: Dictionary)
signal cancelled()

@onready var name_input: LineEdit = $Panel/VBox/NameInput
@onready var color_picker: ColorPickerButton = $Panel/VBox/ColorHBox/ColorPickerButton
@onready var magic_type_option: OptionButton = $Panel/VBox/MagicHBox/MagicOptionButton
@onready var create_button: Button = $Panel/VBox/BtnHBox/CreateButton
@onready var cancel_button: Button = $Panel/VBox/BtnHBox/CancelButton

func _ready() -> void:
	_setup_magic_types()
	create_button.pressed.connect(_on_create_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func _setup_magic_types() -> void:
	magic_type_option.clear()
	for i in range(1, 7): # Enums.Element.FIRE to DARK
		var element_name = Enums.element_to_string(i as Enums.Element)
		magic_type_option.add_item(element_name, i)
	magic_type_option.select(0)

func _on_create_pressed() -> void:
	var char_name = name_input.text.strip_edges()
	if char_name.is_empty():
		char_name = "Mage"
	
	var char_data = {
		"color": color_picker.color.to_html(),
		"magic_type": magic_type_option.get_selected_id()
	}
	
	character_created.emit(char_name, char_data)

func _on_cancel_pressed() -> void:
	cancelled.emit()
