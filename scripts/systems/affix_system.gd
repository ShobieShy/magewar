## AffixSystem - Manages item affixes (prefixes and suffixes)
## Affixes add special properties and stat bonuses to items
class_name AffixSystem
extends Node

# =============================================================================
# AFFIX DEFINITIONS
# =============================================================================

## Number of affixes per rarity tier
const AFFIXES_PER_RARITY: Dictionary = {
	Enums.Rarity.BASIC: 0,
	Enums.Rarity.UNCOMMON: 1,
	Enums.Rarity.RARE: 2,
	Enums.Rarity.MYTHIC: 3,
	Enums.Rarity.PRIMORDIAL: 4,
	Enums.Rarity.UNIQUE: 5  # Plus named bonus
}

## Affix pool by type
var _affix_pools: Dictionary = {}

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _init() -> void:
	_initialize_affixes()


# =============================================================================
# AFFIX GENERATION
# =============================================================================

## Generate affixes for an item
func generate_affixes(
	base_item: ItemData,
	rarity: Enums.Rarity,
	player_level: int = 1
) -> Array:
	"""
	Generate random affixes for an item based on rarity.
	Returns an array of affix dictionaries.
	"""
	
	var affix_count = AFFIXES_PER_RARITY.get(rarity, 0)
	var affixes: Array = []
	
	# Get appropriate affix pool for this item type
	var pool = _get_affix_pool_for_item(base_item)
	
	if pool.is_empty() or affix_count == 0:
		return affixes
	
	# Select random affixes without duplicates
	var selected = []
	var attempts = 0
	var max_attempts = affix_count * 3
	
	while selected.size() < affix_count and attempts < max_attempts:
		var affix = pool[randi() % pool.size()]
		
		# Avoid duplicate affix types
		if affix.get("id") not in selected:
			var affix_copy = affix.duplicate()
			
			# Scale affix values based on level
			_scale_affix_by_level(affix_copy, player_level)
			
			affixes.append(affix_copy)
			selected.append(affix.get("id"))
		
		attempts += 1
	
	return affixes


## Get all affixes for an item
func get_affixes_for_item(base_item: ItemData) -> Array:
	"""Return all available affixes for an item type."""
	return _get_affix_pool_for_item(base_item)


## Get affix by ID
func get_affix_by_id(affix_id: String) -> Dictionary:
	"""Look up an affix by its ID."""
	for pool in _affix_pools.values():
		for affix in pool:
			if affix.get("id") == affix_id:
				return affix.duplicate()
	
	return {}


# =============================================================================
# AFFIX APPLICATION
# =============================================================================

## Apply affixes to an item
func apply_affixes_to_item(item: ItemData, affixes: Array) -> void:
	"""
	Apply affix modifications to an item.
	This modifies the item's properties directly.
	"""
	
	if not item is EquipmentData:
		return
	
	var equipment: EquipmentData = item
	
	for affix in affixes:
		# Apply stat bonuses
		if affix.has("stat_bonuses"):
			for stat_type in affix.stat_bonuses.keys():
				match stat_type:
					"health":
						equipment.health_bonus += affix.stat_bonuses[stat_type]
					"magika":
						equipment.magika_bonus += affix.stat_bonuses[stat_type]
					"stamina":
						equipment.stamina_bonus += affix.stat_bonuses[stat_type]
					"defense":
						equipment.defense_bonus += affix.stat_bonuses[stat_type]
					"damage":
						equipment.damage_bonus += affix.stat_bonuses[stat_type]
					"move_speed":
						equipment.move_speed_bonus += affix.stat_bonuses[stat_type]
					"crit_chance":
						equipment.crit_chance_bonus += affix.stat_bonuses[stat_type]
					"crit_damage":
						equipment.crit_damage_bonus += affix.stat_bonuses[stat_type]
		
		# Apply name prefix/suffix
		if affix.has("prefix"):
			item.item_name = affix.prefix + " " + item.item_name
		elif affix.has("suffix"):
			item.item_name = item.item_name + " " + affix.suffix
		
		# Apply special effects
		if affix.has("special_effects"):
			for effect in affix.special_effects:
				if effect not in equipment.special_effects:
					equipment.special_effects.append(effect)


## Get formatted affix list for tooltip
func get_affix_description(affixes: Array) -> String:
	"""Generate a tooltip string describing the affixes."""
	
	if affixes.is_empty():
		return ""
	
	var text = "[color=gold]Affixes:[/color]\n"
	
	for affix in affixes:
		var affix_name = affix.get("prefix", "") + affix.get("suffix", "")
		text += "• " + affix_name.capitalize() + "\n"
		
		# Add stat bonuses
		if affix.has("stat_bonuses"):
			for stat_name in affix.stat_bonuses.keys():
				var value = affix.stat_bonuses[stat_name]
				if value > 0:
					text += "  +" + str(int(value)) + " " + stat_name.capitalize() + "\n"
	
	return text


# =============================================================================
# PRIVATE METHODS
# =============================================================================

## Initialize all affix pools
func _initialize_affixes() -> void:
	"""Set up all available affixes for different item types."""
	
	# Equipment affixes
	_affix_pools[Enums.ItemType.EQUIPMENT] = [
		# Strength affixes
		{
			"id": "strong",
			"prefix": "Strong",
			"stat_bonuses": {"damage": 5.0},
			"weight": 1.0
		},
		{
			"id": "mighty",
			"prefix": "Mighty",
			"stat_bonuses": {"damage": 10.0},
			"weight": 0.7
		},
		{
			"id": "heroic",
			"prefix": "Heroic",
			"stat_bonuses": {"damage": 15.0},
			"weight": 0.3
		},
		
		# Protective affixes
		{
			"id": "fortified",
			"suffix": "of Fortification",
			"stat_bonuses": {"defense": 8.0},
			"weight": 1.0
		},
		{
			"id": "armored",
			"suffix": "of Armor",
			"stat_bonuses": {"defense": 12.0, "health": 10.0},
			"weight": 0.7
		},
		{
			"id": "shielding",
			"suffix": "of Shielding",
			"stat_bonuses": {"defense": 15.0},
			"weight": 0.3
		},
		
		# Vitality affixes
		{
			"id": "healthy",
			"suffix": "of Vitality",
			"stat_bonuses": {"health": 15.0},
			"weight": 1.0
		},
		{
			"id": "vigorous",
			"prefix": "Vigorous",
			"stat_bonuses": {"health": 25.0, "health_regen": 1.0},
			"weight": 0.7
		},
		{
			"id": "life_giving",
			"suffix": "of Life",
			"stat_bonuses": {"health": 30.0},
			"weight": 0.3
		},
		
		# Speed affixes
		{
			"id": "swift",
			"prefix": "Swift",
			"stat_bonuses": {"move_speed": 0.10},
			"weight": 0.8
		},
		{
			"id": "fleet",
			"prefix": "Fleet",
			"stat_bonuses": {"move_speed": 0.15},
			"weight": 0.5
		},
		{
			"id": "windblown",
			"suffix": "of Wind",
			"stat_bonuses": {"move_speed": 0.20},
			"weight": 0.2
		},
		
		# Critical affixes
		{
			"id": "keen",
			"prefix": "Keen",
			"stat_bonuses": {"crit_chance": 0.05},
			"weight": 0.8
		},
		{
			"id": "sharp",
			"prefix": "Sharp",
			"stat_bonuses": {"crit_chance": 0.08, "crit_damage": 0.25},
			"weight": 0.5
		},
		{
			"id": "deadshot",
			"suffix": "of Precision",
			"stat_bonuses": {"crit_chance": 0.10, "crit_damage": 0.50},
			"weight": 0.2
		},
		
		# Combination affixes
		{
			"id": "balanced",
			"prefix": "Balanced",
			"stat_bonuses": {"health": 10.0, "damage": 5.0, "defense": 5.0},
			"weight": 0.6
		},
		{
			"id": "masterwork",
			"prefix": "Masterwork",
			"stat_bonuses": {"damage": 12.0, "defense": 8.0, "move_speed": 0.05},
			"weight": 0.3
		},
		{
			"id": "legendary",
			"prefix": "Legendary",
			"stat_bonuses": {"damage": 15.0, "defense": 10.0, "health": 20.0},
			"weight": 0.1
		}
	]
	
	# Gem affixes (simpler, more focused)
	_affix_pools[Enums.ItemType.GEM] = [
		{
			"id": "gem_burning",
			"prefix": "Burning",
			"stat_bonuses": {"damage": 3.0},
			"weight": 1.0
		},
		{
			"id": "gem_brilliant",
			"prefix": "Brilliant",
			"stat_bonuses": {"damage": 5.0},
			"weight": 0.6
		},
		{
			"id": "gem_flawless",
			"prefix": "Flawless",
			"stat_bonuses": {"damage": 8.0},
			"weight": 0.2
		},
		{
			"id": "gem_pure",
			"prefix": "Pure",
			"stat_bonuses": {"magika": 5.0},
			"weight": 0.8
		},
		{
			"id": "gem_radiant",
			"prefix": "Radiant",
			"stat_bonuses": {"magika": 8.0},
			"weight": 0.4
		}
	]
	
	# Weapon affixes
	_affix_pools[Enums.ItemType.STAFF_PART] = [
		{
			"id": "staff_power",
			"prefix": "Powerful",
			"stat_bonuses": {"damage": 8.0},
			"weight": 1.0
		},
		{
			"id": "staff_swift",
			"suffix": "of Speed",
			"stat_bonuses": {"damage": 5.0},
			"weight": 0.8
		},
		{
			"id": "staff_charged",
			"prefix": "Charged",
			"stat_bonuses": {"magika": 10.0},
			"weight": 0.7
		},
		{
			"id": "staff_efficient",
			"suffix": "of Efficiency",
			"stat_bonuses": {"magika": 15.0},
			"weight": 0.4
		}
	]


## Get affix pool for an item type
func _get_affix_pool_for_item(item: ItemData) -> Array:
	"""Return the affix pool appropriate for an item."""
	
	var item_type = item.item_type
	
	if _affix_pools.has(item_type):
		return _affix_pools[item_type]
	
	# Default to equipment affixes for unknown types
	return _affix_pools.get(Enums.ItemType.EQUIPMENT, [])


## Scale affix values based on player level
func _scale_affix_by_level(affix: Dictionary, player_level: int) -> void:
	"""Adjust affix values based on player level."""
	
	if not affix.has("stat_bonuses"):
		return
	
	# Simple scaling: 1% per level above level 1
	var level_mult = 1.0 + (float(player_level - 1) * 0.01)
	
	for stat_name in affix.stat_bonuses.keys():
		affix.stat_bonuses[stat_name] *= level_mult


## Select weighted random affix from pool
func _select_weighted_affix(pool: Array) -> Dictionary:
	"""Select a random affix from a pool using weights."""
	
	var total_weight = 0.0
	for affix in pool:
		total_weight += affix.get("weight", 1.0)
	
	var roll = randf() * total_weight
	var current = 0.0
	
	for affix in pool:
		current += affix.get("weight", 1.0)
		if roll <= current:
			return affix
	
	return pool[0] if not pool.is_empty() else {}


# =============================================================================
# DEBUG/UTILITY METHODS
# =============================================================================

## Get all affix IDs in the system
func get_all_affix_ids() -> Array:
	"""Return all affix IDs (useful for debugging/validation)."""
	var ids = []
	for pool in _affix_pools.values():
		for affix in pool:
			if affix.has("id"):
				ids.append(affix.id)
	return ids


## Print affix statistics
func print_affix_stats() -> void:
	"""Debug: Print statistics about all affixes."""
	print("=== AFFIX SYSTEM STATISTICS ===")
	for item_type in _affix_pools.keys():
		var count = _affix_pools[item_type].size()
		print("Item Type %s: %d affixes" % [Enums.ItemType.keys()[item_type], count])
	print("==============================")
