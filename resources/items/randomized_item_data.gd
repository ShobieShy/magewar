## RandomizedItemData - Equipment with procedurally generated stats
## Wraps a base EquipmentData and adds randomized stat modifiers
class_name RandomizedItemData
extends EquipmentData

# =============================================================================
# PROPERTIES
# =============================================================================

## Reference to base item template
var base_item: EquipmentData

## Affixes applied to this item
var affixes: Array = []

## Original randomized stats (before affix application)
var randomized_stats: Dictionary = {}

## Item generation seed (for reproducibility if needed)
var generation_seed: int = 0

## Player level when item was generated
var generated_at_level: int = 1

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	item_type = Enums.ItemType.EQUIPMENT
	pass


## Create a randomized item from a base template
static func create_from_base(
	template: EquipmentData,
	item_rarity: Enums.Rarity,
	player_level: int = 1,
	generate_affixes: bool = true
) -> RandomizedItemData:
	"""
	Create a new randomized item from a base template.
	
	Args:
		template: Base equipment item to randomize
		item_rarity: Rarity tier for the item
		player_level: Player level for stat scaling
		generate_affixes: Whether to generate affixes
	
	Returns:
		A new RandomizedItemData with randomized stats and affixes
	"""
	
	var item = RandomizedItemData.new()
	item.base_item = template
	item.generated_at_level = player_level
	item.rarity = item_rarity
	
	# Copy base properties
	item.item_id = template.item_id + "_randomized_" + str(randi())
	item.item_name = template.item_name
	item.description = template.description
	item.icon = template.icon
	item.item_type = template.item_type
	item.stackable = template.stackable
	item.max_stack = template.max_stack
	item.base_value = template.base_value
	item.level_required = template.level_required
	item.slot = template.slot
	
	# Generate randomized stats
	var gen_system = ItemGenerationSystem.new()
	item.randomized_stats = gen_system.generate_equipment_stats(template, item_rarity, player_level)
	
	# Apply randomized stats to item
	for stat_type in item.randomized_stats.keys():
		match stat_type:
			Enums.StatType.HEALTH:
				item.health_bonus = item.randomized_stats[stat_type]
			Enums.StatType.MAGIKA:
				item.magika_bonus = item.randomized_stats[stat_type]
			Enums.StatType.STAMINA:
				item.stamina_bonus = item.randomized_stats[stat_type]
			Enums.StatType.HEALTH_REGEN:
				item.health_regen_bonus = item.randomized_stats[stat_type]
			Enums.StatType.MAGIKA_REGEN:
				item.magika_regen_bonus = item.randomized_stats[stat_type]
			Enums.StatType.STAMINA_REGEN:
				item.stamina_regen_bonus = item.randomized_stats[stat_type]
			Enums.StatType.MOVE_SPEED:
				item.move_speed_bonus = item.randomized_stats[stat_type]
			Enums.StatType.DAMAGE:
				item.damage_bonus = item.randomized_stats[stat_type]
			Enums.StatType.DEFENSE:
				item.defense_bonus = item.randomized_stats[stat_type]
			Enums.StatType.CRITICAL_CHANCE:
				item.crit_chance_bonus = item.randomized_stats[stat_type]
			Enums.StatType.CRITICAL_DAMAGE:
				item.crit_damage_bonus = item.randomized_stats[stat_type]
	
	# Generate and apply affixes
	if generate_affixes:
		var affix_system = AffixSystem.new()
		item.affixes = affix_system.generate_affixes(template, item_rarity, player_level)
		
		if not item.affixes.is_empty():
			affix_system.apply_affixes_to_item(item, item.affixes)
	
	return item


## Get a detailed tooltip for the randomized item
func get_detailed_tooltip() -> String:
	"""Return a comprehensive tooltip with stats and affixes."""
	
	var tooltip = super.get_tooltip()
	
	# Add randomization info
	tooltip += "\n[color=cyan]─── Randomized ───[/color]\n"
	tooltip += "Generated at Level %d\n" % generated_at_level
	
	# Add affix info
	if not affixes.is_empty():
		var affix_system = AffixSystem.new()
		tooltip += "\n" + affix_system.get_affix_description(affixes)
	
	return tooltip


## Check if this is a randomized item
func is_randomized() -> bool:
	return base_item != null


## Get stat variance information
func get_variance_info() -> Dictionary:
	"""Return information about stat variance."""
	
	var gen_system = ItemGenerationSystem.new()
	var variance = gen_system.get_variance_for_rarity(rarity)
	
	return {
		"variance_percent": variance * 100.0,
		"level_multiplier": gen_system.get_level_multiplier_string(generated_at_level),
		"affix_count": affixes.size()
	}


## Apply this randomized item's stats to a StatsComponent
func apply_to_stats(stats: StatsComponent) -> void:
	"""Override to ensure randomized stats are applied."""
	super.apply_to_stats(stats)


## Get item value (scales with rarity and affixes)
func get_value() -> int:
	"""Calculate gold value including affix bonuses."""
	
	var base_gold = super.get_value()
	
	# Add affix value
	var affix_bonus = 0
	for affix in affixes:
		if affix.has("stat_bonuses"):
			# Rough estimate: 50 gold per stat point added
			for stat_value in affix.stat_bonuses.values():
				affix_bonus += int(abs(stat_value) * 50)
	
	return base_gold + affix_bonus


# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	"""Get data for saving the randomized item."""
	
	var data = {
		"base_item_id": base_item.item_id if base_item else "",
		"rarity": rarity,
		"generated_at_level": generated_at_level,
		"randomized_stats": randomized_stats.duplicate(),
		"affixes": affixes.duplicate(true),
		"generation_seed": generation_seed
	}
	
	return data


func load_from_save_data(data: Dictionary, base_template: EquipmentData) -> void:
	"""Reconstruct a randomized item from save data."""
	
	base_item = base_template
	rarity = data.get("rarity", Enums.Rarity.BASIC)
	generated_at_level = data.get("generated_at_level", 1)
	randomized_stats = data.get("randomized_stats", {})
	affixes = data.get("affixes", [])
	generation_seed = data.get("generation_seed", 0)
	
	# Restore stats from randomized_stats
	for stat_type in randomized_stats.keys():
		match stat_type:
			Enums.StatType.HEALTH:
				health_bonus = randomized_stats[stat_type]
			Enums.StatType.MAGIKA:
				magika_bonus = randomized_stats[stat_type]
			Enums.StatType.STAMINA:
				stamina_bonus = randomized_stats[stat_type]
			Enums.StatType.HEALTH_REGEN:
				health_regen_bonus = randomized_stats[stat_type]
			Enums.StatType.MAGIKA_REGEN:
				magika_regen_bonus = randomized_stats[stat_type]
			Enums.StatType.STAMINA_REGEN:
				stamina_regen_bonus = randomized_stats[stat_type]
			Enums.StatType.MOVE_SPEED:
				move_speed_bonus = randomized_stats[stat_type]
			Enums.StatType.DAMAGE:
				damage_bonus = randomized_stats[stat_type]
			Enums.StatType.DEFENSE:
				defense_bonus = randomized_stats[stat_type]
			Enums.StatType.CRITICAL_CHANCE:
				crit_chance_bonus = randomized_stats[stat_type]
			Enums.StatType.CRITICAL_DAMAGE:
				crit_damage_bonus = randomized_stats[stat_type]
