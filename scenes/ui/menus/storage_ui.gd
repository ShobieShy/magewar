## StorageUI - Interface for transferring items between inventory and storage
## Used with Storage Chest at Home Tree
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal closed()
signal item_deposited(item: Dictionary)
signal item_withdrawn(item: Dictionary)

# =============================================================================
# PROPERTIES
# =============================================================================

var _is_open: bool = false
var _inventory_system: Node = null
var _storage_items: Array = []
var _storage_capacity: int = Constants.STORAGE_SIZE

# UI Components
var _main_container: HBoxContainer
var _inventory_panel: PanelContainer
var _storage_panel: PanelContainer
var _inventory_grid: GridContainer
var _storage_grid: GridContainer
var _inventory_slots: Array[ItemSlot] = []
var _storage_slots: Array[ItemSlot] = []
var _tooltip: ItemTooltip
var _deposit_all_button: Button
var _withdraw_all_button: Button
var _storage_count_label: Label

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_ui()
	_create_tooltip()
	hide()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	
	if event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit to prevent memory leaks"""
	_disconnect_all_signals()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Background dimmer
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	# Main container (centered)
	_main_container = HBoxContainer.new()
	_main_container.name = "MainContainer"
	_main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_main_container.add_theme_constant_override("separation", 16)
	add_child(_main_container)
	
	# Inventory panel (left)
	_create_inventory_panel()
	
	# Transfer buttons (center)
	_create_transfer_buttons()
	
	# Storage panel (right)
	_create_storage_panel()


func _create_inventory_panel() -> void:
	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.custom_minimum_size = Vector2(350, 500)
	_apply_panel_style(_inventory_panel)
	_main_container.add_child(_inventory_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_inventory_panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	
	header.add_child(_create_spacer())
	
	var close_button = Button.new()
	close_button.text = "X"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	
	# Scroll container for inventory
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 5
	_inventory_grid.add_theme_constant_override("h_separation", 4)
	_inventory_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_inventory_grid)


func _create_transfer_buttons() -> void:
	var button_container = VBoxContainer.new()
	button_container.name = "TransferButtons"
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 8)
	_main_container.add_child(button_container)
	
	# Deposit all button
	_deposit_all_button = Button.new()
	_deposit_all_button.text = ">>"
	_deposit_all_button.tooltip_text = "Deposit All"
	_deposit_all_button.custom_minimum_size = Vector2(50, 40)
	_deposit_all_button.pressed.connect(_on_deposit_all_pressed)
	button_container.add_child(_deposit_all_button)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Click to\ntransfer"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	button_container.add_child(instructions)
	
	# Withdraw all button
	_withdraw_all_button = Button.new()
	_withdraw_all_button.text = "<<"
	_withdraw_all_button.tooltip_text = "Withdraw All"
	_withdraw_all_button.custom_minimum_size = Vector2(50, 40)
	_withdraw_all_button.pressed.connect(_on_withdraw_all_pressed)
	button_container.add_child(_withdraw_all_button)


func _create_storage_panel() -> void:
	_storage_panel = PanelContainer.new()
	_storage_panel.name = "StoragePanel"
	_storage_panel.custom_minimum_size = Vector2(400, 500)
	_apply_panel_style(_storage_panel)
	_main_container.add_child(_storage_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_storage_panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Storage Chest"
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	
	header.add_child(_create_spacer())
	
	_storage_count_label = Label.new()
	_storage_count_label.add_theme_font_size_override("font_size", 14)
	_storage_count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(_storage_count_label)
	
	# Scroll container for storage
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	_storage_grid = GridContainer.new()
	_storage_grid.columns = 6
	_storage_grid.add_theme_constant_override("h_separation", 4)
	_storage_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_storage_grid)


func _create_tooltip() -> void:
	_tooltip = ItemTooltip.new()
	add_child(_tooltip)


func _create_spacer() -> Control:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


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

func open(inventory: Node, storage: Array, capacity: int = Constants.STORAGE_SIZE) -> void:
	_inventory_system = inventory
	_storage_items = storage
	_storage_capacity = capacity
	_is_open = true
	
	_refresh_inventory()
	_refresh_storage()
	_update_storage_count()
	
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_is_open = false
	_tooltip.hide_tooltip()
	hide()
	closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# =============================================================================
# DISPLAY REFRESH
# =============================================================================

func _refresh_inventory() -> void:
	# Clear existing slots
	for child in _inventory_grid.get_children():
		child.queue_free()
	_inventory_slots.clear()
	
	if _inventory_system == null:
		return
	
	# Create slots for all inventory items
	for i in range(Constants.INVENTORY_SIZE):
		var slot = ItemSlot.new()
		slot.slot_index = i
		slot.slot_clicked.connect(_on_inventory_slot_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		slot.item_dropped.connect(_on_inventory_slot_dropped)
		
		var entry = _inventory_system.get_item(i)
		if entry and entry.has("item"):
			slot.set_item(entry.item, entry.get("quantity", 1))
		
		_inventory_grid.add_child(slot)
		_inventory_slots.append(slot)


func _refresh_storage() -> void:
	# Clear existing slots
	for child in _storage_grid.get_children():
		child.queue_free()
	_storage_slots.clear()
	
	# Refresh storage items from SaveManager
	_storage_items = SaveManager.get_storage()
	
	# Create slots for storage capacity
	for i in range(_storage_capacity):
		var slot = ItemSlot.new()
		slot.slot_index = i
		slot.slot_clicked.connect(_on_storage_slot_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		slot.item_dropped.connect(_on_storage_slot_dropped)
		
		# Set item if present
		if i < _storage_items.size():
			var entry = _storage_items[i]
			if entry and entry.has("item"):
				var item = _load_item(entry)
				if item:
					slot.set_item(item, entry.get("quantity", 1))
		
		_storage_grid.add_child(slot)
		_storage_slots.append(slot)


func _update_storage_count() -> void:
	_storage_items = SaveManager.get_storage()
	_storage_count_label.text = "%d / %d" % [_storage_items.size(), _storage_capacity]
	
	# Color code capacity
	var fill_ratio = float(_storage_items.size()) / float(_storage_capacity)
	if fill_ratio >= 0.9:
		_storage_count_label.add_theme_color_override("font_color", Color.RED)
	elif fill_ratio >= 0.75:
		_storage_count_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_storage_count_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))


func _load_item(entry: Dictionary) -> ItemData:
	## Load item resource from entry dictionary
	if entry.has("item") and entry.item is ItemData:
		return entry.item
	
	# Try to load by item_id
	if entry.has("item_id"):
		var item_id = entry.item_id
		# Would load from ItemDatabase if available
		# return ItemDatabase.get_item(item_id)
	
	return null

# =============================================================================
# TRANSFER OPERATIONS
# =============================================================================

func _deposit_item(inventory_index: int) -> bool:
	## Move item from inventory to storage
	if _storage_items.size() >= _storage_capacity:
		return false
	
	if _inventory_system == null:
		return false
	
	var entry = _inventory_system.get_item(inventory_index)
	if entry == null or not entry.has("item"):
		return false
	
	# Remove from inventory
	_inventory_system.remove_item(inventory_index)
	
	# Add to storage
	SaveManager.add_to_storage(entry)
	
	item_deposited.emit(entry)
	return true


func _withdraw_item(storage_index: int) -> bool:
	## Move item from storage to inventory
	if _inventory_system == null:
		return false
	
	# Check inventory space
	if not _inventory_system.has_space():
		return false
	
	_storage_items = SaveManager.get_storage()
	if storage_index >= _storage_items.size():
		return false
	
	# Remove from storage
	var entry = SaveManager.remove_from_storage(storage_index)
	if entry.is_empty():
		return false
	
	# Add to inventory
	if entry.has("item") and entry.item is ItemData:
		_inventory_system.add_item(entry.item, entry.get("quantity", 1))
	
	item_withdrawn.emit(entry)
	return true


func _deposit_all() -> int:
	## Deposit all inventory items to storage
	if _inventory_system == null:
		return 0
	
	var deposited = 0
	# Work backwards to avoid index shifting issues
	for i in range(Constants.INVENTORY_SIZE - 1, -1, -1):
		var entry = _inventory_system.get_item(i)
		if entry and entry.has("item"):
			if _deposit_item(i):
				deposited += 1
	
	return deposited


func _withdraw_all() -> int:
	## Withdraw all storage items to inventory
	if _inventory_system == null:
		return 0
	
	var withdrawn = 0
	_storage_items = SaveManager.get_storage()
	
	# Work backwards to avoid index shifting issues
	for i in range(_storage_items.size() - 1, -1, -1):
		if _withdraw_item(i):
			withdrawn += 1
		else:
			break  # Inventory full
	
	return withdrawn

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_inventory_slot_clicked(slot: ItemSlot, button: int) -> void:
	if slot.item == null:
		return
	
	if button == MOUSE_BUTTON_LEFT:
		# Deposit item to storage
		if _deposit_item(slot.slot_index):
			_refresh_inventory()
			_refresh_storage()
			_update_storage_count()
	elif button == MOUSE_BUTTON_RIGHT:
		# Could show context menu or info
		pass


func _on_storage_slot_clicked(slot: ItemSlot, button: int) -> void:
	if slot.item == null:
		return
	
	if button == MOUSE_BUTTON_LEFT:
		# Withdraw item to inventory
		if _withdraw_item(slot.slot_index):
			_refresh_inventory()
			_refresh_storage()
			_update_storage_count()
	elif button == MOUSE_BUTTON_RIGHT:
		# Could show context menu or info
		pass


func _on_inventory_slot_dropped(_slot: ItemSlot, data: Variant) -> void:
	if data is Dictionary and data.has("source_slot"):
		var source = data.source_slot as ItemSlot
		# If dropped from storage, withdraw item
		if source in _storage_slots:
			if _withdraw_item(source.slot_index):
				_refresh_inventory()
				_refresh_storage()
				_update_storage_count()


func _on_storage_slot_dropped(_slot: ItemSlot, data: Variant) -> void:
	if data is Dictionary and data.has("source_slot"):
		var source = data.source_slot as ItemSlot
		# If dropped from inventory, deposit item
		if source in _inventory_slots:
			if _deposit_item(source.slot_index):
				_refresh_inventory()
				_refresh_storage()
				_update_storage_count()


func _on_slot_hovered(slot: ItemSlot) -> void:
	if slot.item:
		_tooltip.show_item(slot.item)


func _on_slot_unhovered(_slot: ItemSlot) -> void:
	_tooltip.hide_tooltip()


func _on_deposit_all_pressed() -> void:
	var count = _deposit_all()
	if count > 0:
		_refresh_inventory()
		_refresh_storage()
		_update_storage_count()


func _on_withdraw_all_pressed() -> void:
	var count = _withdraw_all()
	if count > 0:
		_refresh_inventory()
		_refresh_storage()
		_update_storage_count()

# =============================================================================
# CLEANUP
# =============================================================================

func _disconnect_all_signals() -> void:
	"""Disconnect all ItemSlot signals to prevent memory leaks"""
	# Disconnect inventory slots
	for slot in _inventory_slots:
		if slot and is_instance_valid(slot):
			if slot.slot_clicked.is_connected(_on_inventory_slot_clicked):
				slot.slot_clicked.disconnect(_on_inventory_slot_clicked)
			if slot.slot_hovered.is_connected(_on_slot_hovered):
				slot.slot_hovered.disconnect(_on_slot_hovered)
			if slot.slot_unhovered.is_connected(_on_slot_unhovered):
				slot.slot_unhovered.disconnect(_on_slot_unhovered)
			if slot.item_dropped.is_connected(_on_inventory_slot_dropped):
				slot.item_dropped.disconnect(_on_inventory_slot_dropped)
	
	# Disconnect storage slots
	for slot in _storage_slots:
		if slot and is_instance_valid(slot):
			if slot.slot_clicked.is_connected(_on_storage_slot_clicked):
				slot.slot_clicked.disconnect(_on_storage_slot_clicked)
			if slot.slot_hovered.is_connected(_on_slot_hovered):
				slot.slot_hovered.disconnect(_on_slot_hovered)
			if slot.slot_unhovered.is_connected(_on_slot_unhovered):
				slot.slot_unhovered.disconnect(_on_slot_unhovered)
			if slot.item_dropped.is_connected(_on_storage_slot_dropped):
				slot.item_dropped.disconnect(_on_storage_slot_dropped)
	
	_inventory_slots.clear()
	_storage_slots.clear()
