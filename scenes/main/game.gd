## Game - Main game scene controller
## Handles player spawning, game flow, and world management
extends Node3D

# =============================================================================
# CONSTANTS
# =============================================================================

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const PAUSE_MENU_SCENE = preload("res://scenes/ui/menus/pause_menu.tscn")
const SETTINGS_MENU_SCRIPT = "res://scenes/ui/menus/settings_menu.gd"
const MAIN_MENU_SCENE = "res://scenes/ui/menus/main_menu.tscn"

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var spawn_points: Node3D = $SpawnPoints
@onready var players_node: Node3D = $Players
@onready var hud: CanvasLayer = $HUD
@onready var player_hud: Control = $HUD/PlayerHUD

# =============================================================================
# PROPERTIES
# =============================================================================

var _spawn_index: int = 0
var pause_menu: PauseMenu = null
var settings_menu: Control = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	GameManager.current_state = Enums.GameState.PLAYING
	
	# Connect network signals
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	# Spawn local player
	_spawn_local_player()
	
	# Spawn existing players (if joining mid-game)
	for peer_id in GameManager.players.keys():
		if peer_id != NetworkManager.local_peer_id:
			_spawn_remote_player(peer_id)
	
	# Set up pause menu
	_setup_pause_menu()
	
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Start auto-save
	SaveManager.start_auto_save()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SaveManager.stop_auto_save()


func _input(event: InputEvent) -> void:
	# Toggle mouse capture on right-click (when not in pause menu)
	# Left pause menu to handle escape key for pause/unpause
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if pause_menu == null or not pause_menu.is_paused():
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	var spawn_children = spawn_points.get_children()
	if spawn_children.size() == 0:
		return Vector3.ZERO
	
	var spawn_point = spawn_children[_spawn_index % spawn_children.size()]
	_spawn_index += 1
	return spawn_point.global_position


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
func _rpc_respawn_player(peer_id: int, position: Vector3) -> void:
	var player_name = "Player_" + str(peer_id)
	var player = players_node.get_node_or_null(player_name)
	if player:
		player.position = position
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
# PAUSE MENU
# =============================================================================

func _setup_pause_menu() -> void:
	"""Create and set up the pause menu"""
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	
	# Connect pause menu signals
	pause_menu.resume_requested.connect(_on_pause_menu_resume)
	pause_menu.join_requested.connect(_on_pause_menu_join)
	pause_menu.settings_requested.connect(_on_pause_menu_settings)
	pause_menu.quit_to_menu_requested.connect(_on_pause_menu_quit)


func _on_pause_menu_resume() -> void:
	"""Handle resume from pause menu"""
	# Just show the pause menu, the game will resume automatically
	pass


func _on_pause_menu_join() -> void:
	"""Handle join request from pause menu"""
	# This would open a join/lobby UI
	# For now, just a placeholder
	if pause_menu:
		pause_menu.resume()


func _on_pause_menu_settings() -> void:
	"""Handle settings request from pause menu"""
	if settings_menu == null:
		# Load and instantiate settings menu dynamically
		var SettingsMenuScript = load(SETTINGS_MENU_SCRIPT)
		if SettingsMenuScript:
			settings_menu = SettingsMenuScript.new()
			add_child(settings_menu)
			settings_menu.settings_closed.connect(_on_settings_menu_closed)
		else:
			push_error("Failed to load settings menu script")
			return
	
	# Show the settings menu
	settings_menu.show()


func _on_settings_menu_closed() -> void:
	"""Handle settings menu closed"""
	if settings_menu:
		settings_menu.queue_free()
		settings_menu = null
	
	# Show pause menu again
	if pause_menu:
		pause_menu.pause()


func _on_pause_menu_quit() -> void:
	"""Handle quit to menu request"""
	# Unpause the game
	get_tree().paused = false
	
	# Return to main menu
	GameManager.current_state = Enums.GameState.MAIN_MENU
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
