## CraftingMaterial - Resource-based crafting material definition
## Defines properties for ore, essence, and shard materials used in weapon progression
class_name CraftingMaterial
extends Resource

# =============================================================================
# PROPERTIES
# =============================================================================

@export var material_id: String = ""
@export var material_name: String = ""
@export var material_type: Enums.MaterialType = Enums.MaterialType.ORE
@export var material_tier: Enums.Rarity = Enums.Rarity.BASIC
@export var element: Enums.Element = Enums.Element.FIRE  ## Optional, for element-specific materials

@export var description: String = ""
@export var icon: Texture2D = null
@export var weight: float = 1.0
@export var stack_limit: int = 999

# =============================================================================
# VALIDATION
# =============================================================================

func _validate_property(property: Dictionary) -> void:
	# This method is called by Godot's inspector when validating properties
	# In Godot 4.x, this is used to hide/show properties based on other properties
	pass

# =============================================================================
# UTILITY METHODS
# =============================================================================

## Get display name with tier
func get_display_name() -> String:
	var tier_name = Enums.rarity_to_string(material_tier)
	return "%s %s" % [tier_name, material_name]

## Get tier color for UI
func get_tier_color() -> Color:
	match material_tier:
		Enums.Rarity.BASIC:
			return Color.WHITE
		Enums.Rarity.UNCOMMON:
			return Color.GREEN
		Enums.Rarity.RARE:
			return Color.BLUE
		Enums.Rarity.MYTHIC:
			return Color.MEDIUM_ORCHID
		Enums.Rarity.PRIMORDIAL:
			return Color.ORANGE
		Enums.Rarity.UNIQUE:
			return Color.GOLD
	return Color.WHITE

## Check if this material matches requirements
func matches_requirement(material_id: String, tier: Enums.Rarity) -> bool:
	return self.material_id == material_id and self.material_tier == tier

## Get material type name
func get_type_name() -> String:
	return Enums.material_type_to_string(material_type)
