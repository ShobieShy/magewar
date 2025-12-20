## RefinementSystem - Manages weapon refinement tiers (+0 to +10)
## Handles success/failure mechanics with cost scaling and downgrade risk
class_name RefinementSystem
extends RefCounted

# =============================================================================
# SIGNALS
# =============================================================================

signal refinement_changed(new_tier: int)
signal refinement_succeeded(new_tier: int)
signal refinement_failed(current_tier: int, downgraded: bool)

# =============================================================================
# PROPERTIES
# =============================================================================

var refinement_level: int = 0  ## 0-10
var refinement_exp: float = 0.0  ## Progress within tier (not used in base implementation)

# Success rates per tier (decreases exponentially)
var success_rates: Dictionary = {
	0: 1.0,    # 100%
	1: 0.95,   # 95%
	2: 0.90,   # 90%
	3: 0.85,   # 85%
	4: 0.80,   # 80%
	5: 0.75,   # 75%
	6: 0.70,   # 70%
	7: 0.65,   # 65%
	8: 0.60,   # 60%
	9: 0.55,   # 55%
	10: 0.50   # 50%
}

# Downgrade risk per tier (0 = no downgrade risk)
var downgrade_risk: Dictionary = {
	0: 0.0,    # No risk at +0-+4
	1: 0.0,
	2: 0.0,
	3: 0.0,
	4: 0.0,
	5: 0.10,   # 10% downgrade at +5
	6: 0.20,   # 20% downgrade at +6
	7: 0.30,   # 30% downgrade at +7
	8: 0.40,   # 40% downgrade at +8
	9: 0.50,   # 50% downgrade at +9
	10: 0.60   # 60% downgrade at +10
}

# Material costs per tier (gold + materials)
var refinement_costs: Dictionary = {
	0: {"gold": 0, "ore_fragment": 0},
	1: {"gold": 50, "ore_fragment": 2},
	2: {"gold": 100, "ore_fragment": 4},
	3: {"gold": 200, "ore_piece": 1},
	4: {"gold": 350, "ore_piece": 2},
	5: {"gold": 500, "ore_piece": 3},
	6: {"gold": 750, "ore_chunk": 1},
	7: {"gold": 1000, "ore_chunk": 2},
	8: {"gold": 1500, "ore_chunk": 3},
	9: {"gold": 2000, "ore_crystal": 4},
	10: {"gold": 3000, "ore_crystal": 5}
}

# Stat bonus per refinement level (+3% per tier)
const STAT_BONUS_PER_TIER: float = 0.03

# =============================================================================
# REFINEMENT OPERATIONS
# =============================================================================

## Attempt to refine weapon at current level
## Returns: true if successful, false otherwise
func attempt_refinement() -> bool:
	if refinement_level >= 10:
		return false  # Already maxed
	
	var next_tier = refinement_level + 1
	var success_chance = get_success_chance(refinement_level)
	var roll = randf()
	
	if roll < success_chance:
		# Success!
		refinement_level = next_tier
		refinement_exp = 0.0
		refinement_succeeded.emit(next_tier)
		refinement_changed.emit(next_tier)
		return true
	else:
		# Failure - check for downgrade
		var downgrade_chance = downgrade_risk[refinement_level]
		if downgrade_chance > 0.0 and randf() < downgrade_chance:
			# Downgrade!
			if refinement_level > 0:
				refinement_level -= 1
				refinement_changed.emit(refinement_level)
			refinement_failed.emit(refinement_level + 1, true)
		else:
			refinement_failed.emit(refinement_level, false)
		
		return false

## Force downgrade weapon (used for save state corrections)
func force_downgrade(levels: int = 1) -> void:
	refinement_level = max(0, refinement_level - levels)
	refinement_changed.emit(refinement_level)

## Reset refinement to +0
func reset_refinement() -> void:
	refinement_level = 0
	refinement_exp = 0.0
	refinement_changed.emit(0)

# =============================================================================
# COST CALCULATIONS
# =============================================================================

## Get cost to refine from current level to next
func get_next_refinement_cost() -> Dictionary:
	if refinement_level >= 10:
		return {}
	
	var next_tier = refinement_level + 1
	return refinement_costs[next_tier].duplicate()

## Get gold cost for next refinement
func get_next_refinement_gold_cost() -> int:
	if refinement_level >= 10:
		return 0
	
	var next_tier = refinement_level + 1
	return refinement_costs[next_tier].get("gold", 0)

## Get material cost for next refinement
func get_next_refinement_material_cost() -> Dictionary:
	var cost = get_next_refinement_cost()
	cost.erase("gold")
	return cost

## Calculate recovery insurance cost (prevents material loss on failure)
## Formula: sum of all materials × 50 gold per unit
func calculate_recovery_cost(cost_dict: Dictionary) -> int:
	var material_count = 0
	for key in cost_dict:
		if key != "gold":
			material_count += cost_dict[key]
	
	return material_count * 50

# =============================================================================
# SUCCESS RATE QUERIES
# =============================================================================

## Get success chance for attempting refinement at given tier
func get_success_chance(current_tier: int = -1) -> float:
	if current_tier == -1:
		current_tier = refinement_level
	
	if current_tier >= 10:
		return 0.0
	
	var next_tier = current_tier + 1
	var base_chance = success_rates[next_tier]
	
	# Can be modified by player skills/items in future
	return clamp(base_chance, 0.0, 1.0)

## Get downgrade risk for current tier
func get_downgrade_risk() -> float:
	return downgrade_risk[refinement_level]

## Get if refinement is at max
func is_max_refinement() -> bool:
	return refinement_level >= 10

## Get if can refine further
func can_refine() -> bool:
	return refinement_level < 10

# =============================================================================
# STAT CALCULATIONS
# =============================================================================

## Get damage multiplier from refinement
## Each tier adds 3% bonus (1.0 + 0.03*level)
func get_damage_multiplier() -> float:
	return 1.0 + (refinement_level * STAT_BONUS_PER_TIER)

## Get all stat multipliers as dictionary
func get_stat_multipliers() -> Dictionary:
	return {
		"damage": get_damage_multiplier(),
		# Future: add other stat multipliers (fire_rate, accuracy, etc.)
	}

# =============================================================================
# UTILITY
# =============================================================================

## Get display string (e.g., "+5")
func get_display_string() -> String:
	return "+%d" % refinement_level

## Get tier enum value (0-10 matching Enums.RefinementTier)
func get_refinement_tier() -> int:
	return refinement_level

## Debug info
func debug_print() -> void:
	print("\n=== Refinement System ===")
	print("Refinement Level: +%d/+10" % refinement_level)
	print("Success Chance: %.0f%%" % [get_success_chance() * 100])
	print("Downgrade Risk: %.0f%%" % [get_downgrade_risk() * 100])
	print("Damage Multiplier: %.2f" % get_damage_multiplier())
	print("Next Tier Cost: %s" % get_next_refinement_cost())
	print("========================\n")
