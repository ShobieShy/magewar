## MovementEffect - Applies movement forces (knockback, pull, teleport)
class_name MovementEffect
extends SpellEffect

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

enum MovementType {
	KNOCKBACK,   ## Push away from point
	PULL,        ## Pull toward point
	TELEPORT,    ## Instant teleport
	LAUNCH,      ## Launch upward
	DASH         ## Dash in direction
}

@export_group("Movement")
@export var movement_type: MovementType = MovementType.KNOCKBACK
@export var force: float = 10.0
@export var vertical_force: float = 2.0

@export_group("Teleport")
@export var teleport_distance: float = 10.0
@export var teleport_to_cursor: bool = true

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	effect_type = Enums.SpellEffectType.KNOCKBACK
	effect_name = "Movement"

# =============================================================================
# EFFECT APPLICATION
# =============================================================================

func apply(caster: Node, target: Node, hit_point: Vector3, _spell_data: SpellData) -> void:
	if not can_affect_target(caster, target):
		return
	
	match movement_type:
		MovementType.KNOCKBACK:
			_apply_knockback(caster, target, hit_point)
		MovementType.PULL:
			_apply_pull(caster, target, hit_point)
		MovementType.TELEPORT:
			_apply_teleport(caster, target, hit_point)
		MovementType.LAUNCH:
			_apply_launch(target)
		MovementType.DASH:
			_apply_dash(caster, target)
	
	spawn_impact_effect(hit_point)


func _apply_knockback(caster: Node, target: Node, hit_point: Vector3) -> void:
	if target is CharacterBody3D:
		var direction: Vector3
		if hit_point != Vector3.ZERO:
			direction = (target.global_position - hit_point).normalized()
		else:
			direction = (target.global_position - caster.global_position).normalized()
		
		direction.y = vertical_force / force if force > 0 else 0.0
		direction = direction.normalized()
		target.velocity += direction * force


func _apply_pull(caster: Node, target: Node, hit_point: Vector3) -> void:
	if target is CharacterBody3D:
		var pull_point = hit_point if hit_point != Vector3.ZERO else caster.global_position
		var direction = (pull_point - target.global_position).normalized()
		target.velocity += direction * force


func _apply_teleport(_caster: Node, target: Node, hit_point: Vector3) -> void:
	if target is Node3D:
		if teleport_to_cursor and hit_point != Vector3.ZERO:
			# Teleport to aimed location
			target.global_position = hit_point + Vector3.UP * 0.5
		else:
			# Teleport forward
			var direction = -target.global_transform.basis.z
			target.global_position += direction * teleport_distance


func _apply_launch(target: Node) -> void:
	if target is CharacterBody3D:
		target.velocity.y = force


func _apply_dash(_caster: Node, target: Node) -> void:
	if target is CharacterBody3D:
		var direction = -target.global_transform.basis.z
		target.velocity += direction * force
