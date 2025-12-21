## GemDatabase - Central registry for all gems in the game
## Provides quick lookup of gems by ID
extends Node

# =============================================================================
# GEM REGISTRY
# =============================================================================

var _gems: Dictionary = {}  # gem_id -> GemData resource

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_load_gems()


# =============================================================================
# GEM MANAGEMENT
# =============================================================================

func register_gem(gem: GemData) -> void:
	if gem == null or gem.gem_name.is_empty():
		push_error("Cannot register gem without valid name")
		return
	
	_gems[gem.gem_name] = gem


func get_gem(gem_id: String) -> GemData:
	if not _gems.has(gem_id):
		push_warning("Gem not found in database: %s" % gem_id)
		return null
	
	# Return duplicate so modifications don't affect original
	return _gems[gem_id].duplicate()


func has_gem(gem_id: String) -> bool:
	return _gems.has(gem_id)


func get_all_gems() -> Array[GemData]:
	var result: Array[GemData] = []
	for gem in _gems.values():
		result.append(gem)
	return result


# =============================================================================
# LOADING
# =============================================================================

func _load_gems() -> void:
	# Load all .tres files from gems directory
	_load_gems_from_path("res://resources/items/gems/")
	
	print("GemDatabase loaded %d gems" % _gems.size())


func _load_gems_from_path(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		push_warning("GemDatabase: Could not open path: %s" % path)
		return
	
	var error = dir.list_dir_begin()
	if error != OK:
		push_warning("GemDatabase: Could not list directory: %s (Error: %d)" % [path, error])
		return
	
	var file_name = dir.get_next()
	var _loaded_count = 0  # Tracked for potential logging/debugging
	var failed_count = 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = path.path_join(file_name)
			var resource = load(full_path)
			if resource == null:
				push_warning("GemDatabase: Failed to load resource: %s" % full_path)
				failed_count += 1
			elif resource is GemData:
				register_gem(resource)
				_loaded_count += 1
			else:
				push_warning("GemDatabase: Loaded file is not GemData: %s" % full_path)
				failed_count += 1
		file_name = dir.get_next()
	
	if failed_count > 0:
		push_warning("GemDatabase: Failed to load %d gems from %s" % [failed_count, path])


# =============================================================================
# SEARCH
# =============================================================================

func find_by_name(gem_name: String) -> Array[GemData]:
	var results: Array[GemData] = []
	var search_lower = gem_name.to_lower()
	
	for gem in _gems.values():
		if gem.item_name.to_lower().contains(search_lower):
			results.append(gem)
	
	return results


func find_by_element(element: Enums.Element) -> Array[GemData]:
	var results: Array[GemData] = []
	
	for gem in _gems.values():
		if gem.element == element:
			results.append(gem)
	
	return results


func find_by_rarity(rarity: Enums.Rarity) -> Array[GemData]:
	var results: Array[GemData] = []
	
	for gem in _gems.values():
		if gem.rarity == rarity:
			results.append(gem)
	
	return results
