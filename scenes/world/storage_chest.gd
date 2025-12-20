## StorageChest - Persistent storage interactable for Home Tree
## Players can store and retrieve items that persist across sessions
class_name StorageChest
extends Interactable

# =============================================================================
# SIGNALS
# =============================================================================

signal storage_opened()
signal storage_closed()
signal item_deposited(item: Dictionary)
signal item_withdrawn(item: Dictionary)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Chest Info")
@export var chest_name: String = "Storage Chest"
@export var chest_capacity: int = Constants.STORAGE_SIZE

# =============================================================================
# PROPERTIES
# =============================================================================

var _storage_ui: Control = null
var _is_using: bool = false
var _current_player: Node = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "[E] Open " + chest_name

# =============================================================================
# INTERACTION
# =============================================================================

func _perform_interaction(player: Node) -> void:
	if _is_using:
		return
	
	_open_storage(player)


func _open_storage(player: Node) -> void:
	_is_using = true
	_current_player = player
	storage_opened.emit()
	
	# Create or show storage UI
	if _storage_ui == null:
		_create_storage_ui()
	
	if _storage_ui and _storage_ui.has_method("open"):
		var inventory = player.get_node_or_null("InventorySystem")
		var storage_items = SaveManager.get_storage()
		_storage_ui.open(inventory, storage_items, chest_capacity)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_storage() -> void:
	_is_using = false
	_current_player = null
	storage_closed.emit()
	
	if _storage_ui:
		_storage_ui.hide()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _create_storage_ui() -> void:
	# Try to load from scene
	var ui_scene = load("res://scenes/ui/menus/storage_ui.tscn")
	if ui_scene:
		_storage_ui = ui_scene.instantiate()
	else:
		# Create dynamically from script
		var script = load("res://scenes/ui/menus/storage_ui.gd")
		if script:
			_storage_ui = Control.new()
			_storage_ui.set_script(script)
	
	if _storage_ui:
		get_tree().root.add_child(_storage_ui)
		if _storage_ui.has_signal("closed"):
			_storage_ui.closed.connect(_close_storage)
		if _storage_ui.has_signal("item_deposited"):
			_storage_ui.item_deposited.connect(_on_item_deposited)
		if _storage_ui.has_signal("item_withdrawn"):
			_storage_ui.item_withdrawn.connect(_on_item_withdrawn)

# =============================================================================
# STORAGE OPERATIONS
# =============================================================================

func deposit_item(item_data: Dictionary) -> bool:
	## Add item to storage
	var current_storage = SaveManager.get_storage()
	if current_storage.size() >= chest_capacity:
		return false
	
	SaveManager.add_to_storage(item_data)
	item_deposited.emit(item_data)
	return true


func withdraw_item(storage_index: int) -> Dictionary:
	## Remove item from storage and return it
	var item = SaveManager.remove_from_storage(storage_index)
	if not item.is_empty():
		item_withdrawn.emit(item)
	return item


func get_storage_contents() -> Array:
	return SaveManager.get_storage()


func get_storage_count() -> int:
	return SaveManager.get_storage().size()


func get_capacity() -> int:
	return chest_capacity


func is_full() -> bool:
	return get_storage_count() >= chest_capacity

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_item_deposited(item: Dictionary) -> void:
	item_deposited.emit(item)
	# Auto-save after deposit
	SaveManager.save_player_data()


func _on_item_withdrawn(item: Dictionary) -> void:
	item_withdrawn.emit(item)
	# Auto-save after withdrawal
	SaveManager.save_player_data()
