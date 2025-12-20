## QuestLog - Quest tracking and details UI
## Shows active quests, objectives, and rewards
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal closed()
signal quest_tracked(quest_id: String)
signal quest_abandoned(quest_id: String)

# =============================================================================
# PROPERTIES
# =============================================================================

var _is_open: bool = false
var _selected_quest: QuestData = null

# UI Components
var _main_panel: PanelContainer
var _quest_list: VBoxContainer
var _details_panel: PanelContainer
var _quest_name_label: Label
var _quest_type_label: Label
var _quest_description: RichTextLabel
var _objectives_container: VBoxContainer
var _rewards_container: VBoxContainer
var _track_button: Button
var _abandon_button: Button

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_ui()
	hide()
	
	# Connect to QuestManager signals
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.objective_updated.connect(_on_objective_updated)


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
	
	# Quest list panel (left)
	_create_quest_list_panel(main_container)
	
	# Details panel (right)
	_create_details_panel(main_container)


func _create_quest_list_panel(parent: Control) -> void:
	_main_panel = PanelContainer.new()
	_main_panel.name = "QuestListPanel"
	_main_panel.custom_minimum_size = Vector2(300, 500)
	_apply_panel_style(_main_panel)
	parent.add_child(_main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_main_panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Quest Log"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)
	
	header.add_child(Control.new())
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var close_button = Button.new()
	close_button.text = "X"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Quest list with scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)
	
	_quest_list = VBoxContainer.new()
	_quest_list.name = "QuestList"
	_quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_quest_list)


func _create_details_panel(parent: Control) -> void:
	_details_panel = PanelContainer.new()
	_details_panel.name = "DetailsPanel"
	_details_panel.custom_minimum_size = Vector2(400, 500)
	_apply_panel_style(_details_panel)
	parent.add_child(_details_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_details_panel.add_child(vbox)
	
	# Quest name and type
	_quest_name_label = Label.new()
	_quest_name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_quest_name_label)
	
	_quest_type_label = Label.new()
	_quest_type_label.add_theme_font_size_override("font_size", 12)
	_quest_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(_quest_type_label)
	
	# Description
	_quest_description = RichTextLabel.new()
	_quest_description.bbcode_enabled = true
	_quest_description.fit_content = true
	_quest_description.scroll_active = false
	_quest_description.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(_quest_description)
	
	# Objectives section
	vbox.add_child(HSeparator.new())
	
	var obj_label = Label.new()
	obj_label.text = "Objectives"
	obj_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(obj_label)
	
	_objectives_container = VBoxContainer.new()
	_objectives_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_objectives_container)
	
	# Rewards section
	vbox.add_child(HSeparator.new())
	
	var reward_label = Label.new()
	reward_label.text = "Rewards"
	reward_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(reward_label)
	
	_rewards_container = VBoxContainer.new()
	_rewards_container.add_theme_constant_override("separation", 2)
	vbox.add_child(_rewards_container)
	
	# Spacer
	vbox.add_child(Control.new())
	vbox.get_child(vbox.get_child_count() - 1).size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	vbox.add_child(button_row)
	
	_track_button = Button.new()
	_track_button.text = "Track Quest"
	_track_button.pressed.connect(_on_track_pressed)
	button_row.add_child(_track_button)
	
	_abandon_button = Button.new()
	_abandon_button.text = "Abandon"
	_abandon_button.pressed.connect(_on_abandon_pressed)
	button_row.add_child(_abandon_button)


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
	_refresh_quest_list()
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
	"""Disconnect quest item buttons to prevent memory leaks"""
	# Disconnect quest item buttons
	for quest_button in get_tree().get_nodes_in_group("quest_items"):
		pass  # TODO: Implement button disconnection logic


# =============================================================================
# QUEST LIST
# =============================================================================

func _refresh_quest_list() -> void:
	# Clear existing entries
	for child in _quest_list.get_children():
		child.queue_free()
	
	# Get active quests
	var quests = QuestManager.get_active_quests()
	
	if quests.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No active quests"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_quest_list.add_child(empty_label)
		_clear_details()
		return
	
	# Sort: main quests first, then by name
	quests.sort_custom(func(a, b):
		if a.is_main_quest != b.is_main_quest:
			return a.is_main_quest
		return a.quest_name < b.quest_name
	)
	
	# Add quest entries
	for quest in quests:
		var entry = _create_quest_entry(quest)
		_quest_list.add_child(entry)
	
	# Select first quest by default
	if _selected_quest == null and quests.size() > 0:
		_select_quest(quests[0])


func _create_quest_entry(quest: QuestData) -> Control:
	var button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Build entry text
	var text = ""
	if quest.quest_id == QuestManager.tracked_quest_id:
		text += "[>] "
	
	if quest.is_main_quest:
		text += "[M] "
	
	text += quest.quest_name
	
	# Add progress indicator
	var completed = 0
	var total = 0
	for obj in quest.get_objectives():
		if not obj.is_optional:
			total += 1
			if obj.is_completed:
				completed += 1
	
	text += " (%d/%d)" % [completed, total]
	
	button.text = text
	
	# Style based on state
	if quest.quest_id == QuestManager.tracked_quest_id:
		button.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	elif quest.is_main_quest:
		button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	
	button.pressed.connect(_select_quest.bind(quest))
	
	return button

# =============================================================================
# QUEST DETAILS
# =============================================================================

func _select_quest(quest: QuestData) -> void:
	_selected_quest = quest
	_refresh_details()
	_refresh_quest_list()  # Update selection highlight


func _refresh_details() -> void:
	if _selected_quest == null:
		_clear_details()
		return
	
	# Name
	_quest_name_label.text = _selected_quest.quest_name
	
	# Type
	if _selected_quest.is_main_quest:
		_quest_type_label.text = "Main Quest - Chapter %d" % _selected_quest.chapter
		_quest_type_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	else:
		_quest_type_label.text = "Side Quest"
		_quest_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	
	# Description
	_quest_description.text = "[i]%s[/i]" % _selected_quest.description
	
	# Objectives
	_refresh_objectives()
	
	# Rewards
	_refresh_rewards()
	
	# Button states
	_track_button.disabled = _selected_quest.quest_id == QuestManager.tracked_quest_id
	_track_button.text = "Tracking" if _track_button.disabled else "Track Quest"
	
	_abandon_button.disabled = _selected_quest.is_main_quest  # Can't abandon main quests


func _clear_details() -> void:
	_quest_name_label.text = "No Quest Selected"
	_quest_type_label.text = ""
	_quest_description.text = ""
	
	for child in _objectives_container.get_children():
		child.queue_free()
	for child in _rewards_container.get_children():
		child.queue_free()
	
	_track_button.disabled = true
	_abandon_button.disabled = true


func _refresh_objectives() -> void:
	for child in _objectives_container.get_children():
		child.queue_free()
	
	for obj in _selected_quest.get_objectives():
		if obj.is_hidden and not obj.is_revealed:
			continue
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		_objectives_container.add_child(hbox)
		
		# Checkbox indicator
		var checkbox = Label.new()
		if obj.is_completed:
			checkbox.text = "[X]"
			checkbox.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		elif obj.is_failed:
			checkbox.text = "[!]"
			checkbox.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		else:
			checkbox.text = "[ ]"
			checkbox.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		hbox.add_child(checkbox)
		
		# Objective text
		var obj_text = Label.new()
		obj_text.text = "%s - %s" % [obj.description, obj.get_progress_text()]
		
		if obj.is_optional:
			obj_text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		elif obj.is_completed:
			obj_text.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		elif obj.is_failed:
			obj_text.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		
		hbox.add_child(obj_text)


func _refresh_rewards() -> void:
	for child in _rewards_container.get_children():
		child.queue_free()
	
	if _selected_quest.reward_experience > 0:
		_add_reward_line("%d XP" % _selected_quest.reward_experience, Color(0.6, 0.8, 1.0))
	
	if _selected_quest.reward_gold > 0:
		_add_reward_line("%d Gold" % _selected_quest.reward_gold, Color(1.0, 0.85, 0.0))
	
	if _selected_quest.reward_skill_points > 0:
		_add_reward_line("%d Skill Points" % _selected_quest.reward_skill_points, Color(0.8, 0.4, 1.0))
	
	for item_id in _selected_quest.reward_items:
		_add_reward_line(item_id, Color(0.4, 1.0, 0.4))
	
	if _rewards_container.get_child_count() == 0:
		_add_reward_line("None", Color(0.5, 0.5, 0.5))


func _add_reward_line(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = "- " + text
	label.add_theme_color_override("font_color", color)
	_rewards_container.add_child(label)

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_track_pressed() -> void:
	if _selected_quest:
		QuestManager.track_quest(_selected_quest.quest_id)
		quest_tracked.emit(_selected_quest.quest_id)
		_refresh_quest_list()
		_refresh_details()


func _on_abandon_pressed() -> void:
	if _selected_quest and not _selected_quest.is_main_quest:
		QuestManager.abandon_quest(_selected_quest.quest_id)
		quest_abandoned.emit(_selected_quest.quest_id)
		_selected_quest = null
		_refresh_quest_list()

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_quest_started(_quest: QuestData) -> void:
	if _is_open:
		_refresh_quest_list()


func _on_quest_completed(quest: QuestData) -> void:
	if _is_open:
		if _selected_quest and _selected_quest.quest_id == quest.quest_id:
			_selected_quest = null
		_refresh_quest_list()


func _on_objective_updated(quest: QuestData, _objective: QuestObjective) -> void:
	if _is_open and _selected_quest and _selected_quest.quest_id == quest.quest_id:
		_refresh_objectives()
		_refresh_quest_list()
