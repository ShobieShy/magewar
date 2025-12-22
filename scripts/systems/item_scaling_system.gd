## ItemScalingSystem - Manages item level scaling and progression
## Ensures items scale appropriately with player level and progression
class_name ItemScalingSystem
extends Node

# =============================================================================
# SCALING CONFIGURATION
# =============================================================================

## Base stats by item level (before rarity multipliers)
const BASE_STATS_BY_LEVEL: Dictionary = {
	1: {
		"health": 10,
		"magika": 5,
		"stamina": 8,
		"damage": 8,
		"defense": 3,
		"move_speed": 0.05
	},
	10: {
		"health": 15,
		"magika": 10,
		"stamina": 12,
		"damage": 12,
		"defense": 5,
		"move_speed": 0.08
	},
	20: {
		"health": 25,
		"magika": 15,
		"stamina": 18,
		"damage": 18,
		"defense": 8,
		"move_speed": 0.10
	},
	30: {
		"health": 35,
		"magika": 25,
		"stamina": 28,
		"damage": 25,
		"defense": 12,
		"move_speed": 0.12
	},
	40: {
		"health": 50,
		"magika": 35,
		"stamina": 40,
		"damage": 35,
		"defense": 16,
		"move_speed": 0.15
	},
	50: {
		"health": 70,
		"magika": 50,
		"stamina": 55,
		"damage": 50,
		"defense": 22,
		"move_speed": 0.20
	}
}

## Recommended item level ranges by content difficulty
const DIFFICULTY_LEVELS: Dictionary = {
	"starter": {"min": 1, "max": 5},       # Starting area
	"early": {"min": 5, "max": 15},        # Early game
	"mid": {"min": 15, "max": 30},         # Midgame
	"late": {"min": 30, "max": 40},        # Lategame
	"endgame": {"min": 40, "max": 50}      # Endgame content
}

## Overpowered item threshold (too good for level)
const OVERPOWER_THRESHOLD: float = 1.5

## Underpowered item threshold (too weak for level)
const UNDERPOWER_THRESHOLD: float = 0.7

# =============================================================================
# SCALING CALCULATIONS
# =============================================================================

## Get recommended item level for a player level
func get_recommended_item_level(player_level: int) -> int:
	"""Return the item level that best matches a player level."""
	# Items should be at same level as player for balanced progression
	return clampi(player_level, 1, Constants.MAX_LEVEL)


## Get base stat value for a level and stat type
func get_base_stat_for_level(
	player_level: int,
	stat_name: String
) -> float:
	"""Get the base stat value before rarity scaling."""
	
	var level = clampi(player_level, 1, Constants.MAX_LEVEL)
	
	# Check if we have exact level data
	if BASE_STATS_BY_LEVEL.has(level) and BASE_STATS_BY_LEVEL[level].has(stat_name):
		return float(BASE_STATS_BY_LEVEL[level][stat_name])
	
	# Interpolate between known levels
	var levels = BASE_STATS_BY_LEVEL.keys()
	levels.sort()
	
	var lower_level = 1
	var lower_stat = BASE_STATS_BY_LEVEL[1].get(stat_name, 0.0)
	var upper_level = 50
	var upper_stat = BASE_STATS_BY_LEVEL[50].get(stat_name, 0.0)
	
	for i in range(levels.size() - 1):
		if levels[i] <= level and levels[i + 1] >= level:
			lower_level = levels[i]
			lower_stat = float(BASE_STATS_BY_LEVEL[lower_level].get(stat_name, 0.0))
			upper_level = levels[i + 1]
			upper_stat = float(BASE_STATS_BY_LEVEL[upper_level].get(stat_name, 0.0))
			break
	
	# Linear interpolation
	var progress = float(level - lower_level) / float(upper_level - lower_level)
	return lower_stat + (upper_stat - lower_stat) * progress


## Calculate item effectiveness ratio
func get_item_effectiveness(
	item: ItemData,
	player_level: int
) -> float:
	"""
	Calculate how powerful an item is compared to what's expected at player level.
	Returns a ratio: 1.0 = perfectly scaled, <1.0 = weak, >1.0 = strong
	"""
	
	if not item is EquipmentData:
		return 1.0
	
	var equipment = item as EquipmentData
	var expected_value = get_expected_item_value(player_level)
	
	# Calculate actual item value based on stats
	var actual_value = 0.0
	actual_value += abs(equipment.health_bonus) * 1.0
	actual_value += abs(equipment.magika_bonus) * 1.5
	actual_value += abs(equipment.stamina_bonus) * 1.2
	actual_value += abs(equipment.damage_bonus) * 3.0
	actual_value += abs(equipment.defense_bonus) * 2.5
	actual_value += abs(equipment.move_speed_bonus) * 50.0  # Speed is valuable
	actual_value += abs(equipment.crit_chance_bonus) * 100.0  # Crit is valuable
	actual_value += abs(equipment.crit_damage_bonus) * 1.5
	
	if expected_value <= 0:
		return 1.0
	
	return actual_value / expected_value


## Get expected item value at a player level
func get_expected_item_value(player_level: int) -> float:
	"""Return the expected item 'power' value at a given player level."""
	
	var level = clampi(player_level, 1, Constants.MAX_LEVEL)
	
	# Expected value grows quadratically with level
	return float(level * level) * 2.0


## Check if an item is appropriate for a player level
func is_item_appropriate_for_level(
	item: ItemData,
	player_level: int,
	strict: bool = false
) -> bool:
	"""
	Check if item is appropriate for player level.
	Strict mode is more restrictive (only allows scaled items).
	"""
	
	var effectiveness = get_item_effectiveness(item, player_level)
	
	if strict:
		# Strict: must be close to perfectly scaled
		return effectiveness > 0.8 and effectiveness < 1.2
	else:
		# Normal: allow some variance
		return effectiveness > UNDERPOWER_THRESHOLD and effectiveness < OVERPOWER_THRESHOLD


# =============================================================================
# LEVEL-BASED ITEM GENERATION
# =============================================================================

## Generate a new item for a player level
func generate_item_for_level(
	equipment_slot: Enums.EquipmentSlot,
	rarity: Enums.Rarity,
	player_level: int = 1
) -> RandomizedItemData:
	"""
	Generate a completely new randomized item appropriate for a player level.
	"""
	
	# Create a base template
	var template = EquipmentData.new()
	template.item_id = "generated_" + Enums.EquipmentSlot.keys()[equipment_slot].to_lower()
	template.item_name = "Generated Item"
	template.slot = equipment_slot
	template.level_required = player_level
	
	# Generate stats for this level and slot
	var gen_system = ItemGenerationSystem.new()
	var stats = gen_system.generate_stat_range_for_slot(equipment_slot, rarity, player_level)
	
	# Apply stats to template
	for stat_type in stats.keys():
		match stat_type:
			Enums.StatType.HEALTH:
				template.health_bonus = stats[stat_type]
			Enums.StatType.MAGIKA:
				template.magika_bonus = stats[stat_type]
			Enums.StatType.STAMINA:
				template.stamina_bonus = stats[stat_type]
			Enums.StatType.HEALTH_REGEN:
				template.health_regen_bonus = stats[stat_type]
			Enums.StatType.MAGIKA_REGEN:
				template.magika_regen_bonus = stats[stat_type]
			Enums.StatType.STAMINA_REGEN:
				template.stamina_regen_bonus = stats[stat_type]
			Enums.StatType.MOVE_SPEED:
				template.move_speed_bonus = stats[stat_type]
			Enums.StatType.DAMAGE:
				template.damage_bonus = stats[stat_type]
			Enums.StatType.DEFENSE:
				template.defense_bonus = stats[stat_type]
			Enums.StatType.CRITICAL_CHANCE:
				template.crit_chance_bonus = stats[stat_type]
			Enums.StatType.CRITICAL_DAMAGE:
				template.crit_damage_bonus = stats[stat_type]
	
	# Create randomized version
	return RandomizedItemData.create_from_base(template, rarity, player_level, true)


## Upgrade an item to a higher level
func upgrade_item_to_level(
	item: EquipmentData,
	new_level: int
) -> RandomizedItemData:
	"""
	Upgrade an existing item to scale to a new player level.
	Useful for crafting/enchanting systems.
	"""
	
	var gen_system = ItemGenerationSystem.new()
	var stats = gen_system.generate_equipment_stats(item, item.rarity, new_level)
	
	# Create new randomized version
	var upgraded = RandomizedItemData.create_from_base(
		item,
		item.rarity,
		new_level,
		false  # Don't regenerate affixes
	)
	
	return upgraded


# =============================================================================
# DIFFICULTY HELPERS
# =============================================================================

## Get difficulty name for a player level
func get_difficulty_for_level(player_level: int) -> String:
	"""Return the difficulty tier name for a player level."""
	
	for difficulty in DIFFICULTY_LEVELS.keys():
		var range = DIFFICULTY_LEVELS[difficulty]
		if player_level >= range["min"] and player_level <= range["max"]:
			return difficulty
	
	return "endgame"


## Get recommended loot levels for difficulty
func get_loot_levels_for_difficulty(difficulty: String) -> Dictionary:
	"""Return min/max item levels for a difficulty."""
	return DIFFICULTY_LEVELS.get(difficulty, DIFFICULTY_LEVELS["starter"])


# =============================================================================
# DEBUG/ANALYSIS
# =============================================================================

## Print item scaling analysis
func analyze_item_scaling(item: ItemData, player_level: int) -> void:
	"""Debug: Print detailed scaling analysis for an item."""
	
	print("\n=== ITEM SCALING ANALYSIS ===")
	print("Item: %s" % item.item_name)
	print("Player Level: %d" % player_level)
	print("Item Level Required: %d" % item.level_required)
	
	var effectiveness = get_item_effectiveness(item, player_level)
	print("Effectiveness: %.2f (%.1f%%)" % [effectiveness, effectiveness * 100])
	
	if effectiveness < UNDERPOWER_THRESHOLD:
		print("Status: UNDERPOWERED")
	elif effectiveness > OVERPOWER_THRESHOLD:
		print("Status: OVERPOWERED")
	else:
		print("Status: BALANCED")
	
	var appropriate = is_item_appropriate_for_level(item, player_level)
	print("Appropriate: %s" % ["YES" if appropriate else "NO"])
	print("=============================\n")


## Print all base stats by level
func print_base_stats_table() -> void:
	"""Debug: Print base stats progression table."""
	
	print("\n=== BASE STATS BY LEVEL ===")
	print("Level | Health | Magika | Stamina | Damage | Defense | Speed")
	print("------|--------|--------|---------|--------|---------|-------")
	
	for level in [1, 10, 20, 30, 40, 50]:
		var stats = BASE_STATS_BY_LEVEL[level]
		print("%5d | %6d | %6d | %7d | %6d | %7d | %.2f" % [
			level,
			stats["health"],
			stats["magika"],
			stats["stamina"],
			stats["damage"],
			stats["defense"],
			stats["move_speed"]
		])
	
	print("=============================\n")
