## CraftingManager - Global access point for crafting systems
## Provides easy access to all crafting-related functionality
extends Node

signal crafting_started(config: WeaponConfiguration)
signal crafting_completed(weapon: ItemData, success: bool)
signal crafting_failed(error: String)
signal recipe_discovered(recipe: CraftingRecipe)
signal achievement_unlocked(achievement: CraftingAchievement)

# Main crafting logic
var crafting_logic: CraftingLogic

# Subsystems
var recipe_manager: CraftingRecipeManager
var achievement_manager: CraftingAchievementManager

func _ready() -> void:
	# Initialize main crafting logic
	crafting_logic = CraftingLogic.new()
	add_child(crafting_logic)
	
	# Get subsystems
	recipe_manager = crafting_logic.get_recipe_manager()
	achievement_manager = crafting_logic.get_achievement_manager()
	
	# Connect signals
	crafting_logic.crafting_started.connect(_on_crafting_started)
	crafting_logic.crafting_completed.connect(_on_crafting_completed)
	crafting_logic.crafting_failed.connect(_on_crafting_failed)
	crafting_logic.recipe_discovered.connect(_on_recipe_discovered)
	crafting_logic.achievement_unlocked.connect(_on_achievement_unlocked)
	
	print("CraftingManager initialized")

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Start crafting a weapon
func craft_weapon(config: WeaponConfiguration, player_level: int = 1) -> bool:
	return crafting_logic.start_crafting(config, player_level)

## Cancel current crafting
func cancel_crafting() -> bool:
	return crafting_logic.cancel_crafting()

## Get crafting status
func get_crafting_status() -> Dictionary:
	return {
		"is_crafting": crafting_logic.is_crafting(),
		"progress": crafting_logic.get_crafting_progress(),
		"time_remaining": crafting_logic.get_crafting_time_remaining()
	}

## Get crafting statistics
func get_statistics() -> Dictionary:
	return crafting_logic.get_crafting_stats()

## Simulate crafting result
func simulate_craft(config: WeaponConfiguration, player_level: int = 1) -> Dictionary:
	return crafting_logic.simulate_craft_result(config, player_level)

## Create test configuration for debugging
func create_test_config(weapon_type: String = "staff") -> WeaponConfiguration:
	return crafting_logic.create_test_configuration(weapon_type)

## Print crafting debug info
func debug_crafting_info(config: WeaponConfiguration) -> void:
	crafting_logic.debug_print_crafting_info(config)

# =============================================================================
# RECIPE MANAGEMENT
# =============================================================================

## Get all recipes
func get_all_recipes() -> Array[CraftingRecipe]:
	return recipe_manager.get_all_recipes()

## Get discovered recipes
func get_discovered_recipes() -> Array[CraftingRecipe]:
	return recipe_manager.get_discovered_recipes()

## Find matching recipes for configuration
func find_matching_recipes(config: WeaponConfiguration, player_level: int = 1) -> Array[CraftingRecipe]:
	return recipe_manager.find_matching_recipes(config, player_level)

## Get best recipe for configuration
func get_best_recipe(config: WeaponConfiguration, player_level: int = 1) -> CraftingRecipe:
	return recipe_manager.get_best_recipe(config, player_level)

## Get recipes by weapon type
func get_recipes_by_type(weapon_type: String) -> Array[CraftingRecipe]:
	return recipe_manager.get_recipes_by_type(weapon_type)

## Get recipes by rarity
func get_recipes_by_rarity(min_rarity: Enums.Rarity) -> Array[CraftingRecipe]:
	return recipe_manager.get_recipes_by_rarity(min_rarity)

# =============================================================================
# ACHIEVEMENT MANAGEMENT
# =============================================================================

## Get all achievements
func get_all_achievements() -> Array[CraftingAchievement]:
	return achievement_manager.get_all_achievements()

## Get unlocked achievements
func get_unlocked_achievements() -> Array[CraftingAchievement]:
	return achievement_manager.get_unlocked_achievements()

## Get locked achievements
func get_locked_achievements() -> Array[CraftingAchievement]:
	return achievement_manager.get_locked_achievements()

## Get achievements by rarity
func get_achievements_by_rarity(rarity: Enums.Rarity) -> Array[CraftingAchievement]:
	return achievement_manager.get_achievements_by_rarity(rarity)

## Get achievements by category
func get_achievements_by_category(category: String) -> Array[CraftingAchievement]:
	return achievement_manager.get_achievements_by_category(category)

## Get achievements player is close to completing
func get_near_completion_achievements(threshold: float = 0.8) -> Array[CraftingAchievement]:
	return achievement_manager.get_near_completion_achievements(threshold)

## Get achievement completion statistics
func get_achievement_stats() -> Dictionary:
	return achievement_manager.get_achievement_stats()

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_crafting_started(config: WeaponConfiguration) -> void:
	crafting_started.emit(config)

func _on_crafting_completed(weapon: ItemData, success: bool) -> void:
	crafting_completed.emit(weapon, success)

func _on_crafting_failed(error: String) -> void:
	crafting_failed.emit(error)

func _on_recipe_discovered(recipe: CraftingRecipe) -> void:
	recipe_discovered.emit(recipe)

func _on_achievement_unlocked(achievement: CraftingAchievement) -> void:
	achievement_unlocked.emit(achievement)

# =============================================================================
# UTILITY METHODS
# =============================================================================

## Reset all crafting data (for new game/debug)
func reset_all_data() -> void:
	recipe_manager.reset_discovered_recipes()
	achievement_manager.reset_all_achievements()

## Force save all crafting data
func save_data() -> void:
	recipe_manager._save_discovered_recipes()
	achievement_manager._save_achievement_progress()

## Load all crafting data
func load_data() -> void:
	recipe_manager._load_discovered_recipes()
	achievement_manager._load_achievement_progress()

## Validate configuration
func validate_configuration(config: WeaponConfiguration) -> Array[String]:
	return config.get_validation_errors()

## Get crafting difficulty modifiers
func get_difficulty_multipliers() -> Dictionary:
	return CraftingLogic.DIFFICULTY_MULTIPLIERS

## Check if crafting system is available
func is_available() -> bool:
	return crafting_logic != null and crafting_logic.enable_crafting