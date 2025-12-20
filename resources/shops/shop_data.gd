## ShopData - Definition of a shop's inventory and pricing
## Supports rotating stock, rarity-weighted items, and categories
class_name ShopData
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Shop Info")
@export var shop_id: String = ""
@export var shop_name: String = "Shop"
@export var shop_description: String = ""
@export var shop_keeper_name: String = "Merchant"

@export_group("Stock Configuration")
@export var item_pool: Array[ItemData] = []  ## All possible items this shop can sell
@export var stock_size: int = 12  ## How many items to show at once
@export var refresh_on_load: bool = true  ## Rotate stock on map load

@export_group("Rarity Weights")
## Higher weight = more likely to appear in stock
@export var basic_weight: float = 100.0
@export var uncommon_weight: float = 50.0
@export var rare_weight: float = 20.0
@export var mythic_weight: float = 5.0
@export var primordial_weight: float = 1.0
@export var unique_weight: float = 0.0  ## Usually 0 - unique items are special

@export_group("Pricing")
@export var buy_price_multiplier: float = 1.0  ## Multiply item value for buy price
@export var sell_price_multiplier: float = 0.5  ## Player sells at this rate

@export_group("Categories")
@export var allowed_item_types: Array[Enums.ItemType] = []  ## Empty = all types
@export var specialty_element: Enums.Element = Enums.Element.NONE  ## Bonus for this element

# =============================================================================
# RUNTIME STATE
# =============================================================================

var current_stock: Array[Dictionary] = []  ## [{item: ItemData, price: int, quantity: int}]
var buyback_items: Array[Dictionary] = []  ## Items player has sold

# =============================================================================
# METHODS
# =============================================================================

func generate_stock() -> void:
	## Generate new random stock from item pool
	current_stock.clear()
	
	if item_pool.is_empty():
		return
	
	# Build weighted item list
	var weighted_items: Array[Dictionary] = []
	for item in item_pool:
		# Check item type filter
		if not allowed_item_types.is_empty():
			if item.item_type not in allowed_item_types:
				continue
		
		var weight = _get_rarity_weight(item.rarity)
		if weight > 0:
			weighted_items.append({"item": item, "weight": weight})
	
	# Select random items up to stock_size
	var selected_items: Array[ItemData] = []
	var attempts = 0
	var max_attempts = stock_size * 3
	
	while selected_items.size() < stock_size and attempts < max_attempts:
		var item = _weighted_random_select(weighted_items)
		if item and item not in selected_items:
			selected_items.append(item)
		attempts += 1
	
	# Create stock entries
	for item in selected_items:
		var entry = {
			"item": item,
			"price": _calculate_buy_price(item),
			"quantity": _determine_quantity(item)
		}
		current_stock.append(entry)


func _get_rarity_weight(rarity: Enums.Rarity) -> float:
	match rarity:
		Enums.Rarity.BASIC:
			return basic_weight
		Enums.Rarity.UNCOMMON:
			return uncommon_weight
		Enums.Rarity.RARE:
			return rare_weight
		Enums.Rarity.MYTHIC:
			return mythic_weight
		Enums.Rarity.PRIMORDIAL:
			return primordial_weight
		Enums.Rarity.UNIQUE:
			return unique_weight
	return 0.0


func _weighted_random_select(weighted_items: Array[Dictionary]) -> ItemData:
	if weighted_items.is_empty():
		return null
	
	var total_weight = 0.0
	for entry in weighted_items:
		total_weight += entry.weight
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for entry in weighted_items:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry.item
	
	return weighted_items[-1].item


func _calculate_buy_price(item: ItemData) -> int:
	var base_price = item.get_value()
	return int(base_price * buy_price_multiplier)


func _determine_quantity(item: ItemData) -> int:
	## Consumables can have multiple, equipment is 1
	if item.stackable:
		# Random quantity based on rarity
		match item.rarity:
			Enums.Rarity.BASIC:
				return randi_range(3, 10)
			Enums.Rarity.UNCOMMON:
				return randi_range(2, 5)
			Enums.Rarity.RARE:
				return randi_range(1, 3)
			_:
				return 1
	return 1


func get_sell_price(item: ItemData) -> int:
	var base_price = item.get_value()
	return int(base_price * sell_price_multiplier)

# =============================================================================
# TRANSACTION METHODS
# =============================================================================

func buy_item(index: int, quantity: int = 1) -> Dictionary:
	## Returns {success: bool, item: ItemData, total_cost: int}
	if index < 0 or index >= current_stock.size():
		return {"success": false, "item": null, "total_cost": 0}
	
	var stock_entry = current_stock[index]
	var item = stock_entry.item
	var price = stock_entry.price
	var available = stock_entry.quantity
	
	# Check quantity
	var buy_quantity = min(quantity, available)
	if buy_quantity <= 0:
		return {"success": false, "item": null, "total_cost": 0}
	
	var total_cost = price * buy_quantity
	
	# Check if player can afford
	if not SaveManager.has_gold(total_cost):
		return {"success": false, "item": item, "total_cost": total_cost}
	
	# Process transaction
	SaveManager.remove_gold(total_cost)
	stock_entry.quantity -= buy_quantity
	
	# Remove from stock if depleted
	if stock_entry.quantity <= 0:
		current_stock.remove_at(index)
	
	return {
		"success": true,
		"item": item,
		"quantity": buy_quantity,
		"total_cost": total_cost
	}


func sell_item(item: ItemData, quantity: int = 1) -> Dictionary:
	## Returns {success: bool, gold_earned: int}
	var price_per_item = get_sell_price(item)
	var total_gold = price_per_item * quantity
	
	# Add gold to player
	SaveManager.add_gold(total_gold)
	
	# Add to buyback
	_add_to_buyback(item, quantity, price_per_item)
	
	return {
		"success": true,
		"gold_earned": total_gold
	}


func _add_to_buyback(item: ItemData, quantity: int, price: int) -> void:
	# Check if item already in buyback
	for entry in buyback_items:
		if entry.item.item_id == item.item_id:
			entry.quantity += quantity
			return
	
	# Add new entry (buyback at sell price, not buy price)
	buyback_items.append({
		"item": item,
		"price": price,  # Same price they sold for
		"quantity": quantity
	})
	
	# Limit buyback size
	while buyback_items.size() > 20:
		buyback_items.pop_front()


func buyback_item(index: int, quantity: int = 1) -> Dictionary:
	## Buy back a previously sold item
	if index < 0 or index >= buyback_items.size():
		return {"success": false, "item": null, "total_cost": 0}
	
	var entry = buyback_items[index]
	var item = entry.item
	var price = entry.price
	var available = entry.quantity
	
	var buy_quantity = min(quantity, available)
	if buy_quantity <= 0:
		return {"success": false, "item": null, "total_cost": 0}
	
	var total_cost = price * buy_quantity
	
	if not SaveManager.has_gold(total_cost):
		return {"success": false, "item": item, "total_cost": total_cost}
	
	SaveManager.remove_gold(total_cost)
	entry.quantity -= buy_quantity
	
	if entry.quantity <= 0:
		buyback_items.remove_at(index)
	
	return {
		"success": true,
		"item": item,
		"quantity": buy_quantity,
		"total_cost": total_cost
	}

# =============================================================================
# QUERY METHODS
# =============================================================================

func get_stock() -> Array[Dictionary]:
	return current_stock


func get_buyback() -> Array[Dictionary]:
	return buyback_items


func get_stock_item(index: int) -> Dictionary:
	if index >= 0 and index < current_stock.size():
		return current_stock[index]
	return {}


func clear_buyback() -> void:
	buyback_items.clear()
