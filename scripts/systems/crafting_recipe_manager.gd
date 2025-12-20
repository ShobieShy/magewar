## CraftingRecipeManager - Manages crafting recipes
## Handles recipe discovery, matching, and database operations
extends Node

signal recipe_discovered(recipe: CraftingRecipe)
signal recipe_unlocked(recipe: CraftingRecipe)
signal recipes_updated()

# Recipe database
var _recipes: Dictionary = {}  ## recipe_id -> CraftingRecipe
var _discovered_recipes: Array[String] = []  ## List of discovered recipe IDs

# Recipe discovery tracking
var _crafting_attempts: int = 0
var _successful_crafts: int = 0
var _discovery_chances: Dictionary = {}  ## recipe_id -> cumulative chance

func _ready() -> void:
	_load_default_recipes()
	_load_discovered_recipes()

## Register a new recipe
func register_recipe(recipe: CraftingRecipe) -> void:
	if not recipe or recipe.recipe_id.is_empty():
		push_error("Cannot register recipe without valid ID")
		return
	
	_recipes[recipe.recipe_id] = recipe
	recipes_updated.emit()

## Get recipe by ID
func get_recipe(recipe_id: String) -> CraftingRecipe:
	return _recipes.get(recipe_id, null)

## Get all recipes
func get_all_recipes() -> Array[CraftingRecipe]:
	var all_recipes: Array[CraftingRecipe] = []
	for recipe in _recipes.values():
		all_recipes.append(recipe)
	return all_recipes

## Get discovered recipes
func get_discovered_recipes() -> Array[CraftingRecipe]:
	var discovered: Array[CraftingRecipe] = []
	for recipe_id in _discovered_recipes:
		var recipe = _recipes.get(recipe_id)
		if recipe:
			discovered.append(recipe)
	return discovered

## Get undiscovered recipes count
func get_undiscovered_count() -> int:
	var count = 0
	for recipe in _recipes.values():
		if recipe.is_hidden:
			count += 1
	return count

## Check if configuration matches any recipes
func find_matching_recipes(config: WeaponConfiguration, player_level: int) -> Array[CraftingRecipe]:
	var matching: Array[CraftingRecipe] = []
	
	for recipe in _recipes.values():
		if recipe.matches_configuration(config, player_level):
			matching.append(recipe)
	
	# Sort by rarity (higher rarity first)
	matching.sort_custom(func(a, b): return float(a.result_rarity) > float(b.result_rarity))
	
	return matching

## Process crafting attempt and check for recipe discovery
func process_crafting_attempt(config: WeaponConfiguration, player_level: int, crafting_skill: float) -> CraftingRecipe:
	_crafting_attempts += 1
	
	# Find matching recipes
	var matching_recipes = find_matching_recipes(config, player_level)
	if matching_recipes.is_empty():
		return null
	
	# Check for new recipe discoveries
	for recipe in matching_recipes:
		if recipe.is_hidden:
			var discovery_chance = recipe.get_discovery_chance(config, player_level, crafting_skill)
			
			# Track cumulative chance for this recipe
			var recipe_id = recipe.recipe_id
			var cumulative_chance = _discovery_chances.get(recipe_id, 0.0) + discovery_chance
			_discovery_chances[recipe_id] = cumulative_chance
			
			# Roll for discovery
			if randf() < discovery_chance:
				_discover_recipe(recipe)
				return recipe
	
	return null

## Discover a recipe
func _discover_recipe(recipe: CraftingRecipe) -> void:
	if not recipe.is_hidden:
		return
	
	recipe.discover()
	_discovered_recipes.append(recipe.recipe_id)
	
	print("Recipe Discovered: %s" % recipe.recipe_name)
	recipe_discovered.emit(recipe)
	
	# Save discovery progress
	_save_discovered_recipes()
	recipes_updated.emit()

## Force unlock a recipe (for achievements/rewards)
func unlock_recipe(recipe_id: String) -> bool:
	var recipe = _recipes.get(recipe_id)
	if not recipe:
		return false
	
	if not recipe.is_hidden:
		return false  ## Already unlocked
	
	_discover_recipe(recipe)
	recipe_unlocked.emit(recipe)
	return true

## Get best matching recipe for configuration
func get_best_recipe(config: WeaponConfiguration, player_level: int) -> CraftingRecipe:
	var matching = find_matching_recipes(config, player_level)
	
	if matching.is_empty():
		return null
	
	# Return the highest rarity recipe (already sorted)
	return matching[0]

## Check if player can craft with specific recipe
func can_craft_recipe(recipe_id: String, inventory_system: InventorySystem) -> bool:
	var recipe = _recipes.get(recipe_id)
	if not recipe:
		return false
	
	return recipe.can_craft_with_inventory(inventory_system)

## Craft using a specific recipe
func craft_with_recipe(recipe_id: String, inventory_system: InventorySystem) -> ItemData:
	var recipe = _recipes.get(recipe_id)
	if not recipe:
		push_error("Recipe not found: %s" % recipe_id)
		return null
	
	if not recipe.can_craft_with_inventory(inventory_system):
		push_error("Cannot craft recipe: insufficient materials")
		return null
	
	# Consume materials
	if not recipe.consume_materials(inventory_system):
		push_error("Failed to consume materials")
		return null
	
	# Create the result item
	var result_item = ItemDatabase.get_item(recipe.result_item_id)
	if not result_item:
		push_error("Recipe result item not found: %s" % recipe.result_item_id)
		return null
	
	# Add to inventory
	var slot = inventory_system.add_item(result_item)
	if slot < 0:
		push_error("Inventory full when crafting recipe")
		return null
	
	_successful_crafts += 1
	recipe.discovery_count += 1
	
	_save_discovered_recipes()
	recipes_updated.emit()
	
	return result_item

## Get crafting statistics
func get_crafting_stats() -> Dictionary:
	return {
		"total_attempts": _crafting_attempts,
		"successful_crafts": _successful_crafts,
		"recipes_discovered": _discovered_recipes.size(),
		"total_recipes": _recipes.size(),
		"discovery_rate": float(_discovered_recipes.size()) / float(max(_recipes.size(), 1)) * 100.0,
		"success_rate": float(_successful_crafts) / float(max(_crafting_attempts, 1)) * 100.0
	}

## Reset all discovered recipes (for debugging/new game)
func reset_discovered_recipes() -> void:
	_discovered_recipes.clear()
	_discovery_chances.clear()
	_crafting_attempts = 0
	_successful_crafts = 0
	
	# Reset all recipes to hidden
	for recipe in _recipes.values():
		recipe.is_hidden = true
		recipe.discovery_count = 0
	
	_save_discovered_recipes()
	recipes_updated.emit()

## Get recipes by weapon type
func get_recipes_by_type(weapon_type: String) -> Array[CraftingRecipe]:
	var type_recipes: Array[CraftingRecipe] = []
	
	for recipe in _recipes.values():
		if recipe.weapon_type == weapon_type:
			type_recipes.append(recipe)
	
	return type_recipes

## Get recipes by rarity
func get_recipes_by_rarity(min_rarity: Enums.Rarity) -> Array[CraftingRecipe]:
	var rarity_recipes: Array[CraftingRecipe] = []
	
	for recipe in _recipes.values():
		if float(recipe.result_rarity) >= float(min_rarity):
			rarity_recipes.append(recipe)
	
	return rarity_recipes

## Get recipes that use specific part
func get_recipes_using_part(part_id: String) -> Array[CraftingRecipe]:
	var part_recipes: Array[CraftingRecipe] = []
	
	for recipe in _recipes.values():
		if part_id in recipe.required_parts or part_id in recipe.optional_parts:
			part_recipes.append(recipe)
	
	return part_recipes

## Save discovered recipes
func _save_discovered_recipes() -> void:
	var save_data = {
		"discovered_recipes": _discovered_recipes,
		"crafting_attempts": _crafting_attempts,
		"successful_crafts": _successful_crafts,
		"discovery_chances": _discovery_chances
	}
	
	if SaveManager:
		SaveManager.set_data("crafting_recipes", save_data)

## Load discovered recipes
func _load_discovered_recipes() -> void:
	var save_data = null
	if SaveManager:
		save_data = SaveManager.get_data("crafting_recipes")
	if not save_data:
		return
	
	if save_data.has("discovered_recipes"):
		_discovered_recipes = save_data.discovered_recipes
	
	if save_data.has("crafting_attempts"):
		_crafting_attempts = save_data.crafting_attempts
	
	if save_data.has("successful_crafts"):
		_successful_crafts = save_data.successful_crafts
	
	if save_data.has("discovery_chances"):
		_discovery_chances = save_data.discovery_chances
	
	# Apply discovered state to recipes
	for recipe_id in _discovered_recipes:
		var recipe = _recipes.get(recipe_id)
		if recipe:
			recipe.is_hidden = false

## Load default recipes
func _load_default_recipes() -> void:
	# Basic Staff Recipe
	var basic_staff = CraftingRecipe.new()
	basic_staff.recipe_id = "basic_staff"
	basic_staff.recipe_name = "Basic Staff"
	basic_staff.description = "A simple staff for novice mages"
	basic_staff.weapon_type = "staff"
	basic_staff.required_parts = ["basic_staff_head", "basic_staff_exterior", "basic_staff_interior", "basic_staff_handle"] as Array[String]
	basic_staff.result_item_id = "basic_staff_result"
	basic_staff.result_rarity = Enums.Rarity.UNCOMMON
	basic_staff.discovery_difficulty = 0.8
	basic_staff.experience_reward = 50
	basic_staff.required_level = 1
	register_recipe(basic_staff)
	
	# Basic Wand Recipe
	var basic_wand = CraftingRecipe.new()
	basic_wand.recipe_id = "basic_wand"
	basic_wand.recipe_name = "Basic Wand"
	basic_wand.description = "A simple wand for quick casting"
	basic_wand.weapon_type = "wand"
	basic_wand.required_parts = ["basic_wand_head", "basic_wand_exterior"] as Array[String]
	basic_wand.optional_parts = ["basic_wand_handle"] as Array[String]
	basic_wand.result_item_id = "basic_wand_result"
	basic_wand.result_rarity = Enums.Rarity.UNCOMMON
	basic_wand.discovery_difficulty = 0.8
	basic_wand.experience_reward = 30
	basic_wand.required_level = 1
	register_recipe(basic_wand)
	
	# Fire Staff Recipe
	var fire_staff = CraftingRecipe.new()
	fire_staff.recipe_id = "fire_staff"
	fire_staff.recipe_name = "Fire Staff"
	fire_staff.description = "A staff imbued with fire magic"
	fire_staff.weapon_type = "staff"
	fire_staff.required_parts = ["fire_staff_head", "reinforced_staff_exterior", "fire_staff_interior", "oak_staff_handle"] as Array[String]
	fire_staff.required_gems = ["ruby_gem"] as Array[String]
	fire_staff.result_item_id = "fire_staff_result"
	fire_staff.result_rarity = Enums.Rarity.RARE
	fire_staff.discovery_difficulty = 0.5
	fire_staff.experience_reward = 100
	fire_staff.required_level = 10
	register_recipe(fire_staff)
	
	# Ice Wand Recipe
	var ice_wand = CraftingRecipe.new()
	ice_wand.recipe_id = "ice_wand"
	ice_wand.recipe_name = "Ice Wand"
	ice_wand.description = "A wand that channels ice magic"
	ice_wand.weapon_type = "wand"
	ice_wand.required_parts = ["frost_wand_head", "crystal_wand_exterior"] as Array[String]
	ice_wand.required_gems = ["sapphire_gem"] as Array[String]
	ice_wand.result_item_id = "ice_wand_result"
	ice_wand.result_rarity = Enums.Rarity.RARE
	ice_wand.discovery_difficulty = 0.5
	ice_wand.experience_reward = 80
	ice_wand.required_level = 8
	register_recipe(ice_wand)
	
	print("Loaded %d default crafting recipes" % _recipes.size())