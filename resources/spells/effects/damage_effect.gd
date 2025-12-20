## DamageEffect - Deals damage to targets
class_name DamageEffect
extends SpellEffect

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Damage")
@export var base_damage: float = 10.0
@export var damage_type: Enums.DamageType = Enums.DamageType.MAGICAL
@export var element: Enums.Element = Enums.Element.ARCANE

@export_group("Scaling")
@export var damage_variance: float = 0.1  ## +/- percentage variance
@export var crit_multiplier: float = Constants.CRITICAL_DAMAGE_MULTIPLIER

@export_group("Knockback")
@export var knockback_force: float = 0.0
@export var knockback_up: float = 0.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	effect_type = Enums.SpellEffectType.DAMAGE
	effect_name = "Damage"
	target_type = Enums.TargetType.ENEMY

# =============================================================================
# EFFECT APPLICATION
# =============================================================================

func apply(caster: Node, target: Node, hit_point: Vector3, spell_data: SpellData = null) -> void:
	if not can_affect_target(caster, target):
		return
	
	# Calculate damage and check for crit
	var is_crit = _roll_crit(caster)
	var final_damage = calculate_damage(caster, target, is_crit)
	
	# Apply damage
	if target.has_node("StatsComponent"):
		var stats: StatsComponent = target.get_node("StatsComponent")
		var actual_damage = stats.take_damage(final_damage, damage_type)
		
		# Spawn damage number
		_spawn_damage_number(target, hit_point, actual_damage, is_crit)
	
	# Apply knockback
	if knockback_force > 0.0 and target is CharacterBody3D:
		var direction = (target.global_position - caster.global_position).normalized()
		direction.y = knockback_up
		target.velocity += direction * knockback_force
	
	# Spawn impact effect
	spawn_impact_effect(hit_point)


func _roll_crit(caster: Node) -> bool:
	var crit_chance = Constants.CRITICAL_CHANCE_BASE
	if caster.has_node("StatsComponent"):
		crit_chance += caster.get_node("StatsComponent").get_stat(Enums.StatType.CRITICAL_CHANCE)
	return randf() < crit_chance


func calculate_damage(caster: Node, target: Node, is_crit: bool = false) -> float:
	var damage = base_damage
	
	# Apply variance
	if damage_variance > 0.0:
		var variance_amount = damage * damage_variance
		damage += randf_range(-variance_amount, variance_amount)
	
	# Apply crit multiplier
	if is_crit:
		damage *= crit_multiplier
	
	# Apply caster damage bonus
	if caster.has_node("StatsComponent"):
		var damage_bonus = caster.get_node("StatsComponent").get_stat(Enums.StatType.DAMAGE)
		damage += damage_bonus
	
	# Apply friendly fire reduction
	var friendly_fire = SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false)
	if target.get_script() and target.get_script().get_global_name() == "Player" and friendly_fire:
		damage *= Constants.FRIENDLY_FIRE_DAMAGE_MULTIPLIER
	
	return damage


func _spawn_damage_number(target: Node, hit_point: Vector3, damage: float, is_crit: bool) -> void:
	# Check if damage numbers are enabled
	var show_numbers = SaveManager.settings_data.get("gameplay", {}).get("show_damage_numbers", true)
	if not show_numbers:
		return
	
	# Get the scene tree root to spawn the damage number
	var tree = target.get_tree()
	if tree == null:
		return
	
	var root = tree.current_scene
	if root == null:
		return
	
	# Spawn damage number at hit point (slightly above)
	var spawn_pos = hit_point + Vector3.UP * 0.5
	DamageNumber.spawn(root, spawn_pos, damage, is_crit, false, element)
