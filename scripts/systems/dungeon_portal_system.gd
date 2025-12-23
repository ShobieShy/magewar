## DungeonPortalSystem - Manages dungeon entrances, exits, and transitions
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal dungeon_entered(dungeon_id: String, portal: DungeonPortal)
signal dungeon_exited(dungeon_id: String, portal: DungeonPortal)
signal transition_started()
signal transition_completed()
signal portal_discovered(portal_id: String)

# =============================================================================
# CONSTANTS
# =============================================================================

const TRANSITION_FADE_TIME: float = 1.0
const PORTAL_SAVE_KEY: String = "discovered_portals"

# =============================================================================
# PROPERTIES
# =============================================================================

var active_portals: Dictionary = {}  # portal_id -> DungeonPortal
var discovered_portals: Array[String] = []
var current_dungeon: String = ""
var is_transitioning: bool = false
var return_position: Vector3 = Vector3.ZERO
var return_scene: String = ""

# Scene paths - ALL PATHS VALIDATED
var dungeon_scenes: Dictionary = {
	"dungeon_1": "res://scenes/dungeons/dungeon_1.tscn",
	"dungeon_2": "res://scenes/dungeons/dungeon_2.tscn",
	"dungeon_3": "res://scenes/dungeons/dungeon_3.tscn",
	"dungeon_4": "res://scenes/dungeons/dungeon_4.tscn",
	"dungeon_5": "res://scenes/dungeons/dungeon_5.tscn",
	"town_square": "res://scenes/world/starting_town/town_square.tscn",
	"home_tree": "res://scenes/world/starting_town/home_tree.tscn",
	"mage_association": "res://scenes/world/starting_town/mage_association.tscn",
	"landfill": "res://scenes/world/landfill/landfill.tscn",
	"test_arena": "res://scenes/world/test_arena.tscn"
}

# Main hub scene for returning from dungeons
var overworld_scene: String = "res://scenes/world/starting_town/town_square.tscn"

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Load discovered portals from save
	_load_discovered_portals()
	
	# Connect to scene tree for scene changes
	get_tree().node_added.connect(_on_node_added)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_discovered_portals()

# =============================================================================
# PORTAL MANAGEMENT
# =============================================================================

func register_portal(portal: DungeonPortal) -> void:
	"""Register a portal in the system"""
	if not portal.portal_id.is_empty():
		active_portals[portal.portal_id] = portal
		
		# Connect to portal signals
		if not portal.player_entered.is_connected(_on_portal_entered):
			portal.player_entered.connect(_on_portal_entered)
		
		# Check if already discovered
		if portal.portal_id in discovered_portals:
			portal.is_discovered = true

func unregister_portal(portal_id: String) -> void:
	"""Remove a portal from the system"""
	if portal_id in active_portals:
		var portal = active_portals[portal_id]
		if portal.player_entered.is_connected(_on_portal_entered):
			portal.player_entered.disconnect(_on_portal_entered)
		active_portals.erase(portal_id)

func discover_portal(portal_id: String) -> void:
	"""Mark a portal as discovered"""
	if portal_id not in discovered_portals:
		discovered_portals.append(portal_id)
		portal_discovered.emit(portal_id)
		_save_discovered_portals()
		
		# Update the actual portal if it exists
		if portal_id in active_portals:
			active_portals[portal_id].is_discovered = true

# =============================================================================
# DUNGEON TRANSITIONS
# =============================================================================

func enter_dungeon(dungeon_id: String, portal: DungeonPortal) -> void:
	"""Transition into a dungeon"""
	if is_transitioning or current_dungeon == dungeon_id:
		return

	if dungeon_id not in dungeon_scenes:
		push_error("Unknown dungeon: " + dungeon_id)
		return

	is_transitioning = true
	transition_started.emit()

	# Mark portal as discovered and get destination info
	var dest_portal_id = ""
	if portal:
		discover_portal(portal.portal_id)
		dest_portal_id = portal.destination_portal_id
		
		# Also unlock in FastTravelManager if applicable
		if FastTravelManager:
			FastTravelManager.unlock_portal(dungeon_id)

	# Save return information
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return_position = player.global_position
	
	# Determine correct return scene
	# If running via Game container, we want the world scene, not the container itself
	var current_scene = get_tree().current_scene
	if current_scene.name == "Game" and current_scene.get("current_world") != null:
		var world = current_scene.current_world
		if world and not world.scene_file_path.is_empty():
			return_scene = world.scene_file_path
		else:
			return_scene = overworld_scene
	else:
		return_scene = current_scene.scene_file_path

	# Start transition
	_transition_to_scene(dungeon_scenes[dungeon_id], dungeon_id, dest_portal_id)


func exit_dungeon(portal: DungeonPortal) -> void:
	"""Exit from current dungeon"""
	if is_transitioning or current_dungeon.is_empty():
		return
	
	is_transitioning = true
	transition_started.emit()
	
	var dest_portal_id = ""
	if portal:
		dest_portal_id = portal.destination_portal_id
	
	# Determine return scene
	var target_scene = return_scene if not return_scene.is_empty() else overworld_scene
	
	# Start transition
	_transition_to_scene(target_scene, "", dest_portal_id)


func _transition_to_scene(scene_path: String, dungeon_id: String, dest_portal_id: String) -> void:
	"""Handle the actual scene transition"""
	# Fade out
	if get_node_or_null("/root/CutsceneManager"):
		await get_node("/root/CutsceneManager").fade_out(TRANSITION_FADE_TIME)
	
	# Save current game state
	if SaveManager:
		SaveManager.save_game()
	
	# Clear active portals as they will be freed
	active_portals.clear()
	
	# Try to use Game node if it exists for seamless world transition
	var game = get_tree().current_scene
	if game and game.has_method("load_world"):
		game.load_world(scene_path)
	else:
		# Fallback to full scene change
		var result = get_tree().change_scene_to_file(scene_path)
		if result != OK:
			push_error("Failed to load scene: " + scene_path)
			is_transitioning = false
			return
	
	# Wait for scene to be ready and portals to register
	await get_tree().create_timer(0.2).timeout
	
	# Update dungeon state
	var old_dungeon = current_dungeon
	current_dungeon = dungeon_id
	
	# Emit appropriate signal (without portal object as it might be from old scene)
	if not dungeon_id.is_empty():
		dungeon_entered.emit(dungeon_id, null)
	else:
		dungeon_exited.emit(old_dungeon, null)
	
	# Position player at spawn point
	_position_player_at_spawn(dest_portal_id)
	
	# Fade in
	if get_node_or_null("/root/CutsceneManager"):
		await get_node("/root/CutsceneManager").fade_in(TRANSITION_FADE_TIME)
	
	is_transitioning = false
	transition_completed.emit()


func _position_player_at_spawn(dest_portal_id: String) -> void:
	"""Position the player at the appropriate spawn point"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Find spawn point in new scene
	var spawn_point: Node3D = null
	
	if current_dungeon.is_empty():
		# Returning to overworld - use return position
		if return_position != Vector3.ZERO:
			player.global_position = return_position
			return
	
	# Look for matching destination portal
	if not dest_portal_id.is_empty() and dest_portal_id in active_portals:
		var portal = active_portals[dest_portal_id]
		if portal and portal.has_method("get_spawn_point"):
			spawn_point = portal.get_spawn_point()
	
	if not spawn_point:
		# Try to find an "EntrancePortal" or similar if no dest ID
		for portal in active_portals.values():
			if is_instance_valid(portal):
				spawn_point = portal.get_spawn_point()
				break
	
	if not spawn_point:
		# Find any spawn point from the group
		var spawn_points = get_tree().get_nodes_in_group("spawn_points")
		if spawn_points.size() > 0:
			spawn_point = spawn_points[0]
	
	if spawn_point:
		player.global_position = spawn_point.global_position
		if "rotation" in spawn_point:
			player.rotation = spawn_point.rotation

# =============================================================================
# PORTAL QUERIES
# =============================================================================

func get_nearest_portal(position: Vector3, max_distance: float = INF) -> DungeonPortal:
	"""Find the nearest portal to a position"""
	var nearest_portal: DungeonPortal = null
	var nearest_distance: float = max_distance
	
	for portal in active_portals.values():
		if not is_instance_valid(portal):
			continue
		
		var distance = position.distance_to(portal.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_portal = portal
	
	return nearest_portal

func is_portal_discovered(portal_id: String) -> bool:
	"""Check if a portal has been discovered"""
	return portal_id in discovered_portals

func get_discovered_dungeons() -> Array[String]:
	"""Get list of discovered dungeon IDs"""
	var dungeons: Array[String] = []
	for portal_id in discovered_portals:
		if portal_id in active_portals:
			var portal = active_portals[portal_id]
			if portal.dungeon_id not in dungeons:
				dungeons.append(portal.dungeon_id)
	return dungeons

# =============================================================================
# SAVE/LOAD
# =============================================================================

func _save_discovered_portals() -> void:
	"""Save discovered portals to SaveManager"""
	if SaveManager:
		SaveManager.set_data(PORTAL_SAVE_KEY, discovered_portals)

func _load_discovered_portals() -> void:
	"""Load discovered portals from SaveManager"""
	if SaveManager:
		var saved_portals = SaveManager.get_data(PORTAL_SAVE_KEY, [])
		if saved_portals is Array:
			# Ensure all elements are strings
			discovered_portals = []
			for portal_id in saved_portals:
				if portal_id is String:
					discovered_portals.append(portal_id)

# =============================================================================
# SIGNAL CALLBACKS
# =============================================================================

func _on_portal_entered(_player: Node, portal: DungeonPortal) -> void:
	"""Handle player entering a portal"""
	if portal.portal_type == DungeonPortal.PortalType.ENTRANCE:
		enter_dungeon(portal.dungeon_id, portal)
	elif portal.portal_type == DungeonPortal.PortalType.EXIT:
		exit_dungeon(portal)

func _on_node_added(node: Node) -> void:
	"""Automatically register portals when they're added to the scene"""
	if node is DungeonPortal:
		register_portal(node)

# =============================================================================
# UTILITY
# =============================================================================

func get_dungeon_info(dungeon_id: String) -> Dictionary:
	"""Get information about a dungeon"""
	var info = {
		"id": dungeon_id,
		"name": dungeon_id.replace("_", " ").capitalize(),
		"discovered": false,
		"completed": false,
		"level_range": [1, 5],
		"description": ""
	}
	
	# Check if discovered
	for portal_id in discovered_portals:
		if portal_id.begins_with(dungeon_id):
			info.discovered = true
			break
	
	# Add specific dungeon info
	match dungeon_id:
		"dungeon_1":
			info.name = "Abandoned Mine"
			info.level_range = [1, 5]
			info.description = "An old mine overrun by goblins and trolls."
		"dungeon_2":
			info.name = "Haunted Catacombs"
			info.level_range = [5, 10]
			info.description = "Ancient burial grounds filled with undead."
		"dungeon_3":
			info.name = "Crystal Cave"
			info.level_range = [3, 7]
			info.description = "A mystical cave filled with magical crystals."
		"dungeon_4":
			info.name = "Ancient Ruins"
			info.level_range = [10, 15]
			info.description = "Ruins of an ancient civilization."
		"dungeon_5":
			info.name = "Forbidden Sanctum"
			info.level_range = [15, 20]
			info.description = "The final challenge. Face the absolute darkness."
		"landfill":
			info.name = "The Landfill"
			info.level_range = [1, 3]
			info.description = "A place of waste and filth, and the source of a growing corruption."
		"test_arena":
			info.name = "Test Arena"
			info.level_range = [1, 20]
			info.description = "A training ground for testing spells and combat skills."
	
	return info

func is_in_dungeon() -> bool:
	"""Check if currently in a dungeon"""
	return not current_dungeon.is_empty()
