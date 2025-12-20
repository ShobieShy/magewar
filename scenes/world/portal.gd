## Portal - Fast travel node that allows teleportation between areas
## Extends Interactable for player interaction handling
extends Interactable
class_name Portal

# =============================================================================
# SIGNALS
# =============================================================================

signal portal_activated()
signal portal_deactivated()
signal travel_initiated(destination_id: String)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var portal_id: String = ""  ## Unique ID matching FastTravelManager registry
@export var is_active: bool = false  ## Whether portal can be used
@export var requires_boss_defeat: bool = false  ## Portal activates after boss killed
@export var auto_register: bool = true  ## Register with FastTravelManager on ready

@export_group("Visual")
@export var inactive_color: Color = Color(0.3, 0.3, 0.4, 0.5)
@export var active_color: Color = Color(0.4, 0.6, 1.0, 0.8)
@export var travel_effect_scene: PackedScene

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var portal_mesh: MeshInstance3D = $PortalMesh
@onready var particles: GPUParticles3D = $Particles if has_node("Particles") else null
@onready var light: OmniLight3D = $OmniLight3D if has_node("OmniLight3D") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

# =============================================================================
# PROPERTIES
# =============================================================================

var _portal_material: StandardMaterial3D

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	super._ready()
	
	# Set up interaction
	interaction_prompt = "[E] Fast Travel"
	one_time_only = false
	
	# Create material if mesh exists
	if portal_mesh:
		_portal_material = StandardMaterial3D.new()
		_portal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_portal_material.emission_enabled = true
		portal_mesh.material_override = _portal_material
	
	# Register with FastTravelManager
	if auto_register and not portal_id.is_empty():
		FastTravelManager.register_portal(portal_id, self)
	
	# Set initial state
	_update_visual()
	
	# If portal requires boss defeat, start inactive
	if requires_boss_defeat:
		is_active = false
		can_interact = false


func _exit_tree() -> void:
	if auto_register and not portal_id.is_empty():
		FastTravelManager.unregister_portal(portal_id)

# =============================================================================
# ACTIVATION
# =============================================================================

func set_active(active: bool) -> void:
	var was_active = is_active
	is_active = active
	can_interact = active
	
	_update_visual()
	
	if active and not was_active:
		portal_activated.emit()
		if animation_player and animation_player.has_animation("activate"):
			animation_player.play("activate")
	elif not active and was_active:
		portal_deactivated.emit()


func activate() -> void:
	set_active(true)
	
	# Unlock in FastTravelManager
	if not portal_id.is_empty():
		FastTravelManager.unlock_portal(portal_id)


func deactivate() -> void:
	set_active(false)

# =============================================================================
# INTERACTION
# =============================================================================

func _perform_interaction(player: Node) -> void:
	if not is_active:
		return
	
	# Open fast travel menu
	_open_travel_menu(player)


func _open_travel_menu(player: Node) -> void:
	## Opens the fast travel destination selection UI
	var game = get_tree().current_scene
	
	# Try to find or create fast travel menu
	var travel_menu = game.get_node_or_null("UI/FastTravelMenu")
	if travel_menu == null:
		# Create menu dynamically
		var menu_scene = load("res://scenes/ui/menus/fast_travel_menu.tscn")
		if menu_scene:
			travel_menu = menu_scene.instantiate()
			var ui_node = game.get_node_or_null("UI")
			if ui_node:
				ui_node.add_child(travel_menu)
			else:
				game.add_child(travel_menu)
	
	if travel_menu and travel_menu.has_method("open"):
		travel_menu.open(portal_id)
		travel_menu.destination_selected.connect(_on_destination_selected, CONNECT_ONE_SHOT)


func _on_destination_selected(destination_id: String) -> void:
	if destination_id.is_empty():
		return
	
	travel_initiated.emit(destination_id)
	_perform_travel(destination_id)


func _perform_travel(destination_id: String) -> void:
	## Initiates travel to the destination
	
	# Play travel effect
	if travel_effect_scene:
		var effect = travel_effect_scene.instantiate()
		if effect is Node3D:
			effect.global_position = global_position
		get_tree().current_scene.add_child(effect)
	
	# Animate out
	if animation_player and animation_player.has_animation("travel_out"):
		animation_player.play("travel_out")
		await animation_player.animation_finished
	
	# Execute travel through FastTravelManager
	if GameManager.is_host:
		FastTravelManager.travel_to_portal(destination_id, portal_id)
	else:
		# Request travel from host
		if is_multiplayer_authority():
			FastTravelManager._rpc_request_travel.rpc_id(1, destination_id)
		else:
			push_warning("Cannot request travel: not authority")

# =============================================================================
# VISUAL
# =============================================================================

func _update_visual() -> void:
	var color = active_color if is_active else inactive_color
	
	if _portal_material:
		_portal_material.albedo_color = color
		_portal_material.emission = color * (2.0 if is_active else 0.5)
	
	if particles:
		particles.emitting = is_active
	
	if light:
		light.light_color = color
		light.light_energy = 2.0 if is_active else 0.5


func pulse() -> void:
	## Visual pulse effect when player approaches
	if not is_active:
		return
	
	var tween = create_tween()
	tween.tween_property(_portal_material, "emission", active_color * 4.0, 0.15)
	tween.tween_property(_portal_material, "emission", active_color * 2.0, 0.15)

# =============================================================================
# UTILITY
# =============================================================================

func get_spawn_position() -> Vector3:
	## Returns position where players should spawn when arriving at this portal
	return global_position + FastTravelManager.get_portal_spawn_offset(portal_id)
