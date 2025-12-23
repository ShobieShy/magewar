## DamageNumber - Floating damage number in 3D world space
## Displays damage dealt with animations and color coding
class_name DamageNumber
extends Node3D

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var rise_speed: float = 2.0
@export var duration: float = 1.0
@export var fade_start: float = 0.5  ## When to start fading (0-1)
@export var spread_range: float = 0.5  ## Random horizontal spread
@export var font_size: int = 24

# =============================================================================
# PROPERTIES
# =============================================================================

var damage_value: float = 0.0
var is_critical: bool = false
var is_heal: bool = false
var damage_element: Enums.Element = Enums.Element.NONE

var _label: Label3D
var _time_alive: float = 0.0
var _initial_position: Vector3
var _offset: Vector3

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_label()
	_initial_position = global_position
	
	# Random horizontal offset
	_offset = Vector3(
		randf_range(-spread_range, spread_range),
		0,
		randf_range(-spread_range, spread_range)
	)


func _process(delta: float) -> void:
	_time_alive += delta
	
	# Update position (rise up with slight drift)
	var progress = _time_alive / duration
	global_position = _initial_position + _offset + Vector3.UP * rise_speed * _time_alive
	
	# Billboard behavior is handled by Label3D property
	
	# Fade out
	if progress > fade_start:
		var fade_progress = (progress - fade_start) / (1.0 - fade_start)
		_label.modulate.a = 1.0 - fade_progress
	
	# Scale animation for crits
	if is_critical:
		var scale_factor = 1.0 + sin(progress * PI) * 0.3
		_label.pixel_size = 0.01 * scale_factor
	
	# Destroy when done
	if _time_alive >= duration:
		queue_free()

# =============================================================================
# SETUP
# =============================================================================

func _create_label() -> void:
	_label = Label3D.new()
	_label.name = "Label"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = true
	_label.pixel_size = 0.01
	add_child(_label)
	
	_update_display()


func _update_display() -> void:
	if _label == null:
		return
	
	# Format number
	var text = ""
	if is_heal:
		text = "+%d" % int(abs(damage_value))
	else:
		text = "%d" % int(damage_value)
	
	if is_critical:
		text = "CRIT! " + text
	
	_label.text = text
	
	# Set color based on type
	_label.modulate = _get_color()
	
	# Scale for crits
	if is_critical:
		_label.font_size = int(font_size * 1.5)
	else:
		_label.font_size = font_size
	
	# Outline for visibility
	_label.outline_modulate = Color.BLACK
	_label.outline_size = 4


func _get_color() -> Color:
	if is_heal:
		return Color.GREEN
	
	if is_critical:
		return Color.YELLOW
	
	# Element-based colors
	match damage_element:
		Enums.Element.FIRE:
			return Color.ORANGE_RED
		Enums.Element.WATER:  # Ice
			return Color.CYAN
		Enums.Element.AIR:  # Lightning
			return Color.YELLOW
		Enums.Element.EARTH:
			return Color.SADDLE_BROWN
		Enums.Element.LIGHT:
			return Color.WHITE
		Enums.Element.DARK:
			return Color.DARK_VIOLET
		_:
			return Color.WHITE

# =============================================================================
# STATIC FACTORY
# =============================================================================

static func spawn(
	parent: Node,
	spawn_position: Vector3,
	damage: float,
	critical: bool = false,
	heal: bool = false,
	element: Enums.Element = Enums.Element.NONE
) -> DamageNumber:
	var number = DamageNumber.new()
	number.damage_value = damage
	number.is_critical = critical
	number.is_heal = heal
	number.damage_element = element
	
	# Add to parent first, then set global position (requires to be in scene tree)
	parent.add_child(number)
	number.global_position = spawn_position
	return number
