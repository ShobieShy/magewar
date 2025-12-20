## ShopManager - Global shop management and stock rotation
## Handles shop registration, stock refresh on map load, and transactions
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal shop_opened(shop: ShopData)
signal shop_closed()
signal item_purchased(item: ItemData, quantity: int, cost: int)
signal item_sold(item: ItemData, quantity: int, gold: int)
signal stock_refreshed(shop_id: String)

# =============================================================================
# PROPERTIES
# =============================================================================

## Registered shops
var _shops: Dictionary = {}  ## shop_id -> ShopData

## Currently open shop
var _current_shop: ShopData = null

## Shop UI reference
var _shop_ui: Control = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Connect to game state changes for stock rotation
	if GameManager:
		GameManager.game_state_changed.connect(_on_game_state_changed)

# =============================================================================
# SHOP REGISTRATION
# =============================================================================

func register_shop(shop: ShopData) -> void:
	if shop.shop_id.is_empty():
		push_warning("Cannot register shop with empty ID")
		return
	
	_shops[shop.shop_id] = shop
	
	# Generate initial stock if needed
	if shop.current_stock.is_empty():
		shop.generate_stock()


func unregister_shop(shop_id: String) -> void:
	_shops.erase(shop_id)


func get_shop(shop_id: String) -> ShopData:
	return _shops.get(shop_id)


func get_all_shops() -> Array[ShopData]:
	var result: Array[ShopData] = []
	for shop in _shops.values():
		result.append(shop)
	return result

# =============================================================================
# STOCK MANAGEMENT
# =============================================================================

func refresh_all_stocks() -> void:
	## Called on map load to rotate stock
	for shop_id in _shops:
		var shop = _shops[shop_id]
		if shop.refresh_on_load:
			shop.generate_stock()
			stock_refreshed.emit(shop_id)


func refresh_shop_stock(shop_id: String) -> void:
	var shop = _shops.get(shop_id)
	if shop:
		shop.generate_stock()
		stock_refreshed.emit(shop_id)

# =============================================================================
# SHOP INTERACTION
# =============================================================================

func open_shop(shop_id: String) -> bool:
	var shop = _shops.get(shop_id)
	if shop == null:
		push_error("Shop not found: %s" % shop_id)
		return false
	
	_current_shop = shop
	
	# Create or show shop UI
	_show_shop_ui()
	
	shop_opened.emit(shop)
	return true


func close_shop() -> void:
	_current_shop = null
	_hide_shop_ui()
	shop_closed.emit()


func get_current_shop() -> ShopData:
	return _current_shop


func is_shop_open() -> bool:
	return _current_shop != null

# =============================================================================
# TRANSACTIONS
# =============================================================================

func buy_item(index: int, quantity: int = 1) -> bool:
	if _current_shop == null:
		return false
	
	var result = _current_shop.buy_item(index, quantity)
	
	if result.success:
		item_purchased.emit(result.item, result.quantity, result.total_cost)
		return true
	
	return false


func sell_item(item: ItemData, quantity: int = 1) -> bool:
	if _current_shop == null:
		return false
	
	var result = _current_shop.sell_item(item, quantity)
	
	if result.success:
		item_sold.emit(item, quantity, result.gold_earned)
		return true
	
	return false


func buyback_item(index: int, quantity: int = 1) -> bool:
	if _current_shop == null:
		return false
	
	var result = _current_shop.buyback_item(index, quantity)
	
	if result.success:
		item_purchased.emit(result.item, result.quantity, result.total_cost)
		return true
	
	return false

# =============================================================================
# SHOP UI
# =============================================================================

func _show_shop_ui() -> void:
	if _shop_ui == null:
		_create_shop_ui()
	
	if _shop_ui and _shop_ui.has_method("open"):
		_shop_ui.open(_current_shop)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _hide_shop_ui() -> void:
	if _shop_ui and _shop_ui.has_method("close"):
		_shop_ui.close()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _create_shop_ui() -> void:
	# Try to load from scene
	var shop_ui_scene = load("res://scenes/ui/menus/shop_ui.tscn")
	if shop_ui_scene:
		_shop_ui = shop_ui_scene.instantiate()
	else:
		# Create dynamically if scene doesn't exist
		_shop_ui = _create_dynamic_shop_ui()
	
	# Add to viewport
	var root = get_tree().root
	root.add_child(_shop_ui)
	
	# Connect close signal
	if _shop_ui.has_signal("closed"):
		_shop_ui.closed.connect(_on_shop_ui_closed)


func _create_dynamic_shop_ui() -> Control:
	## Fallback: Create shop UI dynamically
	var shop_ui_script = load("res://scenes/ui/menus/shop_ui.gd")
	if shop_ui_script:
		var ui = Control.new()
		ui.set_script(shop_ui_script)
		return ui
	
	push_error("Could not create shop UI")
	return Control.new()


func _on_shop_ui_closed() -> void:
	close_shop()

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_game_state_changed(old_state: Enums.GameState, new_state: Enums.GameState) -> void:
	# Refresh stock when entering a new map (LOADING -> PLAYING)
	if old_state == Enums.GameState.LOADING and new_state == Enums.GameState.PLAYING:
		refresh_all_stocks()
