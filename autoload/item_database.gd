## ItemDatabase - Central registry for all items in the game
## Provides quick lookup of items by ID
extends Node

# =============================================================================
# ITEM REGISTRY
# =============================================================================

var _items: Dictionary = {}  # item_id -> ItemData resource

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_load_items()


# =============================================================================
# ITEM MANAGEMENT
# =============================================================================

func register_item(item: ItemData) -> void:
	if item == null or item.item_id.is_empty():
		push_error("Cannot register item without valid ID")
		return
	
	_items[item.item_id] = item


func get_item(item_id: String) -> ItemData:
	if not _items.has(item_id):
		push_warning("Item not found in database: %s" % item_id)
		return null
	
	# Return duplicate so modifications don't affect original
	return _items[item_id].duplicate()


func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _items.values():
		result.append(item)
	return result


# =============================================================================
# LOADING
# =============================================================================

func _load_items() -> void:
	# Load all .tres files from equipment and items directories
	_load_items_from_path("res://resources/items/equipment/")
	_load_items_from_path("res://resources/items/grimoires/")
	_load_items_from_path("res://resources/items/potions/")
	
	print("ItemDatabase loaded %d items" % _items.size())


func _load_items_from_path(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		push_warning("ItemDatabase: Could not open path: %s" % path)
		return
	
	var error = dir.list_dir_begin()
	if error != OK:
		push_warning("ItemDatabase: Could not list directory: %s (Error: %d)" % [path, error])
		return
	
	var file_name = dir.get_next()
	var _loaded_count = 0
	var _failed_count = 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = path.path_join(file_name)
			var resource = load(full_path)
			if resource == null:
				push_warning("ItemDatabase: Failed to load resource: %s" % full_path)
				_failed_count += 1
			elif resource is ItemData:
				register_item(resource)
				_loaded_count += 1
			else:
				push_warning("ItemDatabase: Loaded file is not ItemData: %s" % full_path)
				_failed_count += 1
		file_name = dir.get_next()
	
	if _failed_count > 0:
		push_warning("ItemDatabase: Failed to load %d items from %s" % [_failed_count, path])


# =============================================================================
# SEARCH
# =============================================================================

func find_by_name(item_name: String) -> Array[ItemData]:
	var results: Array[ItemData] = []
	var search_lower = item_name.to_lower()
	
	for item in _items.values():
		if item.item_name.to_lower().contains(search_lower):
			results.append(item)
	
	return results


func find_by_type(item_type: Enums.ItemType) -> Array[ItemData]:
	var results: Array[ItemData] = []
	
	for item in _items.values():
		if item.item_type == item_type:
			results.append(item)
	
	return results


func find_by_rarity(rarity: Enums.Rarity) -> Array[ItemData]:
	var results: Array[ItemData] = []
	
	for item in _items.values():
		if item.rarity == rarity:
			results.append(item)
	
	return results
