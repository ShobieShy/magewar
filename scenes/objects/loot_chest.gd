## LootChest - Interactable chest that gives random parts
class_name LootChest
extends Node3D

# =============================================================================
# PROPERTIES
# =============================================================================

@export var parts_to_give: int = 5
@export var has_been_looted: bool = false

var _interactable: Interactable = null
var _mesh_instance: MeshInstance3D = null
var _original_material: Material = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Get or create interactable component
	_interactable = get_node_or_null("Interactable")
	if _interactable == null:
		_interactable = Interactable.new()
		_interactable.name = "Interactable"
		add_child(_interactable)
	
	# Connect to interactable signal
	_interactable.interaction_started.connect(_on_interact)
	
	# Get mesh instance for visual feedback
	_mesh_instance = get_node_or_null("MeshInstance3D")
	if _mesh_instance:
		_original_material = _mesh_instance.get_surface_override_material(0)
	
	# Update visual state
	_update_visual()


# =============================================================================
# INTERACTABLE
# =============================================================================

func _on_interact(player: Node) -> void:
	"""Called when player interacts with chest"""
	if has_been_looted:
		return
	
	# Check if player has inventory
	if not player.has_method("add_item"):
		push_warning("Player doesn't have add_item method")
		return
	
	# Generate and give random parts
	var part_generator = RandomPartGenerator.new()
	var random_parts = part_generator.get_random_parts(parts_to_give)
	
	print("Giving player %d random parts from chest" % random_parts.size())
	
	for part in random_parts:
		if part:
			player.add_item(part)
			print("  - Added: %s (%s)" % [part.item_name, Enums.Rarity.keys()[part.rarity]])
	
	# Mark as looted
	has_been_looted = true
	_update_visual()


func _update_visual() -> void:
	"""Update visual state based on looted status"""
	if not _mesh_instance:
		return
	
	if has_been_looted:
		# Make chest look opened/empty
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.3, 0.3, 1.0)  # Darker color
		_mesh_instance.set_surface_override_material(0, material)
		
		# Update interactable prompt
		if _interactable:
			_interactable.interaction_prompt = "[E] Empty Chest"
			_interactable.can_interact = false
	else:
		# Make chest look fresh/full
		if _original_material:
			_mesh_instance.set_surface_override_material(0, _original_material)
		else:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.7, 0.5, 1.0)  # Wood color
			_mesh_instance.set_surface_override_material(0, material)
		
		# Update interactable prompt
		if _interactable:
			_interactable.interaction_prompt = "[E] Loot Chest"
			_interactable.can_interact = true
