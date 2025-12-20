## SpellBeam - Continuous beam spell effect
## Damages targets while active
class_name SpellBeam
extends Node3D

# =============================================================================
# PROPERTIES
# =============================================================================

var caster: Node = null
var spell: SpellData = null
var spawn_point: Node3D = null
var direction: Vector3 = Vector3.FORWARD
var width: float = 0.1
var range: float = 50.0
var tick_rate: float = 0.1
var max_duration: float = 3.0
var effects: Array[SpellEffect] = []

var _elapsed_time: float = 0.0
var _tick_timer: float = 0.0
var _hit_targets: Array = []
var _area: Area3D = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_area = get_node_or_null("Area3D")
	if _area:
		_area.area_entered.connect(_on_area_entered)
		_area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_elapsed_time += delta
	_tick_timer += delta
	
	# Update beam direction
	if spawn_point:
		global_position = spawn_point.global_position
		look_at(spawn_point.global_position + direction * range, Vector3.UP)
	
	# Tick effects
	if _tick_timer >= tick_rate:
		_tick_timer = 0.0
		_apply_effects()
	
	# Check for end condition
	if _elapsed_time >= max_duration:
		queue_free()


# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(config: Dictionary) -> void:
	caster = config.get("caster")
	spell = config.get("spell")
	spawn_point = config.get("spawn_point")
	direction = config.get("direction", Vector3.FORWARD)
	width = config.get("width", 0.1)
	range = config.get("range", 50.0)
	tick_rate = config.get("tick_rate", 0.1)
	max_duration = config.get("max_duration", 3.0)
	effects = config.get("effects", [])

# =============================================================================
# DAMAGE
# =============================================================================

func _on_body_entered(body: Node3D) -> void:
	if body == caster:
		return
	if body in _hit_targets:
		return
	
	_hit_targets.append(body)


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("hitbox"):
		var owner = area.get_parent()
		if owner and owner != caster and owner not in _hit_targets:
			_hit_targets.append(owner)


func _apply_effects() -> void:
	if effects.is_empty():
		return
	
	# Apply to all current targets
	for target in _hit_targets:
		if target and is_instance_valid(target):
			var hit_point = target.global_position if target is Node3D else global_position
			for effect in effects:
				effect.apply(caster, target, hit_point, spell)
