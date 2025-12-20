## StatusEffect - Applies buff/debuff status effects to targets
class_name StatusEffectSpell
extends SpellEffect

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Status")
@export var status: Enums.StatusEffect = Enums.StatusEffect.NONE
@export var status_duration: float = 5.0
@export var status_strength: float = 1.0  ## Multiplier for effect strength

@export_group("Stat Modification")
@export var stat_to_modify: Enums.StatType = Enums.StatType.DAMAGE
@export var stat_modifier: float = 0.0
@export var is_percentage: bool = true

@export_group("Damage Over Time")
@export var dot_damage: float = 0.0
@export var dot_interval: float = 1.0
@export var dot_element: Enums.Element = Enums.Element.NONE

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	effect_type = Enums.SpellEffectType.BUFF
	effect_name = "Status Effect"

# =============================================================================
# EFFECT APPLICATION
# =============================================================================

func apply(caster: Node, target: Node, hit_point: Vector3, spell_data: SpellData) -> void:
	if not can_affect_target(caster, target):
		return
	
	# Apply status effect via StatusEffectComponent (if target has one)
	if target.has_node("StatusEffectComponent"):
		var status_comp = target.get_node("StatusEffectComponent")
		status_comp.apply_status(status, status_duration, status_strength, {
			"caster": caster,
			"stat_to_modify": stat_to_modify,
			"stat_modifier": stat_modifier,
			"is_percentage": is_percentage,
			"dot_damage": dot_damage,
			"dot_interval": dot_interval,
			"dot_element": dot_element
		})
	elif target.has_node("StatsComponent") and stat_modifier != 0.0:
		# Fallback: directly modify stats temporarily
		var stats: StatsComponent = target.get_node("StatsComponent")
		var modifier_id = "spell_" + str(spell_data.get_instance_id()) + "_" + str(Time.get_ticks_msec())
		stats.add_modifier(stat_to_modify, modifier_id, stat_modifier, is_percentage)
		
		# Schedule removal
		_schedule_modifier_removal(stats, stat_to_modify, modifier_id, status_duration)
	
	spawn_impact_effect(hit_point)


func _schedule_modifier_removal(stats: StatsComponent, stat_type: Enums.StatType, modifier_id: String, duration: float) -> void:
	# Create a timer to remove the modifier
	var timer = stats.get_tree().create_timer(duration)
	timer.timeout.connect(func(): stats.remove_modifier(stat_type, modifier_id))
