## AssemblyUI - Staff and Wand crafting interface
## Allows combining parts to create weapons with gem socketing
extends Control

# Preload dependencies
const ItemSlot = preload("res://scenes/ui/components/item_slot.gd")
const ItemTooltip = preload("res://scenes/ui/components/item_tooltip.gd")

# =============================================================================
# SIGNALS
# =============================================================================

signal closed()
signal item_crafted(item_type: String)

# =============================================================================
# PROPERTIES
# =============================================================================

var _is_open: bool = false
var _inventory_system: Node = null
var _current_tab: int = 0  ## 0 = Staff, 1 = Wand
var _selected_parts: Dictionary = {}  ## StaffPart -> ItemSlot source index
var _selected_gems: Array[int] = []  ## Inventory indices of selected gems

# UI Components
var _main_panel: PanelContainer
var _tab_container: TabContainer
var _staff_slots: Dictionary = {}  ## StaffPart -> ItemSlot
var _wand_slots: Dictionary = {}
var _gem_slots: Array[ItemSlot] = []
var _inventory_grid: GridContainer
var _inventory_slots: Array[ItemSlot] = []
var _preview_panel: VBoxContainer
var _stats_label: RichTextLabel
var _level_label: Label
var _craft_button: Button
var _tooltip: ItemTooltip

# Enhanced UI Components for visual feedback
var _crafting_animation: AnimationPlayer
var _success_effect: ColorRect
var _error_label: Label
var _weapon_preview: TextureRect
var _part_validation_labels: Dictionary = {}  ## StaffPart -> Label

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
	
	# Main container
	var main_container = HBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.add_theme_constant_override("separation", 16)
	add_child(main_container)
	
	# Assembly panel (left)
	_create_assembly_panel(main_container)
	
	# Inventory panel (right)
	_create_inventory_panel(main_container)


func _create_assembly_panel(parent: Control) -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "AssemblyPanel"
	_main_panel.custom_minimum_size = Vector2(500, 650)
	_apply_panel_style(_main_panel)
	parent.add_child(_main_panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	_main_panel.add_child(main_vbox)
	
	# Header with title and close button
	var header = HBoxContainer.new()
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Magic Assembly Station"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	
	header.add_child(Control.new())
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_button = Button.new()
	close_button.text = "X"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	
	# Error feedback label
	_error_label = Label.new()
	_error_label.text = ""
	_error_label.add_theme_color_override("font_color", Color.RED)
	_error_label.add_theme_font_size_override("font_size", 12)
	_error_label.visible = false
	main_vbox.add_child(_error_label)
	
	# Main content area (tabs + preview side by side)
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(content_hbox)
	
	# Left side: Tabs for Staff/Wand
	var tab_panel = PanelContainer.new()
	tab_panel.custom_minimum_size = Vector2(350, 400)
	_apply_panel_style(tab_panel)
	tab_panel.add_theme_stylebox_override("panel", _create_light_panel_style())
	content_hbox.add_child(tab_panel)
	
	var tab_vbox = VBoxContainer.new()
	tab_vbox.add_theme_constant_override("separation", 8)
	tab_panel.add_child(tab_vbox)
	
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.tab_changed.connect(_on_tab_changed)
	tab_vbox.add_child(_tab_container)
	
	# Staff tab
	_create_staff_tab()
	
	# Wand tab
	_create_wand_tab()
	
	# Right side: Weapon preview
	_create_weapon_preview_panel(content_hbox)
	
	# Bottom section: Detailed stats and craft button
	var bottom_vbox = VBoxContainer.new()
	bottom_vbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(bottom_vbox)
	
	# Preview panel
	_create_preview_panel(bottom_vbox)
	
	# Craft button with visual feedback
	var craft_container = HBoxContainer.new()
	bottom_vbox.add_child(craft_container)
	
	craft_container.add_child(Control.new())
	craft_container.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_craft_button = Button.new()
	_craft_button.text = "Craft Weapon"
	_craft_button.custom_minimum_size = Vector2(150, 40)
	_craft_button.pressed.connect(_on_craft_pressed)
	craft_container.add_child(_craft_button)
	
	craft_container.add_child(Control.new())
	craft_container.get_child(2).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create success overlay
	_create_success_overlay()


func _create_staff_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Staff"
	_tab_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	# Part slots
	var parts_grid = GridContainer.new()
	parts_grid.columns = 2
	parts_grid.add_theme_constant_override("h_separation", 16)
	parts_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(parts_grid)
	
	_staff_slots[Enums.StaffPart.HEAD] = _create_part_slot("Head", Enums.StaffPart.HEAD, true, parts_grid)
	_staff_slots[Enums.StaffPart.EXTERIOR] = _create_part_slot("Exterior", Enums.StaffPart.EXTERIOR, true, parts_grid)
	_staff_slots[Enums.StaffPart.INTERIOR] = _create_part_slot("Interior", Enums.StaffPart.INTERIOR, true, parts_grid)
	_staff_slots[Enums.StaffPart.HANDLE] = _create_part_slot("Handle", Enums.StaffPart.HANDLE, true, parts_grid)
	_staff_slots[Enums.StaffPart.CHARM] = _create_part_slot("Charm (Optional)", Enums.StaffPart.CHARM, false, parts_grid)
	
	# Gem slots section
	vbox.add_child(HSeparator.new())
	
	var gem_label = Label.new()
	gem_label.text = "Gem Slots"
	gem_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(gem_label)
	
	var gem_row = HBoxContainer.new()
	gem_row.add_theme_constant_override("separation", 8)
	vbox.add_child(gem_row)
	
	for i in range(3):
		var slot = _create_gem_slot(i)
		gem_row.add_child(slot)
		_gem_slots.append(slot)


func _create_wand_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Wand"
	_tab_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	# Part slots (fewer for wand)
	var parts_grid = GridContainer.new()
	parts_grid.columns = 2
	parts_grid.add_theme_constant_override("h_separation", 16)
	parts_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(parts_grid)
	
	_wand_slots[Enums.StaffPart.HEAD] = _create_part_slot("Head", Enums.StaffPart.HEAD, true, parts_grid)
	_wand_slots[Enums.StaffPart.EXTERIOR] = _create_part_slot("Exterior", Enums.StaffPart.EXTERIOR, true, parts_grid)
	_wand_slots[Enums.StaffPart.HANDLE] = _create_part_slot("Handle (Optional)", Enums.StaffPart.HANDLE, false, parts_grid)
	
	# Gem slot (wands have 1)
	vbox.add_child(HSeparator.new())
	
	var gem_label = Label.new()
	gem_label.text = "Gem Slot"
	gem_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(gem_label)


func _create_part_slot(label_text: String, part_type: Enums.StaffPart, required: bool, parent: Control) -> ItemSlot:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	parent.add_child(container)
	
	var label = Label.new()
	label.text = label_text
	if not required:
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)
	
	# Add validation label for visual feedback
	var validation_label = Label.new()
	validation_label.text = ""
	validation_label.add_theme_font_size_override("font_size", 10)
	validation_label.visible = false
	container.add_child(validation_label)
	_part_validation_labels[part_type] = validation_label
	
	var slot = ItemSlot.new()
	slot.slot_size = Vector2(64, 64)
	slot.slot_clicked.connect(_on_assembly_slot_clicked.bind(part_type))
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_assembly_slot_dropped.bind(part_type))
	container.add_child(slot)
	
	return slot


func _create_gem_slot(index: int) -> ItemSlot:
	var slot = ItemSlot.new()
	slot.slot_size = Vector2(48, 48)
	slot.slot_index = index
	slot.slot_clicked.connect(_on_gem_slot_clicked.bind(index))
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.item_dropped.connect(_on_gem_slot_dropped.bind(index))
	return slot


func _on_gem_slot_dropped(_slot: ItemSlot, data: Variant, index: int) -> void:
	if data is Dictionary and data.has("item"):
		var item = data.item
		if item is GemData:
			_assign_gem_to_slot(item, data.get("slot_index", -1))
		else:
			_show_error("This slot only accepts gems")


func _create_preview_panel(parent: Control) -> void:
	parent.add_child(HSeparator.new())
	
	_preview_panel = VBoxContainer.new()
	_preview_panel.add_theme_constant_override("separation", 4)
	parent.add_child(_preview_panel)
	
	var preview_label = Label.new()
	preview_label.text = "Weapon Stats Preview"
	preview_label.add_theme_font_size_override("font_size", 14)
	_preview_panel.add_child(preview_label)
	
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 16)
	_level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	_preview_panel.add_child(_level_label)
	
	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = true
	_stats_label.scroll_active = false
	_stats_label.custom_minimum_size = Vector2(0, 100)
	_preview_panel.add_child(_stats_label)


func _create_weapon_preview_panel(parent: Control) -> void:
	var preview_panel = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(120, 300)
	_apply_panel_style(preview_panel)
	preview_panel.add_theme_stylebox_override("panel", _create_light_panel_style())
	parent.add_child(preview_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	preview_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Weapon Preview"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Weapon visual preview
	_weapon_preview = TextureRect.new()
	_weapon_preview.custom_minimum_size = Vector2(80, 80)
	_weapon_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_weapon_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_preview.modulate = Color(1, 1, 1, 0.7)
	vbox.add_child(_weapon_preview)
	
	# Gem slots indicator
	var gem_slots_label = Label.new()
	gem_slots_label.text = "Gem Slots: 0"
	gem_slots_label.add_theme_font_size_override("font_size", 12)
	gem_slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gem_slots_label.name = "GemSlotsLabel"
	vbox.add_child(gem_slots_label)


func _create_success_overlay() -> void:
	_success_effect = ColorRect.new()
	_success_effect.color = Color(0.2, 1.0, 0.2, 0.0)
	_success_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_success_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_success_effect)
	
	_crafting_animation = AnimationPlayer.new()
	add_child(_crafting_animation)
	
	# Create success animation
	var animation = Animation.new()
	var length = 1.0
	animation.length = length
	
	# Fade in and out effect
	var fade_track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(fade_track, ":color:a")
	animation.track_insert_key(fade_track, 0.0, 0.0)
	animation.track_insert_key(fade_track, 0.3, 0.5)
	animation.track_insert_key(fade_track, length, 0.0)
	
	_crafting_animation.add_animation("success", animation)


func _create_light_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
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
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _create_inventory_panel(parent: Control) -> void:
	var panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.custom_minimum_size = Vector2(350, 550)
	_apply_panel_style(panel)
	parent.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 5
	_inventory_grid.add_theme_constant_override("h_separation", 4)
	_inventory_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_inventory_grid)


func _create_tooltip() -> void:
	_tooltip = ItemTooltip.new()
	add_child(_tooltip)


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

func open(inventory: Node) -> void:
	_inventory_system = inventory
	_is_open = true
	_clear_assembly()
	_refresh_inventory()
	_update_preview()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_is_open = false
	_tooltip.hide_tooltip()
	hide()
	closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit to prevent memory leaks"""
	_disconnect_all_signals()

# =============================================================================
# DISPLAY REFRESH
# =============================================================================

func _refresh_inventory() -> void:
	# Clear existing
	for child in _inventory_grid.get_children():
		child.queue_free()
	_inventory_slots.clear()
	
	if _inventory_system == null:
		return
	
	# Show only parts and gems
	for i in range(Constants.INVENTORY_SIZE):
		var item = _inventory_system.get_item(i)
		if item == null:
			continue
		
		if item is StaffPartData or item is GemData:
			var slot = ItemSlot.new()
			slot.slot_index = i
			var quantity = item.stack_count if item.stack_count > 0 else 1
			slot.set_item(item, quantity)
			slot.slot_clicked.connect(_on_inventory_slot_clicked)
			slot.slot_hovered.connect(_on_slot_hovered)
			slot.slot_unhovered.connect(_on_slot_unhovered)
			_inventory_grid.add_child(slot)
			_inventory_slots.append(slot)


func _clear_assembly() -> void:
	_selected_parts.clear()
	_selected_gems.clear()
	
	for slot in _staff_slots.values():
		slot.clear()
	for slot in _wand_slots.values():
		slot.clear()
	for slot in _gem_slots:
		slot.clear()


func _update_preview() -> void:
	var parts = _get_selected_parts()
	
	# Clear validation feedback
	_clear_validation_feedback()
	
	if parts.is_empty():
		_level_label.text = "No parts selected"
		_stats_label.text = ""
		_craft_button.disabled = true
		_update_weapon_preview({})
		_update_gem_slots_display(0)
		return
	
	# Calculate average level
	var total_level = 0
	var part_count = 0
	for part in parts.values():
		total_level += part.part_level
		part_count += 1
	
	var avg_level = int(float(total_level) / max(part_count, 1))
	_level_label.text = "Weapon Level: %d (Requires Lv.%d)" % [avg_level, avg_level]
	
	# Check level requirement
	var player_level = SaveManager.player_data.level
	if player_level < avg_level:
		_level_label.add_theme_color_override("font_color", Color.RED)
		_show_error("Player level too low! Requires Lv.%d" % avg_level)
	else:
		_level_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
		_clear_error()
	
	# Build stats preview
	var stats_text = "[u]Weapon Stats:[/u]\n"
	
	# Compute stats similar to Staff._recompute_stats()
	var computed = {
		"gem_slots": 0,
		"fire_rate": 1.0,
		"projectile_speed": 1.0,
		"damage": 1.0,
		"magika_cost": 1.0,
		"handling": 0.0,
		"stability": 0.0,
		"accuracy": 0.0,
	}
	
	for part in parts.values():
		part.apply_to_weapon_stats(computed)
	
	if computed.gem_slots > 0:
		stats_text += "Gem Slots: %d\n" % computed.gem_slots
		_update_gem_slots_display(computed.gem_slots)
	else:
		_update_gem_slots_display(0)
	
	if computed.fire_rate != 1.0:
		stats_text += "Fire Rate: %+.0f%%\n" % [(computed.fire_rate - 1.0) * 100]
	if computed.damage != 1.0:
		stats_text += "Damage: %+.0f%%\n" % [(computed.damage - 1.0) * 100]
	if computed.magika_cost != 1.0:
		stats_text += "Magika Cost: %+.0f%%\n" % [(computed.magika_cost - 1.0) * 100]
	if computed.handling != 0.0:
		stats_text += "Handling: %+.0f\n" % computed.handling
	if computed.stability != 0.0:
		stats_text += "Stability: %+.0f\n" % computed.stability
	if computed.accuracy != 0.0:
		stats_text += "Accuracy: %+.0f\n" % computed.accuracy
	
	# Add gem information
	var gems_text = _get_gems_preview_text()
	if not gems_text.is_empty():
		stats_text += "\n" + gems_text
	
	_stats_label.text = stats_text
	
	# Update weapon visual preview
	_update_weapon_preview(parts)
	
	# Validate parts and show feedback
	_validate_parts(parts)
	
	# Enable craft if required parts are present
	_craft_button.disabled = not _can_craft()


func _update_weapon_preview(parts: Dictionary) -> void:
	if parts.is_empty():
		_weapon_preview.texture = null
		return
	
	# Load weapon preview based on type and parts
	var is_staff = _current_tab == 0
	var preview_texture = _get_weapon_preview_texture(is_staff, parts)
	_weapon_preview.texture = preview_texture
	
	# Apply tint based on parts
	var avg_rarity = 0.0
	var part_count = 0
	for part in parts.values():
		if part is StaffPartData:
			avg_rarity += part.rarity
			part_count += 1
	
	if part_count > 0:
		avg_rarity /= part_count
		var rarity_color = Constants.RARITY_COLORS.get(int(avg_rarity), Color.WHITE)
		_weapon_preview.modulate = rarity_color


func _get_weapon_preview_texture(is_staff: bool, parts: Dictionary) -> Texture2D:
	# In a real implementation, this would load actual weapon preview textures
	# For now, we'll use placeholder logic
	var base_path = "res://assets/ui/"
	
	if is_staff:
		return load(base_path + "staff_preview.png")
	else:
		return load(base_path + "wand_preview.png")


func _update_gem_slots_display(gem_slots: int) -> void:
	var gem_slots_label = _preview_panel.get_node_or_null("../Weapon Preview Panel/GemSlotsLabel")
	if gem_slots_label:
		gem_slots_label.text = "Gem Slots: %d" % gem_slots


func _get_gems_preview_text() -> String:
	if _gem_slots.is_empty():
		return ""
	
	var gems_text = "[u]Socketed Gems:[/u]\n"
	var has_gems = false
	
	for i in range(_gem_slots.size()):
		var slot = _gem_slots[i]
		if slot.item and slot.item is GemData:
			var gem = slot.item as GemData
			gems_text += "- %s" % gem.item_name
			if gem.element != Enums.Element.NONE:
				gems_text += " (%s)" % Enums.Element.keys()[gem.element]
			gems_text += "\n"
			has_gems = true
	
	return gems_text if has_gems else ""


func _validate_parts(parts: Dictionary) -> void:
	var slots = _staff_slots if _current_tab == 0 else _wand_slots
	var required_parts = _get_required_parts()
	
	# Check each required part
	for part_type in required_parts:
		var validation_label = _part_validation_labels.get(part_type)
		if validation_label == null:
			continue
		
		if parts.has(part_type):
			var part = parts[part_type]
			validation_label.text = "✓ Level %d" % part.part_level
			validation_label.add_theme_color_override("font_color", Color.GREEN)
			validation_label.visible = true
		else:
			validation_label.text = "✗ Required"
			validation_label.add_theme_color_override("font_color", Color.RED)
			validation_label.visible = true


func _get_required_parts() -> Array[Enums.StaffPart]:
	if _current_tab == 0:  # Staff
		return [
			Enums.StaffPart.HEAD,
			Enums.StaffPart.EXTERIOR,
			Enums.StaffPart.INTERIOR,
			Enums.StaffPart.HANDLE
		]
	else:  # Wand
		return [
			Enums.StaffPart.HEAD,
			Enums.StaffPart.EXTERIOR
		]


func _clear_validation_feedback() -> void:
	for label in _part_validation_labels.values():
		if label:
			label.visible = false


func _show_error(message: String) -> void:
	_error_label.text = message
	_error_label.visible = true


func _clear_error() -> void:
	_error_label.text = ""
	_error_label.visible = false


func _get_selected_parts() -> Dictionary:
	var parts: Dictionary = {}
	var slots = _staff_slots if _current_tab == 0 else _wand_slots
	
	for part_type in slots:
		var slot = slots[part_type]
		if slot.item != null:
			parts[part_type] = slot.item
	
	return parts


func _can_craft() -> bool:
	var parts = _get_selected_parts()
	
	if _current_tab == 0:  # Staff
		# Required: Head, Exterior, Interior, Handle
		if not parts.has(Enums.StaffPart.HEAD):
			return false
		if not parts.has(Enums.StaffPart.EXTERIOR):
			return false
		if not parts.has(Enums.StaffPart.INTERIOR):
			return false
		if not parts.has(Enums.StaffPart.HANDLE):
			return false
	else:  # Wand
		# Required: Head, Exterior
		if not parts.has(Enums.StaffPart.HEAD):
			return false
		if not parts.has(Enums.StaffPart.EXTERIOR):
			return false
	
	return true

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_tab_changed(tab: int) -> void:
	_current_tab = tab
	_update_preview()


func _on_inventory_slot_clicked(slot: ItemSlot, button: int) -> void:
	if slot.item == null:
		return
	
	if slot.item is StaffPartData:
		_assign_part_to_slot(slot.item, slot.slot_index)
	elif slot.item is GemData:
		_assign_gem_to_slot(slot.item, slot.slot_index)


func _on_assembly_slot_clicked(slot: ItemSlot, button: int, part_type: Enums.StaffPart) -> void:
	if button == MOUSE_BUTTON_RIGHT and slot.item != null:
		# Remove part
		slot.clear()
		_selected_parts.erase(part_type)
		_refresh_inventory()
		_update_preview()


func _on_assembly_slot_dropped(_slot: ItemSlot, data: Variant, part_type: Enums.StaffPart) -> void:
	if data is Dictionary and data.has("item"):
		var item = data.item
		if item is StaffPartData:
			var part = item as StaffPartData
			if part.part_type == part_type:
				_assign_part_to_slot(part, data.get("slot_index", -1))
			else:
				_show_error("Wrong part type! This slot requires %s" % Enums.StaffPart.keys()[part_type])
		else:
			_show_error("This slot only accepts staff/wand parts")


func _on_gem_slot_clicked(slot: ItemSlot, button: int, index: int) -> void:
	if button == MOUSE_BUTTON_RIGHT and slot.item != null:
		slot.clear()
		if index < _selected_gems.size():
			_selected_gems.remove_at(index)
			_refresh_inventory()
			_update_preview()


func _on_slot_hovered(slot: ItemSlot) -> void:
	if slot.item:
		_tooltip.show_item(slot.item)


func _on_slot_unhovered(_slot: ItemSlot) -> void:
	_tooltip.hide_tooltip()


func _assign_part_to_slot(part: StaffPartData, inventory_index: int) -> void:
	var slots = _staff_slots if _current_tab == 0 else _wand_slots
	
	if not slots.has(part.part_type):
		return
	
	# Check if wand part for wand tab
	if _current_tab == 1 and not part.is_wand_part:
		return
	
	var slot = slots[part.part_type]
	slot.set_item(part)
	_selected_parts[part.part_type] = inventory_index
	
	_refresh_inventory()
	_update_preview()


func _assign_gem_to_slot(gem: GemData, inventory_index: int) -> void:
	# Find first empty gem slot
	for i in range(_gem_slots.size()):
		if _gem_slots[i].item == null:
			_gem_slots[i].set_item(gem, 1)
			_selected_gems.append(inventory_index)
			_refresh_inventory()
			return


func _on_craft_pressed() -> void:
	if not _can_craft():
		_show_error("Cannot craft: Missing required parts")
		return
	
	if _inventory_system == null:
		_show_error("Inventory system not available")
		return
	
	var parts = _get_selected_parts()
	if parts.is_empty():
		_show_error("No parts selected")
		return
	
	# Check player level requirement
	var avg_level = _calculate_weapon_level(parts)
	var player_level = SaveManager.player_data.level
	if player_level < avg_level:
		_show_error("Player level too low! Requires Lv.%d" % avg_level)
		return
	
	# Disable button during crafting
	_craft_button.disabled = true
	_craft_button.text = "Crafting..."
	
	# Simulate crafting animation/delay
	await get_tree().create_timer(0.5).timeout
	
	# Remove parts from inventory
	var indices_to_remove: Array[int] = []
	for part_type in _selected_parts:
		indices_to_remove.append(_selected_parts[part_type])
	
	# Sort descending to remove from end first
	indices_to_remove.sort()
	indices_to_remove.reverse()
	
	var removed_parts = 0
	for index in indices_to_remove:
		if index >= 0 and index < Constants.INVENTORY_SIZE:
			_inventory_system.remove_item(index)
			removed_parts += 1
	
	# Remove gems
	var removed_gems = 0
	_selected_gems.sort()
	_selected_gems.reverse()
	for index in _selected_gems:
		if index >= 0 and index < Constants.INVENTORY_SIZE:
			_inventory_system.remove_item(index)
			removed_gems += 1
	
	# Create the weapon (in a real implementation, this would instantiate Staff/Wand scene)
	var item_type = "staff" if _current_tab == 0 else "wand"
	var weapon_data = _create_weapon_data(parts)
	
	# Add crafted weapon to inventory
	var weapon_slot = _inventory_system.add_item(weapon_data)
	if weapon_slot >= 0:
		# Show success animation
		_show_crafting_success()
		_show_success_message("Crafted %s!" % weapon_data.item_name)
		
		# Emit signal for game systems
		item_crafted.emit(item_type)
	else:
		_show_error("Inventory full! Could not add crafted weapon")
		# Restore items (simplified - in real implementation would be more complex)
		_show_error("Crafting failed - items consumed")
	
	# Reset button and clear UI
	_craft_button.disabled = false
	_craft_button.text = "Craft Weapon"
	
	# Clear and refresh
	_clear_assembly()
	_refresh_inventory()
	_update_preview()


func _calculate_weapon_level(parts: Dictionary) -> int:
	var total_level = 0
	var part_count = 0
	
	for part in parts.values():
		if part is StaffPartData:
			total_level += part.part_level
			part_count += 1
	
	return int(float(total_level) / max(part_count, 1))


func _create_weapon_data(parts: Dictionary) -> ItemData:
	# Create a weapon data item based on the assembled parts
	var weapon_name = _generate_weapon_name(parts)
	var weapon_desc = _generate_weapon_description(parts)
	var weapon_rarity = _calculate_weapon_rarity(parts)
	
	var weapon_data = ItemData.new()
	weapon_data.item_id = "crafted_" + weapon_name.to_lower().replace(" ", "_")
	weapon_data.item_name = weapon_name
	weapon_data.description = weapon_desc
	weapon_data.item_type = Enums.ItemType.EQUIPMENT if _current_tab == 0 else Enums.ItemType.EQUIPMENT
	weapon_data.rarity = weapon_rarity
	weapon_data.level_required = _calculate_weapon_level(parts)
	weapon_data.base_value = _calculate_weapon_value(parts)
	
	# In a real implementation, this would create StaffData or WandData instead
	return weapon_data


func _generate_weapon_name(parts: Dictionary) -> String:
	var prefixes = ["Arcane", "Mystic", "Ethereal", "Celestial", "Infernal", "Frost", "Storm"]
	var types = ["Staff", "Wand"]
	var suffixes = ["of Power", "of Wisdom", "of Elements", "of Destruction", "of Creation"]
	
	var prefix = prefixes.pick_random() if parts.size() > 2 else ""
	var type = types[_current_tab]
	var suffix = suffixes.pick_random() if parts.size() > 3 else ""
	
	var name = prefix + " " + type if not prefix.is_empty() else type
	name += " " + suffix if not suffix.is_empty() else ""
	
	return name.strip_edges()


func _generate_weapon_description(parts: Dictionary) -> String:
	var desc = "A magically crafted %s forged from %d parts." % ["staff" if _current_tab == 0 else "wand", parts.size()]
	
	# Add special properties based on parts
	for part in parts.values():
		if part is StaffPartData:
			var staff_part = part as StaffPartData
			if staff_part.part_type == Enums.StaffPart.CHARM and staff_part.charm_effect:
				desc += "\n" + staff_part.charm_effect.effect_name
			break
	
	return desc


func _calculate_weapon_rarity(parts: Dictionary) -> Enums.Rarity:
	var total_rarity = 0
	var part_count = 0
	
	for part in parts.values():
		if part is StaffPartData:
			total_rarity += int(part.rarity)
			part_count += 1
	
	if part_count == 0:
		return Enums.Rarity.BASIC
	
	var avg_rarity = float(total_rarity) / part_count
	
	# Upgrade rarity slightly for crafted weapons
	if avg_rarity < 1.5:
		return Enums.Rarity.UNCOMMON
	elif avg_rarity < 2.5:
		return Enums.Rarity.RARE
	elif avg_rarity < 3.5:
		return Enums.Rarity.MYTHIC
	elif avg_rarity < 4.5:
		return Enums.Rarity.PRIMORDIAL
	else:
		return Enums.Rarity.UNIQUE


func _calculate_weapon_value(parts: Dictionary) -> int:
	var total_value = 0
	for part in parts.values():
		if part is StaffPartData:
			total_value += part.get_value()
	
	# Add crafting bonus
	return int(total_value * 1.2)


func _show_crafting_success() -> void:
	if _crafting_animation and _crafting_animation.has_animation("success"):
		_crafting_animation.play("success")
		await _crafting_animation.animation_finished


func _show_success_message(message: String) -> void:
	# Create a temporary success message overlay
	var success_label = Label.new()
	success_label.text = message
	success_label.add_theme_font_size_override("font_size", 18)
	success_label.add_theme_color_override("font_color", Color.GREEN)
	success_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	success_label.add_theme_constant_override("shadow_offset_x", 2)
	success_label.add_theme_constant_override("shadow_offset_y", 2)
	success_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	success_label.z_index = 200
	
	add_child(success_label)
	
	# Animate the message
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in and scale up
	success_label.modulate.a = 0.0
	success_label.scale = Vector2(0.5, 0.5)
	tween.tween_property(success_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(success_label, "scale", Vector2(1.2, 1.2), 0.3)
	
	# Hold for a moment
	await tween.finished
	
	# Fade out and scale down
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(success_label, "modulate:a", 0.0, 0.5)
	tween.tween_property(success_label, "scale", Vector2(0.8, 0.8), 0.5)
	
	await tween.finished
	success_label.queue_free()

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
	
	# Disconnect assembly slots
	for slot in _staff_slots.values():
		if slot and is_instance_valid(slot):
			if slot.slot_clicked.is_connected(_on_assembly_slot_clicked):
				slot.slot_clicked.disconnect(_on_assembly_slot_clicked)
			if slot.slot_hovered.is_connected(_on_slot_hovered):
				slot.slot_hovered.disconnect(_on_slot_hovered)
			if slot.slot_unhovered.connect(_on_slot_unhovered):
				slot.slot_unhovered.disconnect(_on_slot_unhovered)
	
	for slot in _wand_slots.values():
		if slot and is_instance_valid(slot):
			if slot.slot_clicked.is_connected(_on_assembly_slot_clicked):
				slot.slot_clicked.disconnect(_on_assembly_slot_clicked)
			if slot.slot_hovered.is_connected(_on_slot_hovered):
				slot.slot_hovered.disconnect(_on_slot_hovered)
			if slot.slot_unhovered.connect(_on_slot_unhovered):
				slot.slot_unhovered.disconnect(_on_slot_unhovered)
	
	# Disconnect gem slots
	for i in range(_gem_slots.size()):
		var slot = _gem_slots[i]
		if slot and is_instance_valid(slot):
			if slot.slot_clicked.is_connected(_on_gem_slot_clicked):
				slot.slot_clicked.disconnect(_on_gem_slot_clicked)
			if slot.slot_hovered.is_connected(_on_slot_hovered):
				slot.slot_hovered.disconnect(_on_slot_hovered)
			if slot.slot_unhovered.connect(_on_slot_unhovered):
				slot.slot_unhovered.disconnect(_on_slot_unhovered)
	
	_inventory_slots.clear()
	_staff_slots.clear()
	_wand_slots.clear()
	_gem_slots.clear()
	_part_validation_labels.clear()
