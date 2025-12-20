## LootSystem - Handles loot drops, spawning, and pickup
class_name LootSystem
extends Node

# =============================================================================
# CO-OP INTEGRATION
# =============================================================================

## Reference to co-op loot system
var coop_loot: CoopLootSystem = null

# =============================================================================
# SIGNALS
# =============================================================================

signal loot_dropped(item: ItemData, position: Vector3)
signal loot_picked_up(item: ItemData, player: Player)

# =============================================================================
# CONSTANTS
# =============================================================================

var loot_pickup_scene: PackedScene = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init():
	## Initialize loot pickup scene
	if ResourceLoader.exists("res://scenes/world/loot_pickup.tscn"):
		loot_pickup_scene = load("res://scenes/world/loot_pickup.tscn")

# =============================================================================
# METHODS
# =============================================================================

func drop_loot(item: ItemData, position: Vector3, velocity: Vector3 = Vector3.ZERO) -> Node3D:
	## Spawns a loot pickup in the world
	var pickup: Node3D

	if loot_pickup_scene:
		pickup = loot_pickup_scene.instantiate()
	else:
		# Create simple placeholder pickup
		pickup = _create_placeholder_pickup()

	pickup.global_position = position

	if pickup.has_method("initialize"):
		pickup.initialize(item, velocity)

	get_tree().current_scene.add_child(pickup)
	loot_dropped.emit(item, position)

	# Check if this should be shared loot for co-op
	if coop_loot and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE:
		coop_loot.share_loot_with_party([item], position)

	return pickup


func drop_loot_from_table(loot_table: Array, position: Vector3, count: int = 1) -> Array:
	## Drops random loot from a loot table
	## loot_table format: [{"item": ItemData, "weight": float, "min": int, "max": int}]
	
	var drops: Array = []
	var total_weight = 0.0
	
	for entry in loot_table:
		total_weight += entry.get("weight", 1.0)
	
	for i in range(count):
		var roll = randf() * total_weight
		var current = 0.0
		
		for entry in loot_table:
			current += entry.get("weight", 1.0)
			if roll <= current:
				var item: ItemData = entry.item.duplicate_item()
				
				# Roll quantity
				var min_count = entry.get("min", 1)
				var max_count = entry.get("max", 1)
				if item.stackable:
					item.stack_count = randi_range(min_count, max_count)
				
				# Roll rarity (if not fixed)
				if not entry.has("fixed_rarity"):
					item.rarity = _roll_rarity()
				
				# Spread position slightly
				var offset = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
				var drop_pos = position + offset
				
				# Random upward velocity
				var vel = Vector3(randf_range(-2, 2), randf_range(3, 5), randf_range(-2, 2))
				
				drop_loot(item, drop_pos, vel)
				drops.append(item)
				break
	
	return drops


func _roll_rarity() -> Enums.Rarity:
	## Rolls a random rarity based on weights
	var total_weight = 0
	for weight in Constants.RARITY_WEIGHTS.values():
		total_weight += weight
	
	var roll = randi_range(0, total_weight)
	var current = 0
	
	for rarity in Constants.RARITY_WEIGHTS.keys():
		current += Constants.RARITY_WEIGHTS[rarity]
		if roll <= current:
			return rarity
	
	return Enums.Rarity.BASIC


func _create_placeholder_pickup() -> Node3D:
	## Creates a simple placeholder loot pickup
	var pickup = Area3D.new()
	pickup.collision_layer = Constants.LAYER_PICKUPS
	pickup.collision_mask = Constants.LAYER_PLAYERS
	
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = Constants.LOOT_PICKUP_RANGE
	collision.shape = shape
	pickup.add_child(collision)
	
	var mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.3, 0.3, 0.3)
	mesh.mesh = box_mesh
	pickup.add_child(mesh)
	
	# Add floating animation
	var tween = pickup.create_tween().set_loops()
	tween.tween_property(mesh, "position:y", 0.3, 1.0)
	tween.tween_property(mesh, "position:y", 0.1, 1.0)
	
	return pickup
