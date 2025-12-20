## SkillData - Definition of a single skill in the skill tree
## Supports passive buffs, active abilities, and spell augments
class_name SkillData
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Skill Info")
@export var skill_id: String = ""
@export var skill_name: String = "Unknown Skill"
@export var description: String = ""
@export var icon: Texture2D
@export var skill_type: Enums.SkillType = Enums.SkillType.PASSIVE
@export var category: Enums.SkillCategory = Enums.SkillCategory.OFFENSE

@export_group("Requirements")
@export var required_level: int = 1
@export var prerequisite_skills: Array[String] = []  ## Must have these unlocked first
@export var skill_points_cost: int = 1  ## Usually 1

@export_group("Passive Stats (if PASSIVE)")
@export var stat_modifiers: Dictionary = {}  ## StatType -> float value
@export var is_percentage: bool = false  ## If true, values are percentages

@export_group("Active Ability (if ACTIVE)")
@export var ability_effect: SpellEffect  ## Effect to apply when activated
@export var cooldown: float = 30.0
@export var magika_cost: float = 0.0
@export var stamina_cost: float = 0.0
@export var duration: float = 0.0  ## 0 = instant
@export var activation_animation: String = ""

@export_group("Spell Augment (if SPELL_AUGMENT)")
@export var augment_element: Enums.Element = Enums.Element.NONE  ## NONE = all spells
@export var augment_delivery: Enums.SpellDelivery = Enums.SpellDelivery.HITSCAN  ## Used if element is NONE
@export var augment_any_delivery: bool = true  ## If true, ignores augment_delivery
@export var damage_multiplier: float = 1.0
@export var cost_multiplier: float = 1.0
@export var cooldown_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var aoe_multiplier: float = 1.0
@export var projectile_count_bonus: int = 0
@export var pierce_bonus: int = 0
@export var chain_bonus: int = 0

@export_group("Visual")
@export var tree_position: Vector2 = Vector2.ZERO  ## Position in skill tree UI
@export var connects_to: Array[String] = []  ## Visual connections to other skills

# =============================================================================
# METHODS
# =============================================================================

func can_unlock(player_level: int, unlocked_skills: Array) -> bool:
	if player_level < required_level:
		return false
	
	for prereq in prerequisite_skills:
		if prereq not in unlocked_skills:
			return false
	
	return true


func get_stat_description() -> String:
	var lines: Array[String] = []
	
	match skill_type:
		Enums.SkillType.PASSIVE:
			for stat_type in stat_modifiers:
				var value = stat_modifiers[stat_type]
				var stat_name = Enums.StatType.keys()[stat_type].replace("_", " ").capitalize()
				if is_percentage:
					lines.append("%+.0f%% %s" % [value * 100, stat_name])
				else:
					lines.append("%+.1f %s" % [value, stat_name])
		
		Enums.SkillType.ACTIVE:
			if ability_effect:
				lines.append("Effect: %s" % ability_effect.effect_name)
			if duration > 0:
				lines.append("Duration: %.1fs" % duration)
			lines.append("Cooldown: %.1fs" % cooldown)
			if magika_cost > 0:
				lines.append("Magika Cost: %.0f" % magika_cost)
			if stamina_cost > 0:
				lines.append("Stamina Cost: %.0f" % stamina_cost)
		
		Enums.SkillType.SPELL_AUGMENT:
			var target = "All spells"
			if augment_element != Enums.Element.NONE:
				target = "%s spells" % Enums.Element.keys()[augment_element]
			elif not augment_any_delivery:
				target = "%s spells" % Enums.SpellDelivery.keys()[augment_delivery]
			lines.append("Affects: %s" % target)
			
			if damage_multiplier != 1.0:
				lines.append("%+.0f%% Damage" % [(damage_multiplier - 1.0) * 100])
			if cost_multiplier != 1.0:
				lines.append("%+.0f%% Cost" % [(cost_multiplier - 1.0) * 100])
			if cooldown_multiplier != 1.0:
				lines.append("%+.0f%% Cooldown" % [(cooldown_multiplier - 1.0) * 100])
			if range_multiplier != 1.0:
				lines.append("%+.0f%% Range" % [(range_multiplier - 1.0) * 100])
			if aoe_multiplier != 1.0:
				lines.append("%+.0f%% AoE Size" % [(aoe_multiplier - 1.0) * 100])
			if projectile_count_bonus > 0:
				lines.append("+%d Projectiles" % projectile_count_bonus)
			if pierce_bonus > 0:
				lines.append("+%d Pierce" % pierce_bonus)
			if chain_bonus > 0:
				lines.append("+%d Chain" % chain_bonus)
	
	return "\n".join(lines)


func get_tooltip() -> String:
	var tooltip = "[b]%s[/b]\n" % skill_name
	tooltip += "[color=gray]%s - %s[/color]\n" % [
		Enums.SkillType.keys()[skill_type],
		Enums.SkillCategory.keys()[category]
	]
	
	tooltip += "\n%s\n" % description
	
	var stats = get_stat_description()
	if stats:
		tooltip += "\n%s\n" % stats
	
	if required_level > 1:
		tooltip += "\n[color=yellow]Requires Level %d[/color]" % required_level
	
	if prerequisite_skills.size() > 0:
		tooltip += "\n[color=yellow]Requires: %s[/color]" % ", ".join(prerequisite_skills)
	
	return tooltip


func apply_passive_to_stats(stats_component: Node) -> void:
	## Apply passive stat modifiers
	if skill_type != Enums.SkillType.PASSIVE:
		return
	
	for stat_type in stat_modifiers:
		var value = stat_modifiers[stat_type]
		stats_component.add_modifier(stat_type, "skill_" + skill_id, value, is_percentage)


func remove_passive_from_stats(stats_component: Node) -> void:
	if skill_type != Enums.SkillType.PASSIVE:
		return
	
	for stat_type in stat_modifiers:
		stats_component.remove_modifier(stat_type, "skill_" + skill_id)


func apply_augment_to_spell(spell: SpellData) -> void:
	## Apply spell augment modifiers
	if skill_type != Enums.SkillType.SPELL_AUGMENT:
		return
	
	# Check if this augment applies to this spell
	if augment_element != Enums.Element.NONE:
		if spell.element != augment_element:
			return
	elif not augment_any_delivery:
		if spell.delivery_type != augment_delivery:
			return
	
	# Apply modifiers
	spell.damage_multiplier *= damage_multiplier
	spell.cost_multiplier *= cost_multiplier
	spell.cooldown_multiplier *= cooldown_multiplier
	spell.range_multiplier *= range_multiplier
	spell.aoe_multiplier *= aoe_multiplier
	spell.projectile_count += projectile_count_bonus
	spell.pierce_count += pierce_bonus
	spell.chain_count += chain_bonus


func matches_spell(spell: SpellData) -> bool:
	## Check if this augment would affect the given spell
	if skill_type != Enums.SkillType.SPELL_AUGMENT:
		return false
	
	if augment_element != Enums.Element.NONE:
		return spell.element == augment_element
	elif not augment_any_delivery:
		return spell.delivery_type == augment_delivery
	
	return true  # Affects all spells
