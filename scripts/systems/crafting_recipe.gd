## CraftingRecipe - A discovered crafting recipe
## Represents a specific combination of parts that creates a known weapon
class_name CraftingRecipe
extends Resource

@export var recipe_id: String = ""
@export var recipe_name: String = ""
@export var description: String = ""

@export var weapon_type: String = "staff"  ## "staff" or "wand"
@export var required_parts: Array[String] = []  ## Item IDs of required parts
@export var optional_parts: Array[String] = []  ## Item IDs of optional parts
@export var required_gems: Array[String] = []  ## Item IDs of required gems

@export var result_item_id: String = ""  ## The item this recipe creates
@export var result_rarity: Enums.Rarity = Enums.Rarity.BASIC

@export var discovery_difficulty: float = 1.0  ## How hard to discover (0.1-1.0)
@export var experience_reward: int = 50  ## XP gained when discovered

@export var is_hidden: bool = true  ## True until discovered
@export var discovery_count: int = 0  ## How many times crafted

@export var required_level: int = 1  ## Minimum player level to craft

# Recipe matching criteria
@export var exact_match: bool = false  ## True requires exact part matching
@export var rarity_threshold: Enums.Rarity = Enums.Rarity.BASIC  ## Minimum rarity

func _init() -> void:
	recipe_id = "recipe_" + str(Time.get_unix_time_from_system())

## Check if a configuration matches this recipe
func matches_configuration(config: WeaponConfiguration, player_level: int) -> bool:
	# Check weapon type
	if config.weapon_type != weapon_type:
		return false
	
	# Check player level
	if player_level < required_level:
		return false
	
	# Check required parts
	if required_parts.size() > 0:
		if not _has_required_parts(config):
			return false
	
	# Check exact match requirement
	if exact_match:
		return _is_exact_match(config)
	
	# Check rarity threshold
	if float(config.weapon_rarity) < float(rarity_threshold):
		return false
	
	# Check if configuration has similar structure
	return _has_similar_structure(config)

func _has_required_parts(config: WeaponConfiguration) -> bool:
	## Check if config has all required parts
	var config_parts = _get_config_part_ids(config)
	
	for required_id in required_parts:
		if required_id not in config_parts:
			return false
	
	return true

func _is_exact_match(config: WeaponConfiguration) -> bool:
	## Check if configuration exactly matches recipe requirements
	var config_parts = _get_config_part_ids(config)
	
	# Must have all required parts
	for required_id in required_parts:
		if required_id not in config_parts:
			return false
	
	# Should not have parts outside recipe (unless optional)
	for part_id in config_parts:
		if part_id in required_parts:
			continue
		if part_id in optional_parts:
			continue
		return false
	
	return true

func _has_similar_structure(config: WeaponConfiguration) -> bool:
	## Check if configuration has similar part structure
	var required_structure = _get_part_structure(required_parts)
	var config_structure = _get_part_structure_from_config(config)
	
	# Allow some flexibility in matching
	var match_score = 0.0
	var total_checks = max(required_structure.size(), 1)
	
	for structure in required_structure:
		if structure in config_structure:
			match_score += 1.0 / total_checks
	
	# Require at least 70% structure match
	return match_score >= 0.7

func _get_part_structure(part_ids: Array[String]) -> Array[String]:
	## Get part types from item IDs
	var structure = []
	
	for part_id in part_ids:
		var item = ItemDatabase.get_item(part_id)
		if item and item is StaffPartData:
			var part = item as StaffPartData
			structure.append(Enums.StaffPart.keys()[part.part_type])
	
	return structure

func _get_part_structure_from_config(config: WeaponConfiguration) -> Array[String]:
	## Get part types from configuration
	var structure = []
	
	if config.head:
		structure.append(Enums.StaffPart.keys()[config.head.part_type])
	if config.exterior:
		structure.append(Enums.StaffPart.keys()[config.exterior.part_type])
	if config.interior:
		structure.append(Enums.StaffPart.keys()[config.interior.part_type])
	if config.handle:
		structure.append(Enums.StaffPart.keys()[config.handle.part_type])
	if config.charm:
		structure.append(Enums.StaffPart.keys()[config.charm.part_type])
	
	return structure

func _get_config_part_ids(config: WeaponConfiguration) -> Array[String]:
	## Get all part IDs from configuration
	var part_ids = []
	
	if config.head:
		part_ids.append(config.head.item_id)
	if config.exterior:
		part_ids.append(config.exterior.item_id)
	if config.interior:
		part_ids.append(config.interior.item_id)
	if config.handle:
		part_ids.append(config.handle.item_id)
	if config.charm:
		part_ids.append(config.charm.item_id)
	
	return part_ids

## Discover this recipe
func discover() -> void:
	is_hidden = false
	discovery_count += 1

## Get discovery chance based on crafting attempt
func get_discovery_chance(config: WeaponConfiguration, player_level: int, crafting_skill: float) -> float:
	if not is_hidden:
		return 0.0  ## Already discovered
	
	if not matches_configuration(config, player_level):
		return 0.0  ## Doesn't match
	
	# Base discovery chance
	var base_chance = discovery_difficulty * 0.1  ## Max 10% base
	
	# Player level bonus
	var level_bonus = (player_level - required_level) * 0.02  ## 2% per level above required
	
	# Crafting skill bonus
	var skill_bonus = crafting_skill * 0.05  ## 5% per skill point
	
	# Rarity bonus (higher rarity = easier to discover)
	var rarity_bonus = float(config.weapon_rarity) * 0.02
	
	# Part count bonus (more complex = easier to discover)
	var part_bonus = config.get_total_part_count() * 0.01
	
	var total_chance = base_chance + level_bonus + skill_bonus + rarity_bonus + part_bonus
	
	return clamp(total_chance, 0.01, 0.5)  ## Between 1% and 50%

## Get recipe tier for UI display
func get_recipe_tier() -> String:
	match result_rarity:
		Enums.Rarity.BASIC:
			return "Basic"
		Enums.Rarity.UNCOMMON:
			return "Uncommon"
		Enums.Rarity.RARE:
			return "Rare"
		Enums.Rarity.MYTHIC:
			return "Mythic"
		Enums.Rarity.PRIMORDIAL:
			return "Primordial"
		Enums.Rarity.UNIQUE:
			return "Unique"
		_:
			return "Unknown"

## Get recipe requirements as formatted string
func get_requirements_text() -> String:
	var text = ""
	
	# Required parts
	if required_parts.size() > 0:
		text += "[u]Required Parts:[/u]\n"
		for part_id in required_parts:
			var item = ItemDatabase.get_item(part_id)
			if item:
				text += "• %s\n" % item.item_name
	
	# Optional parts
	if optional_parts.size() > 0:
		text += "\n[u]Optional Parts:[/u]\n"
		for part_id in optional_parts:
			var item = ItemDatabase.get_item(part_id)
			if item:
				text += "• %s\n" % item.item_name
	
	# Required gems
	if required_gems.size() > 0:
		text += "\n[u]Required Gems:[/u]\n"
		for gem_id in required_gems:
			var item = ItemDatabase.get_item(gem_id)
			if item:
				text += "• %s\n" % item.item_name
	
	# Level requirement
	if required_level > 1:
		text += "\n[u]Requirements:[/u]\n"
		text += "• Level %d\n" % required_level
	
	return text

## Get recipe result text
func get_result_text() -> String:
	var item = ItemDatabase.get_item(result_item_id)
	if item:
		var rarity_color = Constants.RARITY_COLORS.get(result_rarity, Color.WHITE)
		return "[color=%s]%s[/color]\n%s" % [rarity_color.to_html(), item.item_name, item.description]
	else:
		return "Unknown Item"

## Check if recipe can be crafted with current inventory
func can_craft_with_inventory(inventory_system: InventorySystem) -> bool:
	# Check required parts
	for part_id in required_parts:
		if not inventory_system.has_item(part_id):
			return false
	
	# Check required gems
	for gem_id in required_gems:
		if not inventory_system.has_item(gem_id):
			return false
	
	return true

## Consume required materials from inventory
func consume_materials(inventory_system: InventorySystem) -> bool:
	# Check if we have all materials first
	if not can_craft_with_inventory(inventory_system):
		return false
	
	# Consume required parts
	for part_id in required_parts:
		inventory_system.remove_item_by_id(part_id, 1)
	
	# Consume required gems
	for gem_id in required_gems:
		inventory_system.remove_item_by_id(gem_id, 1)
	
	return true

## Get total value of required materials
func get_material_value() -> int:
	var total_value = 0
	
	# Add part values
	for part_id in required_parts:
		var item = ItemDatabase.get_item(part_id)
		if item:
			total_value += item.get_value()
	
	# Add gem values
	for gem_id in required_gems:
		var item = ItemDatabase.get_item(gem_id)
		if item:
			total_value += item.get_value()
	
	return total_value

## Check if this recipe is better than another
func is_better_than(other: CraftingRecipe) -> bool:
	if not other:
		return true
	
	# Compare rarity
	if float(result_rarity) > float(other.result_rarity):
		return true
	elif float(result_rarity) < float(other.result_rarity):
		return false
	
	# Compare material value
	return get_material_value() > other.get_material_value()