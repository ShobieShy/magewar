## ItemData - Base class for all items in Magewar
class_name ItemData
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Basic Info")
@export var item_id: String = ""
@export var item_name: String = "Unknown Item"
@export var description: String = ""
@export var icon: Texture2D
@export var item_type: Enums.ItemType = Enums.ItemType.MISC
@export var rarity: Enums.Rarity = Enums.Rarity.BASIC

@export_group("Stacking")
@export var stackable: bool = false
@export var max_stack: int = 1

@export_group("Value")
@export var base_value: int = 0  ## Sell value in gold

@export_group("Requirements")
@export var level_required: int = 1

# =============================================================================
# METHODS
# =============================================================================

func get_display_name() -> String:
	return item_name


func get_rarity_color() -> Color:
	return Constants.RARITY_COLORS.get(rarity, Color.WHITE)


func get_value() -> int:
	## Calculate value based on rarity
	return int(base_value * Constants.RARITY_STAT_MULTIPLIERS.get(rarity, 1.0))


func get_tooltip() -> String:
	var tooltip = "[color=%s][b]%s[/b][/color]\n" % [get_rarity_color().to_html(), item_name]
	tooltip += "[i]%s[/i]\n" % Enums.Rarity.keys()[rarity]
	
	if description:
		tooltip += "\n" + description
	
	if level_required > 1:
		tooltip += "\n\nRequires Level %d" % level_required
	
	tooltip += "\n\nValue: %d gold" % get_value()
	
	return tooltip


func can_use() -> bool:
	## Override in subclasses for usable items
	return false


func use(user: Node) -> bool:
	## Override in subclasses
	return false


func duplicate_item() -> ItemData:
	return duplicate(true)
