## Test shop system: registration, buying, selling
extends Node

func _ready() -> void:
	print("========== SHOP SYSTEM TEST ==========")
	
	# Test 1: Load shop data resource
	print("\n1. Load town_shop resource")
	var town_shop = load("res://resources/shops/town_shop.tres")
	if not town_shop:
		print("✗ Failed to load town_shop.tres")
		get_tree().quit(1)
		return
	print("✓ Town shop loaded: ", town_shop.shop_id)
	
	# Test 2: Verify shop properties
	print("\n2. Verify shop data structure")
	print("  Shop name: ", town_shop.shop_name)
	print("  Shop ID: ", town_shop.shop_id)
	print("  Shop keeper: ", town_shop.shop_keeper_name)
	print("  Item pool size: ", town_shop.item_pool.size())
	
	# Test 3: Generate stock
	print("\n3. Generate stock from item pool")
	town_shop.generate_stock()
	print("  Stock size: ", town_shop.current_stock.size())
	if town_shop.current_stock.size() > 0:
		print("✓ Stock generated successfully")
		var first_item = town_shop.current_stock[0]
		print("  First item: ", first_item.item.item_name)
		print("  Price: ", first_item.price, " gold")
		print("  Quantity: ", first_item.quantity)
	else:
		print("✗ No stock generated")
		get_tree().quit(1)
		return
	
	# Test 4: Test selling mechanics
	print("\n4. Test selling mechanics")
	SaveManager.set_gold(1000)
	print("  Starting gold: ", SaveManager.get_gold())
	
	# Create a test item to sell
	var potion = load("res://resources/items/potions/health_potion.tres")
	if potion:
		var sell_result = town_shop.sell_item(potion, 1)
		if sell_result.success:
			print("✓ Item sold successfully")
			print("  Gold earned: ", sell_result.gold_earned)
			print("  New total gold: ", SaveManager.get_gold())
		else:
			print("✗ Failed to sell item")
			get_tree().quit(1)
			return
	
	# Test 5: Test buying mechanics
	print("\n5. Test buying mechanics")
	SaveManager.set_gold(5000)
	print("  Starting gold: ", SaveManager.get_gold())
	
	if town_shop.current_stock.size() > 0:
		var buy_result = town_shop.buy_item(0, 1)
		if buy_result.success:
			print("✓ Item bought successfully")
			print("  Item: ", buy_result.item.item_name)
			print("  Cost: ", buy_result.total_cost, " gold")
			print("  Remaining gold: ", SaveManager.get_gold())
		else:
			print("✗ Failed to buy item: ", buy_result)
			get_tree().quit(1)
			return
	
	# Test 6: Load shopkeeper NPC scene
	print("\n6. Load shopkeeper NPC scene")
	var shopkeeper_scene = load("res://scenes/main/shopkeeper.tscn")
	if shopkeeper_scene:
		print("✓ Shopkeeper scene loaded")
		var shopkeeper = shopkeeper_scene.instantiate()
		print("  NPC name: ", shopkeeper.npc_name)
		print("  Shop ID: ", shopkeeper.shop_id)
	else:
		print("✗ Failed to load shopkeeper scene")
		get_tree().quit(1)
		return
	
	# Test 7: Load vendor NPC script
	print("\n7. Verify vendor NPC script")
	var vendor_script = load("res://scenes/world/starting_town/vendor_npc.gd")
	if vendor_script:
		print("✓ Vendor NPC script loaded")
	else:
		print("✗ Failed to load vendor NPC script")
		get_tree().quit(1)
		return
	
	print("\n========== ALL TESTS PASSED ==========")
	get_tree().quit(0)
