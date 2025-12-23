## LootPickup - Pickup item on the ground
## Players walk over to collect loot
class_name LootPickup
extends Area3D

# =============================================================================
# SIGNALS
# =============================================================================

signal picked_up()

# =============================================================================
# PROPERTIES
# =============================================================================

var item_data: ItemData = null
var quantity: int = 1
var _despawn_timer: float = 0.0
var _pickup_delay: float = 0.5  # Prevent instant pickup
var _bob_time: float = 0.0  # For bob animation

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	collision_layer = Constants.LAYER_PICKUPS
	collision_mask = Constants.LAYER_PLAYERS
	
	body_entered.connect(_on_body_entered)
	
	# Set despawn timer
	_despawn_timer = Constants.LOOT_DESPAWN_TIME


func _process(delta: float) -> void:
	# Handle despawn timer
	_despawn_timer -= delta
	if _despawn_timer <= 0.0:
		queue_free()
		return  # Don't process further after queue_free
	
	# Handle pickup delay
	if _pickup_delay > 0.0:
		_pickup_delay -= delta
	
	# Gentle bob animation
	_bob_time += delta
	var bob = sin(_bob_time * 2.0) * 0.1
	position.y += bob * delta

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(item: ItemData, qty: int = 1, velocity: Vector3 = Vector3.ZERO) -> void:
	item_data = item
	quantity = qty
	
	# Update visual
	_update_visual()
	
	# Add initial velocity if needed
	if velocity != Vector3.ZERO:
		var rigid = RigidBody3D.new()
		rigid.position = position
		get_parent().add_child(rigid)
		await get_tree().process_frame
		rigid.queue_free()

# =============================================================================
# VISUAL
# =============================================================================

func _update_visual() -> void:
	if item_data == null:
		return
	
	# Update color based on rarity
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = item_data.get_rarity_color()
		mat.emission = item_data.get_rarity_color()
		mat.emission_energy_multiplier = 0.3
		mesh_instance.material_override = mat
	
	# Update light color
	var light = get_node_or_null("OmniLight3D")
	if light:
		light.light_color = item_data.get_rarity_color()

# =============================================================================
# PICKUP
# =============================================================================

func _on_body_entered(body: Node3D) -> void:
	if _pickup_delay > 0.0:
		return
	
	if body is Player:
		_pickup_by_player(body)


func _pickup_by_player(player: Player) -> void:
	if item_data == null:
		return
	
	# Try to add to inventory
	var inventory = player.get_node_or_null("InventorySystem")
	if inventory and inventory.has_method("add_item"):
		for i in range(quantity):
			if not inventory.add_item(item_data):
				# Inventory full, drop remaining items
				break
	
	picked_up.emit()
	queue_free()

# =============================================================================
# UTILITY
# =============================================================================

func get_item_name() -> String:
	if item_data:
		return item_data.item_name
	return "Unknown Item"
