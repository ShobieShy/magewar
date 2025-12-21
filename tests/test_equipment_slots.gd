## Equipment Slot Validation Test
## Tests the drag-drop validation logic for equipment slots
extends SceneTree

func _init():
	print("=== EQUIPMENT SLOT VALIDATION TEST ===")

	# Test 1: Load equipment items
	print("\n1. Testing equipment item loading...")
	var hat = load("res://resources/items/equipment/apprentice_hat.tres")
	var robes = load("res://resources/items/equipment/apprentice_robes.tres")
	var belt = load("res://resources/items/equipment/apprentice_belt.tres")
	var shoes = load("res://resources/items/equipment/apprentice_shoes.tres")

	if hat and robes and belt and shoes:
		print("✅ All equipment items loaded")
	else:
		print("❌ Some equipment items failed to load")

	# Test 2: Test slot validation logic
	print("\n2. Testing slot validation logic...")

	var equipment_script = load("res://resources/items/equipment_data.gd")
	var enums = load("res://scripts/data/enums.gd")

	# Test HEAD slot validation
	if hat and hat.get_script() == equipment_script:
		var is_head_slot_valid = hat.slot == enums.EquipmentSlot.HEAD
		print("   Hat (slot ", hat.slot, ") for HEAD slot (", enums.EquipmentSlot.HEAD, "): ", "✅ Valid" if is_head_slot_valid else "❌ Invalid")

	# Test BODY slot validation
	if robes and robes.get_script() == equipment_script:
		var is_body_slot_valid = robes.slot == enums.EquipmentSlot.BODY
		print("   Robes (slot ", robes.slot, ") for BODY slot (", enums.EquipmentSlot.BODY, "): ", "✅ Valid" if is_body_slot_valid else "❌ Invalid")

	# Test BELT slot validation
	if belt and belt.get_script() == equipment_script:
		var is_belt_slot_valid = belt.slot == enums.EquipmentSlot.BELT
		print("   Belt (slot ", belt.slot, ") for BELT slot (", enums.EquipmentSlot.BELT, "): ", "✅ Valid" if is_belt_slot_valid else "❌ Invalid")

	# Test FEET slot validation
	if shoes and shoes.get_script() == equipment_script:
		var is_feet_slot_valid = shoes.slot == enums.EquipmentSlot.FEET
		print("   Shoes (slot ", shoes.slot, ") for FEET slot (", enums.EquipmentSlot.FEET, "): ", "✅ Valid" if is_feet_slot_valid else "❌ Invalid")

	# Test 3: Test drag-drop simulation
	print("\n3. Testing drag-drop simulation...")

	# Simulate what happens in ItemSlot._can_drop_data
	var test_results = []

	# Test HEAD slot
	var head_slot_type = enums.EquipmentSlot.HEAD
	var head_drop_valid = hat and hat.get_script() == equipment_script and hat.slot == head_slot_type
	test_results.append(["HEAD slot", head_drop_valid])

	# Test BODY slot
	var body_slot_type = enums.EquipmentSlot.BODY
	var body_drop_valid = robes and robes.get_script() == equipment_script and robes.slot == body_slot_type
	test_results.append(["BODY slot", body_drop_valid])

	# Test BELT slot
	var belt_slot_type = enums.EquipmentSlot.BELT
	var belt_drop_valid = belt and belt.get_script() == equipment_script and belt.slot == belt_slot_type
	test_results.append(["BELT slot", belt_drop_valid])

	# Test FEET slot
	var feet_slot_type = enums.EquipmentSlot.FEET
	var feet_drop_valid = shoes and shoes.get_script() == equipment_script and shoes.slot == feet_slot_type
	test_results.append(["FEET slot", feet_drop_valid])

	for result in test_results:
		var slot_name = result[0]
		var is_valid = result[1]
		print("   ", slot_name, ": ", "✅ Can drop" if is_valid else "❌ Cannot drop")

	print("\n=== VALIDATION TEST COMPLETE ===")
	quit()