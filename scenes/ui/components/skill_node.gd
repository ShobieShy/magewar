## SkillNode - Visual representation of a skill in the skill tree
## Shows skill icon, state, and handles interaction
class_name SkillNode
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal skill_clicked(skill: SkillData)
signal skill_hovered(skill: SkillData)
signal skill_unhovered(skill: SkillData)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var node_size: Vector2 = Vector2(64, 64)

# =============================================================================
# PROPERTIES
# =============================================================================

var skill: SkillData = null
var is_unlocked: bool = false
var can_unlock: bool = false
var is_hovered: bool = false

# UI Components
var _background: ColorRect
var _border: ColorRect
var _icon: TextureRect
var _type_indicator: ColorRect
var _lock_overlay: ColorRect

# Colors
const COLOR_LOCKED = Color(0.2, 0.2, 0.2, 0.9)
const COLOR_AVAILABLE = Color(0.3, 0.4, 0.5, 0.9)
const COLOR_UNLOCKED = Color(0.2, 0.3, 0.2, 0.9)
const COLOR_HOVER = Color(0.4, 0.5, 0.6, 0.9)

const BORDER_LOCKED = Color(0.3, 0.3, 0.3)
const BORDER_AVAILABLE = Color(0.5, 0.6, 0.8)
const BORDER_UNLOCKED = Color(0.4, 0.8, 0.4)

const TYPE_PASSIVE = Color(0.3, 0.6, 1.0)
const TYPE_ACTIVE = Color(1.0, 0.6, 0.3)
const TYPE_AUGMENT = Color(0.8, 0.3, 1.0)

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	custom_minimum_size = node_size
	_create_ui()
	_update_display()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if skill:
				skill_clicked.emit(skill)
			accept_event()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Border (slightly larger than background)
	_border = ColorRect.new()
	_border.name = "Border"
	_border.color = BORDER_LOCKED
	_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_border)
	
	# Background
	_background = ColorRect.new()
	_background.name = "Background"
	_background.color = COLOR_LOCKED
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.offset_left = 2
	_background.offset_top = 2
	_background.offset_right = -2
	_background.offset_bottom = -2
	add_child(_background)
	
	# Icon
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 8
	_icon.offset_top = 8
	_icon.offset_right = -8
	_icon.offset_bottom = -8
	add_child(_icon)
	
	# Type indicator (small corner triangle)
	_type_indicator = ColorRect.new()
	_type_indicator.name = "TypeIndicator"
	_type_indicator.custom_minimum_size = Vector2(12, 12)
	_type_indicator.position = Vector2(node_size.x - 14, 2)
	_type_indicator.color = TYPE_PASSIVE
	add_child(_type_indicator)
	
	# Lock overlay (semi-transparent dark overlay)
	_lock_overlay = ColorRect.new()
	_lock_overlay.name = "LockOverlay"
	_lock_overlay.color = Color(0, 0, 0, 0.6)
	_lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lock_overlay.offset_left = 2
	_lock_overlay.offset_top = 2
	_lock_overlay.offset_right = -2
	_lock_overlay.offset_bottom = -2
	add_child(_lock_overlay)

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func set_skill(skill_data: SkillData, unlocked: bool, available: bool) -> void:
	skill = skill_data
	is_unlocked = unlocked
	can_unlock = available
	_update_display()


func set_state(unlocked: bool, available: bool) -> void:
	is_unlocked = unlocked
	can_unlock = available
	_update_display()

# =============================================================================
# DISPLAY UPDATE
# =============================================================================

func _update_display() -> void:
	if not is_inside_tree():
		return
	
	# Icon
	if skill and skill.icon:
		_icon.texture = skill.icon
		_icon.modulate = Color.WHITE if is_unlocked or can_unlock else Color(0.5, 0.5, 0.5)
	else:
		_icon.texture = null
	
	# Type indicator color
	if skill:
		match skill.skill_type:
			Enums.SkillType.PASSIVE:
				_type_indicator.color = TYPE_PASSIVE
			Enums.SkillType.ACTIVE:
				_type_indicator.color = TYPE_ACTIVE
			Enums.SkillType.SPELL_AUGMENT:
				_type_indicator.color = TYPE_AUGMENT
	
	# Background and border based on state
	if is_unlocked:
		_background.color = COLOR_UNLOCKED if not is_hovered else COLOR_HOVER
		_border.color = BORDER_UNLOCKED
		_lock_overlay.visible = false
	elif can_unlock:
		_background.color = COLOR_AVAILABLE if not is_hovered else COLOR_HOVER
		_border.color = BORDER_AVAILABLE
		_lock_overlay.visible = false
	else:
		_background.color = COLOR_LOCKED
		_border.color = BORDER_LOCKED
		_lock_overlay.visible = true
	
	# Mouse cursor
	if is_unlocked:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	elif can_unlock:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN

# =============================================================================
# MOUSE EVENTS
# =============================================================================

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_display()
	if skill:
		skill_hovered.emit(skill)


func _on_mouse_exited() -> void:
	is_hovered = false
	_update_display()
	if skill:
		skill_unhovered.emit(skill)
