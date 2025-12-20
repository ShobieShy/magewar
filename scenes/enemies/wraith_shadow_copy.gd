## Wraith Shadow Copy - Temporary illusion created by Ancient Wraith
class_name WraithShadowCopy
extends CharacterBody3D

# =============================================================================
# PROPERTIES
# =============================================================================

var target: Node = null
var lifetime: float = 10.0
var move_speed: float = 4.0
var damage: float = 10.0

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	add_to_group("enemies")
	
	# Make it look ethereal
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		if mesh.material_override:
			mesh.material_override.albedo_color.a = 0.3

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		_dissolve()
		return
	
	if target and is_instance_valid(target):
		# Move toward target
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		
		velocity = direction * move_speed
		
		# Apply gravity
		if not is_on_floor():
			velocity.y -= 10.0 * delta
		
		move_and_slide()
		
		# Face target
		if direction.length() > 0.1:
			look_at(global_position + direction, Vector3.UP)
		
		# Try to attack if close
		var distance = global_position.distance_to(target.global_position)
		if distance <= 2.0:
			_attack_target()

# =============================================================================
# METHODS
# =============================================================================

func setup(new_target: Node, duration: float) -> void:
	"""Initialize the shadow copy"""
	target = new_target
	lifetime = duration

func _attack_target() -> void:
	"""Deal damage to target"""
	if target.has_node("StatsComponent"):
		var target_stats: StatsComponent = target.get_node("StatsComponent")
		target_stats.take_damage(damage, Enums.DamageType.SHADOW)
		
		# Dissolve after attacking
		_dissolve()

func _dissolve() -> void:
	"""Fade out and remove"""
	var tween = create_tween()
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		tween.tween_property(mesh, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func take_damage(_amount: float, _damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL, _attacker: Node = null) -> void:
	"""Shadow copies dissolve when hit"""
	_dissolve()