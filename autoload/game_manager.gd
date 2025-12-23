## GameManager - Global game state and flow control
## Handles game states, scene transitions, and global events
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal game_state_changed(old_state: Enums.GameState, new_state: Enums.GameState)
signal scene_loading_started(scene_path: String)
signal scene_loading_progress(progress: float)
signal scene_loading_completed(scene_path: String)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)

# =============================================================================
# PROPERTIES
# =============================================================================

var current_state: Enums.GameState = Enums.GameState.NONE:
	set(value):
		if current_state != value:
			var old_state = current_state
			current_state = value
			game_state_changed.emit(old_state, current_state)

var is_host: bool = false
var local_player_id: int = 1
var players: Dictionary = {}  # peer_id -> PlayerInfo

## Currently loaded game scene
var current_scene: Node = null

## Friendly fire setting (optional as per spec)
var friendly_fire_enabled: bool = false

## Pause state
var _is_paused: bool = false

## Projectile object pool for performance optimization
var projectile_pool: ProjectilePool = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process, even when paused
	current_state = Enums.GameState.MAIN_MENU
	
	# Initialize projectile pool
	projectile_pool = ProjectilePool.new()
	add_child(projectile_pool)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_state == Enums.GameState.PLAYING:
		toggle_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_quit_requested()

# =============================================================================
# GAME STATE MANAGEMENT
# =============================================================================

func change_state(new_state: Enums.GameState) -> void:
	current_state = new_state


func toggle_pause() -> void:
	if current_state == Enums.GameState.PLAYING:
		_is_paused = true
		current_state = Enums.GameState.PAUSED
		get_tree().paused = true
	elif current_state == Enums.GameState.PAUSED:
		_is_paused = false
		current_state = Enums.GameState.PLAYING
		get_tree().paused = false


func is_paused() -> bool:
	return _is_paused

# =============================================================================
# SCENE MANAGEMENT
# =============================================================================

func load_scene(scene_path: String) -> void:
	# Try seamless world transition first if possible
	if current_scene and current_scene.has_method("load_world"):
		current_scene.load_world(scene_path)
		scene_loading_completed.emit(scene_path)
		return

	current_state = Enums.GameState.LOADING
	scene_loading_started.emit(scene_path)
	
	# Validate scene path exists
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		push_error("Scene not found: " + scene_path)
		_handle_scene_load_error(scene_path)
		return
	
	# Use ResourceLoader for async loading
	var loader = ResourceLoader.load_threaded_request(scene_path)
	if loader != OK:
		push_error("Failed to start loading scene: " + scene_path)
		_handle_scene_load_error(scene_path)
		return
	
	# Wait for loading to complete with timeout protection
	var timeout: float = 60.0  # 60 second timeout
	var start_time = Time.get_ticks_usec()
	var frame_count: int = 0
	const MAX_FRAMES: int = 3600  # Prevent infinite loops (60 seconds at 60 FPS)

	while frame_count < MAX_FRAMES:
		frame_count += 1

		if (Time.get_ticks_usec() - start_time) / 1000000.0 > timeout:
			push_error("Scene loading timeout after " + str(timeout) + " seconds: " + scene_path)
			_handle_scene_load_error(scene_path)
			return
		
		var progress: Array = []
		var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				scene_loading_progress.emit(progress[0] if progress.size() > 0 else 0.0)
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				var scene = ResourceLoader.load_threaded_get(scene_path)
				if scene == null:
					push_error("Scene resource is null: " + scene_path)
					_handle_scene_load_error(scene_path)
					return
				
				if not _switch_to_scene(scene):
					push_error("Failed to instantiate scene: " + scene_path)
					_handle_scene_load_error(scene_path)
					return
				
				scene_loading_completed.emit(scene_path)
				return
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load scene: " + scene_path)
				_handle_scene_load_error(scene_path)
				return
			_:
				await get_tree().process_frame
	
	# If we get here, we've hit the frame limit
	push_error("Scene loading hit frame limit: " + scene_path)
	_handle_scene_load_error(scene_path)


func _switch_to_scene(scene: PackedScene) -> bool:
	# Remove current scene - ensure it's completely removed from rendering
	if current_scene:
		# First hide it immediately to prevent any rendering
		current_scene.visible = false
		# Remove from tree to ensure it's not rendered
		var parent = current_scene.get_parent()
		if parent:
			parent.remove_child(current_scene)
		# Then queue for deletion to clean up resources
		current_scene.queue_free()
		current_scene = null
	
	# Instance and add new scene
	var instantiated_scene = scene.instantiate()
	if instantiated_scene == null:
		push_error("Failed to instantiate scene")
		return false
	
	# Add to tree with null check on root
	var root = get_tree().root
	if root == null:
		push_error("Failed to add scene to tree: no tree root")
		instantiated_scene.queue_free()
		return false
	
	root.add_child(instantiated_scene)
	current_scene = instantiated_scene
	return true


func _handle_scene_load_error(scene_path: String) -> void:
	"""Handle scene loading errors with fallback to main menu"""
	push_error("Scene loading failed: %s. Returning to main menu." % scene_path)
	current_state = Enums.GameState.MAIN_MENU
	
	# Only fallback to main menu if we're not already trying to load it
	if scene_path != "res://scenes/ui/menus/main_menu.tscn":
		# Clear current scene
		if current_scene:
			current_scene.queue_free()
			current_scene = null
		
		# Load main menu synchronously as fallback
		var main_menu_scene = load("res://scenes/ui/menus/main_menu.tscn")
		if main_menu_scene != null:
			_switch_to_scene(main_menu_scene)
		else:
			push_error("CRITICAL: Failed to load main menu fallback!")
	else:
		# If main menu itself failed, at least clear the scene
		if current_scene:
			current_scene.queue_free()
			current_scene = null


func go_to_main_menu() -> void:
	NetworkManager.disconnect_from_game()
	current_state = Enums.GameState.MAIN_MENU
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")


func start_game() -> void:
	current_state = Enums.GameState.PLAYING
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")

# =============================================================================
# PLAYER MANAGEMENT
# =============================================================================

class PlayerInfo:
	var peer_id: int = 0
	var display_name: String = ""
	var steam_id: int = 0
	var is_ready: bool = false
	var character_data: Dictionary = {}
	var player_node: Node = null
	
	func _init(p_peer_id: int, p_name: String = "", p_steam_id: int = 0, p_char_data: Dictionary = {}) -> void:
		peer_id = p_peer_id
		display_name = p_name
		steam_id = p_steam_id
		character_data = p_char_data


func register_player(peer_id: int, display_name: String = "", steam_id: int = 0, char_data: Dictionary = {}) -> void:
	if not players.has(peer_id):
		players[peer_id] = PlayerInfo.new(peer_id, display_name, steam_id, char_data)
		player_joined.emit(peer_id)
		print("Player registered: ", peer_id, " (", display_name, ")")


func unregister_player(peer_id: int) -> void:
	if players.has(peer_id):
		var info: PlayerInfo = players[peer_id]
		if info.player_node:
			info.player_node.queue_free()
		players.erase(peer_id)
		player_left.emit(peer_id)
		print("Player unregistered: ", peer_id)


func get_player_info(peer_id: int) -> PlayerInfo:
	return players.get(peer_id, null)


func get_player_count() -> int:
	return players.size()


func get_all_player_ids() -> Array:
	return players.keys()


func set_player_ready(peer_id: int, is_ready: bool) -> void:
	if players.has(peer_id):
		players[peer_id].is_ready = is_ready


func are_all_players_ready() -> bool:
	for player_info in players.values():
		if not player_info.is_ready:
			return false
	return players.size() > 0

# =============================================================================
# UTILITY
# =============================================================================

func _on_quit_requested() -> void:
	# Clean up before quitting
	NetworkManager.disconnect_from_game()
	SaveManager.save_all()
	get_tree().quit()


func quit_game() -> void:
	_on_quit_requested()
