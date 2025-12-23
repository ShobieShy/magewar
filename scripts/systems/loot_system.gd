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
# signal loot_picked_up(item: ItemData, player: Player)  # Currently unused but kept for future implementation

# =============================================================================
# RANDOMIZATION SYSTEMS
# =============================================================================

## Reference to item generation system
var item_generation_system: ItemGenerationSystem = null

## Reference to affix system
var affix_system: AffixSystem = null

## Player level for loot scaling (set by owner)
var player_level: int = 1

## Whether to generate randomized stats (can be disabled for testing)
var enable_stat_randomization: bool = true

## Whether to generate affixes (can be disabled for testing)
var enable_affix_generation: bool = true

# =============================================================================
# CONSTANTS
# =============================================================================

var loot_pickup_scene: PackedScene = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	## Initialize loot pickup scene
	if ResourceLoader.exists("res://scenes/world/loot_pickup.tscn"):
		loot_pickup_scene = load("res://scenes/world/loot_pickup.tscn")
	
	## Initialize randomization systems
	item_generation_system = ItemGenerationSystem.new()
	affix_system = AffixSystem.new()

# =============================================================================
# METHODS
# =============================================================================

func drop_loot(item: ItemData, position: Vector3, velocity: Vector3 = Vector3.ZERO) -> Node3D:
	## Spawns a loot pickup in the world
	if item == null:
		push_error("LootSystem.drop_loot: Attempting to drop null item")
		return null
	
	var pickup: Node3D

	if loot_pickup_scene:
		pickup = loot_pickup_scene.instantiate()
	else:
		# Create simple placeholder pickup
		pickup = _create_placeholder_pickup()

	# Add to scene tree BEFORE setting global_position
	get_tree().current_scene.add_child(pickup)
	
	# Now safe to set global position
	pickup.global_position = position

	if pickup.has_method("initialize"):
		pickup.initialize(item, 1, velocity)
		print("LootSystem: Dropped %s at %v" % [item.item_name, position])
	else:
		push_error("LootSystem: Pickup does not have initialize method")
	
	loot_dropped.emit(item, position)

	# Check if this should be shared loot for co-op
	if coop_loot and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE:
		coop_loot.share_loot_with_party([item], position)

	return pickup


func drop_loot_from_table(loot_table: Array, position: Vector3, count: int = 1) -> Array:
	## Drops random loot from a loot table
	## loot_table format: [{"item": ItemData or String, "weight": float, "min": int, "max": int}]
	
	var drops: Array = []
	var total_weight = 0.0
	
	if loot_table.is_empty():
		push_warning("LootSystem.drop_loot_from_table: Empty loot table")
		return drops
	
	for entry in loot_table:
		total_weight += entry.get("weight", 1.0)
	
	print("LootSystem: Attempting to drop %d items from table with %d entries (total weight: %f)" % [count, loot_table.size(), total_weight])
	
	for i in range(count):
		var roll = randf() * total_weight
		var current = 0.0
		
		for entry in loot_table:
			current += entry.get("weight", 1.0)
			if roll <= current:
				# Skip gold entries - gold is handled by _drop_gold() not the loot system
				if entry.item == "gold":
					print("LootSystem: Skipping gold entry")
					continue
				
				# Handle both ItemData objects and string IDs
				var item: ItemData
				
				if entry.item is String:
					# Try to load from ItemDatabase
					print("LootSystem: Loading item from database: %s" % entry.item)
					item = ItemDatabase.get_item(entry.item)
					if item == null:
						push_warning("Loot drop: Item not found in database: %s" % entry.item)
						continue
				else:
					# Already an ItemData object
					item = entry.item
				
				# Now safe to duplicate
				item = item.duplicate_item()
				if item == null:
					push_error("LootSystem: Failed to duplicate item")
					continue
				
				# Roll quantity
				var min_count = entry.get("min", 1)
				var max_count = entry.get("max", 1)
				if item.stackable:
					item.stack_count = randi_range(min_count, max_count)
				
				# Roll rarity (if not fixed)
				var rarity = entry.get("fixed_rarity", null)
				if rarity == null:
					rarity = _roll_rarity()
				
				# Generate randomized stats for equipment items
				if enable_stat_randomization and item is EquipmentData:
					item = RandomizedItemData.create_from_base(
						item as EquipmentData,
						rarity,
						player_level,
						enable_affix_generation
					)
				else:
					item.rarity = rarity
				
				# Spread position slightly
				var offset = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
				var drop_pos = position + offset
				
				# Random upward velocity
				var vel = Vector3(randf_range(-2, 2), randf_range(3, 5), randf_range(-2, 2))
				
				drop_loot(item, drop_pos, vel)
				drops.append(item)
				break
	
	print("LootSystem: Successfully dropped %d items" % drops.size())
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
