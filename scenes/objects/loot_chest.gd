## LootChest - Interactable chest that spawns random parts as ground pickups
class_name LootChest
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal opened()

# =============================================================================
# PROPERTIES
# =============================================================================

@export var parts_min: int = 1
@export var parts_max: int = 10
@export var has_been_looted: bool = false

var _interactable: Interactable = null
var _mesh_instance: MeshInstance3D = null
var _original_material: Material = null
var _custom_loot_table: Array = []

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
# PUBLIC METHODS
# =============================================================================

func set_loot_table(loot_table: Array) -> void:
	"""Set a custom loot table for this chest"""
	_custom_loot_table = loot_table


# =============================================================================
# INTERACTABLE
# =============================================================================

func _on_interact(_player: Node) -> void:
	"""Called when player interacts with chest"""
	if has_been_looted:
		return
	
	# Notify listeners
	opened.emit()
	
	if not _custom_loot_table.is_empty():
		_spawn_custom_loot()
	else:
		_spawn_random_parts()
	
	# Mark as looted
	has_been_looted = true
	_update_visual()


func _spawn_random_parts() -> void:
	# Generate random number of parts (1-10)
	var num_parts = randi_range(parts_min, parts_max)
	
	# Generate random parts
	var part_generator = RandomPartGenerator.new()
	var random_parts = part_generator.get_random_parts(num_parts)
	
	print("Spawning %d random parts from chest" % random_parts.size())
	_drop_items(random_parts)


func _spawn_custom_loot() -> void:
	# This is a simplified implementation of custom loot tables
	print("Spawning custom loot from table")
	
	var items_to_drop = []
	for entry in _custom_loot_table:
		if randf() < 0.5: # 50% chance per entry
			var item_id = entry.get("item", "")
			if item_id == "gold":
				var amount = randi_range(entry.get("min", 1), entry.get("max", 10))
				SaveManager.add_gold(amount)
				continue
			
			# Try to load item from database
			if ItemDatabase:
				var item = ItemDatabase.get_item(item_id)
				if item:
					var drop = item.duplicate_item()
					if drop.stackable:
						drop.stack_count = randi_range(entry.get("min", 1), entry.get("max", 1))
					items_to_drop.append(drop)
	
	_drop_items(items_to_drop)


func _drop_items(items: Array) -> void:
	# Get or create LootSystem
	var loot_system = get_tree().current_scene.get_node_or_null("LootSystem")
	if loot_system == null:
		loot_system = LootSystem.new()
		get_tree().current_scene.add_child(loot_system)
	
	# Spawn each item as a ground pickup
	for item in items:
		if item:
			var offset = Vector3(randf_range(-1.5, 1.5), 0.5, randf_range(-1.5, 1.5))
			var spawn_pos = global_position + offset
			var velocity = Vector3(randf_range(-2, 2), randf_range(3, 5), randf_range(-2, 2))
			loot_system.drop_loot(item, spawn_pos, velocity)


func _update_visual() -> void:
	"""Update visual state based on looted status"""
	if not _mesh_instance:
		return
	
	if has_been_looted:
		# Make chest look opened/empty
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.3, 0.3, 1.0)
		_mesh_instance.set_surface_override_material(0, material)
		
		if _interactable:
			_interactable.interaction_prompt = "[E] Empty Chest"
			_interactable.can_interact = false
	else:
		if _original_material:
			_mesh_instance.set_surface_override_material(0, _original_material)
		else:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.7, 0.5, 1.0)
			_mesh_instance.set_surface_override_material(0, material)
		
		if _interactable:
			_interactable.interaction_prompt = "[E] Loot Chest"
			_interactable.can_interact = true
