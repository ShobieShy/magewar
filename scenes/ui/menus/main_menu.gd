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
@onready var _join_selected_button: Button = $JoinPanel/VBox/HBox/JoinSelectedButton

# Custom UI components
var _save_selection_ui: Control = null
var _char_creation_ui: Control = null
var _pending_network_action: String = "" # "host" or "join"
var _target_lobby_id: int = 0

# Settings menu script class
const SettingsMenuScript = preload("res://scenes/ui/menus/settings_menu.gd")

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_update_steam_status()
	
	# Create settings menu
	_settings_menu = SettingsMenuScript.new()
	add_child(_settings_menu)
	_settings_menu.settings_closed.connect(_on_settings_closed)
	
	# Create save selection and character creation UIs
	_setup_custom_uis()
	
	# Connect signals
	SteamManager.steam_initialized.connect(_on_steam_initialized)
	SteamManager.lobby_created.connect(_on_lobby_created)
	SteamManager.lobby_joined.connect(_on_lobby_joined)
	SteamManager.lobby_match_list_received.connect(_on_lobby_list_received)
	SteamManager.lobby_chat_update.connect(_on_lobby_chat_update)
	
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.game_start_requested.connect(_on_game_start)
	
	lobby_list.item_selected.connect(func(_idx): _join_selected_button.disabled = false)
	
	GameManager.current_state = Enums.GameState.MAIN_MENU

# =============================================================================
# UI STATE
# =============================================================================

func _setup_custom_uis() -> void:
	# Save Selection UI
	_save_selection_ui = _create_save_selection_ui()
	add_child(_save_selection_ui)
	_save_selection_ui.visible = false
	_save_selection_ui.save_selected.connect(_on_save_selected)
	_save_selection_ui.new_save_requested.connect(_on_new_save_requested)
	_save_selection_ui.cancelled.connect(_show_main_menu)
	
	# Character Creation UI
	_char_creation_ui = _create_char_creation_ui()
	add_child(_char_creation_ui)
	_char_creation_ui.visible = false
	_char_creation_ui.character_created.connect(_on_character_created)
	_char_creation_ui.cancelled.connect(_on_char_creation_cancelled)


func _create_save_selection_ui() -> Control:
	var ui = Control.new()
	ui.name = "SaveSelectionUI"
	ui.set_script(load("res://scenes/ui/menus/save_selection_ui.gd"))
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(400, 500)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ui.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Select Save Slot"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var save_list = ItemList.new()
	save_list.name = "SaveList"
	save_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(save_list)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.name = "BtnHBox"
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)
	
	var load_btn = Button.new()
	load_btn.name = "LoadButton"
	load_btn.text = "Load"
	btn_hbox.add_child(load_btn)
	
	var new_btn = Button.new()
	new_btn.name = "NewButton"
	new_btn.text = "New"
	btn_hbox.add_child(new_btn)
	
	var del_btn = Button.new()
	del_btn.name = "DeleteButton"
	del_btn.text = "Delete"
	btn_hbox.add_child(del_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "Cancel"
	btn_hbox.add_child(cancel_btn)
	
	return ui


func _create_char_creation_ui() -> Control:
	var ui = Control.new()
	ui.name = "CharacterCreationUI"
	ui.set_script(load("res://scenes/ui/menus/character_creation_ui.gd"))
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	
	var panel = PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(400, 400)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	ui.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Character Creation"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	vbox.add_child(Label.new())
	vbox.get_child(vbox.get_child_count()-1).text = "Name:"
	
	var name_in = LineEdit.new()
	name_in.name = "NameInput"
	name_in.placeholder_text = "Enter name..."
	vbox.add_child(name_in)
	
	var color_hbox = HBoxContainer.new()
	color_hbox.name = "ColorHBox"
	vbox.add_child(color_hbox)
	color_hbox.add_child(Label.new())
	color_hbox.get_child(0).text = "Capsule Color:"
	var cp = ColorPickerButton.new()
	cp.name = "ColorPickerButton"
	cp.color = Color.WHITE
	color_hbox.add_child(cp)
	
	var magic_hbox = HBoxContainer.new()
	magic_hbox.name = "MagicHBox"
	vbox.add_child(magic_hbox)
	magic_hbox.add_child(Label.new())
	magic_hbox.get_child(0).text = "Magic Type:"
	var opt = OptionButton.new()
	opt.name = "MagicOptionButton"
	magic_hbox.add_child(opt)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.name = "BtnHBox"
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)
	
	var create_btn = Button.new()
	create_btn.name = "CreateButton"
	create_btn.text = "Create"
	btn_hbox.add_child(create_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.name = "CancelButton"
	cancel_btn.text = "Cancel"
	btn_hbox.add_child(cancel_btn)
	
	return ui


func _show_main_menu() -> void:
	main_buttons.visible = true
	lobby_panel.visible = false
	join_panel.visible = false
	_save_selection_ui.visible = false
	_char_creation_ui.visible = false


func _show_save_selection() -> void:
	main_buttons.visible = false
	lobby_panel.visible = false
	join_panel.visible = false
	_save_selection_ui.visible = true
	_char_creation_ui.visible = false
	_save_selection_ui.refresh()


func _show_char_creation() -> void:
	main_buttons.visible = false
	lobby_panel.visible = false
	join_panel.visible = false
	_save_selection_ui.visible = false
	_char_creation_ui.visible = true


func _on_save_selected(slot_id: String) -> void:
	SaveManager.load_player_data(slot_id)
	SaveManager.load_world_data(slot_id)
	_save_selection_ui.visible = false
	
	if _pending_network_action == "host":
		print("Hosting game with slot: ", slot_id)
		NetworkManager.host_game(SteamManager.is_initialized)
	elif _pending_network_action == "join":
		print("Joining game with slot: ", slot_id)
		if _target_lobby_id != 0:
			NetworkManager.join_game("", 0, _target_lobby_id)
		else:
			var address = address_input.text.strip_edges()
			if address.is_empty(): address = "127.0.0.1"
			NetworkManager.join_game(address, Constants.DEFAULT_PORT)


func _on_new_save_requested() -> void:
	_show_char_creation()


func _on_character_created(char_name: String, char_data: Dictionary) -> void:
	# Generate a new unique slot name
	var slot_name = "save_" + str(Time.get_unix_time_from_system())
	SaveManager.create_new_save(slot_name, char_name, char_data)
	_on_save_selected(slot_name)


func _on_char_creation_cancelled() -> void:
	_show_save_selection()


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
	_pending_network_action = "host"
	_show_save_selection()


func _on_join_pressed() -> void:
	_show_join_panel()
	
	# Request Steam lobby list if available
	if SteamManager.is_initialized:
		SteamManager.request_lobby_list()


func _on_join_selected_pressed() -> void:
	var selected = lobby_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var index = selected[0]
	if index < _available_lobbies.size():
		_target_lobby_id = _available_lobbies[index]
		_pending_network_action = "join"
		_show_save_selection()


func _on_join_ip_pressed() -> void:
	_target_lobby_id = 0
	_pending_network_action = "join"
	_show_save_selection()



func _on_back_pressed() -> void:
	_show_main_menu()

# =============================================================================
# NETWORK CALLBACKS
# =============================================================================

func _on_steam_initialized(_success: bool) -> void:
	_update_steam_status()


func _on_lobby_created(_lobby_id: int, result: int) -> void:
	if result == 1:  # Success
		_show_lobby()


func _on_lobby_joined(_lobby_id: int, result: int) -> void:
	if result == 1:  # Success
		_show_lobby()


func _on_lobby_list_received(lobbies: Array) -> void:
	lobby_list.clear()
	_available_lobbies = lobbies
	
	_join_selected_button.disabled = true
	
	if lobbies.is_empty():
		return
	
	for lobby_id in lobbies:
		var lobby_name = Steam.getLobbyData(lobby_id, "name") if SteamManager.is_initialized else "Lobby"
		var member_count = Steam.getNumLobbyMembers(lobby_id) if SteamManager.is_initialized else 0
		lobby_list.add_item(lobby_name + " (" + str(member_count) + "/" + str(Constants.MAX_PLAYERS) + ")")


func _on_lobby_chat_update(_lobby_id: int, _changed_id: int, _making_change_id: int, _state: int) -> void:
	_update_player_list()


func _on_player_connected(_peer_id: int) -> void:
	_update_player_list()
	_update_lobby_buttons()


func _on_player_disconnected(_peer_id: int) -> void:
	_update_player_list()
	_update_lobby_buttons()


func _on_game_start() -> void:
	# Transition to game scene
	GameManager.start_game()


func _on_settings_closed() -> void:
	# Restore input mode when settings close
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


@rpc("any_peer", "call_local", "reliable")
func _rpc_sync_ready_state(peer_id: int, is_ready: bool) -> void:
	## Sync ready state across network
	GameManager.set_player_ready(peer_id, is_ready)
	_update_player_list()
	_update_lobby_buttons()
