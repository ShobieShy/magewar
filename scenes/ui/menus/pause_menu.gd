## PauseMenu - In-game pause menu with Join, Settings, and Quit options
class_name PauseMenu
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================

signal resume_requested
signal join_requested
signal settings_requested
signal quit_to_menu_requested

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var panel: PanelContainer = $PausePanel
@onready var title_label: Label = $PausePanel/VBoxContainer/TitleLabel
@onready var resume_button: Button = $PausePanel/VBoxContainer/ResumeButton
@onready var join_button: Button = $PausePanel/VBoxContainer/JoinButton
@onready var settings_button: Button = $PausePanel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $PausePanel/VBoxContainer/QuitButton

# =============================================================================
# PROPERTIES
# =============================================================================

var _is_paused: bool = false

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	join_button.pressed.connect(_on_join_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Start hidden
	visible = false
	
	# Make sure this canvas layer stays on top
	layer = 128  # High layer number to ensure it's on top


func _process(_delta: float) -> void:
	# Handle pause/resume input in _process which works when paused
	if Input.is_action_just_pressed("pause"):
		if _is_paused:
			resume()
		else:
			pause()


# =============================================================================
# PAUSE/RESUME
# =============================================================================

func pause() -> void:
	"""Show pause menu and pause the game"""
	print("Pausing game...")
	_is_paused = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()
	print("Game paused, mouse visible")


func resume() -> void:
	"""Hide pause menu and resume the game"""
	print("Resuming game...")
	_is_paused = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resume_requested.emit()
	print("Game resumed, mouse captured")


func is_paused() -> bool:
	"""Check if game is paused"""
	return _is_paused

# =============================================================================
# BUTTON CALLBACKS
# =============================================================================

func _on_resume_pressed() -> void:
	print("Resume button pressed")
	resume()


func _on_join_pressed() -> void:
	print("Join button pressed")
	# Emit signal and let the game scene handle the join functionality
	join_requested.emit()
	# For now, just resume the game
	resume()


func _on_settings_pressed() -> void:
	print("Settings button pressed")
	# Emit signal to open settings
	settings_requested.emit()


func _on_quit_pressed() -> void:
	print("Quit button pressed")
	# Resume before quitting to allow proper cleanup
	get_tree().paused = false
	
	# Emit signal to quit to menu
	quit_to_menu_requested.emit()
