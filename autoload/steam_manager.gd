## SteamManager - Steam API wrapper and initialization
## Handles Steam initialization, callbacks, and utility functions
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal steam_initialized(success: bool)
signal lobby_created(lobby_id: int, result: int)
signal lobby_joined(lobby_id: int, result: int)
signal lobby_match_list_received(lobbies: Array)
signal lobby_chat_update(lobby_id: int, changed_id: int, making_change_id: int, state: int)
signal lobby_data_update(lobby_id: int, member_id: int, success: bool)
signal lobby_invite_received(inviter_id: int, lobby_id: int)
signal lobby_message_received(lobby_id: int, user_id: int, message: String, chat_type: int)
signal p2p_session_request(remote_id: int)
signal p2p_session_connect_fail(remote_id: int, reason: int)

# =============================================================================
# PROPERTIES
# =============================================================================

var is_initialized: bool = false
var is_online: bool = false
var steam_id: int = 0
var steam_username: String = ""
var current_lobby_id: int = 0
var lobby_members: Array = []

## Check if Steam is available (GodotSteam loaded)
var is_steam_available: bool:
	get:
		return ClassDB.class_exists("Steam")

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	if is_steam_available:
		_initialize_steam()
	else:
		push_warning("Steam not available - running in offline mode")
		is_initialized = false
		steam_initialized.emit(false)


func _process(_delta: float) -> void:
	if is_initialized and is_steam_available:
		Steam.run_callbacks()

# =============================================================================
# INITIALIZATION
# =============================================================================

func _initialize_steam() -> void:
	# Set app ID before initialization
	OS.set_environment("SteamAppId", str(Constants.STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(Constants.STEAM_APP_ID))
	
	var init_result: Dictionary = Steam.steamInitEx(false)
	print("Steam Init Result: ", init_result)
	
	if init_result.status == 0:  # OK
		is_initialized = true
		is_online = Steam.loggedOn()
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
		
		print("Steam initialized successfully!")
		print("  Steam ID: ", steam_id)
		print("  Username: ", steam_username)
		print("  Online: ", is_online)
		
		_connect_steam_signals()
		steam_initialized.emit(true)
	else:
		push_error("Steam initialization failed: " + str(init_result))
		is_initialized = false
		steam_initialized.emit(false)


func _connect_steam_signals() -> void:
	# Lobby signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_message.connect(_on_lobby_message)
	
	# P2P signals
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)

# =============================================================================
# LOBBY MANAGEMENT
# =============================================================================

func create_lobby(privacy: Enums.LobbyPrivacy = Enums.LobbyPrivacy.FRIENDS_ONLY) -> void:
	if not is_initialized:
		push_error("Cannot create lobby - Steam not initialized")
		return
	
	var lobby_type: int
	match privacy:
		Enums.LobbyPrivacy.PUBLIC:
			lobby_type = Steam.LOBBY_TYPE_PUBLIC
		Enums.LobbyPrivacy.FRIENDS_ONLY:
			lobby_type = Steam.LOBBY_TYPE_FRIENDS_ONLY
		Enums.LobbyPrivacy.PRIVATE:
			lobby_type = Steam.LOBBY_TYPE_PRIVATE
	
	Steam.createLobby(lobby_type, Constants.MAX_PLAYERS)
	print("Creating lobby...")


func join_lobby(lobby_id: int) -> void:
	if not is_initialized:
		push_error("Cannot join lobby - Steam not initialized")
		return
	
	Steam.joinLobby(lobby_id)
	print("Joining lobby: ", lobby_id)


func leave_lobby() -> void:
	if current_lobby_id != 0:
		Steam.leaveLobby(current_lobby_id)
		print("Left lobby: ", current_lobby_id)
		current_lobby_id = 0
		lobby_members.clear()


func request_lobby_list() -> void:
	if not is_initialized:
		push_error("Cannot request lobby list - Steam not initialized")
		return
	
	# Add filters if needed
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListResultCountFilter(50)
	Steam.requestLobbyList()
	print("Requesting lobby list...")


func set_lobby_data(key: String, value: String) -> bool:
	if current_lobby_id == 0:
		return false
	return Steam.setLobbyData(current_lobby_id, key, value)


func get_lobby_data(key: String) -> String:
	if current_lobby_id == 0:
		return ""
	return Steam.getLobbyData(current_lobby_id, key)


func send_lobby_chat_message(message: String) -> bool:
	if current_lobby_id == 0:
		return false
	return Steam.sendLobbyChatMsg(current_lobby_id, message)


func get_lobby_member_count() -> int:
	if current_lobby_id == 0:
		return 0
	return Steam.getNumLobbyMembers(current_lobby_id)


func get_lobby_member_by_index(index: int) -> int:
	if current_lobby_id == 0:
		return 0
	return Steam.getLobbyMemberByIndex(current_lobby_id, index)


func is_lobby_owner() -> bool:
	if current_lobby_id == 0:
		return false
	return Steam.getLobbyOwner(current_lobby_id) == steam_id


func get_lobby_owner() -> int:
	if current_lobby_id == 0:
		return 0
	return Steam.getLobbyOwner(current_lobby_id)

# =============================================================================
# P2P NETWORKING
# =============================================================================

func send_p2p_packet(target_id: int, data: PackedByteArray, channel: int = 0, reliable: bool = true) -> bool:
	if not is_initialized:
		return false
	
	var send_type = Steam.P2P_SEND_RELIABLE if reliable else Steam.P2P_SEND_UNRELIABLE
	return Steam.sendP2PPacket(target_id, data, send_type, channel)


func read_p2p_packet(channel: int = 0) -> Dictionary:
	if not is_initialized:
		return {}
	
	var packet_size = Steam.getAvailableP2PPacketSize(channel)
	if packet_size > 0:
		return Steam.readP2PPacket(packet_size, channel)
	return {}


func accept_p2p_session(remote_id: int) -> void:
	Steam.acceptP2PSessionWithUser(remote_id)


func close_p2p_session(remote_id: int) -> void:
	Steam.closeP2PSessionWithUser(remote_id)


func close_all_p2p_sessions() -> void:
	for member_id in lobby_members:
		if member_id != steam_id:
			Steam.closeP2PSessionWithUser(member_id)

# =============================================================================
# UTILITY
# =============================================================================

func get_friend_persona_name(friend_id: int) -> String:
	if not is_initialized:
		return "Unknown"
	return Steam.getFriendPersonaName(friend_id)


func get_player_avatar(player_id: int = 0, size: int = Steam.AVATAR_MEDIUM) -> Image:
	if not is_initialized:
		return null
	
	var id = player_id if player_id != 0 else steam_id
	Steam.getPlayerAvatar(size, id)
	# Note: Avatar is returned via signal, handle async
	return null


func invite_friend(friend_id: int) -> bool:
	if current_lobby_id == 0:
		return false
	return Steam.inviteUserToLobby(current_lobby_id, friend_id)


func get_friends_playing_this_game() -> Array:
	## Get list of friends currently playing this game
	var friends = []
	if not is_initialized:
		return friends
	
	var friend_count = Steam.getFriendCount(Steam.FRIEND_FLAG_IMMEDIATE)
	var app_id = Steam.getAppID()
	
	for i in range(friend_count):
		var friend_steam_id = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info = Steam.getFriendGamePlayed(friend_steam_id)
		
		# Check if they are playing the same game
		if not game_info.is_empty() and int(game_info.get("id", 0)) == app_id:
			friends.append({
				"steam_id": friend_steam_id,
				"name": Steam.getFriendPersonaName(friend_steam_id),
				"lobby_id": game_info.get("lobby", 0)
			})
			
	return friends

# =============================================================================
# STEAM CALLBACKS
# =============================================================================

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result == Steam.RESULT_OK:
		current_lobby_id = lobby_id
		print("Lobby created successfully: ", lobby_id)
		
		# Set default lobby data
		Steam.setLobbyData(lobby_id, "name", steam_username + "'s Lobby")
		Steam.setLobbyData(lobby_id, "game", "Magewar")
		Steam.setLobbyData(lobby_id, "version", "0.1")
		
		_update_lobby_members()
	else:
		push_error("Lobby creation failed with result: ", result)
	
	lobby_created.emit(lobby_id, result)


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, result: int) -> void:
	if result == Steam.RESULT_OK:
		current_lobby_id = lobby_id
		print("Joined lobby: ", lobby_id)
		_update_lobby_members()
	else:
		push_error("Failed to join lobby with result: ", result)
	
	lobby_joined.emit(lobby_id, result)


func _on_lobby_match_list(lobbies: Array) -> void:
	print("Received ", lobbies.size(), " lobbies")
	lobby_match_list_received.emit(lobbies)


func _on_lobby_chat_update(lobby_id: int, changed_id: int, making_change_id: int, state: int) -> void:
	_update_lobby_members()
	lobby_chat_update.emit(lobby_id, changed_id, making_change_id, state)


func _on_lobby_data_update(lobby_id: int, member_id: int, success: int) -> void:
	lobby_data_update.emit(lobby_id, member_id, success == 1)


func _on_lobby_invite(inviter_id: int, lobby_id: int, _game_id: int) -> void:
	lobby_invite_received.emit(inviter_id, lobby_id)


func _on_lobby_message(result: int, user_id: int, message: String, chat_type: int) -> void:
	if result > 0:
		lobby_message_received.emit(current_lobby_id, user_id, message, chat_type)


func _on_p2p_session_request(remote_id: int) -> void:
	print("P2P session request from: ", remote_id)
	# Auto-accept if they're in our lobby
	if remote_id in lobby_members:
		accept_p2p_session(remote_id)
	p2p_session_request.emit(remote_id)


func _on_p2p_session_connect_fail(remote_id: int, reason: int) -> void:
	push_error("P2P connection failed with ", remote_id, " reason: ", reason)
	p2p_session_connect_fail.emit(remote_id, reason)


func _update_lobby_members() -> void:
	lobby_members.clear()
	var count = get_lobby_member_count()
	for i in range(count):
		var member_id = get_lobby_member_by_index(i)
		lobby_members.append(member_id)
	print("Lobby members updated: ", lobby_members.size())
