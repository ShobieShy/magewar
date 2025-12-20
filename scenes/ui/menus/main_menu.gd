## MainMenu - Title screen with host/join functionality
extends Control

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var main_buttons: VBoxContainer = $VBoxContainer
@onready var steam_status: Label = $VBoxContainer/SteamStatus
@onready var lobby_panel: PanelContainer = $LobbyPanel
@onready var player_list: ItemList = $LobbyPanel/VBox/PlayerList
@onready var start_button: Button = $LobbyPanel/VBox/HBox/StartButton
@onready var ready_button: Button = $LobbyPanel/VBox/HBox/ReadyButton
@onready var join_panel: PanelContainer = $JoinPanel
@onready var address_input: LineEdit = $JoinPanel/VBox/AddressInput
@onready var lobby_list: ItemList = $JoinPanel/VBox/LobbyList

# =============================================================================
# PROPERTIES
# =============================================================================

var _available_lobbies: Array = []

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_update_steam_status()
	
	# Connect signals
	SteamManager.steam_initialized.connect(_on_steam_initialized)
	SteamManager.lobby_created.connect(_on_lobby_created)
	SteamManager.lobby_joined.connect(_on_lobby_joined)
	SteamManager.lobby_match_list_received.connect(_on_lobby_list_received)
	SteamManager.lobby_chat_update.connect(_on_lobby_chat_update)
	
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.game_start_requested.connect(_on_game_start)
	
	GameManager.current_state = Enums.GameState.MAIN_MENU

# =============================================================================
# UI STATE
# =============================================================================

func _show_main_menu() -> void:
	main_buttons.visible = true
	lobby_panel.visible = false
	join_panel.visible = false


func _show_lobby() -> void:
	main_buttons.visible = false
	lobby_panel.visible = true
	join_panel.visible = false
	_update_player_list()
	_update_lobby_buttons()


func _show_join_panel() -> void:
	main_buttons.visible = false
	lobby_panel.visible = false
	join_panel.visible = true


func _update_steam_status() -> void:
	if SteamManager.is_initialized:
		steam_status.text = "Steam: Connected as " + SteamManager.steam_username
		steam_status.modulate = Color.GREEN
	elif SteamManager.is_steam_available:
		steam_status.text = "Steam: Initializing..."
		steam_status.modulate = Color.YELLOW
	else:
		steam_status.text = "Steam: Not available (ENet fallback)"
		steam_status.modulate = Color.ORANGE


func _update_player_list() -> void:
	player_list.clear()
	
	for peer_id in GameManager.players.keys():
		var info = GameManager.players[peer_id]
		var status = " [Ready]" if info.is_ready else ""
		var host_tag = " (Host)" if peer_id == 1 else ""
		player_list.add_item(info.display_name + host_tag + status)


func _update_lobby_buttons() -> void:
	# Only host can start
	start_button.visible = GameManager.is_host
	start_button.disabled = not GameManager.are_all_players_ready()

# =============================================================================
# BUTTON CALLBACKS
# =============================================================================

func _on_host_pressed() -> void:
	print("Hosting game...")
	NetworkManager.host_game(SteamManager.is_initialized)


func _on_join_pressed() -> void:
	_show_join_panel()
	
	# Request Steam lobby list if available
	if SteamManager.is_initialized:
		SteamManager.request_lobby_list()


func _on_settings_pressed() -> void:
	# TODO: Open settings menu
	print("Settings not yet implemented")


func _on_quit_pressed() -> void:
	GameManager.quit_game()


func _on_ready_pressed() -> void:
	var is_ready = ready_button.button_pressed
	GameManager.set_player_ready(NetworkManager.local_peer_id, is_ready)
	_update_player_list()
	_update_lobby_buttons()
	
	# Sync ready state over network to all peers
	if is_multiplayer_authority():
		_rpc_sync_ready_state.rpc(NetworkManager.local_peer_id, is_ready)
	else:
		push_warning("Cannot sync ready state: not multiplayer authority")


func _on_start_pressed() -> void:
	if not GameManager.is_host:
		return
	
	NetworkManager.request_game_start()


func _on_leave_lobby_pressed() -> void:
	NetworkManager.disconnect_from_game()
	_show_main_menu()


func _on_refresh_pressed() -> void:
	lobby_list.clear()
	if SteamManager.is_initialized:
		SteamManager.request_lobby_list()


func _on_join_selected_pressed() -> void:
	var selected = lobby_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var index = selected[0]
	if index < _available_lobbies.size():
		var lobby_id = _available_lobbies[index]
		NetworkManager.join_game("", 0, lobby_id)


func _on_join_ip_pressed() -> void:
	var address = address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	
	NetworkManager.join_game(address, Constants.DEFAULT_PORT)


func _on_back_pressed() -> void:
	_show_main_menu()

# =============================================================================
# NETWORK CALLBACKS
# =============================================================================

func _on_steam_initialized(success: bool) -> void:
	_update_steam_status()


func _on_lobby_created(lobby_id: int, result: int) -> void:
	if result == 1:  # Success
		_show_lobby()


func _on_lobby_joined(lobby_id: int, result: int) -> void:
	if result == 1:  # Success
		_show_lobby()


func _on_lobby_list_received(lobbies: Array) -> void:
	lobby_list.clear()
	_available_lobbies = lobbies
	
	for lobby_id in lobbies:
		var lobby_name = Steam.getLobbyData(lobby_id, "name") if SteamManager.is_initialized else "Lobby"
		var member_count = Steam.getNumLobbyMembers(lobby_id) if SteamManager.is_initialized else 0
		lobby_list.add_item(lobby_name + " (" + str(member_count) + "/" + str(Constants.MAX_PLAYERS) + ")")


func _on_lobby_chat_update(_lobby_id: int, _changed_id: int, _making_change_id: int, _state: int) -> void:
	_update_player_list()


func _on_player_connected(peer_id: int) -> void:
	_update_player_list()
	_update_lobby_buttons()


func _on_player_disconnected(peer_id: int) -> void:
	_update_player_list()
	_update_lobby_buttons()


func _on_game_start() -> void:
	# Transition to game scene
	GameManager.start_game()


@rpc("any_peer", "call_local", "reliable")
func _rpc_sync_ready_state(peer_id: int, is_ready: bool) -> void:
	## Sync ready state across network
	GameManager.set_player_ready(peer_id, is_ready)
	_update_player_list()
	_update_lobby_buttons()
