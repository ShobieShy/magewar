## HealEffect - Restores health to targets
class_name HealEffect
extends SpellEffect

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Healing")
@export var base_heal: float = 20.0
@export var heal_variance: float = 0.1

@export_group("Bonus")
@export var restore_magika: float = 0.0
@export var restore_stamina: float = 0.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	effect_type = Enums.SpellEffectType.HEAL
	effect_name = "Heal"
	target_type = Enums.TargetType.ALLY

# =============================================================================
# EFFECT APPLICATION
# =============================================================================

func apply(caster: Node, target: Node, hit_point: Vector3, _spell_data: SpellData = null) -> void:
	if not can_affect_target(caster, target):
		return
	
	if not target.has_node("StatsComponent"):
		return
	
	var stats: StatsComponent = target.get_node("StatsComponent")
	
	# Calculate heal amount
	var heal_amount = base_heal
	if heal_variance > 0.0:
		var variance_amount = heal_amount * heal_variance
		heal_amount += randf_range(-variance_amount, variance_amount)
	
	# Apply healing
	var actual_heal = stats.heal(heal_amount)
	
	# Spawn heal number
	_spawn_heal_number(target, hit_point, actual_heal)
	
	# Restore magika/stamina if specified
	if restore_magika > 0.0:
		stats.restore_magika(restore_magika)
	
	if restore_stamina > 0.0:
		stats.restore_stamina(restore_stamina)
	
	# Spawn effect
	spawn_impact_effect(hit_point)


func _spawn_heal_number(target: Node, hit_point: Vector3, heal_amount: float) -> void:
	var show_numbers = SaveManager.settings_data.get("gameplay", {}).get("show_damage_numbers", true)
	if not show_numbers or heal_amount <= 0:
		return
	
	var tree = target.get_tree()
	if tree == null:
		return
	
	var root = tree.current_scene
	if root == null:
		return
	
	var spawn_pos = hit_point + Vector3.UP * 0.5
	DamageNumber.spawn(root, spawn_pos, heal_amount, false, true, Enums.Element.WATER)
