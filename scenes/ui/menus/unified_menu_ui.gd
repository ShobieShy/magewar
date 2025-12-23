## UnifiedMenuUI - Integrated pause menu, inventory, skill tree, and stats
## Single unified interface accessed via Esc to toggle
## Tabs to switch between Pause Menu, Inventory, Skill Tree, and Stats
class_name UnifiedMenuUI
extends CanvasLayer

# Preload StatAllocationUI script
const StatAllocationUIScript = preload("res://scenes/ui/menus/stat_allocation_ui.gd")

# =============================================================================
# SIGNALS
# =============================================================================

signal menu_opened
signal menu_closed
# signal tab_changed(tab_name: String)  # Currently unused but kept for future implementation
signal settings_requested
signal quit_to_menu_requested
signal join_requested

# =============================================================================
# ENUMS
# =============================================================================

enum MenuTab {
	PAUSE = 0,
	INVENTORY = 1,
	SKILLS = 2,
	STATS = 3,
	SETTINGS = 4,
	SHOP = 5,
	CRAFTING = 6,
	REFINEMENT = 7,
	STORAGE = 8,
	QUESTS = 9,
	FAST_TRAVEL = 10
}

# =============================================================================
# PROPERTIES
# =============================================================================

var _is_open: bool = false
var _is_paused: bool = false
var _current_tab: MenuTab = MenuTab.PAUSE
var _inventory_system: Node = null

# UI Components
var _main_container: Control
var _tab_container: TabContainer
var _pause_panel: Control
var _inventory_panel: Control
var _skills_panel: Control
var _stats_ui: Control  ## StatAllocationUI instance

# Pause Menu Components
var _resume_button: Button
var _join_button: Button
var _settings_button: Button
var _quit_button: Button

# Inventory Components
# var _inventory_ui: Control  # Currently unused but kept for future implementation
var _equipment_panel: Control
var _inventory_grid: GridContainer
var _equipment_slots: Dictionary = {}
var _inventory_slots: Array[ItemSlot] = []
var _current_page: int = 0
var _page_label: Label
const ITEMS_PER_PAGE: int = 48
var _gold_label: Label
var _player_level_label: Label
var _inventory_tooltip: ItemTooltip
var _context_menu: PopupMenu
var _context_slot: ItemSlot = null

# Skill Tree Components
# var _skill_tree_ui: Control  # Currently unused but kept for future implementation
var _skill_nodes: Dictionary = {}
var _category_tabs: TabContainer
var _skill_containers: Dictionary = {}
var _skill_name_label: Label
var _skill_type_label: Label
var _skill_description: RichTextLabel
var _skill_stats: VBoxContainer
var _unlock_button: Button
var _set_active_button: Button
var _points_label: Label
var _selected_skill: SkillData = null

# Settings Components
var _settings_panel: Control

# Shop Components
var _shop_panel: Control

# Crafting Components
var _crafting_panel: Control

# Refinement Components
var _refinement_panel: Control

# Storage Components
var _storage_panel: Control

# Quests Components
var _quests_panel: Control

# Fast Travel Components
var _fast_travel_panel: Control

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var columns: int = 8
@export var slot_size: Vector2 = Vector2(64, 64)
@export var slot_spacing: int = 4

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	visible = false  # Start invisible instead of using hide()
	layer = 100  # UI layer
	
	# Connect to managers
	SaveManager.gold_changed.connect(_on_gold_changed)
	SkillManager.skill_unlocked.connect(_on_skill_unlocked)
	SkillManager.skill_points_changed.connect(_on_skill_points_changed)


func _process(_delta: float) -> void:
	# Handle pause input - works when paused
	if Input.is_action_just_pressed("pause"):
		if _is_open:
			close()
		else:
			# Default to Pause tab when opening via Escape
			_switch_tab(MenuTab.PAUSE)
			open()
			
	# Handle inventory input - open directly to inventory
	elif Input.is_action_just_pressed("inventory"):
		if _is_open:
			if _current_tab == MenuTab.INVENTORY:
				close()
			else:
				_switch_tab(MenuTab.INVENTORY)
		else:
			_switch_tab(MenuTab.INVENTORY)
			open()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	
	# Close on Esc/Pause - Handled in _process
	
	# Tab shortcuts (when menu is open)
	if event.is_action_pressed("inventory"):  # Tab or I
		# Handled in _process now
		pass
	
	elif event.is_action_pressed("skill_tree"):  # K
		_switch_tab(MenuTab.SKILLS)
		get_viewport().set_input_as_handled()
	
	# Numeric shortcuts for other tabs
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:  # Settings
				_switch_tab(MenuTab.SETTINGS)
				get_viewport().set_input_as_handled()
			KEY_H:  # sHop
				_switch_tab(MenuTab.SHOP)
				get_viewport().set_input_as_handled()
			KEY_C:  # Crafting
				_switch_tab(MenuTab.CRAFTING)
				get_viewport().set_input_as_handled()
			KEY_R:  # Refinement
				_switch_tab(MenuTab.REFINEMENT)
				get_viewport().set_input_as_handled()
			KEY_D:  # storAge/depot
				_switch_tab(MenuTab.STORAGE)
				get_viewport().set_input_as_handled()
			KEY_Q:  # Quests
				_switch_tab(MenuTab.QUESTS)
				get_viewport().set_input_as_handled()
			KEY_M:  # Map/fast travel
				_switch_tab(MenuTab.FAST_TRAVEL)
				get_viewport().set_input_as_handled()


# =============================================================================
# MENU MANAGEMENT
# =============================================================================

func open() -> void:
	"""Open the unified menu"""
	_is_open = true
	visible = true
	
	# Pause the game
	_is_paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Refresh all displays
	_refresh_inventory_display()
	_update_skill_tree_display()
	
	menu_opened.emit()


func close() -> void:
	"""Close the unified menu"""
	_is_open = false
	visible = false
	
	# Resume the game
	_is_paused = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Clean up
	if _inventory_tooltip:
		_inventory_tooltip.hide_tooltip()
	
	menu_closed.emit()


func is_open() -> bool:
	return _is_open


func is_paused() -> bool:
	return _is_paused


func set_inventory_system(inventory_system: Node) -> void:
	"""Set the inventory system to display"""
	_inventory_system = inventory_system
	if _is_open:
		_refresh_inventory_display()


# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Background dimmer - fills entire screen
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.anchor_left = 0.0
	dimmer.anchor_top = 0.0
	dimmer.anchor_right = 1.0
	dimmer.anchor_bottom = 1.0
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	# Main VBox container - centered
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.anchor_left = 0.5
	main_vbox.anchor_top = 0.5
	main_vbox.anchor_right = 0.5
	main_vbox.anchor_bottom = 0.5
	main_vbox.offset_left = -500  # Half of width (1000/2)
	main_vbox.offset_top = -300   # Half of height (600/2)
	main_vbox.offset_right = 500
	main_vbox.offset_bottom = 300
	add_child(main_vbox)
	_main_container = main_vbox  # Store reference
	
	# Tab container for switching between menus
	_tab_container = TabContainer.new()
	_tab_container.name = "MenuTabs"
	_tab_container.custom_minimum_size = Vector2(1000, 600)
	_tab_container.tab_changed.connect(_on_tab_changed)
	main_vbox.add_child(_tab_container)
	
	# Create tab panels
	_create_pause_tab()
	_create_inventory_tab()
	_create_skills_tab()
	_create_stats_tab()
	_create_settings_tab()
	_create_shop_tab()
	_create_crafting_tab()
	_create_refinement_tab()
	_create_storage_tab()
	_create_quests_tab()
	_create_fast_travel_tab()
	
	# Create tooltip and context menu (shared across tabs)
	_inventory_tooltip = ItemTooltip.new()
	_inventory_tooltip.name = "ItemTooltip"
	add_child(_inventory_tooltip)
	
	_context_menu = PopupMenu.new()
	_context_menu.name = "ContextMenu"
	_context_menu.id_pressed.connect(_on_context_menu_selected)
	add_child(_context_menu)


func _create_pause_tab() -> void:
	"""Create the pause menu tab"""
	_pause_panel = PanelContainer.new()
	_pause_panel.name = "Pause"
	_apply_panel_style(_pause_panel)
	_tab_container.add_child(_pause_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_pause_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "GAME PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Resume button
	_resume_button = Button.new()
	_resume_button.text = "Resume Game"
	_resume_button.custom_minimum_size = Vector2(300, 50)
	_resume_button.pressed.connect(_on_resume_pressed)
	vbox.add_child(_resume_button)
	
	# Join button
	_join_button = Button.new()
	_join_button.text = "Join Player"
	_join_button.custom_minimum_size = Vector2(300, 50)
	_join_button.pressed.connect(_on_join_pressed)
	vbox.add_child(_join_button)
	
	# Settings button
	_settings_button = Button.new()
	_settings_button.text = "Settings"
	_settings_button.custom_minimum_size = Vector2(300, 50)
	_settings_button.pressed.connect(_on_settings_pressed)
	vbox.add_child(_settings_button)
	
	# Quit button
	_quit_button = Button.new()
	_quit_button.text = "Quit to Menu"
	_quit_button.custom_minimum_size = Vector2(300, 50)
	_quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(_quit_button)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)


func _create_inventory_tab() -> void:
	"""Create the inventory tab"""
	_inventory_panel = PanelContainer.new()
	_inventory_panel.name = "Inventory"
	_apply_panel_style(_inventory_panel)
	_tab_container.add_child(_inventory_panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 16)
	_inventory_panel.add_child(main_hbox)
	
	# Equipment panel (left side)
	_create_equipment_panel(main_hbox)
	
	# Inventory panel (right side)
	_create_inventory_grid_panel(main_hbox)


func _create_equipment_panel(parent: Control) -> void:
	"""Create equipment slots panel"""
	_equipment_panel = PanelContainer.new()
	_equipment_panel.name = "EquipmentPanel"
	_equipment_panel.custom_minimum_size = Vector2(250, 500)
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
	"""Create a single equipment slot"""
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


func _create_inventory_grid_panel(parent: Control) -> void:
	"""Create inventory grid panel"""
	var inventory_panel_container = PanelContainer.new()
	inventory_panel_container.name = "InventoryGridPanel"
	inventory_panel_container.custom_minimum_size = Vector2(600, 500)
	_apply_panel_style(inventory_panel_container)
	parent.add_child(inventory_panel_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	inventory_panel_container.add_child(vbox)
	
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
	
	# Create inventory slots for a single page
	for i in range(ITEMS_PER_PAGE):
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
	
	# Pagination UI
	var pagination = HBoxContainer.new()
	pagination.alignment = BoxContainer.ALIGNMENT_CENTER
	pagination.add_theme_constant_override("separation", 20)
	vbox.add_child(pagination)
	
	var prev_btn = Button.new()
	prev_btn.text = "<"
	prev_btn.pressed.connect(_on_prev_page_pressed)
	pagination.add_child(prev_btn)
	
	_page_label = Label.new()
	_page_label.text = "Page 1"
	pagination.add_child(_page_label)
	
	var next_btn = Button.new()
	next_btn.text = ">"
	next_btn.pressed.connect(_on_next_page_pressed)
	pagination.add_child(next_btn)


func _on_prev_page_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_refresh_inventory_display()


func _on_next_page_pressed() -> void:
	var total_pages = ceili(float(Constants.INVENTORY_SIZE) / ITEMS_PER_PAGE)
	if _current_page < total_pages - 1:
		_current_page += 1
		_refresh_inventory_display()


func _create_skills_tab() -> void:
	"""Create the skill tree tab"""
	_skills_panel = PanelContainer.new()
	_skills_panel.name = "Skills"
	_apply_panel_style(_skills_panel)
	_tab_container.add_child(_skills_panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 16)
	_skills_panel.add_child(main_hbox)
	
	# Skill tree panel (left)
	_create_skill_tree_panel(main_hbox)
	
	# Details panel (right)
	_create_skill_details_panel(main_hbox)


func _create_skill_tree_panel(parent: Control) -> void:
	"""Create skill tree panel with categories"""
	var tree_panel = PanelContainer.new()
	tree_panel.name = "TreePanel"
	tree_panel.custom_minimum_size = Vector2(500, 500)
	_apply_panel_style(tree_panel)
	parent.add_child(tree_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	tree_panel.add_child(vbox)
	
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
	
	# Category tabs
	_category_tabs = TabContainer.new()
	_category_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_category_tabs)
	
	# Create category panels
	_create_skill_category_panel(Enums.SkillCategory.OFFENSE, "Offense")
	_create_skill_category_panel(Enums.SkillCategory.DEFENSE, "Defense")
	_create_skill_category_panel(Enums.SkillCategory.UTILITY, "Utility")
	_create_skill_category_panel(Enums.SkillCategory.ELEMENTAL, "Elemental")


func _create_skill_category_panel(category: Enums.SkillCategory, title: String) -> void:
	"""Create a skill category panel"""
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


func _create_skill_details_panel(parent: Control) -> void:
	"""Create skill details panel"""
	var details_panel = PanelContainer.new()
	details_panel.name = "DetailsPanel"
	details_panel.custom_minimum_size = Vector2(300, 500)
	_apply_panel_style(details_panel)
	parent.add_child(details_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	details_panel.add_child(vbox)
	
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
	_unlock_button.pressed.connect(_on_skill_unlock_pressed)
	button_row.add_child(_unlock_button)
	
	_set_active_button = Button.new()
	_set_active_button.text = "Set as Active Ability"
	_set_active_button.pressed.connect(_on_skill_set_active_pressed)
	button_row.add_child(_set_active_button)


func _apply_panel_style(panel: PanelContainer) -> void:
	"""Apply consistent panel styling"""
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
# TAB SWITCHING
# =============================================================================

func _switch_tab(tab: MenuTab) -> void:
	"""Switch to a specific tab"""
	_current_tab = tab
	_tab_container.current_tab = tab
	
	match tab:
		MenuTab.PAUSE:
			_resume_button.grab_focus()
		MenuTab.INVENTORY:
			_refresh_inventory_display()
		MenuTab.SKILLS:
			_update_skill_tree_display()
		MenuTab.STATS:
			if _stats_ui and _stats_ui.is_visible_in_tree():
				_stats_ui.open()
		MenuTab.SETTINGS:
			pass  # Settings tab is static
		MenuTab.SHOP:
			pass  # Shop tab populated by ShopManager
		MenuTab.CRAFTING:
			pass  # Crafting tab is static
		MenuTab.REFINEMENT:
			pass  # Refinement tab is static
		MenuTab.STORAGE:
			pass  # Storage tab is static
		MenuTab.QUESTS:
			pass  # Quests tab is static
		MenuTab.FAST_TRAVEL:
			pass  # Fast Travel tab is static


func _on_tab_changed(tab_index: int) -> void:
	"""Handle tab container tab change"""
	_current_tab = tab_index as MenuTab
	
	match tab_index:
		MenuTab.INVENTORY:
			_refresh_inventory_display()
		MenuTab.SKILLS:
			_update_skill_tree_display()
		MenuTab.STATS:
			if _stats_ui:
				_stats_ui.open()
		MenuTab.SETTINGS:
			pass  # Settings tab is static
		MenuTab.SHOP:
			pass  # Shop tab populated by ShopManager
		MenuTab.CRAFTING:
			pass  # Crafting tab is static
		MenuTab.REFINEMENT:
			pass  # Refinement tab is static
		MenuTab.STORAGE:
			pass  # Storage tab is static
		MenuTab.QUESTS:
			pass  # Quests tab is static
		MenuTab.FAST_TRAVEL:
			pass  # Fast Travel tab is static


# =============================================================================
# INVENTORY DISPLAY
# =============================================================================

func _refresh_inventory_display() -> void:
	"""Refresh inventory display"""
	_refresh_inventory_items()
	_refresh_equipment_display()
	_refresh_gold_display()
	_refresh_player_info_display()


func _refresh_inventory_items() -> void:
	"""Refresh inventory grid items"""
	if _inventory_system == null:
		return
	
	var total_pages = ceili(float(Constants.INVENTORY_SIZE) / ITEMS_PER_PAGE)
	_current_page = clamp(_current_page, 0, total_pages - 1)
	
	if _page_label:
		_page_label.text = "Page %d / %d" % [_current_page + 1, total_pages]
	
	for i in range(_inventory_slots.size()):
		var slot = _inventory_slots[i]
		var inventory_index = _current_page * ITEMS_PER_PAGE + i
		
		# Set the slot index so interactions affect the right item
		slot.slot_index = inventory_index
		
		if inventory_index < Constants.INVENTORY_SIZE:
			var item = _inventory_system.get_item(inventory_index)
			if item:
				slot.set_item(item.item, item.get("quantity", 1))
				slot.visible = true
			else:
				slot.clear()
				slot.visible = true
		else:
			slot.clear()
			slot.visible = false


func _refresh_equipment_display() -> void:
	"""Refresh equipment slots"""
	if _inventory_system == null:
		return
	
	for slot_type in _equipment_slots:
		var ui_slot = _equipment_slots[slot_type].get_child(0) as ItemSlot
		var equipped = _inventory_system.get_equipped(slot_type)
		if equipped:
			ui_slot.set_item(equipped)
		else:
			ui_slot.clear()


func _refresh_gold_display() -> void:
	"""Refresh gold label"""
	_gold_label.text = "%d Gold" % SaveManager.get_gold()


func _refresh_player_info_display() -> void:
	"""Refresh player level and XP info"""
	var level = SaveManager.player_data.level
	var exp_data = SaveManager.get_exp_progress()
	_player_level_label.text = "Level %d (%.0f%%)" % [level, exp_data.progress * 100]


# =============================================================================
# SKILL TREE DISPLAY
# =============================================================================

func _update_skill_tree_display() -> void:
	"""Update skill tree display"""
	_populate_skill_tree()
	_update_skill_points_display()
	_clear_skill_details()


func _populate_skill_tree() -> void:
	"""Populate skill tree with all skills"""
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


func _create_skill_node(skill: SkillData) -> SkillNode:
	"""Create a skill node UI element"""
	var node = SkillNode.new()
	var is_unlocked = SkillManager.is_skill_unlocked(skill.skill_id)
	var can_unlock = SkillManager.can_unlock_skill(skill.skill_id)
	
	node.set_skill(skill, is_unlocked, can_unlock)
	node.skill_clicked.connect(_on_skill_node_clicked)
	node.skill_hovered.connect(_on_skill_node_hovered)
	node.skill_unhovered.connect(_on_skill_node_unhovered)
	
	return node


func _refresh_skill_states() -> void:
	"""Refresh all skill node states"""
	for skill_id in _skill_nodes:
		var node = _skill_nodes[skill_id]
		var is_unlocked = SkillManager.is_skill_unlocked(skill_id)
		var can_unlock = SkillManager.can_unlock_skill(skill_id)
		node.set_state(is_unlocked, can_unlock)


func _update_skill_points_display() -> void:
	"""Update skill points display"""
	var points = SaveManager.get_skill_points()
	_points_label.text = "Skill Points: %d" % points


func _select_skill(skill: SkillData) -> void:
	"""Select a skill and show its details"""
	_selected_skill = skill
	_update_skill_details()


func _update_skill_details() -> void:
	"""Update skill details panel"""
	if _selected_skill == null:
		_clear_skill_details()
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
	_refresh_skill_stats()
	
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


func _clear_skill_details() -> void:
	"""Clear skill details panel"""
	_selected_skill = null
	_skill_name_label.text = "Select a Skill"
	_skill_type_label.text = ""
	_skill_description.text = ""
	
	for child in _skill_stats.get_children():
		child.queue_free()
	
	_unlock_button.visible = false
	_set_active_button.visible = false


func _refresh_skill_stats() -> void:
	"""Refresh skill stats display"""
	for child in _skill_stats.get_children():
		child.queue_free()
	
	var stat_desc = _selected_skill.get_stat_description()
	if stat_desc.is_empty():
		_add_skill_stat_line("No special effects", Color(0.5, 0.5, 0.5))
		return
	
	for line in stat_desc.split("\n"):
		_add_skill_stat_line(line, Color(0.4, 1.0, 0.4))


func _add_skill_stat_line(text: String, color: Color) -> void:
	"""Add a stat line to the skill stats display"""
	var label = Label.new()
	label.text = "- " + text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 13)
	_skill_stats.add_child(label)


# =============================================================================
# PAUSE MENU BUTTON HANDLERS
# =============================================================================

func _on_resume_pressed() -> void:
	"""Handle resume button"""
	close()


func _on_join_pressed() -> void:
	"""Handle join button - placeholder for multiplayer"""
	join_requested.emit()


func _on_settings_pressed() -> void:
	"""Handle settings button"""
	settings_requested.emit()


func _on_quit_pressed() -> void:
	"""Handle quit to menu button"""
	quit_to_menu_requested.emit()


# =============================================================================
# INVENTORY INTERACTIONS
# =============================================================================

func _on_slot_clicked(slot: ItemSlot, button: int) -> void:
	"""Handle slot click"""
	if button == MOUSE_BUTTON_RIGHT and slot.item != null:
		_show_context_menu(slot)


func _on_slot_double_clicked(slot: ItemSlot) -> void:
	"""Handle slot double click"""
	if slot.item == null:
		return
	
	# Double-click to equip/use
	if slot.item is EquipmentData or slot.item is StaffPartData:
		_equip_item(slot)
	elif slot.item.can_use():
		_use_item(slot)


func _on_slot_hovered(slot: ItemSlot) -> void:
	"""Handle slot hover"""
	if slot.item != null:
		_inventory_tooltip.show_item(slot.item)


func _on_slot_unhovered(_slot: ItemSlot) -> void:
	"""Handle slot unhover"""
	_inventory_tooltip.hide_tooltip()


func _on_item_dropped(target_slot: ItemSlot, data: Variant) -> void:
	"""Handle item drop"""
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
			_refresh_inventory_display()
			return
		
		# Extra validation: verify source item ID matches what we expect
		if actual_item.item_id != source_slot.item.item_id:
			push_warning("Item mismatch detected - drop cancelled for safety")
			_refresh_inventory_display()
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
	
	_refresh_inventory_display()


func _handle_equip_drop(source: ItemSlot, target: ItemSlot) -> void:
	"""Handle equipment drop"""
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
	"""Handle unequip drop"""
	_inventory_system.unequip_to_inventory(source.slot_type)


func _handle_inventory_swap(source: ItemSlot, target: ItemSlot) -> void:
	"""Handle inventory item swap"""
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


func _show_context_menu(slot: ItemSlot) -> void:
	"""Show context menu for item"""
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
	
	_context_menu.position = get_viewport().get_mouse_position()
	_context_menu.popup()


func _on_context_menu_selected(id: int) -> void:
	"""Handle context menu selection"""
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
	_refresh_inventory_display()


func _use_item(slot: ItemSlot) -> void:
	"""Use an item"""
	if _inventory_system and slot.slot_index >= 0:
		_inventory_system.use_item(slot.slot_index)
		_refresh_inventory_display()


func _equip_item(slot: ItemSlot) -> void:
	"""Equip an item"""
	if _inventory_system and slot.slot_index >= 0:
		_inventory_system.equip_item(slot.slot_index)
		_refresh_inventory_display()


func _unequip_item(slot: ItemSlot) -> void:
	"""Unequip an item"""
	if _inventory_system and slot.slot_type != Enums.EquipmentSlot.NONE:
		_inventory_system.unequip_to_inventory(slot.slot_type)
		_refresh_inventory_display()


func _drop_item(slot: ItemSlot) -> void:
	"""Drop an item"""
	if _inventory_system and slot.slot_index >= 0:
		_inventory_system.remove_item(slot.slot_index)
		_refresh_inventory_display()


# =============================================================================
# SKILL TREE INTERACTIONS
# =============================================================================

func _on_skill_node_clicked(skill: SkillData) -> void:
	"""Handle skill node click"""
	_select_skill(skill)


func _on_skill_node_hovered(_skill: SkillData) -> void:
	"""Handle skill node hover"""
	pass


func _on_skill_node_unhovered(_skill: SkillData) -> void:
	"""Handle skill node unhover"""
	pass


func _on_skill_unlock_pressed() -> void:
	"""Handle unlock button press"""
	if _selected_skill and SkillManager.can_unlock_skill(_selected_skill.skill_id):
		SkillManager.unlock_skill(_selected_skill.skill_id)


func _on_skill_set_active_pressed() -> void:
	"""Handle set active ability button press"""
	if _selected_skill and _selected_skill.skill_type == Enums.SkillType.ACTIVE:
		SkillManager.set_active_ability(_selected_skill.skill_id)
		_update_skill_details()


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_gold_changed(_new_amount: int, _delta: int) -> void:
	"""Handle gold change"""
	if _is_open and _current_tab == MenuTab.INVENTORY:
		_refresh_gold_display()


func _on_skill_unlocked(_skill: SkillData) -> void:
	"""Handle skill unlocked"""
	_refresh_skill_states()
	_update_skill_points_display()
	if _selected_skill:
		_update_skill_details()


func _on_skill_points_changed(_new_amount: int) -> void:
	"""Handle skill points changed"""
	_update_skill_points_display()
	_refresh_skill_states()
	if _selected_skill:
		_update_skill_details()


# =============================================================================
# STATS TAB
# =============================================================================

func _create_stats_tab() -> void:
	"""Create the stats allocation tab"""
	_stats_ui = StatAllocationUIScript.new()
	_stats_ui.name = "Stats"
	_stats_ui.is_embedded = true
	
	# We add it directly to tab container as it now handles its own internal layout
	_tab_container.add_child(_stats_ui)
	
	_stats_ui.closed.connect(_on_stats_closed)

func _on_stats_closed() -> void:
	"""Handle stats UI closed"""
	pass


# =============================================================================
# SETTINGS TAB
# =============================================================================

func _create_settings_tab() -> void:
	"""Create the settings tab - integrates audio, video, and gameplay settings"""
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "Settings"
	_apply_panel_style(_settings_panel)
	_tab_container.add_child(_settings_panel)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_settings_panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Audio Settings
	var audio_title = Label.new()
	audio_title.text = "Audio"
	audio_title.add_theme_font_size_override("font_size", 18)
	audio_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	vbox.add_child(audio_title)
	
	# Master Volume
	var master_hbox = HBoxContainer.new()
	master_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(master_hbox)
	
	var master_label = Label.new()
	master_label.text = "Master Volume:"
	master_label.custom_minimum_size = Vector2(150, 0)
	master_hbox.add_child(master_label)
	
	var master_slider = HSlider.new()
	master_slider.min_value = 0
	master_slider.max_value = 100
	master_slider.step = 1
	master_slider.value = 80
	master_slider.custom_minimum_size = Vector2(200, 0)
	master_hbox.add_child(master_slider)
	
	# Music Volume
	var music_hbox = HBoxContainer.new()
	music_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(music_hbox)
	
	var music_label = Label.new()
	music_label.text = "Music Volume:"
	music_label.custom_minimum_size = Vector2(150, 0)
	music_hbox.add_child(music_label)
	
	var music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.step = 1
	music_slider.value = 70
	music_slider.custom_minimum_size = Vector2(200, 0)
	music_hbox.add_child(music_slider)
	
	# SFX Volume
	var sfx_hbox = HBoxContainer.new()
	sfx_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(sfx_hbox)
	
	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume:"
	sfx_label.custom_minimum_size = Vector2(150, 0)
	sfx_hbox.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.step = 1
	sfx_slider.value = 80
	sfx_slider.custom_minimum_size = Vector2(200, 0)
	sfx_hbox.add_child(sfx_slider)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Gameplay Settings
	var gameplay_title = Label.new()
	gameplay_title.text = "Gameplay"
	gameplay_title.add_theme_font_size_override("font_size", 18)
	gameplay_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	vbox.add_child(gameplay_title)
	
	# Mouse Sensitivity
	var mouse_hbox = HBoxContainer.new()
	mouse_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(mouse_hbox)
	
	var mouse_label = Label.new()
	mouse_label.text = "Mouse Sensitivity:"
	mouse_label.custom_minimum_size = Vector2(150, 0)
	mouse_hbox.add_child(mouse_label)
	
	var mouse_slider = HSlider.new()
	mouse_slider.min_value = 0.1
	mouse_slider.max_value = 2.0
	mouse_slider.step = 0.1
	mouse_slider.value = 1.0
	mouse_slider.custom_minimum_size = Vector2(200, 0)
	mouse_hbox.add_child(mouse_slider)
	
	# Damage Numbers
	var damage_hbox = HBoxContainer.new()
	damage_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(damage_hbox)
	
	var damage_label = Label.new()
	damage_label.text = "Show Damage Numbers:"
	damage_label.custom_minimum_size = Vector2(150, 0)
	damage_hbox.add_child(damage_label)
	
	var damage_check = CheckBox.new()
	damage_check.button_pressed = true
	damage_hbox.add_child(damage_check)
	
	# Friendly Fire
	var friendly_hbox = HBoxContainer.new()
	friendly_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(friendly_hbox)
	
	var friendly_label = Label.new()
	friendly_label.text = "Friendly Fire:"
	friendly_label.custom_minimum_size = Vector2(150, 0)
	friendly_hbox.add_child(friendly_label)
	
	var friendly_check = CheckBox.new()
	friendly_check.button_pressed = false
	friendly_hbox.add_child(friendly_check)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Info
	var info = Label.new()
	info.text = "Settings are saved automatically"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(info)


# =============================================================================
# SHOP TAB
# =============================================================================

func _create_shop_tab() -> void:
	"""Create the shop tab"""
	_shop_panel = PanelContainer.new()
	_shop_panel.name = "Shop"
	_apply_panel_style(_shop_panel)
	_tab_container.add_child(_shop_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_shop_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Shop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var placeholder = Label.new()
	placeholder.text = "[Interact with a Shopkeeper to view their shop]"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(placeholder)


# =============================================================================
# CRAFTING TAB
# =============================================================================

func _create_crafting_tab() -> void:
	"""Create the crafting tab"""
	_crafting_panel = PanelContainer.new()
	_crafting_panel.name = "Crafting"
	_apply_panel_style(_crafting_panel)
	_tab_container.add_child(_crafting_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_crafting_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Crafting"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var placeholder = Label.new()
	placeholder.text = "[Crafting content coming soon]\nPress C to access Crafting"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(placeholder)


# =============================================================================
# REFINEMENT TAB
# =============================================================================

func _create_refinement_tab() -> void:
	"""Create the refinement tab"""
	_refinement_panel = PanelContainer.new()
	_refinement_panel.name = "Refinement"
	_apply_panel_style(_refinement_panel)
	_tab_container.add_child(_refinement_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_refinement_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Refinement"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var placeholder = Label.new()
	placeholder.text = "[Refinement content coming soon]\nPress R to access Refinement"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(placeholder)


# =============================================================================
# STORAGE TAB
# =============================================================================

func _create_storage_tab() -> void:
	"""Create the storage tab"""
	_storage_panel = PanelContainer.new()
	_storage_panel.name = "Storage"
	_apply_panel_style(_storage_panel)
	_tab_container.add_child(_storage_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_storage_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Storage"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var placeholder = Label.new()
	placeholder.text = "[Storage content coming soon]\nPress D to access Storage"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(placeholder)


# =============================================================================
# QUESTS TAB
# =============================================================================

func _create_quests_tab() -> void:
	"""Create the quests tab"""
	_quests_panel = PanelContainer.new()
	_quests_panel.name = "Quests"
	_apply_panel_style(_quests_panel)
	_tab_container.add_child(_quests_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_quests_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Quests"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var placeholder = Label.new()
	placeholder.text = "[Quest Log content coming soon]\nPress Q to access Quests"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(placeholder)


# =============================================================================
# FAST TRAVEL TAB
# =============================================================================

func _create_fast_travel_tab() -> void:
	"""Create the fast travel tab"""
	_fast_travel_panel = PanelContainer.new()
	_fast_travel_panel.name = "Map"
	_apply_panel_style(_fast_travel_panel)
	_tab_container.add_child(_fast_travel_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_fast_travel_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Fast Travel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var placeholder = Label.new()
	placeholder.text = "[Fast Travel content coming soon]\nPress M to access Map"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(placeholder)

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	"""Disconnect all signals before tree exit"""
	_disconnect_all_signals()


func _disconnect_all_signals() -> void:
	"""Disconnect all signals to prevent memory leaks"""
	# Disconnect inventory item slots
	for slot in _inventory_slots:
		if slot and is_instance_valid(slot):
			if slot.slot_clicked.is_connected(_on_slot_clicked):
				slot.slot_clicked.disconnect(_on_slot_clicked)
			if slot.slot_hovered.is_connected(_on_slot_hovered):
				slot.slot_hovered.disconnect(_on_slot_hovered)
			if slot.slot_unhovered.is_connected(_on_slot_unhovered):
				slot.slot_unhovered.disconnect(_on_slot_unhovered)
			if slot.slot_double_clicked.is_connected(_on_slot_double_clicked):
				slot.slot_double_clicked.disconnect(_on_slot_double_clicked)
			if slot.item_dropped.is_connected(_on_item_dropped):
				slot.item_dropped.disconnect(_on_item_dropped)
	
	# Disconnect equipment item slots
	for slot_type in _equipment_slots:
		var container = _equipment_slots[slot_type]
		if container and is_instance_valid(container):
			var item_slot = container.get_child(0) as ItemSlot
			if item_slot and is_instance_valid(item_slot):
				if item_slot.slot_clicked.is_connected(_on_slot_clicked):
					item_slot.slot_clicked.disconnect(_on_slot_clicked)
				if item_slot.slot_hovered.is_connected(_on_slot_hovered):
					item_slot.slot_hovered.disconnect(_on_slot_hovered)
				if item_slot.slot_unhovered.is_connected(_on_slot_unhovered):
					item_slot.slot_unhovered.disconnect(_on_slot_unhovered)
				if item_slot.item_dropped.is_connected(_on_item_dropped):
					item_slot.item_dropped.disconnect(_on_item_dropped)
	
	# Disconnect context menu
	if _context_menu and is_instance_valid(_context_menu):
		if _context_menu.id_pressed.is_connected(_on_context_menu_selected):
			_context_menu.id_pressed.disconnect(_on_context_menu_selected)
	
	# Disconnect manager signals
	if SaveManager:
		if SaveManager.gold_changed.is_connected(_on_gold_changed):
			SaveManager.gold_changed.disconnect(_on_gold_changed)
	
	if SkillManager:
		if SkillManager.skill_unlocked.is_connected(_on_skill_unlocked):
			SkillManager.skill_unlocked.disconnect(_on_skill_unlocked)
		if SkillManager.skill_points_changed.is_connected(_on_skill_points_changed):
			SkillManager.skill_points_changed.disconnect(_on_skill_points_changed)
	
	# Clear collections
	_inventory_slots.clear()
	_equipment_slots.clear()
	_skill_nodes.clear()
