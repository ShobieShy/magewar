## NetworkManager - Multiplayer networking abstraction layer
## Supports Steam P2P (primary) and Godot ENet (fallback)
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal connection_state_changed(state: Enums.ConnectionState)
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_started()
signal server_stopped()
signal game_start_requested()

# =============================================================================
# PROPERTIES
# =============================================================================

var network_mode: Enums.NetworkMode = Enums.NetworkMode.OFFLINE
var connection_state: Enums.ConnectionState = Enums.ConnectionState.DISCONNECTED:
	set(value):
		if connection_state != value:
			connection_state = value
			connection_state_changed.emit(connection_state)

var is_server: bool = false
var local_peer_id: int = 1

## Maps Steam IDs to Godot peer IDs (for Steam mode)
var _steam_to_peer: Dictionary = {}
var _peer_to_steam: Dictionary = {}

## ENet peer for fallback mode
var _enet_peer: ENetMultiplayerPeer = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Connect Steam signals if available
	if SteamManager.is_steam_available:
		SteamManager.lobby_created.connect(_on_steam_lobby_created)
		SteamManager.lobby_joined.connect(_on_steam_lobby_joined)
		SteamManager.p2p_session_request.connect(_on_steam_p2p_request)


func _process(_delta: float) -> void:
	if network_mode == Enums.NetworkMode.STEAM and connection_state == Enums.ConnectionState.CONNECTED:
		_process_steam_packets()

# =============================================================================
# CONNECTION MANAGEMENT
# =============================================================================

## Host a game - tries Steam first, falls back to ENet
func host_game(use_steam: bool = true, port: int = Constants.DEFAULT_PORT) -> bool:
	if use_steam and SteamManager.is_initialized:
		return _host_steam_game()
	else:
		return _host_enet_game(port)


## Join a game
func join_game(address: String = "", port: int = Constants.DEFAULT_PORT, steam_lobby_id: int = 0) -> bool:
	if steam_lobby_id != 0 and SteamManager.is_initialized:
		return _join_steam_game(steam_lobby_id)
	else:
		return _join_enet_game(address, port)


## Disconnect from current game
func disconnect_from_game() -> void:
	match network_mode:
		Enums.NetworkMode.STEAM:
			_disconnect_steam()
		Enums.NetworkMode.ENET:
			_disconnect_enet()
	
	network_mode = Enums.NetworkMode.OFFLINE
	connection_state = Enums.ConnectionState.DISCONNECTED
	is_server = false
	_steam_to_peer.clear()
	_peer_to_steam.clear()

# =============================================================================
# STEAM NETWORKING
# =============================================================================

func _host_steam_game() -> bool:
	print("Hosting Steam game...")
	network_mode = Enums.NetworkMode.STEAM
	connection_state = Enums.ConnectionState.CONNECTING
	is_server = true
	
	SteamManager.create_lobby(Enums.LobbyPrivacy.FRIENDS_ONLY)
	return true


func _join_steam_game(lobby_id: int) -> bool:
	print("Joining Steam lobby: ", lobby_id)
	network_mode = Enums.NetworkMode.STEAM
	connection_state = Enums.ConnectionState.CONNECTING
	is_server = false
	
	SteamManager.join_lobby(lobby_id)
	return true


func _disconnect_steam() -> void:
	SteamManager.close_all_p2p_sessions()
	SteamManager.leave_lobby()


func _on_steam_lobby_created(_lobby_id: int, result: int) -> void:
	if result == 1:  # Steam.RESULT_OK
		print("Steam lobby created, setting up as host")
		local_peer_id = 1
		connection_state = Enums.ConnectionState.CONNECTED
		
		# Register self as host
		_steam_to_peer[SteamManager.steam_id] = 1
		_peer_to_steam[1] = SteamManager.steam_id
		
		GameManager.is_host = true
		var char_data = SaveManager.player_data.get("character", {})
		GameManager.register_player(1, SteamManager.steam_username, SteamManager.steam_id, char_data)
		
		server_started.emit()
	else:
		connection_state = Enums.ConnectionState.FAILED
		push_error("Failed to create Steam lobby")


func _on_steam_lobby_joined(_lobby_id: int, result: int) -> void:
	if result == 1:  # Steam.RESULT_OK
		print("Joined Steam lobby successfully")
		connection_state = Enums.ConnectionState.CONNECTED
		
		# Request P2P connection to host
		var host_id = SteamManager.get_lobby_owner()
		if host_id != SteamManager.steam_id:
			# We're a client
			local_peer_id = _generate_peer_id()
			_steam_to_peer[SteamManager.steam_id] = local_peer_id
			_peer_to_steam[local_peer_id] = SteamManager.steam_id
			
			# Send join request to host
			_send_steam_packet(host_id, {
				"type": "join_request",
				"steam_id": SteamManager.steam_id,
				"name": SteamManager.steam_username,
				"peer_id": local_peer_id,
				"character": SaveManager.player_data.get("character", {})
			})
	else:
		connection_state = Enums.ConnectionState.FAILED


func _on_steam_p2p_request(remote_id: int) -> void:
	# Accept P2P sessions from lobby members
	if remote_id in SteamManager.lobby_members:
		SteamManager.accept_p2p_session(remote_id)


func _process_steam_packets() -> void:
	var packet = SteamManager.read_p2p_packet(0)
	while packet.size() > 0:
		_handle_steam_packet(packet)
		packet = SteamManager.read_p2p_packet(0)


func _handle_steam_packet(packet: Dictionary) -> void:
	var data = bytes_to_var(packet.data)
	var sender_steam_id = packet.steam_id_remote
	
	if data is Dictionary:
		match data.get("type", ""):
			"join_request":
				_handle_join_request(sender_steam_id, data)
			"join_accepted":
				_handle_join_accepted(data)
			"player_list":
				_handle_player_list(data)
			"game_start":
				game_start_requested.emit()
			"rpc":
				_handle_steam_rpc(data)


func _handle_join_request(steam_id: int, data: Dictionary) -> void:
	if not is_server:
		return
	
	var peer_id = data.get("peer_id", _generate_peer_id())
	var player_name = data.get("name", "Unknown")
	var char_data = data.get("character", {})
	
	# Register new player
	_steam_to_peer[steam_id] = peer_id
	_peer_to_steam[peer_id] = steam_id
	
	GameManager.register_player(peer_id, player_name, steam_id, char_data)
	
	# Send acceptance and full player list
	_send_steam_packet(steam_id, {
		"type": "join_accepted",
		"peer_id": peer_id
	})
	
	# Broadcast player list to all
	_broadcast_player_list()
	
	player_connected.emit(peer_id)


func _handle_join_accepted(data: Dictionary) -> void:
	local_peer_id = data.get("peer_id", local_peer_id)
	print("Join accepted, assigned peer ID: ", local_peer_id)


func _handle_player_list(data: Dictionary) -> void:
	var players = data.get("players", {})
	for peer_id_str in players.keys():
		var peer_id = int(peer_id_str)
		var player_data = players[peer_id_str]
		GameManager.register_player(
			peer_id, 
			player_data.get("name", ""), 
			player_data.get("steam_id", 0),
			player_data.get("character", {})
		)


func _broadcast_player_list() -> void:
	var players_data = {}
	for peer_id in GameManager.players.keys():
		var info = GameManager.players[peer_id]
		players_data[str(peer_id)] = {
			"name": info.display_name,
			"steam_id": info.steam_id,
			"character": info.character_data
		}
	
	for steam_id in SteamManager.lobby_members:
		if steam_id != SteamManager.steam_id:
			_send_steam_packet(steam_id, {
				"type": "player_list",
				"players": players_data
			})


func _send_steam_packet(target_steam_id: int, data: Dictionary, reliable: bool = true) -> void:
	var bytes = var_to_bytes(data)
	SteamManager.send_p2p_packet(target_steam_id, bytes, 0, reliable)


func _broadcast_steam_packet(data: Dictionary, reliable: bool = true) -> void:
	for steam_id in SteamManager.lobby_members:
		if steam_id != SteamManager.steam_id:
			_send_steam_packet(steam_id, data, reliable)


func _handle_steam_rpc(data: Dictionary) -> void:
	# Handle RPC calls over Steam P2P
	var node_path = data.get("path", "")
	var method = data.get("method", "")
	var args = data.get("args", [])
	
	var node = get_node_or_null(node_path)
	if node and node.has_method(method):
		node.callv(method, args)

# =============================================================================
# ENET FALLBACK NETWORKING
# =============================================================================

func _host_enet_game(port: int) -> bool:
	print("Hosting ENet game on port ", port)
	network_mode = Enums.NetworkMode.ENET
	connection_state = Enums.ConnectionState.CONNECTING
	is_server = true
	
	_enet_peer = ENetMultiplayerPeer.new()
	var error = _enet_peer.create_server(port, Constants.MAX_PLAYERS)
	
	if error != OK:
		push_error("Failed to create server: ", error)
		connection_state = Enums.ConnectionState.FAILED
		return false
	
	multiplayer.multiplayer_peer = _enet_peer
	local_peer_id = 1
	
	GameManager.is_host = true
	var char_data = SaveManager.player_data.get("character", {})
	GameManager.register_player(1, "Host", 0, char_data)
	
	connection_state = Enums.ConnectionState.CONNECTED
	server_started.emit()
	
	print("ENet server started on port ", port)
	return true


func _join_enet_game(address: String, port: int) -> bool:
	print("Joining ENet game at ", address, ":", port)
	network_mode = Enums.NetworkMode.ENET
	connection_state = Enums.ConnectionState.CONNECTING
	is_server = false
	
	_enet_peer = ENetMultiplayerPeer.new()
	var error = _enet_peer.create_client(address, port)
	
	if error != OK:
		push_error("Failed to create client: ", error)
		connection_state = Enums.ConnectionState.FAILED
		return false
	
	multiplayer.multiplayer_peer = _enet_peer
	return true


func _disconnect_enet() -> void:
	if _enet_peer:
		_enet_peer.close()
		_enet_peer = null
	multiplayer.multiplayer_peer = null

# =============================================================================
# MULTIPLAYER CALLBACKS
# =============================================================================

@rpc("any_peer", "call_local", "reliable")
func _rpc_relay_enet(node_path: NodePath, method: String, args: Array) -> void:
	## Relay an RPC call to all peers in ENet mode
	var node = get_node_or_null(node_path)
	if node and node.has_method(method):
		node.callv(method, args)


func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)
	
	if network_mode == Enums.NetworkMode.ENET:
		GameManager.register_player(peer_id, "Player " + str(peer_id))
		player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)
	GameManager.unregister_player(peer_id)
	player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	print("Connected to server")
	local_peer_id = multiplayer.get_unique_id()
	connection_state = Enums.ConnectionState.CONNECTED
	var char_data = SaveManager.player_data.get("character", {})
	var player_name = SaveManager.player_data.get("name", "Player " + str(local_peer_id))
	
	GameManager.register_player(local_peer_id, player_name, 0, char_data)
	
	# Send info to server
	_rpc_client_info.rpc_id(1, player_name, char_data)


@rpc("any_peer", "call_local", "reliable")
func _rpc_client_info(player_name: String, char_data: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if is_server:
		print("Received client info from ", sender_id, ": ", player_name)
		GameManager.register_player(sender_id, player_name, 0, char_data)
		# Update other clients
		_broadcast_player_list_enet()


func _broadcast_player_list_enet() -> void:
	if not is_server or network_mode != Enums.NetworkMode.ENET:
		return
	
	var players_data = {}
	for peer_id in GameManager.players.keys():
		var info = GameManager.players[peer_id]
		players_data[str(peer_id)] = {
			"name": info.display_name,
			"character": info.character_data
		}
	
	_rpc_sync_player_list_enet.rpc(players_data)


@rpc("authority", "call_local", "reliable")
func _rpc_sync_player_list_enet(players: Dictionary) -> void:
	if is_server: return # Server already has info
	
	for peer_id_str in players.keys():
		var peer_id = int(peer_id_str)
		if peer_id == local_peer_id: continue # Skip self
		
		var data = players[peer_id_str]
		GameManager.register_player(peer_id, data.name, 0, data.character)


func _on_connection_failed() -> void:
	print("Connection failed")
	connection_state = Enums.ConnectionState.FAILED


func _on_server_disconnected() -> void:
	print("Server disconnected")
	connection_state = Enums.ConnectionState.DISCONNECTED
	server_stopped.emit()

# =============================================================================
# RPC HELPERS
# =============================================================================

## Call RPC on all peers (works for both Steam and ENet)
func rpc_broadcast(node: Node, method: String, args: Array = []) -> void:
	match network_mode:
		Enums.NetworkMode.STEAM:
			_broadcast_steam_packet({
				"type": "rpc",
				"path": node.get_path(),
				"method": method,
				"args": args
			})
			# Also call locally
			if node.has_method(method):
				node.callv(method, args)
		Enums.NetworkMode.ENET:
			# Use Godot's built-in RPC
			# Since rpc doesn't support arrays directly, we handle common argument counts
			match args.size():
				0: node.rpc(method)
				1: node.rpc(method, args[0])
				2: node.rpc(method, args[0], args[1])
				3: node.rpc(method, args[0], args[1], args[2])
				4: node.rpc(method, args[0], args[1], args[2], args[3])
				_: push_error("rpc_broadcast: too many arguments for ENet")
		_:
			# Offline - just call locally
			if node.has_method(method):
				node.callv(method, args)


## Call RPC on specific peer
func rpc_to(peer_id: int, node: Node, method: String, args: Array = []) -> void:
	match network_mode:
		Enums.NetworkMode.STEAM:
			var steam_id = _peer_to_steam.get(peer_id, 0)
			if steam_id != 0:
				_send_steam_packet(steam_id, {
					"type": "rpc",
					"path": node.get_path(),
					"method": method,
					"args": args
				})
		Enums.NetworkMode.ENET:
			match args.size():
				0: node.rpc_id(peer_id, method)
				1: node.rpc_id(peer_id, method, args[0])
				2: node.rpc_id(peer_id, method, args[0], args[1])
				3: node.rpc_id(peer_id, method, args[0], args[1], args[2])
				4: node.rpc_id(peer_id, method, args[0], args[1], args[2], args[3])
				_: push_error("rpc_to: too many arguments for ENet")

# =============================================================================
# UTILITY
# =============================================================================

func get_peer_id() -> int:
	return local_peer_id


func get_steam_id_for_peer(peer_id: int) -> int:
	return _peer_to_steam.get(peer_id, 0)


func get_peer_id_for_steam(steam_id: int) -> int:
	return _steam_to_peer.get(steam_id, 0)


func is_host() -> bool:
	return is_server


func is_connected_to_game() -> bool:
	return connection_state == Enums.ConnectionState.CONNECTED


func _generate_peer_id() -> int:
	# Generate unique peer ID for Steam mode
	return randi_range(2, 999999)


## Request host to start the game (only valid for lobby host)
func request_game_start() -> void:
	if is_server:
		game_start_requested.emit()
		match network_mode:
			Enums.NetworkMode.STEAM:
				_broadcast_steam_packet({"type": "game_start"})
