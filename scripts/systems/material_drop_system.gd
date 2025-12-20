## MaterialDropSystem - Generates material drops from enemies based on rarity
## Integrates with LootSystem to drop materials into the world
class_name MaterialDropSystem
extends RefCounted

# =============================================================================
# MATERIAL DROP CONFIGURATION
# =============================================================================

# Drop chance by enemy rarity (how likely to drop materials at all)
var drop_chances_by_rarity: Dictionary = {
	Enums.Rarity.BASIC: 0.60,        # 60% chance
	Enums.Rarity.UNCOMMON: 0.70,     # 70% chance
	Enums.Rarity.RARE: 0.80,         # 80% chance
	Enums.Rarity.MYTHIC: 0.90,       # 90% chance
	Enums.Rarity.PRIMORDIAL: 0.95,   # 95% chance
	Enums.Rarity.UNIQUE: 1.0         # 100% chance
}

# Material type distribution (roll which type of material to drop)
# Ore: 60%, Essence: 30%, Shard: 10%
var material_type_weights: Dictionary = {
	Enums.MaterialType.ORE: 60,
	Enums.MaterialType.ESSENCE: 30,
	Enums.MaterialType.SHARD: 10
}

# Quantity dropped per type
var drop_quantities: Dictionary = {
	Enums.MaterialType.ORE: {"min": 1, "max": 3},
	Enums.MaterialType.ESSENCE: {"min": 1, "max": 2},
	Enums.MaterialType.SHARD: {"min": 1, "max": 2}
}

# Material IDs by type and tier
var material_ids_by_type: Dictionary = {
	Enums.MaterialType.ORE: [
		"ore_fragment",   # BASIC
		"ore_piece",      # UNCOMMON
		"ore_chunk",      # RARE
		"ore_lump",       # MYTHIC
		"ore_nugget",     # PRIMORDIAL
		"ore_crystal"     # UNIQUE
	],
	Enums.MaterialType.SHARD: [
		"shard_fragment",    # BASIC
		"shard_piece",       # UNCOMMON
		"shard_chunk",       # RARE
		"shard_core",        # MYTHIC
		"shard_nexus",       # PRIMORDIAL
		"shard_transcendent" # UNIQUE
	]
	# Essence materials are handled separately due to element variation
}

# Element essence IDs (base name without tier suffix)
var essence_base_ids: Array[String] = [
	"fire_essence",
	"water_essence",
	"earth_essence",
	"wind_essence",
	"light_essence",
	"dark_essence"
]

# =============================================================================
# METHODS
# =============================================================================

## Generate material drops for an enemy defeat
## Returns array of CraftingMaterial items to drop
func generate_enemy_drops(enemy_rarity: Enums.Rarity, enemy_level: int = 1) -> Array[CraftingMaterial]:
	var drops: Array[CraftingMaterial] = []
	
	# Check if enemy drops materials at all
	var drop_chance = drop_chances_by_rarity.get(enemy_rarity, 0.5)
	if randf() > drop_chance:
		return drops  # No drops this time
	
	# Roll how many materials drop (1-3)
	var drop_count = randi_range(1, 3)
	
	for i in range(drop_count):
		var material = _roll_material(enemy_rarity)
		if material:
			drops.append(material)
	
	return drops

## Roll a single material drop
func _roll_material(enemy_rarity: Enums.Rarity) -> CraftingMaterial:
	# Determine which type of material to drop
	var material_type = _roll_material_type()
	
	# Get the material ID based on type and rarity
	var material_id = _get_material_id_for_type_and_rarity(material_type, enemy_rarity)
	
	if not material_id:
		return null
	
	# Load the material resource
	var material_path = "res://resources/items/materials/%s.tres" % material_id
	if ResourceLoader.exists(material_path):
		return load(material_path)
	
	push_warning("Material not found: %s" % material_path)
	return null

## Roll which material type drops (ore, essence, shard)
func _roll_material_type() -> Enums.MaterialType:
	var total_weight = 0
	for weight in material_type_weights.values():
		total_weight += weight
	
	var roll = randi_range(0, total_weight)
	var current = 0
	
	for material_type in material_type_weights.keys():
		current += material_type_weights[material_type]
		if roll <= current:
			return material_type
	
	return Enums.MaterialType.ORE  # Fallback

## Get material ID for a specific type and rarity
func _get_material_id_for_type_and_rarity(material_type: Enums.MaterialType, rarity: Enums.Rarity) -> String:
	match material_type:
		Enums.MaterialType.ORE:
			return material_ids_by_type[Enums.MaterialType.ORE][rarity]
		
		Enums.MaterialType.SHARD:
			return material_ids_by_type[Enums.MaterialType.SHARD][rarity]
		
		Enums.MaterialType.ESSENCE:
			# Pick a random element essence
			var element_idx = randi() % essence_base_ids.size()
			var essence_base = essence_base_ids[element_idx]
			return "%s_%d" % [essence_base, rarity]  # e.g., "fire_essence_2"
	
	return ""

## Create an ItemData from a CraftingMaterial for inventory
## This wrapper allows materials to be stored in inventory
func create_material_item_data(material: CraftingMaterial, quantity: int = 1) -> ItemData:
	var item = ItemData.new()
	item.item_id = material.material_id
	item.item_name = material.get_display_name()
	item.description = material.description
	item.item_type = Enums.ItemType.MISC  # Materials are miscellaneous items
	item.rarity = material.material_tier
	item.stackable = true
	item.stack_count = quantity
	item.icon = material.icon
	item.weight = material.weight
	
	return item

## Debug: print drop table
func debug_print_drop_table() -> void:
	print("\n=== Material Drop System ===")
	print("Drop Chances by Rarity:")
	for rarity in drop_chances_by_rarity:
		print("  %s: %.0f%%" % [Enums.rarity_to_string(rarity), drop_chances_by_rarity[rarity] * 100])
	print("\nMaterial Type Distribution:")
	var total = 0
	for mat_type in material_type_weights:
		total += material_type_weights[mat_type]
	for mat_type in material_type_weights:
		var pct = (material_type_weights[mat_type] / float(total)) * 100
		print("  %s: %.0f%%" % [Enums.material_type_to_string(mat_type), pct])
	print("===========================\n")
