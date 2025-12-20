## AssemblyStation - Magic Assembly Station for crafting staffs and wands
## Interactable station where players combine parts to create weapons
class_name AssemblyStation
extends Interactable

# =============================================================================
# SIGNALS
# =============================================================================

signal station_opened()
signal station_closed()
signal item_crafted(item_type: String)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Station Info")
@export var station_name: String = "Magic Assembly Station"

# =============================================================================
# PROPERTIES
# =============================================================================

var _assembly_ui: Control = null
var _is_using: bool = false

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	super._ready()
	interaction_prompt = "[E] Use " + station_name

# =============================================================================
# INTERACTION
# =============================================================================

func _perform_interaction(player: Node) -> void:
	if _is_using:
		return
	
	_open_assembly_ui(player)


func _open_assembly_ui(player: Node) -> void:
	_is_using = true
	station_opened.emit()
	
	# Create or show assembly UI
	if _assembly_ui == null:
		_create_assembly_ui()
	
	if _assembly_ui and _assembly_ui.has_method("open"):
		var inventory = player.get_node_or_null("InventorySystem")
		_assembly_ui.open(inventory)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_assembly_ui() -> void:
	_is_using = false
	station_closed.emit()
	
	if _assembly_ui:
		_assembly_ui.hide()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _create_assembly_ui() -> void:
	# Try to load from scene
	var ui_scene = load("res://scenes/ui/menus/assembly_ui.tscn")
	if ui_scene:
		_assembly_ui = ui_scene.instantiate()
	else:
		# Create dynamically
		var script = load("res://scenes/ui/menus/assembly_ui.gd")
		if script:
			_assembly_ui = Control.new()
			_assembly_ui.set_script(script)
	
	if _assembly_ui:
		get_tree().root.add_child(_assembly_ui)
		if _assembly_ui.has_signal("closed"):
			_assembly_ui.closed.connect(_close_assembly_ui)
		if _assembly_ui.has_signal("item_crafted"):
			_assembly_ui.item_crafted.connect(_on_item_crafted)


func _on_item_crafted(item_type: String) -> void:
	item_crafted.emit(item_type)
