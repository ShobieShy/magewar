## SkillTreeUI - Skill tree management interface
## Shows skill categories, nodes, and allows unlocking skills
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal closed()

# =============================================================================
# PROPERTIES
# =============================================================================

var _is_open: bool = false
var _selected_skill: SkillData = null
var _skill_nodes: Dictionary = {}  ## skill_id -> SkillNode

# UI Components
var _main_panel: PanelContainer
var _category_tabs: TabContainer
var _skill_containers: Dictionary = {}  ## SkillCategory -> Control
var _details_panel: PanelContainer
var _skill_name_label: Label
var _skill_type_label: Label
var _skill_description: RichTextLabel
var _skill_stats: VBoxContainer
var _unlock_button: Button
var _set_active_button: Button
var _points_label: Label
var _tooltip_panel: PanelContainer
var _tooltip_label: RichTextLabel

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_ui()
	hide()
	
	# Connect to SkillManager
	SkillManager.skill_unlocked.connect(_on_skill_unlocked)
	SkillManager.skill_points_changed.connect(_on_skill_points_changed)


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	
	if event.is_action_pressed("pause"):
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
	
	# Skill tree panel (left)
	_create_tree_panel(main_container)
	
	# Details panel (right)
	_create_details_panel(main_container)


func _create_tree_panel(parent: Control) -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "TreePanel"
	_main_panel.custom_minimum_size = Vector2(500, 500)
	_apply_panel_style(_main_panel)
	parent.add_child(_main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_main_panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Skill Tree"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	
	header.add_child(Control.new())
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 16)
	_points_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	header.add_child(_points_label)
	
	var close_button = Button.new()
	close_button.text = "X"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	
	# Category tabs
	_category_tabs = TabContainer.new()
	_category_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_category_tabs)
	
	# Create category panels
	_create_category_panel(Enums.SkillCategory.OFFENSE, "Offense")
	_create_category_panel(Enums.SkillCategory.DEFENSE, "Defense")
	_create_category_panel(Enums.SkillCategory.UTILITY, "Utility")
	_create_category_panel(Enums.SkillCategory.ELEMENTAL, "Elemental")


func _create_category_panel(category: Enums.SkillCategory, title: String) -> void:
	var scroll = ScrollContainer.new()
	scroll.name = title
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_tabs.add_child(scroll)
	
	var container = Control.new()
	container.name = "SkillContainer"
	container.custom_minimum_size = Vector2(450, 400)
	scroll.add_child(container)
	
	_skill_containers[category] = container


func _create_details_panel(parent: Control) -> void:
	_details_panel = PanelContainer.new()
	_details_panel.name = "DetailsPanel"
	_details_panel.custom_minimum_size = Vector2(300, 500)
	_apply_panel_style(_details_panel)
	parent.add_child(_details_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_details_panel.add_child(vbox)
	
	# Skill name
	_skill_name_label = Label.new()
	_skill_name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_skill_name_label)
	
	# Skill type
	_skill_type_label = Label.new()
	_skill_type_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_skill_type_label)
	
	vbox.add_child(HSeparator.new())
	
	# Description
	_skill_description = RichTextLabel.new()
	_skill_description.bbcode_enabled = true
	_skill_description.fit_content = true
	_skill_description.scroll_active = false
	_skill_description.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(_skill_description)
	
	vbox.add_child(HSeparator.new())
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = "Effects"
	stats_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(stats_label)
	
	_skill_stats = VBoxContainer.new()
	_skill_stats.add_theme_constant_override("separation", 2)
	vbox.add_child(_skill_stats)
	
	# Spacer
	vbox.add_child(Control.new())
	vbox.get_child(vbox.get_child_count() - 1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Buttons
	var button_row = VBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	vbox.add_child(button_row)
	
	_unlock_button = Button.new()
	_unlock_button.text = "Unlock Skill"
	_unlock_button.pressed.connect(_on_unlock_pressed)
	button_row.add_child(_unlock_button)
	
	_set_active_button = Button.new()
	_set_active_button.text = "Set as Active Ability"
	_set_active_button.pressed.connect(_on_set_active_pressed)
	button_row.add_child(_set_active_button)


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

func open() -> void:
	_is_open = true
	_populate_skill_tree()
	_update_points_display()
	_clear_details()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_is_open = false
	hide()
	closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return _is_open


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit to prevent memory leaks"""
	_disconnect_all_signals()


func _disconnect_all_signals() -> void:
	"""Disconnect button signals to prevent memory leaks"""
	# Disconnect skill node buttons
	for skill_button in get_tree().get_nodes_in_group("skill_buttons"):
		pass  # TODO: Implement button disconnection logic

	
	# Disconnect action buttons if they exist
	if _unlock_button and is_instance_valid(_unlock_button):
		if _unlock_button.pressed.is_connected(_on_unlock_pressed):
			_unlock_button.pressed.disconnect(_on_unlock_pressed)
	
	if _set_active_button and is_instance_valid(_set_active_button):
		if _set_active_button.pressed.is_connected(_on_set_active_pressed):
			_set_active_button.pressed.disconnect(_on_set_active_pressed)

# =============================================================================
# SKILL TREE POPULATION
# =============================================================================

func _populate_skill_tree() -> void:
	_skill_nodes.clear()
	
	# Clear existing nodes
	for category in _skill_containers:
		var container = _skill_containers[category]
		for child in container.get_children():
			child.queue_free()
	
	# Get all skills
	var all_skills = SkillManager.get_all_skills()
	
	# Create nodes for each skill
	for skill in all_skills:
		var node = _create_skill_node(skill)
		var container = _skill_containers.get(skill.category)
		if container:
			container.add_child(node)
			node.position = skill.tree_position
			_skill_nodes[skill.skill_id] = node
	
	# Draw connection lines (would need to be implemented with Line2D or _draw)


func _create_skill_node(skill: SkillData) -> SkillNode:
	var node = SkillNode.new()
	var is_unlocked = SkillManager.is_skill_unlocked(skill.skill_id)
	var can_unlock = SkillManager.can_unlock_skill(skill.skill_id)
	
	node.set_skill(skill, is_unlocked, can_unlock)
	node.skill_clicked.connect(_on_skill_clicked)
	node.skill_hovered.connect(_on_skill_hovered)
	node.skill_unhovered.connect(_on_skill_unhovered)
	
	return node


func _refresh_skill_states() -> void:
	for skill_id in _skill_nodes:
		var node = _skill_nodes[skill_id]
		var is_unlocked = SkillManager.is_skill_unlocked(skill_id)
		var can_unlock = SkillManager.can_unlock_skill(skill_id)
		node.set_state(is_unlocked, can_unlock)

# =============================================================================
# DETAILS PANEL
# =============================================================================

func _select_skill(skill: SkillData) -> void:
	_selected_skill = skill
	_update_details()


func _update_details() -> void:
	if _selected_skill == null:
		_clear_details()
		return
	
	# Name
	_skill_name_label.text = _selected_skill.skill_name
	
	# Type with color
	var type_name = Enums.SkillType.keys()[_selected_skill.skill_type]
	var category_name = Enums.SkillCategory.keys()[_selected_skill.category]
	_skill_type_label.text = "%s - %s" % [type_name.capitalize(), category_name.capitalize()]
	
	match _selected_skill.skill_type:
		Enums.SkillType.PASSIVE:
			_skill_type_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
		Enums.SkillType.ACTIVE:
			_skill_type_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		Enums.SkillType.SPELL_AUGMENT:
			_skill_type_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
	
	# Description
	_skill_description.text = "[i]%s[/i]" % _selected_skill.description
	
	# Stats
	_refresh_stats()
	
	# Button states
	var is_unlocked = SkillManager.is_skill_unlocked(_selected_skill.skill_id)
	var can_unlock = SkillManager.can_unlock_skill(_selected_skill.skill_id)
	
	_unlock_button.visible = not is_unlocked
	_unlock_button.disabled = not can_unlock
	
	if not can_unlock and not is_unlocked:
		# Show why it can't be unlocked
		if SaveManager.get_skill_points() < _selected_skill.skill_points_cost:
			_unlock_button.text = "Need %d Skill Points" % _selected_skill.skill_points_cost
		elif SaveManager.player_data.level < _selected_skill.required_level:
			_unlock_button.text = "Requires Level %d" % _selected_skill.required_level
		elif _selected_skill.prerequisite_skills.size() > 0:
			_unlock_button.text = "Requires Prerequisites"
		else:
			_unlock_button.text = "Unlock Skill"
	else:
		_unlock_button.text = "Unlock Skill (1 Point)"
	
	# Active ability button
	_set_active_button.visible = is_unlocked and _selected_skill.skill_type == Enums.SkillType.ACTIVE
	var current_active = SkillManager.get_active_ability()
	_set_active_button.disabled = current_active and current_active.skill_id == _selected_skill.skill_id
	_set_active_button.text = "Currently Active" if _set_active_button.disabled else "Set as Active Ability"


func _clear_details() -> void:
	_selected_skill = null
	_skill_name_label.text = "Select a Skill"
	_skill_type_label.text = ""
	_skill_description.text = ""
	
	for child in _skill_stats.get_children():
		child.queue_free()
	
	_unlock_button.visible = false
	_set_active_button.visible = false


func _refresh_stats() -> void:
	for child in _skill_stats.get_children():
		child.queue_free()
	
	var stat_desc = _selected_skill.get_stat_description()
	if stat_desc.is_empty():
		_add_stat_line("No special effects", Color(0.5, 0.5, 0.5))
		return
	
	for line in stat_desc.split("\n"):
		_add_stat_line(line, Color(0.4, 1.0, 0.4))


func _add_stat_line(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = "- " + text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 13)
	_skill_stats.add_child(label)


func _update_points_display() -> void:
	var points = SaveManager.get_skill_points()
	_points_label.text = "Skill Points: %d" % points

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_skill_clicked(skill: SkillData) -> void:
	_select_skill(skill)


func _on_skill_hovered(_skill: SkillData) -> void:
	# Could show tooltip here
	pass


func _on_skill_unhovered(_skill: SkillData) -> void:
	pass


func _on_unlock_pressed() -> void:
	if _selected_skill and SkillManager.can_unlock_skill(_selected_skill.skill_id):
		SkillManager.unlock_skill(_selected_skill.skill_id)


func _on_set_active_pressed() -> void:
	if _selected_skill and _selected_skill.skill_type == Enums.SkillType.ACTIVE:
		SkillManager.set_active_ability(_selected_skill.skill_id)
		_update_details()


func _on_skill_unlocked(_skill: SkillData) -> void:
	_refresh_skill_states()
	_update_points_display()
	if _selected_skill:
		_update_details()


func _on_skill_points_changed(_new_amount: int) -> void:
	_update_points_display()
	_refresh_skill_states()
	if _selected_skill:
		_update_details()
