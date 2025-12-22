## ItemGenerationSystem - Procedural item stat generation
## Handles randomizing item stats based on rarity, level, and item type
class_name ItemGenerationSystem
extends Node

# =============================================================================
# STAT VARIANCE RANGES
# =============================================================================

## Variance percentage per rarity (how much stats can deviate from base)
const STAT_VARIANCE_BY_RARITY: Dictionary = {
	Enums.Rarity.BASIC: 0.10,        # ±10% variance
	Enums.Rarity.UNCOMMON: 0.15,     # ±15% variance
	Enums.Rarity.RARE: 0.20,         # ±20% variance
	Enums.Rarity.MYTHIC: 0.25,       # ±25% variance
	Enums.Rarity.PRIMORDIAL: 0.30,   # ±30% variance
	Enums.Rarity.UNIQUE: 0.35        # ±35% variance (rare, special items)
}

## Per-stat variance modifiers (some stats vary more than others)
const STAT_VARIANCE_MULTIPLIERS: Dictionary = {
	Enums.StatType.HEALTH: 1.0,
	Enums.StatType.MAGIKA: 1.0,
	Enums.StatType.STAMINA: 1.0,
	Enums.StatType.HEALTH_REGEN: 1.2,        # Slightly higher variance
	Enums.StatType.MAGIKA_REGEN: 1.2,
	Enums.StatType.STAMINA_REGEN: 1.2,
	Enums.StatType.MOVE_SPEED: 0.8,          # Lower variance (important for balance)
	Enums.StatType.CAST_SPEED: 0.8,
	Enums.StatType.DAMAGE: 1.1,
	Enums.StatType.DEFENSE: 1.1,
	Enums.StatType.CRITICAL_CHANCE: 0.6,     # Very low variance
	Enums.StatType.CRITICAL_DAMAGE: 0.9
}

## Minimum stat value (prevent items with 0 stats)
const MINIMUM_STAT_THRESHOLD: float = 0.5

# =============================================================================
# LEVEL SCALING
# =============================================================================

## Level scaling multiplier (stats increase with player level)
## Formula: base_stat * (1.0 + level_scaling * (player_level / 50))
const LEVEL_SCALING_FACTOR: float = 0.15  # 15% increase per level (at level 50)

## Equipment stat values are scaled based on item level/player level
const ITEM_LEVEL_MULTIPLIER: Dictionary = {
	1: 0.7,
	10: 0.85,
	20: 1.0,
	30: 1.2,
	40: 1.4,
	50: 1.7
}

# =============================================================================
# STAT GENERATION
# =============================================================================

## Generate randomized stats for equipment
func generate_equipment_stats(
	base_item: EquipmentData,
	rarity: Enums.Rarity,
	player_level: int = 1
) -> Dictionary:
	"""
	Generate randomized stats for equipment based on rarity and level.
	Returns a dictionary with all stat bonuses.
	"""
	
	var stats = {}
	
	# Get base stats from the item
	var base_stats = base_item.get_stat_bonuses()
	
	# Calculate level multiplier
	var level_mult = _get_level_multiplier(player_level)
	
	# Get variance percentage for this rarity
	var variance = STAT_VARIANCE_BY_RARITY.get(rarity, 0.0)
	
	# Generate each stat
	for stat_type in base_stats.keys():
		var base_value = base_stats[stat_type]
		
		if base_value == 0.0:
			stats[stat_type] = 0.0
			continue
		
		# Apply level scaling
		var scaled_value = base_value * level_mult
		
		# Generate variance
		var variance_mult = STAT_VARIANCE_MULTIPLIERS.get(stat_type, 1.0)
		var actual_variance = variance * variance_mult
		
		# Apply random variance
		var randomized_value = _apply_variance(scaled_value, actual_variance)
		
		# Ensure minimum threshold
		if abs(randomized_value) < MINIMUM_STAT_THRESHOLD and base_value > 0:
			randomized_value = MINIMUM_STAT_THRESHOLD
		
		stats[stat_type] = randomized_value
	
	return stats


## Generate randomized gem modifiers
func generate_gem_modifiers(
	base_gem: GemData,
	rarity: Enums.Rarity,
	player_level: int = 1
) -> Dictionary:
	"""
	Generate randomized modifiers for a gem.
	Returns a dictionary with multiplier adjustments.
	"""
	
	var modifiers = {}
	var _level_mult = _get_level_multiplier(player_level)
	var variance = STAT_VARIANCE_BY_RARITY.get(rarity, 0.0)
	
	# Damage multiplier
	if base_gem.damage_multiplier != 1.0:
		var base = base_gem.damage_multiplier
		var variance_mult = 0.8  # Lower variance for multipliers
		modifiers["damage_multiplier"] = maxf(
			1.0 + _apply_variance(base - 1.0, variance * variance_mult),
			0.5  # Min 0.5x
		)
	else:
		modifiers["damage_multiplier"] = 1.0
	
	# Cost multiplier
	if base_gem.cost_multiplier != 1.0:
		modifiers["cost_multiplier"] = maxf(
			1.0 + _apply_variance(base_gem.cost_multiplier - 1.0, variance * 0.7),
			0.5
		)
	else:
		modifiers["cost_multiplier"] = 1.0
	
	# Cooldown multiplier
	if base_gem.cooldown_multiplier != 1.0:
		modifiers["cooldown_multiplier"] = maxf(
			1.0 + _apply_variance(base_gem.cooldown_multiplier - 1.0, variance * 0.7),
			0.5
		)
	else:
		modifiers["cooldown_multiplier"] = 1.0
	
	# Other multipliers with lower variance
	modifiers["range_multiplier"] = maxf(
		1.0 + _apply_variance((base_gem.range_multiplier - 1.0), variance * 0.5),
		0.8
	) if base_gem.range_multiplier != 1.0 else 1.0
	
	modifiers["aoe_multiplier"] = maxf(
		1.0 + _apply_variance((base_gem.aoe_multiplier - 1.0), variance * 0.5),
		0.8
	) if base_gem.aoe_multiplier != 1.0 else 1.0
	
	modifiers["projectile_speed_multiplier"] = maxf(
		1.0 + _apply_variance((base_gem.projectile_speed_multiplier - 1.0), variance * 0.4),
		0.7
	) if base_gem.projectile_speed_multiplier != 1.0 else 1.0
	
	return modifiers


## Generate stat range for an equipment slot at a given level
func generate_stat_range_for_slot(
	equipment_slot: Enums.EquipmentSlot,
	rarity: Enums.Rarity,
	player_level: int = 1
) -> Dictionary:
	"""
	Generate appropriate stat ranges for a specific equipment slot.
	Useful for generating completely new items.
	"""
	
	var stats = {}
	var level_mult = _get_level_multiplier(player_level)
	var variance = STAT_VARIANCE_BY_RARITY.get(rarity, 0.0)
	
	# Base stat values vary by slot
	var base_stats = _get_base_stats_for_slot(equipment_slot)
	
	for stat_type in base_stats.keys():
		var base = base_stats[stat_type]
		var variance_mult = STAT_VARIANCE_MULTIPLIERS.get(stat_type, 1.0)
		
		var scaled = base * level_mult
		var actual_variance = variance * variance_mult
		
		stats[stat_type] = _apply_variance(scaled, actual_variance)
	
	return stats


# =============================================================================
# PRIVATE METHODS
# =============================================================================

## Apply variance to a stat value
func _apply_variance(base_value: float, variance_percent: float) -> float:
	"""Apply random variance to a stat value."""
	if variance_percent <= 0.0:
		return base_value
	
	# Random multiplier between (1 - variance) and (1 + variance)
	var variance_mult = randf_range(1.0 - variance_percent, 1.0 + variance_percent)
	return base_value * variance_mult


## Get level multiplier for stat scaling
func _get_level_multiplier(player_level: int) -> float:
	"""
	Calculate stat scaling multiplier based on player level.
	Higher levels = higher stat bonuses.
	"""
	if player_level <= 1:
		return 1.0
	
	# Check if we have exact level data
	if ITEM_LEVEL_MULTIPLIER.has(player_level):
		return ITEM_LEVEL_MULTIPLIER[player_level]
	
	# Interpolate between known values
	var levels = ITEM_LEVEL_MULTIPLIER.keys()
	levels.sort()
	
	var lower_level = 1
	var lower_mult = 1.0
	var upper_level = 50
	var upper_mult = 1.7
	
	for i in range(levels.size() - 1):
		if levels[i] <= player_level and levels[i + 1] >= player_level:
			lower_level = levels[i]
			lower_mult = ITEM_LEVEL_MULTIPLIER[lower_level]
			upper_level = levels[i + 1]
			upper_mult = ITEM_LEVEL_MULTIPLIER[upper_level]
			break
	
	# Linear interpolation
	var progress = float(player_level - lower_level) / float(upper_level - lower_level)
	return lower_mult + (upper_mult - lower_mult) * progress


## Get base stats for an equipment slot
func _get_base_stats_for_slot(slot: Enums.EquipmentSlot) -> Dictionary:
	"""Return base stat values for a specific equipment slot."""
	
	match slot:
		Enums.EquipmentSlot.HEAD:
			return {
				Enums.StatType.HEALTH: 15.0,
				Enums.StatType.MAGIKA: 10.0,
				Enums.StatType.DEFENSE: 5.0
			}
		
		Enums.EquipmentSlot.BODY:
			return {
				Enums.StatType.HEALTH: 30.0,
				Enums.StatType.DEFENSE: 15.0,
				Enums.StatType.HEALTH_REGEN: 1.0
			}
		
		Enums.EquipmentSlot.BELT:
			return {
				Enums.StatType.HEALTH: 20.0,
				Enums.StatType.STAMINA: 20.0,
				Enums.StatType.DEFENSE: 8.0
			}
		
		Enums.EquipmentSlot.FEET:
			return {
				Enums.StatType.HEALTH: 10.0,
				Enums.StatType.MOVE_SPEED: 0.15,
				Enums.StatType.STAMINA: 15.0
			}
		
		Enums.EquipmentSlot.PRIMARY_WEAPON:
			return {
				Enums.StatType.DAMAGE: 25.0,
				Enums.StatType.CAST_SPEED: 0.1
			}
		
		Enums.EquipmentSlot.SECONDARY_WEAPON:
			return {
				Enums.StatType.DAMAGE: 15.0,
				Enums.StatType.CRITICAL_CHANCE: 0.05
			}
		
		Enums.EquipmentSlot.GRIMOIRE:
			return {
				Enums.StatType.MAGIKA: 25.0,
				Enums.StatType.MAGIKA_REGEN: 2.0,
				Enums.StatType.DAMAGE: 10.0
			}
		
		_:
			return {}


# =============================================================================
# UTILITY METHODS
# =============================================================================

## Get variance percentage for a rarity
func get_variance_for_rarity(rarity: Enums.Rarity) -> float:
	return STAT_VARIANCE_BY_RARITY.get(rarity, 0.0)


## Get level multiplier display string
func get_level_multiplier_string(player_level: int) -> String:
	var mult = _get_level_multiplier(player_level)
	return "%.2fx" % mult
