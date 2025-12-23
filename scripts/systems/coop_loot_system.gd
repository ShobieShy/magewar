## CoopLootSystem - Extended loot system for co-op sharing
## Handles loot distribution and sharing across all players
class_name CoopLootSystem
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal loot_shared(loot: Array, distribution_type: String)
signal loot_assigned(player_id: int, items: Array)
signal player_pickup_queue_updated(player_id: int, queue: Array)

# =============================================================================
# PROPERTIES
# =============================================================================

## Reference to main loot system
var loot_system: LootSystem

## Track pending loot assignments for each player
var pending_assignments: Dictionary = {}  ## player_id -> Array[ItemData]

## Track player pickup queues (when players can't pick up immediately)
var player_queues: Dictionary = {}  ## player_id -> Array[ItemData]

## Loot distribution strategies
enum DistributionType {
	FREE_FOR_ALL,      ## Anyone can take
	ROUND_ROBIN,        ## Take turns
	MASTER_LOOTER,      ## One player decides
	GREED_BASED,       ## Roll need-based
	CLASS_BASED,        ## By class/role
	VOTE               ## Party votes
}

var current_distribution_type: DistributionType = DistributionType.FREE_FOR_ALL

# Array size limits to prevent unbounded growth
const MAX_PENDING_ASSIGNMENTS: int = 500
const MAX_QUEUE_PER_PLAYER: int = 100
const MAX_SHARED_CONTAINERS: int = 100

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Get reference to main loot system
	loot_system = LootSystem.new()
	add_child(loot_system)

# =============================================================================
# SHARED LOOT MANAGEMENT
# =============================================================================

func share_loot_with_party(loot_items: Array, position: Vector3) -> void:
	## Share dropped loot with all party members
	if not NetworkManager.is_server:
		return
	
	if loot_items.size() == 0:
		return
	
	# Create shared loot container
	var shared_container = _create_shared_loot_container(loot_items, position)
	
	# Add to scene
	get_tree().current_scene.add_child(shared_container)
	
	# Notify players of available loot
	_notify_party_loot_available(loot_items)
	
	loot_shared.emit(loot_items, "party_drop")

func assign_loot_to_player(player_id: int, items: Array) -> void:
	## Assign specific items to a player (loot distribution UI calls this)
	if not NetworkManager.is_server:
		return
	
	# Add to player's assignment with size limit
	if not pending_assignments.has(player_id):
		pending_assignments[player_id] = []
	
	# Check total size
	var total_pending = 0
	for queues in pending_assignments.values():
		total_pending += queues.size()
	
	if total_pending + items.size() > MAX_PENDING_ASSIGNMENTS:
		push_warning("CoopLootSystem: Max pending assignments exceeded. Some items discarded.")
		# Only add what fits
		var can_add = MAX_PENDING_ASSIGNMENTS - total_pending
		if can_add > 0:
			pending_assignments[player_id].append_array(items.slice(0, can_add))
	else:
		pending_assignments[player_id].append_array(items)
	
	# Send assignment to client
	if NetworkManager.is_server:
		_rpc_assign_loot.rpc_id(player_id, items)
	
	print("Assigned %d items to player %d" % [items.size(), player_id])

func process_pickup_request(player_id: int, loot_index: int) -> void:
	## Handle player request to pick up from shared container
	if not NetworkManager.is_server:
		return
	
	var shared_containers = get_tree().get_nodes_in_group("shared_loot")
	if shared_containers.size() <= loot_index:
		return
	
	var container = shared_containers[loot_index]
	if not container or not container.has_method("request_pickup"):
		return
	
	container.request_pickup(player_id)

func notify_player_pickup_completed(player_id: int, items: Array) -> void:
	## Called when player successfully picks up assigned items
	if pending_assignments.has(player_id):
		pending_assignments.erase(player_id)
	
	loot_assigned.emit(player_id, items)
	player_pickup_queue_updated.emit(player_id, [])

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _create_shared_loot_container(_loot: Array, position: Vector3) -> Node3D:
	## Create a visual loot container that players can interact with
	var container = Area3D.new()
	container.name = "SharedLootContainer"
	container.collision_layer = Constants.LAYER_PICKUPS
	container.collision_mask = Constants.LAYER_PLAYERS
	
	# Add visual indicator
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.8, 0.3, 0.8)
	mesh_instance.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission_enabled = true
	material.emission = Color.YELLOW
	material.emission_energy_multiplier = 2.0
	mesh_instance.material_override = material
	
	container.add_child(mesh_instance)
	
	# Add interaction area
	var interaction_area = Area3D.new()
	interaction_area.name = "InteractionArea"
	var collision_shape = SphereShape3D.new()
	collision_shape.radius = 1.5
	interaction_area.add_child(collision_shape)
	container.add_child(interaction_area)
	
	# Position and basic setup
	container.global_position = position
	
	# Add to shared loot group for easy access
	container.add_to_group("shared_loot")
	
	return container

func _notify_party_loot_available(loot: Array) -> void:
## Notify all players that shared loot is available
	var available_items = []
	for item in loot:
		available_items.append({
			"item_id": item.get("item_id", "unknown"),
			"name": item.get("item_name", "Unknown Item"),
			"rarity": item.get("rarity", 0),
			"icon": item.get("icon", null)
		})
	
	for player_id in NetworkManager.connected_players:
		_rpc_notify_loot_available.rpc_id(player_id, available_items)

# =============================================================================
# RPC METHODS
# =============================================================================

@rpc("authority", "call_remote", "reliable")
func _rpc_notify_loot_available(loot_data: Array) -> void:
	## Client receives notification of available shared loot
	print("Shared loot available: %d items" % loot_data.size())
	
	# Show UI prompt for opening loot distribution
	_show_loot_distribution_ui(loot_data)

@rpc("authority", "call_remote", "reliable")
func _rpc_assign_loot(player_id: int, items: Array) -> void:
	## Client receives loot assignment
	print("Received loot assignment: %d items" % items.size())
	
	# Add to player's pickup queue with size limit
	if not player_queues.has(player_id):
		player_queues[player_id] = []
	
	if player_queues[player_id].size() + items.size() > MAX_QUEUE_PER_PLAYER:
		push_warning("CoopLootSystem: Max queue size for player %d exceeded. Some items discarded." % player_id)
		# Only add what fits
		var can_add = MAX_QUEUE_PER_PLAYER - player_queues[player_id].size()
		if can_add > 0:
			player_queues[player_id].append_array(items.slice(0, can_add))
	else:
		player_queues[player_id].append_array(items)

@rpc("authority", "call_remote", "reliable")
func _rpc_assign_master_looter(master_player_id: int) -> void:
	## Assign master looter role for distribution
	current_distribution_type = DistributionType.MASTER_LOOTER
	print("Player %d is now master looter" % master_player_id)

@rpc("authority", "call_remote", "reliable")
func _rpc_set_distribution_type(type: int) -> void:
	## Set loot distribution method
	if type < DistributionType.size():
		current_distribution_type = type as DistributionType
		print("Loot distribution type set to: %s" % DistributionType.keys()[type])

# =============================================================================
# UI METHODS
# =============================================================================

func _show_loot_distribution_ui(loot_data: Array) -> void:
	## Show UI for loot distribution among party members
	print("=== LOOT DISTRIBUTION ===")
	print("Available items:")
	for i in range(loot_data.size()):
		var item = loot_data[i]
		print("  %d. %s (%s)" % [i + 1, item.name, item.get("rarity", 0).capitalize()])

func _get_distribution_summary() -> String:
	## Get current distribution method summary
	match current_distribution_type:
		DistributionType.FREE_FOR_ALL:
			return "Free for All"
		DistributionType.ROUND_ROBIN:
			return "Round Robin"
		DistributionType.MASTER_LOOTER:
			return "Master Looter: " + str(NetworkManager.local_peer_id) if NetworkManager.is_server else "Unknown"
		DistributionType.GREED_BASED:
			return "Need-Based"
		DistributionType.CLASS_BASED:
			return "Class-Based"
		DistributionType.VOTE:
			return "Party Vote"
		_:
			return "Unknown"
