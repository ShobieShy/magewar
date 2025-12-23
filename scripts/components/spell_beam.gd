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
var _enemies_in_beam: Array = []  # Track enemies currently in beam (continuous damage)
var _hit_targets: Array = []  # Legacy compatibility
var _area: Area3D = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_area = get_node_or_null("Area3D")
	if _area:
		_area.area_entered.connect(_on_area_entered)
		_area.body_entered.connect(_on_body_entered)
		_area.area_exited.connect(_on_area_exited)
		_area.body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_elapsed_time += delta
	_tick_timer += delta
	
	# Update beam direction
	if spawn_point:
		global_position = spawn_point.global_position
		var target = spawn_point.global_position + direction * range
		if spawn_point.global_position.distance_to(target) > 0.01:
			var up = Vector3.UP
			if abs(direction.normalized().dot(Vector3.UP)) > 0.99:
				up = Vector3.RIGHT
			look_at(target, up)
	
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
	if body in _enemies_in_beam:
		return
	
	# Check if this is an enemy
	if body.is_in_group("enemies"):
		_enemies_in_beam.append(body)
		print_debug("Beam entered enemy: %s" % body.name)


func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("hitbox"):
		var owner = area.get_parent()
		if owner and owner != caster and owner not in _enemies_in_beam:
			if owner.is_in_group("enemies"):
				_enemies_in_beam.append(owner)
				print_debug("Beam entered enemy (hitbox): %s" % owner.name)


func _on_body_exited(body: Node3D) -> void:
	if body in _enemies_in_beam:
		_enemies_in_beam.erase(body)
		print_debug("Beam exited enemy: %s" % body.name)


func _on_area_exited(area: Area3D) -> void:
	if area.is_in_group("hitbox"):
		var owner = area.get_parent()
		if owner in _enemies_in_beam:
			_enemies_in_beam.erase(owner)
			print_debug("Beam exited enemy (hitbox): %s" % owner.name)


func _apply_effects() -> void:
	if effects.is_empty():
		return
	
	# Apply continuous damage to all enemies currently in beam
	for enemy in _enemies_in_beam:
		if enemy and is_instance_valid(enemy):
			var hit_point = enemy.global_position if enemy is Node3D else global_position
			for effect in effects:
				if effect and effect.has_method("apply"):
					effect.apply(caster, enemy, hit_point, spell)
	
	# Debug logging
	if not _enemies_in_beam.is_empty():
		print_debug("Beam damage tick: %d enemies hit" % _enemies_in_beam.size())
