## WeaponLevelingSystem - Manages weapon level progression and experience
## Tracks XP from spell casts and enemy kills, applies stat bonuses based on level
class_name WeaponLevelingSystem
extends RefCounted

# =============================================================================
# SIGNALS
# =============================================================================

signal level_changed(new_level: int)
signal experience_gained(amount: float)
signal level_up(new_level: int)

# =============================================================================
# PROPERTIES
# =============================================================================

var weapon_level: int = 1
var weapon_experience: float = 0.0
var total_experience: float = 0.0

var max_player_level: int = 50  ## Dynamic cap based on player level
var _owner_player: Node = null  ## Reference to owning player

# XP thresholds per level (exponential scaling)
var experience_table: Array[float] = []

# Stat bonus multipliers per level
var stat_bonus_per_level: Dictionary = {
	"damage": 2.0,        ## +2 damage per level
	"fire_rate": 0.1,     ## +10% per level
	"accuracy": 0.05,     ## +5% per level
	"mana_efficiency": 0.02 ## +2% mana cost reduction per level
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _init(player: Node = null) -> void:
	_owner_player = player
	_generate_experience_table()

# =============================================================================
# EXPERIENCE MANAGEMENT
# =============================================================================

## Add experience to weapon (from spell cast or enemy kill)
func add_experience(amount: float) -> void:
	if amount <= 0:
		return
	
	weapon_experience += amount
	total_experience += amount
	experience_gained.emit(amount)
	
	# Check for level up
	while weapon_experience >= get_xp_for_next_level():
		_level_up()

## Get XP required to reach next level
func get_xp_for_next_level() -> float:
	if weapon_level >= max_player_level:
		return INF  # Max level reached
	
	if weapon_level - 1 < experience_table.size():
		return experience_table[weapon_level - 1]
	
	# Fallback calculation if table is incomplete
	return 1000.0 * pow(weapon_level, 1.5)

## Get progress to next level (0.0 to 1.0)
func get_level_progress() -> float:
	var xp_needed = get_xp_for_next_level()
	if xp_needed == INF:
		return 1.0
	
	var prev_level_xp = 0.0
	if weapon_level > 1 and weapon_level - 2 < experience_table.size():
		prev_level_xp = experience_table[weapon_level - 2]
	
	var current_level_progress = weapon_experience - prev_level_xp
	return clamp(current_level_progress / (xp_needed - prev_level_xp), 0.0, 1.0)

# =============================================================================
# LEVEL MANAGEMENT
# =============================================================================

## Internal level up logic
func _level_up() -> void:
	var xp_needed = get_xp_for_next_level()
	weapon_experience -= xp_needed
	
	if weapon_level < max_player_level:
		weapon_level += 1
		level_changed.emit(weapon_level)
		level_up.emit(weapon_level)

## Set weapon level (used when equiping different weapon)
func set_level(new_level: int) -> void:
	weapon_level = clamp(new_level, 1, max_player_level)
	weapon_experience = 0.0
	level_changed.emit(weapon_level)

## Update max player level (called when player levels up)
func update_max_player_level(new_player_level: int) -> void:
	max_player_level = new_player_level
	
	# If weapon can now level up beyond current level, allow it
	if weapon_level >= max_player_level:
		weapon_level = max_player_level

## Check if weapon can level up further
func can_level_up() -> bool:
	return weapon_level < max_player_level

# =============================================================================
# STAT CALCULATIONS
# =============================================================================

## Get damage bonus from weapon level
func get_damage_bonus() -> float:
	return (weapon_level - 1) * stat_bonus_per_level["damage"]

## Get fire rate bonus multiplier from weapon level
func get_fire_rate_bonus() -> float:
	return 1.0 + ((weapon_level - 1) * stat_bonus_per_level["fire_rate"])

## Get accuracy bonus multiplier from weapon level
func get_accuracy_bonus() -> float:
	return 1.0 + ((weapon_level - 1) * stat_bonus_per_level["accuracy"])

## Get mana efficiency bonus (reduces mana cost)
func get_mana_efficiency_bonus() -> float:
	return 1.0 - ((weapon_level - 1) * stat_bonus_per_level["mana_efficiency"])

## Get all stat bonuses as dictionary
func get_all_stat_bonuses() -> Dictionary:
	return {
		"damage": get_damage_bonus(),
		"fire_rate": get_fire_rate_bonus(),
		"accuracy": get_accuracy_bonus(),
		"mana_efficiency": get_mana_efficiency_bonus()
	}

# =============================================================================
# UTILITY
# =============================================================================

## Get formatted level display (e.g., "Level 5")
func get_display_string() -> String:
	return "Level %d" % weapon_level

## Get experience display for UI
func get_experience_display() -> String:
	var progress = int(get_level_progress() * 100)
	return "%d%%" % progress

## Generate experience table with exponential scaling
func _generate_experience_table() -> void:
	experience_table.clear()
	
	# Generate XP requirements for levels 1-50
	for level in range(1, 51):
		var xp_required = 1000.0 * pow(level, 1.5)
		experience_table.append(xp_required)

## Debug info
func debug_print() -> void:
	print("\n=== Weapon Leveling System ===")
	print("Level: %d (max: %d)" % [weapon_level, max_player_level])
	print("Experience: %.1f / %.1f" % [weapon_experience, get_xp_for_next_level()])
	print("Progress: %.1f%%" % [get_level_progress() * 100])
	print("Stat Bonuses:")
	var bonuses = get_all_stat_bonuses()
	for stat_name in bonuses:
		print("  %s: %.2f" % [stat_name, bonuses[stat_name]])
	print("===========================\n")
