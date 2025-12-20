## EquipmentData - Wearable equipment (Hat, Clothes, Belt, Shoes)
class_name EquipmentData
extends ItemData

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Equipment")
@export var slot: Enums.EquipmentSlot = Enums.EquipmentSlot.NONE

@export_group("Stats")
@export var health_bonus: float = 0.0
@export var magika_bonus: float = 0.0
@export var stamina_bonus: float = 0.0
@export var health_regen_bonus: float = 0.0
@export var magika_regen_bonus: float = 0.0
@export var stamina_regen_bonus: float = 0.0
@export var move_speed_bonus: float = 0.0
@export var damage_bonus: float = 0.0
@export var defense_bonus: float = 0.0
@export var crit_chance_bonus: float = 0.0
@export var crit_damage_bonus: float = 0.0

@export_group("Special Effects")
@export var special_effects: Array[SpellEffect] = []
@export var passive_status: Enums.StatusEffect = Enums.StatusEffect.NONE

@export_group("Visual")
@export var mesh: Mesh
@export var material: Material

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	item_type = Enums.ItemType.EQUIPMENT

# =============================================================================
# METHODS
# =============================================================================

func get_stat_bonuses() -> Dictionary:
	return {
		Enums.StatType.HEALTH: health_bonus,
		Enums.StatType.MAGIKA: magika_bonus,
		Enums.StatType.STAMINA: stamina_bonus,
		Enums.StatType.HEALTH_REGEN: health_regen_bonus,
		Enums.StatType.MAGIKA_REGEN: magika_regen_bonus,
		Enums.StatType.STAMINA_REGEN: stamina_regen_bonus,
		Enums.StatType.MOVE_SPEED: move_speed_bonus,
		Enums.StatType.DAMAGE: damage_bonus,
		Enums.StatType.DEFENSE: defense_bonus,
		Enums.StatType.CRITICAL_CHANCE: crit_chance_bonus,
		Enums.StatType.CRITICAL_DAMAGE: crit_damage_bonus
	}


func apply_to_stats(stats: StatsComponent) -> void:
	var bonuses = get_stat_bonuses()
	var equip_id = "equip_" + item_id
	
	for stat_type in bonuses.keys():
		var bonus = bonuses[stat_type]
		if bonus != 0.0:
			stats.add_modifier(stat_type, equip_id + "_" + str(stat_type), bonus, false)


func remove_from_stats(stats: StatsComponent) -> void:
	var bonuses = get_stat_bonuses()
	var equip_id = "equip_" + item_id
	
	for stat_type in bonuses.keys():
		stats.remove_modifier(stat_type, equip_id + "_" + str(stat_type))


func get_stat_description() -> String:
	var stats: Array[String] = []
	
	if health_bonus != 0:
		stats.append("%+.0f Health" % health_bonus)
	if magika_bonus != 0:
		stats.append("%+.0f Magika" % magika_bonus)
	if stamina_bonus != 0:
		stats.append("%+.0f Stamina" % stamina_bonus)
	if health_regen_bonus != 0:
		stats.append("%+.1f Health Regen" % health_regen_bonus)
	if magika_regen_bonus != 0:
		stats.append("%+.1f Magika Regen" % magika_regen_bonus)
	if stamina_regen_bonus != 0:
		stats.append("%+.1f Stamina Regen" % stamina_regen_bonus)
	if move_speed_bonus != 0:
		stats.append("%+.0f%% Move Speed" % (move_speed_bonus * 100))
	if damage_bonus != 0:
		stats.append("%+.0f Damage" % damage_bonus)
	if defense_bonus != 0:
		stats.append("%+.0f Defense" % defense_bonus)
	if crit_chance_bonus != 0:
		stats.append("%+.1f%% Crit Chance" % (crit_chance_bonus * 100))
	if crit_damage_bonus != 0:
		stats.append("%+.0f%% Crit Damage" % (crit_damage_bonus * 100))
	
	return "\n".join(stats)


func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	
	var slot_name = Enums.EquipmentSlot.keys()[slot].replace("_", " ").capitalize()
	tooltip += "\n\n[u]%s[/u]\n" % slot_name
	
	var stat_desc = get_stat_description()
	if stat_desc:
		tooltip += stat_desc
	
	if special_effects.size() > 0:
		tooltip += "\n\nSpecial Effects:"
		for effect in special_effects:
			tooltip += "\n- " + effect.effect_name
	
	if passive_status != Enums.StatusEffect.NONE:
		tooltip += "\n\nPassive: " + Enums.StatusEffect.keys()[passive_status]
	
	return tooltip
