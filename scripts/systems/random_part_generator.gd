## RandomPartGenerator - Generates random staff parts with random rarities
class_name RandomPartGenerator
extends RefCounted

# =============================================================================
# CONSTANTS
# =============================================================================

# All available staff parts organized by type
const PART_HEADS = [
	"cracked_crystal",
	"polished_focus",
	"primordial_core"
]

const PART_EXTERIORS = [
	"rough_wood",
	"carved_oak",
	"runewood"
]

const PART_INTERIORS = [
	"iron_conduit",
	"silver_conduit",
	"mithril_core"
]

const PART_HANDLES = [
	"leather_wrap",
	"silk_binding",
	"masters_grip"
]

const PART_CHARMS = [
	"ember_charm",
	"frost_charm",
	"vampiric_charm"
]

# Part types
const PART_TYPES = [
	PART_HEADS,
	PART_EXTERIORS,
	PART_INTERIORS,
	PART_HANDLES,
	PART_CHARMS
]

# =============================================================================
# METHODS
# =============================================================================

func get_random_parts(count: int = 5) -> Array[ItemData]:
	"""Generate an array of random parts with random rarities"""
	var parts: Array[ItemData] = []
	
	for i in range(count):
		var part = get_single_random_part()
		if part:
			parts.append(part)
	
	return parts


func get_single_random_part() -> ItemData:
	"""Get a single random part with random rarity"""
	# Pick random part type
	var part_type = PART_TYPES[randi() % PART_TYPES.size()]
	
	# Pick random part from that type
	var part_id = part_type[randi() % part_type.size()]
	
	# Get the part from the database
	var part = ItemDatabase.get_item(part_id)
	
	if part == null:
		push_warning("Failed to get part: %s" % part_id)
		return null
	
	# Apply random rarity
	var rarity = _get_random_rarity()
	if part is StaffPartData:
		part.rarity = rarity
	
	return part


func _get_random_rarity() -> Enums.Rarity:
	"""Get a random rarity based on weighted probability"""
	var roll = randf()
	
	# Rarity weights from Constants
	var weights = Constants.RARITY_WEIGHTS
	var total_weight = 0.0
	
	# Calculate total weight
	for weight in weights.values():
		total_weight += weight
	
	# Roll for rarity
	var current = 0.0
	for rarity_enum in weights.keys():
		var weight = weights[rarity_enum]
		current += weight / total_weight
		if roll <= current:
			return rarity_enum
	
	# Fallback to basic
	return Enums.Rarity.BASIC
