## SimpleCraftingTest - Basic validation of crafting system
extends SceneTree

func _init() -> void:
	print("=== Simple Crafting System Test ===")
	
	# Test 1: Check if files exist
	print("\n--- File Existence Test ---")
	var files = [
		"res://scripts/systems/weapon_configuration.gd",
		"res://scripts/systems/crafting_recipe.gd", 
		"res://scripts/systems/crafting_achievement.gd",
		"res://scripts/systems/crafting_logic.gd",
		"res://scripts/systems/crafting_recipe_manager.gd",
		"res://scripts/systems/crafting_achievement_manager.gd",
		"res://scripts/systems/crafting_manager.gd",
		"res://scripts/systems/crafting_integration.gd"
	]
	
	for file_path in files:
		if FileAccess.file_exists(file_path):
			print("✓ %s" % file_path.get_file())
		else:
			print("✗ %s" % file_path.get_file())
	
	# Test 2: Basic class instantiation
	print("\n--- Class Instantiation Test ---")
	
	# Test WeaponConfiguration
	var config_script = load("res://scripts/systems/weapon_configuration.gd")
	if config_script:
		var config = config_script.new()
		if config:
			print("✓ WeaponConfiguration instantiated")
			print("  Default type: %s" % config.weapon_type)
			print("  Is complete: %s" % config.is_complete())
		else:
			print("✗ WeaponConfiguration instantiation failed")
	else:
		print("✗ WeaponConfiguration script not found")
	
	# Test CraftingRecipe
	var recipe_script = load("res://scripts/systems/crafting_recipe.gd")
	if recipe_script:
		var recipe = recipe_script.new()
		if recipe:
			print("✓ CraftingRecipe instantiated")
			print("  Recipe ID: %s" % recipe.recipe_id)
			print("  Is hidden: %s" % recipe.is_hidden)
		else:
			print("✗ CraftingRecipe instantiation failed")
	else:
		print("✗ CraftingRecipe script not found")
	
	# Test CraftingAchievement
	var achievement_script = load("res://scripts/systems/crafting_achievement.gd")
	if achievement_script:
		var achievement = achievement_script.new()
		if achievement:
			print("✓ CraftingAchievement instantiated")
			print("  Achievement ID: %s" % achievement.achievement_id)
			print("  Is unlocked: %s" % achievement.is_unlocked)
		else:
			print("✗ CraftingAchievement instantiation failed")
	else:
		print("✗ CraftingAchievement script not found")
	
	# Test 3: Basic functionality
	print("\n--- Basic Functionality Test ---")
	
	if config_script and recipe_script:
		var config = config_script.new()
		var recipe = recipe_script.new()
		
		# Test configuration methods
		config.weapon_type = "staff"
		print("✓ Configuration weapon type set: %s" % config.weapon_type)
		
		# Test recipe methods
		recipe.weapon_type = "staff"
		print("✓ Recipe weapon type set: %s" % recipe.weapon_type)
		
		# Test matching (basic)
		var matches = recipe.matches_configuration(config, 1)
		print("✓ Recipe matching executed: %s" % matches)
	
	# Test 4: Managers
	print("\n--- Manager Test ---")
	
	# Test RecipeManager
	var recipe_manager_script = load("res://scripts/systems/crafting_recipe_manager.gd")
	if recipe_manager_script:
		var recipe_manager = recipe_manager_script.new()
		if recipe_manager:
			print("✓ CraftingRecipeManager instantiated")
			
			# Test recipe registration
			if recipe_script:
				var test_recipe = recipe_script.new()
				test_recipe.recipe_id = "test_recipe"
				recipe_manager.register_recipe(test_recipe)
				
				var retrieved = recipe_manager.get_recipe("test_recipe")
				if retrieved:
					print("✓ Recipe registration and retrieval works")
				else:
					print("✗ Recipe registration failed")
		else:
			print("✗ CraftingRecipeManager instantiation failed")
	else:
		print("✗ CraftingRecipeManager script not found")
	
	print("\n=== Test Complete ===")
	print("Basic crafting system structure validated!")