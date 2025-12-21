## Equipment System Test
## Tests equipment item loading and validation
extends SceneTree

func _init():
	print("=== EQUIPMENT SYSTEM TEST ===")

	# Test 1: Load equipment items
	print("\n1. Testing equipment item loading...")
	var hat = load("res://resources/items/equipment/apprentice_hat.tres")
	var robes = load("res://resources/items/equipment/apprentice_robes.tres")

	if hat and robes:
		print("✅ Equipment items loaded successfully")
		print("   Hat slot:", hat.slot, "(should be 1 = HEAD)")
		print("   Robes slot:", robes.slot, "(should be 2 = BODY)")
	else:
		print("❌ Failed to load equipment items")

	# Test 2: Check EquipmentData class
	print("\n2. Testing EquipmentData class...")
	var equipment_script = load("res://resources/items/equipment_data.gd")
	if hat and hat.get_script() == equipment_script:
		print("✅ Hat is EquipmentData")
		print("   Magika bonus:", hat.magika_bonus)
		print("   Magika regen:", hat.magika_regen_bonus)
	else:
		print("❌ Hat is not EquipmentData")
		print("   Hat script:", hat.get_script() if hat else "null")
		print("   Equipment script:", equipment_script)

	if robes and robes.get_script() == equipment_script:
		print("✅ Robes is EquipmentData")
		print("   Health bonus:", robes.health_bonus)
		print("   Defense bonus:", robes.defense_bonus)
	else:
		print("❌ Robes is not EquipmentData")
		print("   Robes script:", robes.get_script() if robes else "null")

	# Test 3: Check enums
	print("\n3. Testing enum values...")
	var enums = preload("res://scripts/data/enums.gd")
	print("   EquipmentSlot.HEAD =", enums.EquipmentSlot.HEAD, "(should be 1)")
	print("   EquipmentSlot.BODY =", enums.EquipmentSlot.BODY, "(should be 2)")
	print("   EquipmentSlot.BELT =", enums.EquipmentSlot.BELT, "(should be 3)")
	print("   EquipmentSlot.FEET =", enums.EquipmentSlot.FEET, "(should be 4)")

	print("\n=== TEST COMPLETE ===")
	quit()