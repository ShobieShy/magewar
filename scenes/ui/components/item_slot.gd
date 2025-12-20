## ItemSlot - Reusable UI component for displaying items
## Used in inventory, equipment, storage, and shop interfaces
class_name ItemSlot
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal slot_clicked(slot: ItemSlot, button: int)
signal slot_double_clicked(slot: ItemSlot)
signal slot_hovered(slot: ItemSlot)
signal slot_unhovered(slot: ItemSlot)
signal item_dropped(slot: ItemSlot, data: Variant)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Slot Settings")
@export var slot_index: int = -1
@export var slot_type: Enums.EquipmentSlot = Enums.EquipmentSlot.NONE
@export var accept_any_item: bool = true
@export var show_background: bool = true
@export var show_quantity: bool = true
@export var slot_size: Vector2 = Vector2(64, 64)

@export_group("Visual")
@export var empty_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var hover_color: Color = Color(0.4, 0.4, 0.4, 0.9)
@export var selected_color: Color = Color(0.3, 0.5, 0.7, 0.9)
@export var locked_color: Color = Color(0.1, 0.1, 0.1, 0.9)

# =============================================================================
# PROPERTIES
# =============================================================================

var item: ItemData = null
var quantity: int = 1
var is_locked: bool = false
var is_selected: bool = false
var is_hovered: bool = false

# Node references
var _background: ColorRect
var _icon: TextureRect
var _quantity_label: Label
var _rarity_border: ColorRect
var _slot_type_icon: TextureRect

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	custom_minimum_size = slot_size
	_create_ui()
	_update_display()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.double_click:
				slot_double_clicked.emit(self)
			else:
				slot_clicked.emit(self, event.button_index)
			accept_event()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if is_locked:
		return false
	
	if data is Dictionary and data.has("item"):
		var dropped_item = data.item as ItemData
		if dropped_item == null:
			return false
		
		# Check slot type restrictions
		if not accept_any_item and slot_type != Enums.EquipmentSlot.NONE:
			if dropped_item is EquipmentData:
				return dropped_item.slot == slot_type
			return false
		
		return true
	
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Validate the drop data before processing
	if data is Dictionary and data.has("source_slot"):
		var source = data.source_slot
		if source and is_instance_valid(source) and source != self:
			item_dropped.emit(self, data)
		elif source == self:
			# Dropping on same slot - no action needed
			pass
		else:
			push_warning("Invalid drop data - source slot is invalid")


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null or is_locked:
		return null
	
	# Create drag preview
	var preview = _create_drag_preview()
	set_drag_preview(preview)
	
	# Store the item data but don't pass the actual item reference
	# This prevents the item from existing in multiple places
	return {
		"source_slot": self,
		"item": item,  # Keep for type checking, but source_slot is the authority
		"quantity": quantity,
		"slot_index": slot_index,
		"slot_type": slot_type
	}

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Background
	_background = ColorRect.new()
	_background.name = "Background"
	_background.color = empty_color
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_background)
	
	# Rarity border (behind icon)
	_rarity_border = ColorRect.new()
	_rarity_border.name = "RarityBorder"
	_rarity_border.color = Color.TRANSPARENT
	_rarity_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rarity_border.offset_left = 2
	_rarity_border.offset_top = 2
	_rarity_border.offset_right = -2
	_rarity_border.offset_bottom = -2
	add_child(_rarity_border)
	
	# Icon
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 4
	_icon.offset_top = 4
	_icon.offset_right = -4
	_icon.offset_bottom = -4
	add_child(_icon)
	
	# Quantity label
	_quantity_label = Label.new()
	_quantity_label.name = "QuantityLabel"
	_quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_quantity_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quantity_label.offset_right = -4
	_quantity_label.offset_bottom = -2
	_quantity_label.add_theme_font_size_override("font_size", 12)
	_quantity_label.add_theme_color_override("font_color", Color.WHITE)
	_quantity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_quantity_label.add_theme_constant_override("shadow_offset_x", 1)
	_quantity_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_quantity_label)
	
	# Slot type indicator (for equipment slots)
	_slot_type_icon = TextureRect.new()
	_slot_type_icon.name = "SlotTypeIcon"
	_slot_type_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_slot_type_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_slot_type_icon.modulate = Color(1, 1, 1, 0.3)
	_slot_type_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_slot_type_icon.size = Vector2(32, 32)
	_slot_type_icon.position = -_slot_type_icon.size / 2
	add_child(_slot_type_icon)

# =============================================================================
# DISPLAY UPDATE
# =============================================================================

func _update_display() -> void:
	if not is_inside_tree():
		return
	
	# Background
	if show_background:
		_background.visible = true
		if is_locked:
			_background.color = locked_color
		elif is_selected:
			_background.color = selected_color
		elif is_hovered:
			_background.color = hover_color
		else:
			_background.color = empty_color
	else:
		_background.visible = false
	
	# Item display
	if item:
		_icon.texture = item.icon
		_icon.visible = true
		_slot_type_icon.visible = false
		
		# Rarity border
		_rarity_border.color = item.get_rarity_color()
		_rarity_border.color.a = 0.5
		
		# Quantity
		if show_quantity and item.stackable and quantity > 1:
			_quantity_label.text = str(quantity)
			_quantity_label.visible = true
		else:
			_quantity_label.visible = false
	else:
		_icon.texture = null
		_icon.visible = false
		_rarity_border.color = Color.TRANSPARENT
		_quantity_label.visible = false
		
		# Show slot type icon when empty
		if slot_type != Enums.EquipmentSlot.NONE:
			_slot_type_icon.visible = true
			# Would load slot type icon here if available
		else:
			_slot_type_icon.visible = false

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func set_item(new_item: ItemData, new_quantity: int = 1) -> void:
	item = new_item
	quantity = new_quantity
	_update_display()


func clear() -> void:
	item = null
	quantity = 0
	_update_display()


func set_locked(locked: bool) -> void:
	is_locked = locked
	_update_display()


func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_display()


func get_item() -> ItemData:
	return item


func get_quantity() -> int:
	return quantity


func is_empty() -> bool:
	return item == null

# =============================================================================
# DRAG PREVIEW
# =============================================================================

func _create_drag_preview() -> Control:
	var preview = TextureRect.new()
	preview.texture = item.icon if item else null
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = slot_size * 0.8
	preview.modulate = Color(1, 1, 1, 0.7)
	return preview

# =============================================================================
# MOUSE EVENTS
# =============================================================================

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_display()
	slot_hovered.emit(self)


func _on_mouse_exited() -> void:
	is_hovered = false
	_update_display()
	slot_unhovered.emit(self)
