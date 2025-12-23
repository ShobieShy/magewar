## InventoryUI - Player inventory and equipment screen
## Grid-based inventory with equipment slots and item management
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal closed()

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var columns: int = 8
@export var slot_size: Vector2 = Vector2(64, 64)
@export var slot_spacing: int = 4

# =============================================================================
# PROPERTIES
# =============================================================================

var _inventory_system: Node = null
var _is_open: bool = false

# UI Components
var _main_panel: PanelContainer
var _equipment_panel: PanelContainer
var _inventory_grid: GridContainer
var _equipment_slots: Dictionary = {}  ## EquipmentSlot -> ItemSlot
var _inventory_slots: Array[ItemSlot] = []
var _tooltip: ItemTooltip
var _gold_label: Label
var _player_level_label: Label

# Context menu
var _context_menu: PopupMenu
var _context_slot: ItemSlot = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_ui()
	_create_tooltip()
	_create_context_menu()
	hide()
	
	# Connect to SaveManager for gold updates
	SaveManager.gold_changed.connect(_on_gold_changed)


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	
	if event.is_action_pressed("inventory") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Main container
	var main_container = HBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.add_theme_constant_override("separation", 16)
	add_child(main_container)
	
	# Background dimmer
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	move_child(dimmer, 0)
	
	# Equipment panel (left side)
	_create_equipment_panel(main_container)
	
	# Inventory panel (right side)
	_create_inventory_panel(main_container)
	
	# Center the main container
	main_container.position = -main_container.size / 2


func _create_equipment_panel(parent: Control) -> void:
	_equipment_panel = PanelContainer.new()
	_equipment_panel.name = "EquipmentPanel"
	_apply_panel_style(_equipment_panel)
	parent.add_child(_equipment_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_equipment_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Equipment"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	# Player level
	_player_level_label = Label.new()
	_player_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_level_label.add_theme_font_size_override("font_size", 14)
	_player_level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	vbox.add_child(_player_level_label)
	
	# Equipment grid (2 columns)
	var equipment_grid = GridContainer.new()
	equipment_grid.columns = 2
	equipment_grid.add_theme_constant_override("h_separation", slot_spacing)
	equipment_grid.add_theme_constant_override("v_separation", slot_spacing)
	vbox.add_child(equipment_grid)
	
	# Create equipment slots in order
	var equipment_order = [
		[Enums.EquipmentSlot.HEAD, "Head"],
		[Enums.EquipmentSlot.PRIMARY_WEAPON, "Staff"],
		[Enums.EquipmentSlot.BODY, "Body"],
		[Enums.EquipmentSlot.SECONDARY_WEAPON, "Wand"],
		[Enums.EquipmentSlot.BELT, "Belt"],
		[Enums.EquipmentSlot.GRIMOIRE, "Grimoire"],
		[Enums.EquipmentSlot.FEET, "Feet"],
		[Enums.EquipmentSlot.POTION, "Potion"]
	]
	
	for data in equipment_order:
		var slot = _create_equipment_slot(data[0], data[1])
		equipment_grid.add_child(slot)
		_equipment_slots[data[0]] = slot


func _create_equipment_slot(slot_type: Enums.EquipmentSlot, label_text: String) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	
	var slot = ItemSlot.new()
	slot.slot_type = slot_type
	slot.accept_any_item = false
	slot.slot_size = slot_size
	slot.slot_clicked.connect(_on_slot_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_item_dropped)
	container.add_child(slot)
	
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	container.add_child(label)
	
	return container


func _create_inventory_panel(parent: Control) -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "InventoryPanel"
	_apply_panel_style(_main_panel)
	parent.add_child(_main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_main_panel.add_child(vbox)
	
	# Header with title and gold
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	
	header.add_child(Control.new())  # Spacer
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	header.add_child(_gold_label)
	
	# Inventory grid
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = columns
	_inventory_grid.add_theme_constant_override("h_separation", slot_spacing)
	_inventory_grid.add_theme_constant_override("v_separation", slot_spacing)
	vbox.add_child(_inventory_grid)
	
	# Create inventory slots
	for i in range(Constants.INVENTORY_SIZE):
		var slot = ItemSlot.new()
		slot.slot_index = i
		slot.slot_size = slot_size
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_double_clicked.connect(_on_slot_double_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		slot.item_dropped.connect(_on_item_dropped)
		_inventory_grid.add_child(slot)
		_inventory_slots.append(slot)


func _create_tooltip() -> void:
	_tooltip = ItemTooltip.new()
	_tooltip.name = "ItemTooltip"
	add_child(_tooltip)


func _create_context_menu() -> void:
	_context_menu = PopupMenu.new()
	_context_menu.name = "ContextMenu"
	_context_menu.id_pressed.connect(_on_context_menu_selected)
	add_child(_context_menu)


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

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func open(inventory_system: Node) -> void:
	_inventory_system = inventory_system
	_is_open = true
	_refresh_display()
	show()
	
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_is_open = false
	if _tooltip:
		_tooltip.hide_tooltip()
	_disconnect_all_signals()  # Clean up signals when closing
	hide()
	closed.emit()
	
	# Release mouse back to game
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return _is_open


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit to prevent memory leaks"""
	_disconnect_all_signals()


func _disconnect_all_signals() -> void:
	"""Disconnect ItemSlot signals to prevent memory leaks"""
	# Disconnect inventory item slots
	for slot in _inventory_slots:
		if slot and is_instance_valid(slot):
			_safely_disconnect_signal(slot.slot_clicked, _on_slot_clicked)
			_safely_disconnect_signal(slot.slot_hovered, _on_slot_hovered)
			_safely_disconnect_signal(slot.slot_unhovered, _on_slot_unhovered)
			_safely_disconnect_signal(slot.slot_double_clicked, _on_slot_double_clicked)
			_safely_disconnect_signal(slot.item_dropped, _on_item_dropped)
	
	# Disconnect equipment item slots
	for slot in _equipment_slots:
		if slot and is_instance_valid(slot):
			# Equipment slots are stored in a dictionary value, get the actual ItemSlot
			var item_slot = slot if slot is ItemSlot else slot.get_meta("item_slot", null)
			if item_slot and is_instance_valid(item_slot):
				_safely_disconnect_signal(item_slot.slot_clicked, _on_slot_clicked)
				_safely_disconnect_signal(item_slot.slot_hovered, _on_slot_hovered)
				_safely_disconnect_signal(item_slot.slot_unhovered, _on_slot_unhovered)
				_safely_disconnect_signal(item_slot.slot_double_clicked, _on_slot_double_clicked)
				_safely_disconnect_signal(item_slot.item_dropped, _on_item_dropped)
	
	# Disconnect context menu
	if _context_menu and is_instance_valid(_context_menu):
		_safely_disconnect_signal(_context_menu.id_pressed, _on_context_menu_selected)
	
	# Disconnect SaveManager signals
	if SaveManager:
		_safely_disconnect_signal(SaveManager.gold_changed, _on_gold_changed)
	
	_inventory_slots.clear()
	_equipment_slots.clear()

func _safely_disconnect_signal(signal_obj: Signal, callable_obj: Callable) -> void:
	"""Safely disconnect a signal without errors"""
	if signal_obj.is_connected(callable_obj):
		signal_obj.disconnect(callable_obj)

# =============================================================================
# DISPLAY REFRESH
# =============================================================================

func _refresh_display() -> void:
	_refresh_inventory()
	_refresh_equipment()
	_refresh_gold()
	_refresh_player_info()


func _refresh_inventory() -> void:
	if _inventory_system == null:
		return
	
	for i in range(_inventory_slots.size()):
		var slot = _inventory_slots[i]
		var item = _inventory_system.get_item(i)
		if item:
			# Get stack count from item (defaults to 1 if not set)
			var quantity = item.stack_count if item.stack_count > 0 else 1
			slot.set_item(item, quantity)
		else:
			slot.clear()


func _refresh_equipment() -> void:
	if _inventory_system == null:
		return
	
	for slot_type in _equipment_slots:
		var ui_slot = _equipment_slots[slot_type].get_child(0) as ItemSlot
		var equipped = _inventory_system.get_equipped(slot_type)
		if equipped:
			ui_slot.set_item(equipped)
		else:
			ui_slot.clear()


func _refresh_gold() -> void:
	_gold_label.text = "%d Gold" % SaveManager.get_gold()


func _refresh_player_info() -> void:
	var level = SaveManager.player_data.level
	var exp_data = SaveManager.get_exp_progress()
	_player_level_label.text = "Level %d (%.0f%%)" % [level, exp_data.progress * 100]

# =============================================================================
# SLOT INTERACTIONS
# =============================================================================

func _on_slot_clicked(slot: ItemSlot, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT and slot.item != null:
		_show_context_menu(slot)


func _on_slot_double_clicked(slot: ItemSlot) -> void:
	if slot.item == null:
		return
	
	# Double-click to equip/use
	if slot.item is EquipmentData or slot.item is StaffPartData:
		_equip_item(slot)
	elif slot.item.can_use():
		_use_item(slot)


func _on_slot_hovered(slot: ItemSlot) -> void:
	if slot.item != null:
		_tooltip.show_item(slot.item)


func _on_slot_unhovered(_slot: ItemSlot) -> void:
	_tooltip.hide_tooltip()


func _on_item_dropped(target_slot: ItemSlot, data: Variant) -> void:
	if not data is Dictionary or not data.has("source_slot"):
		return
	
	var source_slot = data.source_slot as ItemSlot
	if source_slot == target_slot:
		return
	
	# Comprehensive validation to prevent duplication
	if not source_slot.item:
		push_warning("Attempted to drop null item - potential duplication prevented")
		return
	
	# Verify source item still exists in inventory system
	if source_slot.slot_index >= 0:
		var actual_item = _inventory_system.get_item(source_slot.slot_index)
		if actual_item == null or not is_instance_valid(actual_item):
			push_warning("Source item no longer exists in inventory - drop cancelled")
			_refresh_display()
			return
		
		# Extra validation: verify source item ID matches what we expect
		if actual_item.item_id != source_slot.item.item_id:
			push_warning("Item mismatch detected - drop cancelled for safety")
			_refresh_display()
			return
	
	# Handle different drop scenarios
	if target_slot.slot_type != Enums.EquipmentSlot.NONE:
		# Dropping into equipment slot
		_handle_equip_drop(source_slot, target_slot)
	elif source_slot.slot_type != Enums.EquipmentSlot.NONE:
		# Dropping from equipment to inventory
		_handle_unequip_drop(source_slot, target_slot)
	else:
		# Inventory to inventory move/swap
		_handle_inventory_swap(source_slot, target_slot)
	
	_refresh_display()


func _handle_equip_drop(source: ItemSlot, target: ItemSlot) -> void:
	if source.item == null:
		return
	
	if source.item is EquipmentData:
		var equipment = source.item as EquipmentData
		if equipment.slot == target.slot_type:
			# Get the item from the inventory system (not the UI)
			var item_to_equip = _inventory_system.get_item(source.slot_index)
			if item_to_equip:
				_inventory_system.equip_item(item_to_equip, source.slot_index)


func _handle_unequip_drop(source: ItemSlot, _target: ItemSlot) -> void:
	_inventory_system.unequip_to_inventory(source.slot_type)


func _handle_inventory_swap(source: ItemSlot, target: ItemSlot) -> void:
	# Validate both slots are inventory slots
	if source.slot_index < 0 or target.slot_index < 0:
		push_warning("_handle_inventory_swap: Invalid slot indices")
		return
	
	# Get target item to decide swap or move
	var target_item = _inventory_system.get_item(target.slot_index)
	
	if target_item == null:
		# Target is empty - do atomic move instead of swap
		var transaction_id = _inventory_system.move_item(source.slot_index, target.slot_index)
		if transaction_id < 0:
			push_warning("Failed to move item from slot %d to %d" % [source.slot_index, target.slot_index])
	else:
		# Target has item - do swap
		var transaction_id = _inventory_system.swap_items(source.slot_index, target.slot_index)
		if transaction_id < 0:
			push_warning("Failed to swap items between slots %d and %d" % [source.slot_index, target.slot_index])

# =============================================================================
# CONTEXT MENU
# =============================================================================

func _show_context_menu(slot: ItemSlot) -> void:
	_context_slot = slot
	_context_menu.clear()
	
	var item = slot.item
	
	if item.can_use():
		_context_menu.add_item("Use", 0)
	
	if item is EquipmentData or item is StaffPartData:
		if slot.slot_type == Enums.EquipmentSlot.NONE:
			_context_menu.add_item("Equip", 1)
		else:
			_context_menu.add_item("Unequip", 2)
	
	_context_menu.add_separator()
	_context_menu.add_item("Drop", 10)
	
	_context_menu.position = get_global_mouse_position()
	_context_menu.popup()


func _on_context_menu_selected(id: int) -> void:
	if _context_slot == null:
		return
	
	match id:
		0:  # Use
			_use_item(_context_slot)
		1:  # Equip
			_equip_item(_context_slot)
		2:  # Unequip
			_unequip_item(_context_slot)
		10:  # Drop
			_drop_item(_context_slot)
	
	_context_slot = null
	_refresh_display()


func _use_item(slot: ItemSlot) -> void:
	if _inventory_system and slot.slot_index >= 0:
		_inventory_system.use_item(slot.slot_index)
		_refresh_display()


func _equip_item(slot: ItemSlot) -> void:
	if _inventory_system and slot.slot_index >= 0:
		# Get the item from inventory and equip it
		var item = _inventory_system.get_item(slot.slot_index)
		if item and item is EquipmentData:
			_inventory_system.equip_item(item, slot.slot_index)
			_refresh_display()
		else:
			push_warning("Cannot equip non-equipment item or item not found")


func _unequip_item(slot: ItemSlot) -> void:
	if _inventory_system and slot.slot_type != Enums.EquipmentSlot.NONE:
		_inventory_system.unequip_to_inventory(slot.slot_type)
		_refresh_display()


func _drop_item(slot: ItemSlot) -> void:
	if _inventory_system and slot.slot_index >= 0:
		_inventory_system.remove_item(slot.slot_index)
		# Could spawn dropped item in world here
		_refresh_display()

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	if _is_open:
		_refresh_gold()
