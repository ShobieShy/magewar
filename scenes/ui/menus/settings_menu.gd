## SettingsMenu - In-game settings interface
## Provides audio, video, gameplay, and control configuration
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal settings_closed()
signal settings_applied()

# =============================================================================
# PROPERTIES
# =============================================================================

var _is_open: bool = false
var _tab_index: int = 0  # 0=Audio, 1=Video, 2=Gameplay, 3=Controls

# UI Nodes
var _main_panel: PanelContainer
var _tab_container: TabContainer
var _close_button: Button
var _apply_button: Button

# Audio controls
var _master_volume_slider: HSlider
var _music_volume_slider: HSlider
var _sfx_volume_slider: HSlider
var _voice_volume_slider: HSlider

# Video controls
var _fullscreen_checkbox: CheckBox
var _vsync_checkbox: CheckBox
var _resolution_option: OptionButton
var _quality_option: OptionButton

# Gameplay controls
var _mouse_sensitivity_slider: HSlider
var _invert_y_checkbox: CheckBox
var _friendly_fire_checkbox: CheckBox
var _damage_numbers_checkbox: CheckBox

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_create_ui()
	_load_settings()
	hide()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	
	if event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
		close()
		get_viewport().set_input_as_handled()

# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Dimmer background
	var dimmer = ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	
	# Main panel
	_main_panel = PanelContainer.new()
	_main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_main_panel.custom_minimum_size = Vector2(700, 600)
	_apply_panel_style(_main_panel)
	add_child(_main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_main_panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)
	
	header.add_child(Control.new())
	header.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(40, 40)
	_close_button.pressed.connect(close)
	header.add_child(_close_button)
	
	# Tabs
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_tab_container)
	
	_create_audio_tab()
	_create_video_tab()
	_create_gameplay_tab()
	_create_controls_tab()
	
	# Buttons
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(button_hbox)
	
	var reset_button = Button.new()
	reset_button.text = "Reset to Defaults"
	reset_button.pressed.connect(_on_reset_pressed)
	button_hbox.add_child(reset_button)
	
	button_hbox.add_child(Control.new())
	button_hbox.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_apply_button = Button.new()
	_apply_button.text = "Apply & Close"
	_apply_button.custom_minimum_size = Vector2(150, 40)
	_apply_button.pressed.connect(_on_apply_pressed)
	button_hbox.add_child(_apply_button)


func _create_audio_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Audio"
	_tab_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)
	
	# Master Volume
	vbox.add_child(_create_slider_option("Master Volume", "_master_volume_slider"))
	_master_volume_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("Slider")
	
	# Music Volume
	vbox.add_child(_create_slider_option("Music Volume", "_music_volume_slider"))
	_music_volume_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("Slider")
	
	# SFX Volume
	vbox.add_child(_create_slider_option("Sound Effects Volume", "_sfx_volume_slider"))
	_sfx_volume_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("Slider")
	
	# Voice Volume
	vbox.add_child(_create_slider_option("Voice Volume", "_voice_volume_slider"))
	_voice_volume_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("Slider")


func _create_video_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Video"
	_tab_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	# Resolution
	vbox.add_child(_create_option_menu("Resolution", "_resolution_option"))
	_resolution_option = vbox.get_child(vbox.get_child_count() - 1).get_node("Option")
	_resolution_option.add_item("1280 x 720")
	_resolution_option.add_item("1920 x 1080")
	_resolution_option.add_item("2560 x 1440")
	
	# Quality
	vbox.add_child(_create_option_menu("Quality", "_quality_option"))
	_quality_option = vbox.get_child(vbox.get_child_count() - 1).get_node("Option")
	_quality_option.add_item("Low")
	_quality_option.add_item("Medium")
	_quality_option.add_item("High")
	_quality_option.add_item("Ultra")
	
	# Fullscreen
	vbox.add_child(_create_checkbox_option("Fullscreen", "_fullscreen_checkbox"))
	_fullscreen_checkbox = vbox.get_child(vbox.get_child_count() - 1).get_node("CheckBox")
	
	# VSync
	vbox.add_child(_create_checkbox_option("V-Sync", "_vsync_checkbox"))
	_vsync_checkbox = vbox.get_child(vbox.get_child_count() - 1).get_node("CheckBox")


func _create_gameplay_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Gameplay"
	_tab_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	# Mouse Sensitivity
	vbox.add_child(_create_slider_option("Mouse Sensitivity", "_mouse_sensitivity_slider"))
	_mouse_sensitivity_slider = vbox.get_child(vbox.get_child_count() - 1).get_node("Slider")
	_mouse_sensitivity_slider.min_value = 0.5
	_mouse_sensitivity_slider.max_value = 3.0
	_mouse_sensitivity_slider.step = 0.1
	
	# Invert Y
	vbox.add_child(_create_checkbox_option("Invert Y Axis", "_invert_y_checkbox"))
	_invert_y_checkbox = vbox.get_child(vbox.get_child_count() - 1).get_node("CheckBox")
	
	# Friendly Fire
	vbox.add_child(_create_checkbox_option("Friendly Fire", "_friendly_fire_checkbox"))
	_friendly_fire_checkbox = vbox.get_child(vbox.get_child_count() - 1).get_node("CheckBox")
	
	# Damage Numbers
	vbox.add_child(_create_checkbox_option("Show Damage Numbers", "_damage_numbers_checkbox"))
	_damage_numbers_checkbox = vbox.get_child(vbox.get_child_count() - 1).get_node("CheckBox")


func _create_controls_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Controls"
	_tab_container.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	
	var info = Label.new()
	info.text = "Control remapping coming in future update.\n\nCurrent controls:\n\nMovement: WASD\nJump: Space\nCrouch: Ctrl\nSprint: Shift\nInteract: E\n\nCombat:\nPrimary Fire: Left Click\nSecondary Fire: Right Click\nInventory: I\nSkills: K\nQuests: Q"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)


func _create_slider_option(label_text: String, node_name: String) -> Control:
	var container = VBoxContainer.new()
	container.name = node_name
	container.add_theme_constant_override("separation", 4)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(300, 0)
	container.add_child(slider)
	
	return container


func _create_option_menu(label_text: String, node_name: String) -> Control:
	var container = HBoxContainer.new()
	container.name = node_name
	container.add_theme_constant_override("separation", 16)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(200, 0)
	container.add_child(label)
	
	var option = OptionButton.new()
	option.name = "Option"
	option.custom_minimum_size = Vector2(200, 0)
	container.add_child(option)
	
	return container


func _create_checkbox_option(label_text: String, node_name: String) -> Control:
	var container = HBoxContainer.new()
	container.name = node_name
	container.add_theme_constant_override("separation", 16)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.custom_minimum_size = Vector2(200, 0)
	container.add_child(label)
	
	var checkbox = CheckBox.new()
	checkbox.name = "CheckBox"
	container.add_child(checkbox)
	
	return container


func _apply_panel_style(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.35)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func open() -> void:
	_is_open = true
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_load_settings()


func close() -> void:
	_is_open = false
	hide()
	settings_closed.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# =============================================================================
# SETTINGS LOAD/SAVE
# =============================================================================

func _load_settings() -> void:
	if SaveManager == null:
		return
	
	var settings = SaveManager.settings_data
	
	# Audio
	if settings.has("audio"):
		_master_volume_slider.value = settings.audio.get("master_volume", 1.0)
		_music_volume_slider.value = settings.audio.get("music_volume", 0.8)
		_sfx_volume_slider.value = settings.audio.get("sfx_volume", 1.0)
		_voice_volume_slider.value = settings.audio.get("voice_volume", 1.0)
	
	# Video
	if settings.has("video"):
		_fullscreen_checkbox.button_pressed = settings.video.get("fullscreen", false)
		_vsync_checkbox.button_pressed = settings.video.get("vsync", true)
		_resolution_option.select(settings.video.get("resolution_index", 1))
		_quality_option.select(settings.video.get("quality_preset", 2))
	
	# Gameplay
	if settings.has("gameplay"):
		_mouse_sensitivity_slider.value = settings.gameplay.get("mouse_sensitivity", Constants.MOUSE_SENSITIVITY)
		_invert_y_checkbox.button_pressed = settings.gameplay.get("invert_y", false)
		_friendly_fire_checkbox.button_pressed = settings.gameplay.get("friendly_fire", false)
		_damage_numbers_checkbox.button_pressed = settings.gameplay.get("show_damage_numbers", true)


func _save_settings() -> void:
	if SaveManager == null:
		return
	
	# Audio
	SaveManager.settings_data.audio.master_volume = _master_volume_slider.value
	SaveManager.settings_data.audio.music_volume = _music_volume_slider.value
	SaveManager.settings_data.audio.sfx_volume = _sfx_volume_slider.value
	SaveManager.settings_data.audio.voice_volume = _voice_volume_slider.value
	
	# Video
	SaveManager.settings_data.video.fullscreen = _fullscreen_checkbox.button_pressed
	SaveManager.settings_data.video.vsync = _vsync_checkbox.button_pressed
	SaveManager.settings_data.video.resolution_index = _resolution_option.selected
	SaveManager.settings_data.video.quality_preset = _quality_option.selected
	
	# Gameplay
	SaveManager.settings_data.gameplay.mouse_sensitivity = _mouse_sensitivity_slider.value
	SaveManager.settings_data.gameplay.invert_y = _invert_y_checkbox.button_pressed
	SaveManager.settings_data.gameplay.friendly_fire = _friendly_fire_checkbox.button_pressed
	SaveManager.settings_data.gameplay.show_damage_numbers = _damage_numbers_checkbox.button_pressed
	
	# Apply video settings
	if _fullscreen_checkbox.button_pressed:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
	
	get_window().vsync_mode = DisplayServer.VSYNC_ENABLED if _vsync_checkbox.button_pressed else DisplayServer.VSYNC_DISABLED
	
	# Apply gameplay settings to player
	var local_player = _get_local_player()
	if local_player:
		# Apply mouse sensitivity
		if local_player.has_method("set_mouse_sensitivity"):
			local_player.set_mouse_sensitivity(_mouse_sensitivity_slider.value)
		
		# Apply invert Y
		if local_player.has_method("set_invert_y"):
			local_player.set_invert_y(_invert_y_checkbox.button_pressed)
	
	# Apply audio settings to audio buses
	_apply_audio_settings()
	
	# Save to file
	SaveManager.save_settings()
	settings_applied.emit()

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_apply_pressed() -> void:
	_save_settings()
	close()


func _on_reset_pressed() -> void:
	# Confirm reset
	var confirmation = ConfirmationDialog.new()
	confirmation.title = "Reset Settings"
	confirmation.dialog_text = "Are you sure you want to reset all settings to defaults?"
	confirmation.confirmed.connect(_perform_reset)
	add_child(confirmation)
	confirmation.popup_centered_ratio(0.3)


func _perform_reset() -> void:
	SaveManager.settings_data = SaveManager._get_default_settings()
	_load_settings()


func _exit_tree() -> void:
	"""Disconnect all signals before tree exit to prevent memory leaks"""
	_disconnect_all_signals()


func _disconnect_all_signals() -> void:
	"""Disconnect button signals to prevent memory leaks"""
	if _close_button and is_instance_valid(_close_button):
		if _close_button.pressed.is_connected(close):
			_close_button.pressed.disconnect(close)
	
	if _apply_button and is_instance_valid(_apply_button):
		if _apply_button.pressed.is_connected(_on_apply_pressed):
			_apply_button.pressed.disconnect(_on_apply_pressed)


func _apply_audio_settings() -> void:
	"""Apply audio settings to audio buses"""
	# Get AudioBusLayout if it exists, otherwise use string names
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	var voice_bus = AudioServer.get_bus_index("Voice")
	
	# Convert volume (0.0-1.0) to dB (-40 to 0)
	var master_db = linear_to_db(_master_volume_slider.value) if _master_volume_slider.value > 0 else -80
	var music_db = linear_to_db(_music_volume_slider.value) if _music_volume_slider.value > 0 else -80
	var sfx_db = linear_to_db(_sfx_volume_slider.value) if _sfx_volume_slider.value > 0 else -80
	var voice_db = linear_to_db(_voice_volume_slider.value) if _voice_volume_slider.value > 0 else -80
	
	if master_bus != -1:
		AudioServer.set_bus_volume_db(master_bus, master_db)
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, music_db)
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, sfx_db)
	if voice_bus != -1:
		AudioServer.set_bus_volume_db(voice_bus, voice_db)


func _get_local_player() -> Node:
	"""Find the local player node"""
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.has_method("is_local_player") and player.is_local_player:
			return player
	return null
