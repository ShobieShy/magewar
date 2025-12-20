## ShieldEffect - Creates a damage absorption shield
class_name ShieldEffect
extends SpellEffect

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Shield")
@export var shield_amount: float = 50.0
@export var shield_duration: float = 10.0
@export var shield_decay_rate: float = 0.0  ## Shield lost per second

@export_group("Reflection")
@export var reflect_damage: bool = false
@export var reflect_percentage: float = 0.25

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	effect_type = Enums.SpellEffectType.SHIELD
	effect_name = "Shield"
	target_type = Enums.TargetType.ALLY

# =============================================================================
# EFFECT APPLICATION
# =============================================================================

func apply(caster: Node, target: Node, hit_point: Vector3, spell_data: SpellData) -> void:
	if not can_affect_target(caster, target):
		return
	
	# Apply shield via ShieldComponent or StatusEffectComponent
	if target.has_node("ShieldComponent"):
		var shield_comp = target.get_node("ShieldComponent")
		shield_comp.add_shield(shield_amount, shield_duration, {
			"decay_rate": shield_decay_rate,
			"reflect_damage": reflect_damage,
			"reflect_percentage": reflect_percentage,
			"caster": caster
		})
	elif target.has_node("StatusEffectComponent"):
		var status_comp = target.get_node("StatusEffectComponent")
		status_comp.apply_status(Enums.StatusEffect.SHIELDED, shield_duration, 1.0, {
			"shield_amount": shield_amount,
			"decay_rate": shield_decay_rate,
			"reflect_damage": reflect_damage,
			"reflect_percentage": reflect_percentage
		})
	
	spawn_impact_effect(hit_point if hit_point != Vector3.ZERO else target.global_position)
