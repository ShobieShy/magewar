## StatAllocationUI - Stat point allocation interface
## Allows players to distribute unallocated stat points to various attributes
class_name StatAllocationUI
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal closed()

# =============================================================================
# PROPERTIES
# =============================================================================

var is_embedded: bool = false
var _is_open: bool = false
var _selected_stat: Enums.StatType = Enums.StatType.HEALTH

# UI Components
var _main_panel: PanelContainer
var _stats_list: VBoxContainer
var _details_panel: PanelContainer
var _stat_name_label: Label
var _stat_description: RichTextLabel
var _current_value_label: Label
var _allocated_value_label: Label
var _preview_value_label: Label
var _allocate_button: Button
var _deallocate_button: Button
var _allocate_all_button: Button
var _reset_button: Button
var _points_label: Label
var _stat_items: Dictionary = {}  ## StatType -> Control (stat item in list)

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Set size flags for proper container integration
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_create_ui()
	
	if not is_embedded:
		hide()
	
	# Connect to SaveManager signals
	SaveManager.stat_points_changed.connect(_on_stat_points_changed)
	SaveManager.stat_allocated.connect(_on_stat_allocated)
	SaveManager.stat_deallocated.connect(_on_stat_deallocated)


func _input(event: InputEvent) -> void:
	if is_embedded:
		return
		
	if not _is_open:
		return
	
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Background dimmer (only when not embedded)
	if not is_embedded:
		var dimmer = ColorRect.new()
		dimmer.color = Color(0, 0, 0, 0.5)
		dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(dimmer)
	
	# Main container
	var main_container = HBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.add_theme_constant_override("separation", 16)
	
	if is_embedded:
		main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_container.alignment = BoxContainer.ALIGNMENT_CENTER
		# When embedded, we want the container to be centered but fill the space
		main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		
	add_child(main_container)
	
	# Stats list panel (left)
	_create_stats_panel(main_container)
	
	# Details panel (right)
	_create_details_panel(main_container)


func _create_stats_panel(parent: Control) -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "StatsPanel"
	_main_panel.custom_minimum_size = Vector2(350, 500)
	_apply_panel_style(_main_panel)
	parent.add_child(_main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_main_panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Allocate Stats"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	
	header.add_child(Control.new())
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 16)
	_points_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	header.add_child(_points_label)
	
	if not is_embedded:
		var close_button = Button.new()
		close_button.text = "X"
		close_button.pressed.connect(close)
		header.add_child(close_button)
	
	# Stats list with scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	_stats_list = VBoxContainer.new()
	_stats_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_stats_list)
	
	# Create stat items for all allocatable stats
	var allocatable_stats = [
		[Enums.StatType.HEALTH, "Health"],
		[Enums.StatType.MAGIKA, "Magika"],
		[Enums.StatType.STAMINA, "Stamina"],
		[Enums.StatType.DAMAGE, "Damage"],
		[Enums.StatType.DEFENSE, "Defense"],
		[Enums.StatType.MOVE_SPEED, "Move Speed"],
		[Enums.StatType.CAST_SPEED, "Cast Speed"],
		[Enums.StatType.CRITICAL_CHANCE, "Critical Chance"],
		[Enums.StatType.CRITICAL_DAMAGE, "Critical Damage"],
	]
	
	for stat_info in allocatable_stats:
		var stat_type = stat_info[0]
		var stat_name = stat_info[1]
		var stat_item = _create_stat_item(stat_type, stat_name)
		_stats_list.add_child(stat_item)
		_stat_items[stat_type] = stat_item


func _create_stat_item(stat_type: Enums.StatType, display_name: String) -> Control:
	var item = PanelContainer.new()
	item.add_theme_stylebox_override("panel", _create_item_style())
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.gui_input.connect(func(event): _on_stat_item_clicked(event, stat_type))
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	item.add_child(hbox)
	
	# Stat name
	var name_label = Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)
	
	# Spacer
	hbox.add_child(Control.new())
	hbox.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Allocated value
	var allocated_label = Label.new()
	allocated_label.text = "0"
	allocated_label.add_theme_font_size_override("font_size", 14)
	allocated_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	item.set_meta("allocated_label", allocated_label)
	hbox.add_child(allocated_label)
	
	item.set_meta("stat_type", stat_type)
	item.custom_minimum_size = Vector2(300, 32)
	
	return item


func _create_details_panel(parent: Control) -> void:
	_details_panel = PanelContainer.new()
	_details_panel.name = "DetailsPanel"
	_details_panel.custom_minimum_size = Vector2(300, 500)
	_apply_panel_style(_details_panel)
	parent.add_child(_details_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_details_panel.add_child(vbox)
	
	# Stat name
	_stat_name_label = Label.new()
	_stat_name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_stat_name_label)
	
	vbox.add_child(HSeparator.new())
	
	# Description
	_stat_description = RichTextLabel.new()
	_stat_description.bbcode_enabled = true
	_stat_description.fit_content = true
	_stat_description.scroll_active = false
	_stat_description.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(_stat_description)
	
	vbox.add_child(HSeparator.new())
	
	# Values section
	var values_label = Label.new()
	values_label.text = "Current Allocation"
	values_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(values_label)
	
	_current_value_label = Label.new()
	_current_value_label.add_theme_font_size_override("font_size", 12)
	_current_value_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_current_value_label)
	
	_allocated_value_label = Label.new()
	_allocated_value_label.add_theme_font_size_override("font_size", 12)
	_allocated_value_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	vbox.add_child(_allocated_value_label)
	
	_preview_value_label = Label.new()
	_preview_value_label.add_theme_font_size_override("font_size", 12)
	_preview_value_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.8))
	vbox.add_child(_preview_value_label)
	
	# Spacer
	vbox.add_child(Control.new())
	vbox.get_child(vbox.get_child_count() - 1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Buttons
	var button_row = VBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	vbox.add_child(button_row)
	
	# Allocate/Deallocate buttons
	var alloc_dealloc_row = HBoxContainer.new()
	alloc_dealloc_row.add_theme_constant_override("separation", 4)
	button_row.add_child(alloc_dealloc_row)
	
	_allocate_button = Button.new()
	_allocate_button.text = "+ Allocate"
	_allocate_button.pressed.connect(_on_allocate_pressed)
	alloc_dealloc_row.add_child(_allocate_button)
	
	_deallocate_button = Button.new()
	_deallocate_button.text = "- Deallocate"
	_deallocate_button.pressed.connect(_on_deallocate_pressed)
	alloc_dealloc_row.add_child(_deallocate_button)
	
	# Allocate all / Reset buttons
	var bulk_row = HBoxContainer.new()
	bulk_row.add_theme_constant_override("separation", 4)
	button_row.add_child(bulk_row)
	
	_allocate_all_button = Button.new()
	_allocate_all_button.text = "Allocate All"
	_allocate_all_button.pressed.connect(_on_allocate_all_pressed)
	bulk_row.add_child(_allocate_all_button)
	
	_reset_button = Button.new()
	_reset_button.text = "Reset All"
	_reset_button.pressed.connect(_on_reset_pressed)
	bulk_row.add_child(_reset_button)


func _apply_panel_style(panel: PanelContainer) -> void:
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
	panel.add_theme_stylebox_override("panel", style)


func _create_item_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.25, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func open() -> void:
	_is_open = true
	_refresh_display()
	show()
	if not is_embedded:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Select first stat by default
	if Enums.StatType.HEALTH in _stat_items:
		_select_stat(Enums.StatType.HEALTH)


func close() -> void:
	_is_open = false
	hide()
	closed.emit()
	if not is_embedded:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return _is_open


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit"""
	_disconnect_all_signals()


func _disconnect_all_signals() -> void:
	"""Disconnect button and stat item signals"""
	if _allocate_button and is_instance_valid(_allocate_button):
		if _allocate_button.pressed.is_connected(_on_allocate_pressed):
			_allocate_button.pressed.disconnect(_on_allocate_pressed)
	
	if _deallocate_button and is_instance_valid(_deallocate_button):
		if _deallocate_button.pressed.is_connected(_on_deallocate_pressed):
			_deallocate_button.pressed.disconnect(_on_deallocate_pressed)
	
	if _allocate_all_button and is_instance_valid(_allocate_all_button):
		if _allocate_all_button.pressed.is_connected(_on_allocate_all_pressed):
			_allocate_all_button.pressed.disconnect(_on_allocate_all_pressed)
	
	if _reset_button and is_instance_valid(_reset_button):
		if _reset_button.pressed.is_connected(_on_reset_pressed):
			_reset_button.pressed.disconnect(_on_reset_pressed)

# =============================================================================
# DISPLAY REFRESH
# =============================================================================

func _refresh_display() -> void:
	_update_points_display()
	_refresh_stat_items()
	_select_stat(Enums.StatType.HEALTH)


func _update_points_display() -> void:
	var points = SaveManager.get_available_stat_points()
	_points_label.text = "Points: %d" % points


func _refresh_stat_items() -> void:
	for stat_type in _stat_items:
		var item = _stat_items[stat_type]
		var allocated = SaveManager.get_allocated_stat(stat_type)
		var label = item.get_meta("allocated_label")
		label.text = "%d" % allocated


func _select_stat(stat_type: Enums.StatType) -> void:
	_selected_stat = stat_type
	_update_details()
	
	# Highlight selected item
	for stat_type_key in _stat_items:
		var item = _stat_items[stat_type_key]
		var style = _create_item_style()
		if stat_type_key == stat_type:
			style.bg_color = Color(0.2, 0.25, 0.3, 0.9)
			style.border_color = Color(0.6, 0.6, 0.8)
		item.add_theme_stylebox_override("panel", style)


func _update_details() -> void:
	if _selected_stat == null:
		return
	
	# Get stat type name
	var stat_name = Enums.StatType.keys()[_selected_stat]
	_stat_name_label.text = stat_name.capitalize()
	
	# Get descriptions
	var descriptions = {
		Enums.StatType.HEALTH: "Maximum health pool. Increases how much damage you can take.",
		Enums.StatType.MAGIKA: "Maximum magika pool. Increases spell casting capacity.",
		Enums.StatType.STAMINA: "Maximum stamina pool. Increases sprint and jump capacity.",
		Enums.StatType.DAMAGE: "Physical and spell damage. Increases all damage output.",
		Enums.StatType.DEFENSE: "Armor and resistance. Reduces incoming damage.",
		Enums.StatType.MOVE_SPEED: "Movement speed multiplier. Increases all movement.",
		Enums.StatType.CAST_SPEED: "Spell casting speed. Reduces time between casts.",
		Enums.StatType.CRITICAL_CHANCE: "Chance to land critical hits. Deals extra damage.",
		Enums.StatType.CRITICAL_DAMAGE: "Multiplier for critical hits. Higher crits deal more damage.",
	}
	
	_stat_description.text = descriptions.get(_selected_stat, "No description")
	
	# Get current values
	var allocated = SaveManager.get_allocated_stat(_selected_stat)
	var available = SaveManager.get_available_stat_points()
	
	_current_value_label.text = "Base: (see character sheet)"
	_allocated_value_label.text = "Allocated: %d points" % allocated
	_preview_value_label.text = "Next: +1 point (if allocated)"
	
	# Update button states
	_allocate_button.disabled = available <= 0
	_deallocate_button.disabled = allocated <= 0
	_allocate_all_button.disabled = available <= 0
	_reset_button.disabled = allocated <= 0

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_stat_item_clicked(event: InputEvent, stat_type: Enums.StatType) -> void:
	if event is InputEventMouseButton and event.pressed:
		_select_stat(stat_type)


func _on_allocate_pressed() -> void:
	if SaveManager.allocate_stat_point(_selected_stat):
		SaveManager.save_player_data()
		_refresh_display()


func _on_deallocate_pressed() -> void:
	if SaveManager.deallocate_stat_point(_selected_stat):
		SaveManager.save_player_data()
		_refresh_display()


func _on_allocate_all_pressed() -> void:
	var available = SaveManager.get_available_stat_points()
	for i in range(available):
		SaveManager.allocate_stat_point(_selected_stat)
	SaveManager.save_player_data()
	_refresh_display()


func _on_reset_pressed() -> void:
	var allocated = SaveManager.get_allocated_stat(_selected_stat)
	for i in range(allocated):
		SaveManager.deallocate_stat_point(_selected_stat)
	SaveManager.save_player_data()
	_refresh_display()


func _on_stat_points_changed(_new_amount: int) -> void:
	if _is_open:
		_refresh_display()


func _on_stat_allocated(_stat_type: int, _new_value: int) -> void:
	if _is_open:
		_refresh_display()


func _on_stat_deallocated(_stat_type: int, _new_value: int) -> void:
	if _is_open:
		_refresh_display()
