## ItemTooltip - Rich tooltip for displaying item information
## Follows mouse cursor and shows item stats, description, and requirements
class_name ItemTooltip
extends PanelContainer

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var max_width: float = 300.0
@export var offset_from_cursor: Vector2 = Vector2(16, 16)
@export var fade_duration: float = 0.1

# =============================================================================
# PROPERTIES
# =============================================================================

var _current_item: ItemData = null
var _is_visible: bool = false

# Node references
var _content: VBoxContainer
var _name_label: RichTextLabel
var _type_label: Label
var _description_label: RichTextLabel
var _stats_container: VBoxContainer
var _requirements_label: Label
var _value_label: Label

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_ui()
	hide()
	
	# Set up as top-level so it's not clipped by parent containers
	top_level = true
	z_index = 100


func _process(_delta: float) -> void:
	if _is_visible:
		_follow_cursor()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Style the panel
	custom_minimum_size = Vector2(200, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.35)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	
	# Content container
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.add_theme_constant_override("separation", 4)
	add_child(_content)
	
	# Item name (with rarity color)
	_name_label = RichTextLabel.new()
	_name_label.name = "NameLabel"
	_name_label.bbcode_enabled = true
	_name_label.fit_content = true
	_name_label.scroll_active = false
	_name_label.custom_minimum_size = Vector2(0, 24)
	_content.add_child(_name_label)
	
	# Item type and rarity
	_type_label = Label.new()
	_type_label.name = "TypeLabel"
	_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_type_label.add_theme_font_size_override("font_size", 12)
	_content.add_child(_type_label)
	
	# Separator
	var sep1 = HSeparator.new()
	sep1.add_theme_constant_override("separation", 8)
	_content.add_child(sep1)
	
	# Description
	_description_label = RichTextLabel.new()
	_description_label.name = "DescriptionLabel"
	_description_label.bbcode_enabled = true
	_description_label.fit_content = true
	_description_label.scroll_active = false
	_description_label.add_theme_color_override("default_color", Color(0.8, 0.8, 0.8))
	_content.add_child(_description_label)
	
	# Stats container
	_stats_container = VBoxContainer.new()
	_stats_container.name = "StatsContainer"
	_stats_container.add_theme_constant_override("separation", 2)
	_content.add_child(_stats_container)
	
	# Requirements
	_requirements_label = Label.new()
	_requirements_label.name = "RequirementsLabel"
	_requirements_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_requirements_label.add_theme_font_size_override("font_size", 12)
	_content.add_child(_requirements_label)
	
	# Separator
	var sep2 = HSeparator.new()
	sep2.add_theme_constant_override("separation", 8)
	_content.add_child(sep2)
	
	# Value
	_value_label = Label.new()
	_value_label.name = "ValueLabel"
	_value_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_value_label.add_theme_font_size_override("font_size", 12)
	_content.add_child(_value_label)

# =============================================================================
# DISPLAY
# =============================================================================

func show_item(item: ItemData) -> void:
	if item == null:
		hide_tooltip()
		return
	
	_current_item = item
	_populate_tooltip()
	_is_visible = true
	show()
	
	# Ensure proper positioning on first frame
	await get_tree().process_frame
	_follow_cursor()


func hide_tooltip() -> void:
	_is_visible = false
	_current_item = null
	hide()


func _populate_tooltip() -> void:
	if _current_item == null:
		return
	
	# Name with rarity color
	var rarity_color = _current_item.get_rarity_color().to_html()
	_name_label.text = "[b][color=#%s]%s[/color][/b]" % [rarity_color, _current_item.item_name]
	
	# Type and rarity
	var type_name = Enums.ItemType.keys()[_current_item.item_type]
	var rarity_name = Enums.Rarity.keys()[_current_item.rarity]
	_type_label.text = "%s - %s" % [rarity_name.capitalize(), type_name.replace("_", " ").capitalize()]
	
	# Description
	if _current_item.description.is_empty():
		_description_label.visible = false
	else:
		_description_label.visible = true
		_description_label.text = "[i]%s[/i]" % _current_item.description
	
	# Stats (varies by item type)
	_populate_stats()
	
	# Requirements
	if _current_item.level_required > 1:
		_requirements_label.visible = true
		var player_level = SaveManager.player_data.level
		if player_level >= _current_item.level_required:
			_requirements_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			_requirements_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_requirements_label.text = "Requires Level %d" % _current_item.level_required
	else:
		_requirements_label.visible = false
	
	# Value
	_value_label.text = "Value: %d gold" % _current_item.get_value()


func _populate_stats() -> void:
	# Clear existing stats
	for child in _stats_container.get_children():
		child.queue_free()
	
	# Add stats based on item type
	if _current_item is EquipmentData:
		var equipment = _current_item as EquipmentData
		var slot_name = Enums.EquipmentSlot.keys()[equipment.slot].replace("_", " ").capitalize()
		_add_stat_line(slot_name, "", Color(0.7, 0.7, 1.0))
		
		var stat_desc = equipment.get_stat_description()
		if not stat_desc.is_empty():
			for line in stat_desc.split("\n"):
				_add_stat_line(line, "", Color(0.4, 1.0, 0.4))
	
	elif _current_item is StaffPartData:
		var part = _current_item as StaffPartData
		var part_name = Enums.StaffPart.keys()[part.part_type].capitalize()
		_add_stat_line(part_name + " Part", "", Color(0.7, 0.7, 1.0))
		_add_stat_line("Level: %d" % part.part_level, "", Color(0.8, 0.8, 0.8))
		
		var stat_desc = part.get_stat_description()
		if not stat_desc.is_empty():
			for line in stat_desc.split("\n"):
				if not line.begins_with("Part Level"):  # Skip duplicate level line
					_add_stat_line(line, "", Color(0.4, 1.0, 0.4))
	
	elif _current_item is GemData:
		var gem = _current_item as GemData
		_add_stat_line("Gem", gem.gem_name, Color(0.7, 0.7, 1.0))
		
		var mod_desc = gem.get_modifier_description()
		if not mod_desc.is_empty():
			for line in mod_desc.split("\n"):
				_add_stat_line(line, "", Color(0.4, 1.0, 0.4))
	
	_stats_container.visible = _stats_container.get_child_count() > 0


func _add_stat_line(text: String, value: String = "", color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 13)
	
	if value.is_empty():
		label.text = text
	else:
		label.text = "%s: %s" % [text, value]
	
	_stats_container.add_child(label)

# =============================================================================
# POSITIONING
# =============================================================================

func _follow_cursor() -> void:
	var viewport = get_viewport()
	if viewport == null:
		return
	
	var mouse_pos = viewport.get_mouse_position()
	var tooltip_size = size
	var viewport_size = viewport.get_visible_rect().size
	
	# Default position: bottom-right of cursor
	var new_pos = mouse_pos + offset_from_cursor
	
	# Flip horizontal if would go off screen
	if new_pos.x + tooltip_size.x > viewport_size.x:
		new_pos.x = mouse_pos.x - tooltip_size.x - offset_from_cursor.x
	
	# Flip vertical if would go off screen
	if new_pos.y + tooltip_size.y > viewport_size.y:
		new_pos.y = mouse_pos.y - tooltip_size.y - offset_from_cursor.y
	
	# Ensure not off left/top edge
	new_pos.x = max(0, new_pos.x)
	new_pos.y = max(0, new_pos.y)
	
	global_position = new_pos
