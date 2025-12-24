## FastTravelMenu - UI for selecting fast travel destinations
## Displays unlocked portals and handles destination selection
class_name FastTravelMenu
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal destination_selected(portal_id: String)
signal menu_closed()

# =============================================================================
# NODE REFERENCES
# =============================================================================

var panel: PanelContainer
var title_label: Label
var destination_list: VBoxContainer
var close_button: Button

# =============================================================================
# PROPERTIES
# =============================================================================

var is_embedded: bool = false
var current_portal_id: String = ""

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Set size flags for proper container integration
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_create_ui()
	
	if not is_embedded:
		visible = false
	
	if close_button:
		if is_embedded:
			close_button.visible = false
		else:
			close_button.pressed.connect(_on_close_pressed)
	
	# If embedded, populate immediately
	if is_embedded:
		_populate_destinations()


func _input(event: InputEvent) -> void:
	if is_embedded:
		return
		
	if not visible:
		return
	
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Create panel structure
	panel = PanelContainer.new()
	panel.name = "Panel"
	if is_embedded:
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		panel.custom_minimum_size = Vector2(400, 500)
	
	_apply_panel_style(panel)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	# Header
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Fast Travel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)
	
	# Scroll area
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	destination_list = VBoxContainer.new()
	destination_list.name = "DestinationList"
	destination_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	destination_list.add_theme_constant_override("separation", 8)
	scroll.add_child(destination_list)
	
	# Close button (if not embedded)
	if not is_embedded:
		close_button = Button.new()
		close_button.name = "CloseButton"
		close_button.text = "Close"
		close_button.custom_minimum_size = Vector2(100, 40)
		close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(close_button)


func _apply_panel_style(panel_node: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.35)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel_node.add_theme_stylebox_override("panel", style)

# =============================================================================
# MENU CONTROL
# =============================================================================

func open(from_portal_id: String = "") -> void:
	current_portal_id = from_portal_id
	
	# Populate destination list
	_populate_destinations()
	
	if not is_embedded:
		# Show menu
		visible = true
		
		# Pause game and show mouse
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true


func close() -> void:
	if is_embedded:
		return
		
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
	if destination_list:
		for child in destination_list.get_children():
			child.queue_free()
	else:
		return
	
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
	button.add_to_group("fast_travel_buttons")
	
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
	
	if is_embedded:
		# If embedded, we probably want to trigger travel but not close the menu
		# Or maybe the Unified UI handles closure?
		# Actually, FastTravelManager.travel_to_portal will change scene which might close UI
		FastTravelManager.travel_to_portal(portal_id)
	else:
		close()


func _on_close_pressed() -> void:
	destination_selected.emit("")  # Empty string = cancelled
	close()

		get_viewport().set_input_as_handled()

# =============================================================================
# MENU CONTROL
# =============================================================================

func open(from_portal_id: String = "") -> void:
	current_portal_id = from_portal_id
	
	# Populate destination list
	_populate_destinations()
	
	if not is_embedded:
		# Show menu
		visible = true
		
		# Pause game and show mouse
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true


func close() -> void:
	if is_embedded:
		return
		
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
	
	if is_embedded:
		# If embedded, we probably want to trigger travel but not close the menu
		# Or maybe the Unified UI handles closure?
		# Actually, FastTravelManager.travel_to_portal will change scene which might close UI
		FastTravelManager.travel_to_portal(portal_id)
	else:
		close()



func _on_close_pressed() -> void:
	destination_selected.emit("")  # Empty string = cancelled
	close()
