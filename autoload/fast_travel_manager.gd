## FastTravelManager - Manages portal unlocks and fast travel
## Unlocked portals persist in world save (host only)
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal portal_unlocked(portal_id: String)
signal portal_travel_started(from_id: String, to_id: String)
signal portal_travel_completed(portal_id: String)

# =============================================================================
# PORTAL DATA
# =============================================================================

## All available portals in the game
## Format: portal_id -> { name, scene_path, spawn_offset }
const PORTAL_REGISTRY: Dictionary = {
	"starting_town": {
		"name": "Starting Town",
		"scene_path": "res://scenes/world/starting_town/town_square.tscn",
		"spawn_offset": Vector3(0, 1, 2)
	},
	"mage_association": {
		"name": "Mage Association",
		"scene_path": "res://scenes/world/starting_town/mage_association.tscn",
		"spawn_offset": Vector3(0, 1, 2)
	},
	"home_tree": {
		"name": "Home Tree",
		"scene_path": "res://scenes/world/starting_town/home_tree.tscn",
		"spawn_offset": Vector3(0, 1, 2)
	},
	"landfill": {
		"name": "The Landfill",
		"scene_path": "res://scenes/world/landfill/landfill.tscn",
		"spawn_offset": Vector3(0, 1, 2)
	}
}

# =============================================================================
# PROPERTIES
# =============================================================================

var unlocked_portals: Array[String] = ["starting_town"]  # Starting town always unlocked
var _active_portals: Dictionary = {}  # portal_id -> portal node reference
var _spawn_points: Dictionary = {}  # location_id -> Vector3

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Load unlocked portals from save
	_load_unlocked_portals()

# =============================================================================
# PORTAL REGISTRATION
# =============================================================================

func register_portal(portal_id: String, portal_node: Node) -> void:
	## Called by Portal scenes when they're ready
	_active_portals[portal_id] = portal_node
	
	# Update portal state based on unlock status
	if portal_node.has_method("set_active"):
		portal_node.set_active(is_portal_unlocked(portal_id))


func unregister_portal(portal_id: String) -> void:
	_active_portals.erase(portal_id)


func register_spawn_point(location_id: String, spawn_pos: Vector3) -> void:
	## Register a spawn point for a location
	_spawn_points[location_id] = spawn_pos


func unregister_spawn_point(location_id: String) -> void:
	## Unregister a spawn point
	_spawn_points.erase(location_id)


func get_spawn_point(location_id: String) -> Vector3:
	## Get spawn point for a location
	return _spawn_points.get(location_id, Vector3.ZERO)


func get_portal_node(portal_id: String) -> Node:
	return _active_portals.get(portal_id, null)

# =============================================================================
# UNLOCK MANAGEMENT
# =============================================================================

func unlock_portal(portal_id: String) -> void:
	if portal_id in unlocked_portals:
		return
	
	if portal_id not in PORTAL_REGISTRY:
		push_warning("Attempted to unlock unknown portal: ", portal_id)
		return
	
	unlocked_portals.append(portal_id)
	portal_unlocked.emit(portal_id)
	
	# Update portal node if active
	var portal_node = _active_portals.get(portal_id)
	if portal_node and portal_node.has_method("set_active"):
		portal_node.set_active(true)
	
	# Save to world data (host only)
	_save_unlocked_portals()
	
	print("Portal unlocked: ", get_portal_name(portal_id))


func is_portal_unlocked(portal_id: String) -> bool:
	return portal_id in unlocked_portals


func get_unlocked_portals() -> Array[String]:
	return unlocked_portals.duplicate()


func get_available_destinations(current_portal_id: String) -> Array[Dictionary]:
	## Returns list of portals the player can travel to from current location
	var destinations: Array[Dictionary] = []
	
	for portal_id in unlocked_portals:
		if portal_id == current_portal_id:
			continue  # Can't travel to current location
		
		if portal_id in PORTAL_REGISTRY:
			var data = PORTAL_REGISTRY[portal_id].duplicate()
			data["id"] = portal_id
			destinations.append(data)
	
	return destinations

# =============================================================================
# PORTAL INFO
# =============================================================================

func get_portal_name(portal_id: String) -> String:
	if portal_id in PORTAL_REGISTRY:
		return PORTAL_REGISTRY[portal_id].name
	return portal_id


func get_portal_scene_path(portal_id: String) -> String:
	if portal_id in PORTAL_REGISTRY:
		return PORTAL_REGISTRY[portal_id].scene_path
	return ""


func get_portal_spawn_offset(portal_id: String) -> Vector3:
	if portal_id in PORTAL_REGISTRY:
		return PORTAL_REGISTRY[portal_id].spawn_offset
	return Vector3.ZERO

# =============================================================================
# TRAVEL
# =============================================================================

func travel_to_portal(destination_id: String, from_id: String = "") -> bool:
	## Initiates travel to the specified portal
	## Returns false if the portal is not unlocked or doesn't exist
	
	if not is_portal_unlocked(destination_id):
		push_warning("Cannot travel to locked portal: ", destination_id)
		return false
	
	if destination_id not in PORTAL_REGISTRY:
		push_warning("Unknown portal destination: ", destination_id)
		return false
	
	portal_travel_started.emit(from_id, destination_id)
	
	# Load the destination scene
	var scene_path = get_portal_scene_path(destination_id)
	if scene_path.is_empty():
		push_error("Portal has no scene path: ", destination_id)
		return false
	
	# Use GameManager to change scene
	if GameManager.has_method("load_level"):
		GameManager.load_level(scene_path, destination_id)
	else:
		# Fallback: direct scene change
		get_tree().change_scene_to_file(scene_path)
	
	portal_travel_completed.emit(destination_id)
	return true


func get_spawn_position_for_portal(portal_id: String) -> Vector3:
	## Returns the world position where players should spawn when traveling to this portal
	var portal_node = _active_portals.get(portal_id)
	
	if portal_node and portal_node is Node3D:
		return portal_node.global_position + get_portal_spawn_offset(portal_id)
	
	# Fallback position
	return Vector3(0, 1, 0) + get_portal_spawn_offset(portal_id)

# =============================================================================
# SAVE/LOAD
# =============================================================================

func _load_unlocked_portals() -> void:
	## Load unlocked portals from SaveManager
	if SaveManager.world_data.has("unlocked_portals"):
		unlocked_portals.clear()
		for portal_id in SaveManager.world_data.unlocked_portals:
			unlocked_portals.append(portal_id)
	
	# Ensure starting town is always unlocked
	if "starting_town" not in unlocked_portals:
		unlocked_portals.append("starting_town")


func _save_unlocked_portals() -> void:
	## Save unlocked portals to world data (host only)
	if not GameManager.is_host:
		return
	
	SaveManager.world_data["unlocked_portals"] = unlocked_portals.duplicate()
	SaveManager.save_world_data()

# =============================================================================
# NETWORK SYNC
# =============================================================================

func sync_portals_to_clients() -> void:
	## Host calls this to sync unlocked portals to all clients
	if not GameManager.is_host:
		return
	
	if not is_multiplayer_authority():
		push_error("FastTravelManager: Not network authority, cannot sync portals")
		return
	
	# Send unlocked portals to all peers
	for peer_id in NetworkManager.connected_peers:
		if peer_id > 0:  # Valid peer ID check
			_rpc_sync_portals.rpc_id(peer_id, unlocked_portals)


@rpc("authority", "call_remote", "reliable")
func _rpc_sync_portals(portals: Array) -> void:
	## Called on clients to receive portal unlock state
	unlocked_portals.clear()
	for portal_id in portals:
		if portal_id is String:
			unlocked_portals.append(portal_id)


@rpc("any_peer", "call_local", "reliable")
func _rpc_request_travel(destination_id: String) -> void:
	## Client requests travel - host validates and initiates
	if not GameManager.is_host:
		push_warning("FastTravelManager: Received travel request but not host")
		return
	
	# Validate destination is unlocked
	if not is_portal_unlocked(destination_id):
		push_warning("FastTravelManager: Portal not unlocked: %s" % destination_id)
		return
	
	# Broadcast travel to all players
	_rpc_execute_travel.rpc(destination_id)


@rpc("authority", "call_local", "reliable")
func _rpc_execute_travel(destination_id: String) -> void:
	## All clients execute travel
	if not is_multiplayer_authority():
		push_warning("FastTravelManager: Execute travel called without authority")
		return
	
	travel_to_portal(destination_id)
