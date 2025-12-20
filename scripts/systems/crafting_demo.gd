## CraftingDemo - Demonstrates the complete crafting system
## Shows how to create, configure, and craft weapons
extends Node

# Reference to crafting manager
var crafting_manager: CraftingManager

func _ready() -> void:
	print("=== Crafting System Demo ===")
	
	# Get crafting manager
	crafting_manager = get_node_or_null("/root/CraftingManager")
	if not crafting_manager:
		crafting_manager = CraftingManager.new()
		get_tree().root.add_child(crafting_manager)
	
	# Run demonstrations
	await get_tree().create_timer(1.0).timeout
	_demo_basic_configuration()
	
	await get_tree().create_timer(2.0).timeout
	_demo_recipe_discovery()
	
	await get_tree().create_timer(2.0).timeout
	_demo_achievement_system()
	
	await get_tree().create_timer(2.0).timeout
	_demo_crafting_process()
	
	print("=== Demo Complete ===")

func _demo_basic_configuration() -> void:
	print("\n--- Basic Configuration Demo ---")
	
	# Create a basic staff configuration
	var config = WeaponConfiguration.new()
	config.weapon_type = "staff"
	config.weapon_rarity = Enums.Rarity.UNCOMMON
	
	# Add parts (these would normally come from inventory/database)
	var head = StaffPartData.new()
	head.item_id = "oak_staff_head"
	head.item_name = "Oak Staff Head"
	head.part_type = Enums.StaffPart.HEAD
	head.part_level = 5
	head.rarity = Enums.Rarity.UNCOMMON
	head.gem_slots = 2
	
	var exterior = StaffPartData.new()
	exterior.item_id = "reinforced_exterior"
	exterior.item_name = "Reinforced Exterior"
	exterior.part_type = Enums.StaffPart.EXTERIOR
	exterior.part_level = 4
	exterior.rarity = Enums.Rarity.UNCOMMON
	exterior.fire_rate_modifier = 0.1  # 10% faster
	
	var interior = StaffPartData.new()
	interior.item_id = "enchanted_interior"
	interior.item_name = "Enchanted Interior"
	interior.part_type = Enums.StaffPart.INTERIOR
	interior.part_level = 6
	interior.rarity = Enums.Rarity.RARE
	interior.damage_modifier = 0.15  # 15% more damage
	
	var handle = StaffPartData.new()
	handle.item_id = "sturdy_handle"
	handle.item_name = "Sturdy Handle"
	handle.part_type = Enums.StaffPart.HANDLE
	handle.part_level = 3
	handle.rarity = Enums.Rarity.BASIC
	handle.handling = 5.0
	handle.stability = 3.0
	
	# Add parts to configuration
	config.add_part(head)
	config.add_part(exterior)
	config.add_part(interior)
	config.add_part(handle)
	
	# Add gems
	var fire_gem = GemData.new()
	fire_gem.item_id = "ruby_gem"
	fire_gem.item_name = "Ruby"
	fire_gem.rarity = Enums.Rarity.UNCOMMON
	fire_gem.element = Enums.Element.FIRE
	fire_gem.damage_multiplier = 1.2  # 20% more damage
	fire_gem.converts_element = true
	
	var ice_gem = GemData.new()
	ice_gem.item_id = "sapphire_gem"
	ice_gem.item_name = "Sapphire"
	ice_gem.rarity = Enums.Rarity.RARE
	ice_gem.element = Enums.Element.ICE
	ice_gem.damage_multiplier = 1.1
	ice_gem.cost_multiplier = 0.9  # 10% cheaper
	ice_gem.projectile_speed_multiplier = 0.8  # slower projectiles
	
	config.add_gem(fire_gem)
	config.add_gem(ice_gem)
	
	# Show configuration details
	print("Weapon Type: %s" % config.weapon_type)
	print("Weapon Name: %s" % config.generate_weapon_name())
	print("Weapon Level: %d" % config.weapon_level)
	print("Weapon Rarity: %s" % Enums.Rarity.keys()[config.weapon_rarity])
	print("Total Parts: %d" % config.get_total_part_count())
	print("Total Gems: %d" % config.gems.size())
	print("Success Chance: %.1f%%" % (config.success_chance * 100))
	print("Craft Time: %.1fs" % config.craft_time)
	print("Craft Cost: %d gold" % config.craft_cost)
	
	print("\nWeapon Stats:")
	for key in config.stats:
		print("  %s: %s" % [key, config.stats[key]])
	
	print("\nIs Complete: %s" % config.is_complete())

func _demo_recipe_discovery() -> void:
	print("\n--- Recipe Discovery Demo ---")
	
	# Get all recipes
	var all_recipes = crafting_manager.get_all_recipes()
	print("Total Recipes: %d" % all_recipes.size())
	
	# Get discovered recipes
	var discovered = crafting_manager.get_discovered_recipes()
	print("Discovered Recipes: %d" % discovered.size())
	
	# Create a test configuration to find matching recipes
	var config = crafting_manager.create_test_config("staff")
	
	# Find matching recipes
	var matching = crafting_manager.find_matching_recipes(config, 5)
	print("Matching Recipes: %d" % matching.size())
	
	for recipe in matching:
		print("  - %s (Rarity: %s)" % [recipe.recipe_name, Enums.Rarity.keys()[recipe.result_rarity]])
		if recipe.is_hidden:
			print("    Not yet discovered")
		else:
			print("    Already discovered")

func _demo_achievement_system() -> void:
	print("\n--- Achievement System Demo ---")
	
	# Get achievement statistics
	var stats = crafting_manager.get_achievement_stats()
	print("Total Achievements: %d" % stats.total_achievements)
	print("Unlocked Achievements: %d" % stats.unlocked_achievements)
	print("Completion Rate: %.1f%%" % stats.completion_rate)
	
	# Get achievements by category
	var quantity_achievements = crafting_manager.get_achievements_by_category("quantity")
	print("Quantity Achievements: %d" % quantity_achievements.size())
	
	# Get near completion achievements
	var near_completion = crafting_manager.get_near_completion_achievements(0.5)
	print("Near Completion (50%%+): %d" % near_completion.size())
	
	for achievement in near_completion:
		print("  - %s (%.1f%%)" % [achievement.achievement_name, achievement.get_progress_percentage()])

func _demo_crafting_process() -> void:
	print("\n--- Crafting Process Demo ---")
	
	# Create a configuration
	var config = crafting_manager.create_test_config("wand")
	
	# Simulate crafting
	var result = crafting_manager.simulate_craft(config, 10)  # Level 10 player
	print("Simulation Result:")
	print("  Success: %s" % result.success)
	print("  Success Chance: %.1f%%" % (result.success_chance * 100))
	print("  Craft Time: %.1fs" % result.craft_time)
	print("  Craft Cost: %d gold" % result.craft_cost)
	
	# Show crafting status
	var status = crafting_manager.get_crafting_status()
	print("\nCurrent Status:")
	print("  Is Crafting: %s" % status.is_crafting)
	print("  Progress: %.1f%%" % (status.progress * 100))
	print("  Time Remaining: %.1fs" % status.time_remaining)
	
	# Get full statistics
	var full_stats = crafting_manager.get_statistics()
	print("\nFull Statistics:")
	print("  Recipe Discoveries: %d" % full_stats.recipe_stats.recipes_discovered)
	print("  Successful Crafts: %d" % full_stats.recipe_stats.successful_crafts)
	print("  Total Weapons Crafted: %d" % full_stats.achievement_stats.total_weapons_crafted)

func _input(event: InputEvent) -> void:
	# Demo controls
	if event.is_action_pressed("ui_accept"):  # Enter key
		print("\n--- Manual Demo Trigger ---")
		_demo_manual_crafting()

func _demo_manual_crafting() -> void:
	# Create random configuration for manual testing
	var config = WeaponConfiguration.new()
	config.weapon_type = "staff" if randf() > 0.5 else "wand"
	config.weapon_rarity = [Enums.Rarity.BASIC, Enums.Rarity.UNCOMMON, Enums.Rarity.RARE].pick_random()
	
	# Add random parts
	var part_types = [Enums.StaffPart.HEAD, Enums.StaffPart.EXTERIOR, Enums.StaffPart.INTERIOR, Enums.StaffPart.HANDLE]
	for part_type in part_types:
		if config.weapon_type == "wand" and part_type == Enums.StaffPart.INTERIOR:
			continue  # Wands don't use interior parts
		
		var part = StaffPartData.new()
		part.item_id = "test_part_" + Enums.StaffPart.keys()[part_type].to_lower()
		part.item_name = "Test " + Enums.StaffPart.keys()[part_type]
		part.part_type = part_type
		part.part_level = randi_range(1, 10)
		part.rarity = config.weapon_rarity
		
		config.add_part(part)
	
	# Add random gems
	var gem_count = randi_range(1, 2)
	for i in gem_count:
		var gem = GemData.new()
		gem.item_id = "test_gem_" + str(i)
		gem.item_name = "Test Gem " + str(i)
		gem.rarity = Enums.Rarity.BASIC
		gem.damage_multiplier = 1.0 + randf() * 0.3
		
		config.add_gem(gem)
	
	print("Created random configuration:")
	crafting_manager.debug_crafting_info(config)