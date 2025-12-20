## FastTravelMenu - UI for selecting fast travel destinations
## Displays unlocked portals and handles destination selection
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal destination_selected(portal_id: String)
signal menu_closed()

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var destination_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/DestinationList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

# =============================================================================
# PROPERTIES
# =============================================================================

var current_portal_id: String = ""
var _button_pool: Array[Button] = []

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	visible = false
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# MENU CONTROL
# =============================================================================

func open(from_portal_id: String = "") -> void:
	current_portal_id = from_portal_id
	
	# Populate destination list
	_populate_destinations()
	
	# Show menu
	visible = true
	
	# Pause game and show mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func close() -> void:
	visible = false
	current_portal_id = ""
	
	# Resume game and capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	
	menu_closed.emit()


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit to prevent memory leaks"""
	_disconnect_all_signals()


func _disconnect_all_signals() -> void:
	"""Disconnect destination buttons to prevent memory leaks"""
	# Disconnect all destination button signals
	for button in get_tree().get_nodes_in_group("fast_travel_buttons"):
		if button and is_instance_valid(button):
			if button.pressed.is_connected(_on_destination_pressed):
				button.pressed.disconnect(_on_destination_pressed)

# =============================================================================
# DESTINATION LIST
# =============================================================================

func _populate_destinations() -> void:
	# Clear existing buttons
	for child in destination_list.get_children():
		child.queue_free()
	
	# Get available destinations
	var destinations = FastTravelManager.get_available_destinations(current_portal_id)
	
	if destinations.is_empty():
		_add_no_destinations_label()
		return
	
	# Create button for each destination
	for dest in destinations:
		var button = _create_destination_button(dest)
		destination_list.add_child(button)


func _create_destination_button(dest: Dictionary) -> Button:
	var button = Button.new()
	button.text = dest.get("name", dest.get("id", "Unknown"))
	button.custom_minimum_size = Vector2(200, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Style the button
	button.add_theme_font_size_override("font_size", 18)
	
	# Store portal ID in metadata
	var portal_id = dest.get("id", "")
	button.pressed.connect(_on_destination_pressed.bind(portal_id))
	
	return button


func _add_no_destinations_label() -> void:
	var label = Label.new()
	label.text = "No destinations available"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.GRAY)
	destination_list.add_child(label)

# =============================================================================
# CALLBACKS
# =============================================================================

func _on_destination_pressed(portal_id: String) -> void:
	destination_selected.emit(portal_id)
	close()


func _on_close_pressed() -> void:
	destination_selected.emit("")  # Empty string = cancelled
	close()
