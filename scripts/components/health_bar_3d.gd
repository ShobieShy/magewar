## HealthBar3D - Displays a 3D health bar above entities
class_name HealthBar3D
extends Node3D

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var sub_viewport: SubViewport = $SubViewport
@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar
@onready var sprite_3d: Sprite3D = $Sprite3D

# =============================================================================
# PROPERTIES
# =============================================================================

var stats_component: StatsComponent = null
var _update_rate: float = 0.1  # Update every 0.1 seconds to reduce overhead
var _update_timer: float = 0.0

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Get stats component from parent
	var parent = get_parent()
	if parent and parent.has_node("StatsComponent"):
		stats_component = parent.get_node("StatsComponent")
		
		# Connect to health changed signal
		if stats_component:
			stats_component.health_changed.connect(_on_health_changed)
			
			# Initialize health bar
			_update_health_bar()
	
	# Make sure SubViewport is enabled
	if sub_viewport:
		sub_viewport.transparent_bg = true
	
	# Make sure sprite is a billboard (faces camera)
	if sprite_3d:
		sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED


func _process(delta: float) -> void:
	if not stats_component:
		return
	
	# Update health bar periodically
	_update_timer += delta
	if _update_timer >= _update_rate:
		_update_health_bar()
		_update_timer = 0.0
	
	# Hide health bar if entity is dead
	if stats_component.is_dead and visible:
		visible = false
	elif not stats_component.is_dead and not visible:
		visible = true

# =============================================================================
# HEALTH BAR UPDATE
# =============================================================================

func _update_health_bar() -> void:
	if not stats_component or not progress_bar:
		return
	
	var health_percent = stats_component.get_health_percent()
	
	# Update the value (0-100)
	progress_bar.value = health_percent * 100.0
	
	# Change color based on health percentage
	var color = _get_health_color(health_percent)
	
	# Create and apply theme override for the fill color
	var theme = Theme.new()
	var style = StyleBoxFlat.new()
	style.bg_color = color
	theme.set_stylebox("fill", "ProgressBar", style)
	progress_bar.theme = theme


func _get_health_color(percent: float) -> Color:
	"""Get health bar color based on health percentage"""
	if percent > 0.5:
		# Green for high health
		return Color.from_hsv(0.33, 0.8, 0.8)  # Green
	elif percent > 0.25:
		# Yellow for medium health
		return Color.from_hsv(0.13, 0.8, 0.8)  # Orange
	else:
		# Red for low health
		return Color.from_hsv(0.0, 0.8, 0.8)   # Red


func _on_health_changed(_current: float, _maximum: float) -> void:
	"""Called when health changes"""
	_update_health_bar()
