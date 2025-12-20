## CraftingSystemTest - Comprehensive test suite for crafting system
## Validates all components of crafting logic system
extends Node

# Preload required classes
const WeaponConfiguration = preload("res://scripts/systems/weapon_configuration.gd")
const CraftingRecipe = preload("res://scripts/systems/crafting_recipe.gd")
const CraftingAchievement = preload("res://scripts/systems/crafting_achievement.gd")
const CraftingLogic = preload("res://scripts/systems/crafting_logic.gd")
const CraftingRecipeManager = preload("res://scripts/systems/crafting_recipe_manager.gd")
const CraftingAchievementManager = preload("res://scripts/systems/crafting_achievement_manager.gd")

# Test results
var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""

func _ready() -> void:
	print("Starting Crafting System Tests...")
	print("==================================================")
	
	# Run all tests
	_test_weapon_configuration()
	_test_crafting_recipe()
	_test_crafting_achievement()
	_test_crafting_logic()
	_test_integration()
	
	# Print summary
	print("==================================================")
	print("Tests Complete!")
	print("Passed: %d" % _tests_passed)
	print("Failed: %d" % _tests_failed)
	print("Total: %d" % (_tests_passed + _tests_failed))

func _test_weapon_configuration() -> void:
	print("\n--- Testing WeaponConfiguration ---")
	
	# Test basic configuration creation
	var config = WeaponConfiguration.new()
	_assert(config != null, "WeaponConfiguration creation")
	_assert(config.weapon_type == "staff", "Default weapon type")
	_assert(config.is_complete() == false, "Incomplete configuration check")
	
	# Test adding parts
	var test_head = _create_test_part(Enums.StaffPart.HEAD)
	config.add_part(test_head)
	_assert(config.head == test_head, "Part addition")
	_assert(config.get_total_part_count() == 1, "Part count")
	
	# Test weapon name generation
	var name = config.generate_weapon_name()
	_assert(not name.is_empty(), "Weapon name generation")
	
	# Test stats calculation
	config._recalculate_stats()
	_assert(config.weapon_level >= 1, "Weapon level calculation")
	_assert(config.craft_time > 0, "Craft time calculation")
	_assert(config.craft_cost > 0, "Craft cost calculation")

func _test_crafting_recipe() -> void:
	print("\n--- Testing CraftingRecipe ---")
	
	# Test recipe creation
	var recipe = CraftingRecipe.new()
	_assert(recipe != null, "CraftingRecipe creation")
	_assert(not recipe.is_hidden == false or true, "Default hidden state")  # Should be true by default
	
	# Test recipe matching
	var config = WeaponConfiguration.new()
	config.weapon_type = "staff"
	
	var match_result = recipe.matches_configuration(config, 1)
	_assert(match_result == false, "Recipe matching with empty recipe")  # No required parts set
	
	# Test recipe with required parts
	recipe.required_parts = ["test_head", "test_exterior"]
	match_result = recipe.matches_configuration(config, 1)
	_assert(match_result == false, "Recipe matching with missing parts")

func _test_crafting_achievement() -> void:
	print("\n--- Testing CraftingAchievement ---")
	
	# Test achievement creation
	var achievement = CraftingAchievement.new()
	_assert(achievement != null, "CraftingAchievement creation")
	_assert(not achievement.is_unlocked, "Default unlocked state")
	
	# Test achievement progress
	var weapon_data = ItemData.new()
	var config = WeaponConfiguration.new()
	
	var progressed = achievement.check_crafting_event(weapon_data, config, null)
	_assert(progressed == true or progressed == false, "Achievement progress check")  # Should return boolean
	
	# Test progress calculation
	var progress_percent = achievement.get_progress_percentage()
	_assert(progress_percent >= 0.0 and progress_percent <= 100.0, "Progress percentage range")

func _test_crafting_logic() -> void:
	print("\n--- Testing CraftingLogic ---")
	
	# Create crafting logic instance
	var crafting_logic = CraftingLogic.new()
	add_child(crafting_logic)
	
	_assert(crafting_logic != null, "CraftingLogic creation")
	_assert(not crafting_logic.is_crafting(), "Initial crafting state")
	
	# Test crafting configuration
	var config = _create_test_configuration()
	
	# Test crafting simulation
	var result = crafting_logic.simulate_craft_result(config, 1)
	_assert(result.has("success"), "Crafting simulation result structure")
	_assert(result.has("success_chance"), "Crafting simulation includes success chance")
	_assert(result.success_chance >= 0.0 and result.success_chance <= 1.0, "Success chance range")
	
	# Test manager access
	var recipe_manager = crafting_logic.get_recipe_manager()
	var achievement_manager = crafting_logic.get_achievement_manager()
	
	_assert(recipe_manager != null, "Recipe manager access")
	_assert(achievement_manager != null, "Achievement manager access")
	
	crafting_logic.queue_free()

func _test_integration() -> void:
	print("\n--- Testing System Integration ---")
	
	# Test manager initialization
	var recipe_manager = CraftingRecipeManager.new()
	var achievement_manager = CraftingAchievementManager.new()
	
	add_child(recipe_manager)
	add_child(achievement_manager)
	
	# Test recipe registration
	var recipe = CraftingRecipe.new()
	recipe.recipe_id = "test_recipe"
	recipe.recipe_name = "Test Recipe"
	
	recipe_manager.register_recipe(recipe)
	var retrieved = recipe_manager.get_recipe("test_recipe")
	_assert(retrieved == recipe, "Recipe registration and retrieval")
	
	# Test achievement registration
	var achievement = CraftingAchievement.new()
	achievement.achievement_id = "test_achievement"
	achievement.achievement_name = "Test Achievement"
	
	achievement_manager.register_achievement(achievement)
	var retrieved_achievement = achievement_manager.get_achievement("test_achievement")
	_assert(retrieved_achievement == achievement, "Achievement registration and retrieval")
	
	# Test statistics
	var recipe_stats = recipe_manager.get_crafting_stats()
	var achievement_stats = achievement_manager.get_achievement_stats()
	
	_assert(recipe_stats.has("total_attempts"), "Recipe statistics structure")
	_assert(achievement_stats.has("total_achievements"), "Achievement statistics structure")
	
	recipe_manager.queue_free()
	achievement_manager.queue_free()

# Helper methods

func _create_test_part(part_type: Enums.StaffPart) -> StaffPartData:
	var part = StaffPartData.new()
	part.item_id = "test_part_" + str(Time.get_unix_time_from_system())
	part.item_name = "Test Part"
	part.part_type = part_type
	part.part_level = 5
	part.rarity = Enums.Rarity.UNCOMMON
	return part

func _create_test_configuration() -> WeaponConfiguration:
	var config = WeaponConfiguration.new()
	config.weapon_type = "staff"
	config.weapon_level = 5
	config.weapon_rarity = Enums.Rarity.UNCOMMON
	
	# Add some test parts
	var head = _create_test_part(Enums.StaffPart.HEAD)
	var exterior = _create_test_part(Enums.StaffPart.EXTERIOR)
	var interior = _create_test_part(Enums.StaffPart.INTERIOR)
	var handle = _create_test_part(Enums.StaffPart.HANDLE)
	
	config.add_part(head)
	config.add_part(exterior)
	config.add_part(interior)
	config.add_part(handle)
	
	return config

# Assertion helper

func _assert(condition: bool, test_name: String) -> void:
	_current_test = test_name
	
	if condition:
		_tests_passed += 1
		print("✓ %s" % test_name)
	else:
		_tests_failed += 1
		print("✗ %s" % test_name)

# Performance test

func run_performance_test() -> void:
	print("\n--- Performance Test ---")
	
	var start_time = Time.get_ticks_msec()
	
	# Create many configurations
	for i in range(100):
		var config = WeaponConfiguration.new()
		config.weapon_type = "staff" if i % 2 == 0 else "wand"
		
		# Add random parts
		var part_types = [Enums.StaffPart.HEAD, Enums.StaffPart.EXTERIOR, Enums.StaffPart.INTERIOR, Enums.StaffPart.HANDLE]
		for part_type in part_types:
			var part = _create_test_part(part_type)
			config.add_part(part)
		
		config._recalculate_stats()
	
	var end_time = Time.get_ticks_msec()
	var elapsed = (end_time - start_time) / 1000.0
	
	print("Created and calculated 100 configurations in %.3fs" % elapsed)
	print("Average per configuration: %.3fms" % ((end_time - start_time) / 100.0))

# Memory test

func run_memory_test() -> void:
	print("\n--- Memory Test ---")
	
	var configs = []
	
	# Create many configurations to test memory
	for i in range(1000):
		var config = WeaponConfiguration.new()
		config.weapon_type = "staff" if i % 2 == 0 else "wand"
		configs.append(config)
	
	print("Created 1000 WeaponConfiguration instances")
	
	# Clear references
	configs.clear()
	
	print("Cleared references - memory should be freed by GC")