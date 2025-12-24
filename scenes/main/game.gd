## Game - Main game scene controller
## Handles player spawning, game flow, and world management
extends Node3D

# =============================================================================
# CONSTANTS
# =============================================================================

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const UNIFIED_MENU_SCENE = preload("res://scenes/ui/menus/unified_menu_ui.gd")
const SETTINGS_MENU_SCRIPT = "res://scenes/ui/menus/settings_menu.gd"
const MAIN_MENU_SCENE = "res://scenes/ui/menus/main_menu.tscn"
const TOWN_SHOP_DATA = preload("res://resources/shops/town_shop.tres")

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var spawn_points: Node3D = $SpawnPoints
@onready var players_node: Node3D = $Players
@onready var world_node: Node3D = $World
@onready var hud: CanvasLayer = $HUD
@onready var player_hud: Control = $HUD/PlayerHUD

# =============================================================================
# PROPERTIES
# =============================================================================

var _spawn_index: int = 0
var unified_menu: UnifiedMenuUI = null
var settings_menu: Control = null
var current_world: Node = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	GameManager.current_state = Enums.GameState.PLAYING
	GameManager.current_scene = self
	
	# Register shops
	_register_shops()
	
	# Connect network signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# Load initial world (Town Square)
	_load_initial_world()
	
	# Spawn local player
	_spawn_local_player()
	
	# Spawn existing players (if joining mid-game)
	for peer_id in GameManager.players.keys():
		if peer_id != NetworkManager.local_peer_id:
			_spawn_remote_player(peer_id)
	
	# Set up unified menu (deferred to ensure player is ready)
	call_deferred("_setup_unified_menu")
	
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Start auto-save
	SaveManager.start_auto_save()


func _load_initial_world() -> void:
	# Default to town square
	load_world("res://scenes/world/starting_town/town_square.tscn")


func load_world(world_path: String) -> void:
	"""Load a new world scene into the World container"""
	# Prevent recursion/nesting of Game scene
	if world_path.ends_with("game.tscn") or world_path == scene_file_path:
		push_error("Attempted to load Game scene into itself: " + world_path)
		return

	if current_world:
		current_world.queue_free()
		current_world = null
	
	if not ResourceLoader.exists(world_path):
		push_error("World not found: " + world_path)
		return
	
	var world_scene = load(world_path)
	if world_scene:
		current_world = world_scene.instantiate()
		world_node.add_child(current_world)
		print("Loaded world: ", world_path)
		
		# Update spawn points if the new world has them
		_update_spawn_points()


func _update_spawn_points() -> void:
	"""Update spawn points from the current world"""
	# If world has a specific spawn points node, use it
	var world_spawns = current_world.find_child("SpawnPoints", true, false)
	if not world_spawns:
		world_spawns = current_world.find_child("PlayerSpawn", true, false)
	
	if world_spawns:
		# We could either copy the points or just use the node
		# For now, let's just make sure GameManager can find spawn points in groups
		pass


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SaveManager.stop_auto_save()


func _input(_event: InputEvent) -> void:
	# Right-click is reserved for gameplay spell casting only
	# Mouse mode is controlled exclusively by pause menu
	# Pause menu handles escape key for pause/unpause
	pass

# =============================================================================
# SHOP REGISTRATION
# =============================================================================

func _register_shops() -> void:
	"""Register all available shops with ShopManager"""
	if TOWN_SHOP_DATA:
		ShopManager.register_shop(TOWN_SHOP_DATA)
		print("Registered town shop: ", TOWN_SHOP_DATA.shop_id)

# =============================================================================
# PLAYER SPAWNING
# =============================================================================

func _spawn_local_player() -> void:
	var spawn_pos = _get_next_spawn_position()
	var player = PLAYER_SCENE.instantiate()
	player.name = "Player_" + str(NetworkManager.local_peer_id)
	player.position = spawn_pos
	player.set_multiplayer_authority(NetworkManager.local_peer_id)
	player.is_local_player = true
	players_node.add_child(player)
	
	# Register player node
	var info = GameManager.get_player_info(NetworkManager.local_peer_id)
	if info:
		info.player_node = player
	
	# Connect HUD to local player
	if player_hud:
		player_hud.initialize(player)
		player.hud = player_hud
	
	print("Spawned local player at ", spawn_pos)


func _spawn_remote_player(peer_id: int) -> void:
	var spawn_pos = _get_next_spawn_position()
	var player = PLAYER_SCENE.instantiate()
	player.name = "Player_" + str(peer_id)
	player.position = spawn_pos
	player.set_multiplayer_authority(peer_id)
	player.is_local_player = false
	players_node.add_child(player)
	
	# Register player node
	var info = GameManager.get_player_info(peer_id)
	if info:
		info.player_node = player
	
	print("Spawned remote player ", peer_id, " at ", spawn_pos)


func _get_next_spawn_position() -> Vector3:
	# Try to find spawn points in the current world first
	if current_world:
		var world_spawns = current_world.find_child("SpawnPoints", true, false)
		if not world_spawns:
			world_spawns = current_world.find_child("NPCSpawns", true, false) # Fallback
		
		if world_spawns and world_spawns.get_child_count() > 0:
			var spawn_children = world_spawns.get_children()
			var spawn_point = spawn_children[_spawn_index % spawn_children.size()]
			_spawn_index += 1
			return spawn_point.global_position
		
		# Try looking for a single PlayerSpawn marker
		var player_spawn_node = current_world.find_child("PlayerSpawn", true, false)
		if player_spawn_node:
			return player_spawn_node.global_position

	# Fallback to local spawn points in Game scene
	var fallback_spawns = spawn_points.get_children()
	if fallback_spawns.size() > 0:
		var spawn_point = fallback_spawns[_spawn_index % fallback_spawns.size()]
		_spawn_index += 1
		return spawn_point.global_position
	
	return Vector3.ZERO


func _despawn_player(peer_id: int) -> void:
	var player_name = "Player_" + str(peer_id)
	var player = players_node.get_node_or_null(player_name)
	if player:
		player.queue_free()

# =============================================================================
# RESPAWN
# =============================================================================

func respawn_player(peer_id: int) -> void:
	# SERVER AUTHORITY CHECK: Only host handles respawns
	if not GameManager.is_host:
		push_warning("Non-host attempted to respawn player")
		return
	
	# SECURITY: Validate peer_id
	if peer_id <= 0:
		push_error("Invalid peer_id for respawn: " + str(peer_id))
		return
	
	var spawn_pos = _get_next_spawn_position()
	var player_name = "Player_" + str(peer_id)
	var player = players_node.get_node_or_null(player_name)
	
	if not player:
		push_error("Player not found for respawn: " + player_name)
		return
	
	# SECURITY: Verify player is actually dead before respawning
	if not player.stats or not player.stats.is_dead:
		push_warning("Attempted to respawn player who is not dead: " + str(peer_id))
		return
	
	# SECURITY: Verify spawn position is valid
	if spawn_pos == Vector3.ZERO:
		push_warning("Invalid spawn position for respawn")
		return
	
	player.position = spawn_pos
	player.respawn()
	
	# Notify all clients
	_rpc_respawn_player.rpc(peer_id, spawn_pos)


@rpc("authority", "call_remote", "reliable")
func _rpc_respawn_player(peer_id: int, spawn_position: Vector3) -> void:
	var player_name = "Player_" + str(peer_id)
	var player = players_node.get_node_or_null(player_name)
	if player:
		player.position = spawn_position
		player.respawn()

# =============================================================================
# NETWORK CALLBACKS
# =============================================================================

func _on_player_connected(peer_id: int) -> void:
	# Spawn newly connected player
	_spawn_remote_player(peer_id)


func _on_player_disconnected(peer_id: int) -> void:
	_despawn_player(peer_id)

# =============================================================================
# UNIFIED MENU
# =============================================================================

func _setup_unified_menu() -> void:
	"""Create and set up the unified menu"""
	unified_menu = UNIFIED_MENU_SCENE.new()
	add_child(unified_menu)
	
	# Pass inventory system reference when available
	var player = _get_local_player()
	if player and player.inventory:
		unified_menu.set_inventory_system(player.inventory)
	
	# Connect unified menu signals
	unified_menu.quit_to_menu_requested.connect(_on_unified_menu_quit)
	# unified_menu.settings_requested.connect(_on_unified_menu_settings)
	# unified_menu.join_requested.connect(_on_unified_menu_join)


func _get_local_player() -> Node:
	"""Get the local player node"""
	var player_name = "Player_" + str(NetworkManager.local_peer_id)
	var players_container = get_node_or_null("Players")
	if players_container:
		return players_container.get_node_or_null(player_name)
	return null


# func _on_unified_menu_settings() -> void:
# 	"""Handle settings request from unified menu"""
# 	pass
	
	# if settings_menu == null:
	# 	# Load and instantiate settings menu dynamically
	# 	var SettingsMenuScript = load(SETTINGS_MENU_SCRIPT)
	# 	if SettingsMenuScript:
	# 		settings_menu = SettingsMenuScript.new()
	# 		add_child(settings_menu)
	# 		settings_menu.settings_closed.connect(_on_settings_menu_closed)
	# 	else:
	# 		push_error("Failed to load settings menu script")
	# 		return
	
	# # Show the settings menu
	# settings_menu.show()


# func _on_settings_menu_closed() -> void:
# 	"""Handle settings menu closed"""
# 	if settings_menu:
# 		settings_menu.queue_free()
# 		settings_menu = null
	
# 	# Show unified menu again
# 	if unified_menu:
# 		unified_menu.open()


func _on_unified_menu_quit() -> void:
	"""Handle quit to menu request"""
	# Unpause the game
	get_tree().paused = false
	
	# Return to main menu
	GameManager.current_state = Enums.GameState.MAIN_MENU
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# func _on_unified_menu_join() -> void:
# 	"""Handle join request from unified menu"""
# 	pass
# 	# This would open a join/lobby UI
# 	# For now, just a placeholder
# 	if unified_menu:
# 		unified_menu.close()
