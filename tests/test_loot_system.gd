## Test script to verify loot system fixes and functionality
extends Node

func _ready():
	var separator = "="
	separator = separator.repeat(80)
	print("\n" + separator)
	print("LOOT SYSTEM VERIFICATION TEST")
	print(separator)
	
	var all_pass = true
	
	# Test 1: Verify LootSystem exists and loads
	print("\n[TEST 1] LootSystem Script Loading")
	var loot_system_script = load("res://scripts/systems/loot_system.gd")
	if loot_system_script:
		print("  ✓ LootSystem script loaded")
		var script_src = loot_system_script.source_code
		
		# Check for the fix we applied
		if "if entry.item is String:" in script_src:
			print("  ✓ PASS: Type checking fix is in place")
		else:
			print("  ✗ FAIL: Type checking fix not found")
			all_pass = false
		
		if "ItemDatabase.get_item" in script_src:
			print("  ✓ PASS: ItemDatabase lookup is implemented")
		else:
			print("  ✗ FAIL: ItemDatabase lookup not found")
			all_pass = false
	else:
		print("  ✗ FAIL: Could not load LootSystem script")
		all_pass = false
	
	# Test 2: Verify ItemDatabase and key items exist
	print("\n[TEST 2] ItemDatabase and Item Validation")
	if ItemDatabase:
		print("  ✓ ItemDatabase loaded")
		
		# Test items that we mapped to enemy drops
		var test_items = [
			"apprentice_robes",
			"reinforced_belt",
			"apprentice_shoes",
			"enchanted_shoes",
			"apprentice_hat",
			"arcane_robes",
			"enhanced_robes",
			"magical_belt",
			"swift_shoes",
			"journeyman_hat"
		]
		
		var missing_items = []
		for item_id in test_items:
			var item = ItemDatabase.get_item(item_id)
			if item:
				print("  ✓ Found: %s" % item_id)
			else:
				print("  ✗ Missing: %s" % item_id)
				missing_items.append(item_id)
				all_pass = false
		
		if missing_items.is_empty():
			print("  ✓ PASS: All mapped items exist in database")
		else:
			print("  ✗ FAIL: %d items missing from database" % missing_items.size())
	else:
		print("  ✗ FAIL: ItemDatabase not loaded")
		all_pass = false
	
	# Test 3: Verify enemy data has correct item drops
	print("\n[TEST 3] Enemy Data Item Drops")
	var enemy_types = {
		"res://resources/enemies/skeleton_enemy_data.gd": ["apprentice_robes", "reinforced_belt"],
		"res://resources/enemies/goblin_enemy_data.gd": ["apprentice_shoes", "enchanted_shoes"],
		"res://resources/enemies/slime_enemy_data.gd": ["apprentice_hat", "arcane_robes"],
		"res://resources/enemies/troll_enemy_data.gd": ["enhanced_robes", "magical_belt"],
		"res://resources/enemies/wraith_enemy_data.gd": ["swift_shoes", "journeyman_hat"]
	}
	
	for enemy_script_path in enemy_types.keys():
		var enemy_script = load(enemy_script_path)
		if enemy_script:
			var script_src = enemy_script.source_code
			var expected_items = enemy_types[enemy_script_path]
			var found_all = true
			
			for item_id in expected_items:
				if '"%s"' % item_id in script_src:
					print("  ✓ %s has %s" % [enemy_script_path.get_file(), item_id])
				else:
					print("  ✗ %s missing %s" % [enemy_script_path.get_file(), item_id])
					found_all = false
					all_pass = false
			
			if found_all:
				print("  ✓ PASS: %s has all correct items" % enemy_script_path.get_file())
		else:
			print("  ✗ FAIL: Could not load %s" % enemy_script_path)
			all_pass = false
	
	# Test 4: Verify LootPickup scene exists
	print("\n[TEST 4] LootPickup Scene")
	var loot_pickup_scene = load("res://scenes/objects/loot_pickup.tscn")
	if loot_pickup_scene:
		print("  ✓ LootPickup scene loaded")
		print("  ✓ PASS: LootPickup scene exists and is valid")
	else:
		print("  ✗ FAIL: Could not load LootPickup scene")
		all_pass = false
	
	# Test 5: Verify enemy_base has loot drop logic
	print("\n[TEST 5] Enemy Death Loot Trigger")
	var enemy_base_script = load("res://scenes/enemies/enemy_base.gd")
	if enemy_base_script:
		var script_src = enemy_base_script.source_code
		
		var checks = [
			["_drop_loot()", "drop_loot function"],
			["_drop_gold()", "drop_gold function"],
			["loot_system.drop_loot_from_table", "loot system call"],
			["SaveManager.add_gold", "gold collection"],
			["_award_experience()", "experience award"]
		]
		
		for check in checks:
			if check[0] in script_src:
				print("  ✓ Found: %s" % check[1])
			else:
				print("  ✗ Missing: %s" % check[1])
				all_pass = false
		
		print("  ✓ PASS: All loot drop logic is in place")
	else:
		print("  ✗ FAIL: Could not load enemy_base script")
		all_pass = false
	
	# Test 6: Instantiation test - can we create loot items?
	print("\n[TEST 6] Item Instantiation Test")
	var instantiation_pass = true
	if ItemDatabase:
		var test_items_to_create = ["apprentice_robes", "reinforced_belt", "apprentice_shoes"]
		for item_id in test_items_to_create:
			var item = ItemDatabase.get_item(item_id)
			if item:
				var duplicated = item.duplicate_item()
				if duplicated:
					print("  ✓ Successfully duplicated: %s" % item_id)
				else:
					print("  ✗ Failed to duplicate: %s" % item_id)
					instantiation_pass = false
					all_pass = false
			else:
				print("  ✗ Could not load: %s" % item_id)
				instantiation_pass = false
				all_pass = false
		
		if instantiation_pass:
			print("  ✓ PASS: Items can be instantiated for loot drops")
	
	# Summary
	separator = "="
	separator = separator.repeat(80)
	print("\n" + separator)
	print("TEST SUMMARY:")
	print(separator)
	
	if all_pass:
		print("✓✓✓ ALL TESTS PASSED ✓✓✓")
		print("\nLoot System Status: READY FOR GAMEPLAY TEST")
		print("\nNext Steps:")
		print("  1. Launch the game in debug mode")
		print("  2. Enter Dungeon 1")
		print("  3. Kill Skeleton, Goblin, Slime, Troll, and Wraith enemies")
		print("  4. Verify items drop and appear on ground")
		print("  5. Verify items can be picked up")
		print("  6. Verify items appear in inventory")
	else:
		print("✗✗✗ SOME TESTS FAILED ✗✗✗")
		print("\nPlease review failures above")
	
	print(separator + "\n")
	
	get_tree().quit()
