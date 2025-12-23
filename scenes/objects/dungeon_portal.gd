## DungeonPortal - Interactive portal for entering/exiting dungeons
class_name DungeonPortal
extends Area3D

# =============================================================================
# SIGNALS
# =============================================================================

signal player_entered(player: Node, portal: DungeonPortal)
signal player_exited(player: Node)
signal activated()
signal deactivated()

# =============================================================================
# ENUMS
# =============================================================================

enum PortalType {
	ENTRANCE,  # Enter a dungeon
	EXIT,      # Exit a dungeon
	TELEPORT   # Teleport within dungeon
}

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Portal Configuration")
@export var portal_id: String = ""  ## Unique identifier
@export var portal_type: PortalType = PortalType.ENTRANCE
@export var dungeon_id: String = ""  ## Which dungeon this leads to
@export var destination_portal_id: String = ""  ## For teleport portals
@export var portal_name: String = "Dungeon Portal"

@export_group("Requirements")
@export var required_level: int = 1
@export var required_quest: String = ""  ## Quest ID that must be active/complete
@export var required_item: String = ""  ## Item needed to use portal
@export var consume_item: bool = false  ## Whether to consume the required item

@export_group("Visuals")
@export var portal_color: Color = Color.CYAN
@export var portal_energy: float = 2.0
@export var rotation_speed: float = 1.0
@export var pulse_speed: float = 2.0
@export var show_particles: bool = true

@export_group("Activation")
@export var is_active: bool = true
@export var is_discovered: bool = false
@export var auto_enter: bool = false  ## Enter immediately on contact
@export var requires_interaction: bool = true  ## Press E to enter

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var light: OmniLight3D = $OmniLight3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interaction_prompt: Label3D = $InteractionPrompt

# =============================================================================
# PROPERTIES
# =============================================================================

var player_in_range: Node = null
var rotation_offset: float = 0.0
var pulse_offset: float = 0.0
var original_scale: Vector3

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	add_to_group("dungeon_portals")
	
	# Set up collision
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Store original scale
	original_scale = scale
	if original_scale.length_squared() < 0.001:
		original_scale = Vector3.ONE
		scale = Vector3.ONE
	
	# Configure visuals
	_setup_visuals()
	
	# Register with portal system
	if has_node("/root/DungeonPortalSystem"):
		var portal_system = get_node("/root/DungeonPortalSystem")
		portal_system.register_portal(self)
	
	# Set initial state
	set_active(is_active)
	
	# Hide interaction prompt initially
	if interaction_prompt:
		interaction_prompt.visible = false

func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Rotate portal effect
	rotation_offset += rotation_speed * delta
	if mesh_instance:
		mesh_instance.rotation.y = rotation_offset
	
	# Pulse effect
	pulse_offset += pulse_speed * delta
	var pulse_scale = 1.0 + sin(pulse_offset) * 0.1
	scale = original_scale * pulse_scale
	
	# Update light intensity
	if light:
		light.light_energy = portal_energy * (1.0 + sin(pulse_offset) * 0.3)
	
	# Handle interaction
	if player_in_range and requires_interaction:
		if Input.is_action_just_pressed("interact"):
			_use_portal(player_in_range)

func _physics_process(_delta: float) -> void:
	# Face the interaction prompt toward camera if player is near
	# Note: Billboard property on Label3D handles this automatically, 
	# but we keep this function if we need other physics logic
	pass

# =============================================================================
# VISUAL SETUP
# =============================================================================

func _setup_visuals() -> void:
	"""Configure portal visuals"""
	# Create mesh if not present
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
	
	# Set up torus mesh for portal
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.2
	torus.rings = 32
	torus.ring_segments = 16
	mesh_instance.mesh = torus
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = portal_color
	material.emission_enabled = true
	material.emission = portal_color
	material.emission_energy_multiplier = portal_energy
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	mesh_instance.material_override = material
	
	# Set up particles
	if not particles:
		particles = GPUParticles3D.new()
		add_child(particles)
	
	if show_particles:
		_setup_particles()
	else:
		particles.emitting = false
	
	# Set up light
	if not light:
		light = OmniLight3D.new()
		add_child(light)
	
	light.light_color = portal_color
	light.light_energy = portal_energy
	light.omni_range = 5.0
	
	# Create interaction prompt
	if not interaction_prompt:
		interaction_prompt = Label3D.new()
		interaction_prompt.text = "[E] Enter " + portal_name
		interaction_prompt.modulate = Color.WHITE
		interaction_prompt.outline_modulate = Color.BLACK
		interaction_prompt.font_size = 24
		interaction_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		interaction_prompt.position.y = 2.5
		add_child(interaction_prompt)

func _setup_particles() -> void:
	"""Configure particle system"""
	particles.amount = 50
	particles.lifetime = 2.0
	particles.emitting = true
	
	var process_material = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process_material.emission_ring_radius = 1.0
	process_material.emission_ring_inner_radius = 0.8
	process_material.emission_ring_height = 0.0
	process_material.emission_ring_axis = Vector3(0, 1, 0)
	
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 1.5
	process_material.angular_velocity_min = -180.0
	process_material.angular_velocity_max = 180.0
	process_material.orbit_velocity_min = 0.5
	process_material.orbit_velocity_max = 1.0
	
	process_material.scale_min = 0.1
	process_material.scale_max = 0.3
	process_material.color = portal_color
	
	particles.process_material = process_material
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.05
	particles.draw_pass_1.height = 0.1

# =============================================================================
# PORTAL FUNCTIONALITY
# =============================================================================

func set_active(active: bool) -> void:
	"""Enable or disable the portal"""
	is_active = active
	
	if is_active:
		activated.emit()
		if mesh_instance:
			mesh_instance.visible = true
		if particles:
			particles.emitting = show_particles
		if light:
			light.visible = true
		if collision_shape:
			collision_shape.disabled = false
	else:
		deactivated.emit()
		if mesh_instance:
			mesh_instance.visible = false
		if particles:
			particles.emitting = false
		if light:
			light.visible = false
		if collision_shape:
			collision_shape.disabled = true

func activate() -> void:
	set_active(true)

func deactivate() -> void:
	set_active(false)

func can_use_portal(player: Node) -> bool:
	"""Check if player can use this portal"""
	if not is_active:
		return false
	
	# Check level requirement
	if required_level > 1:
		if player.has_method("get_level"):
			if player.get_level() < required_level:
				_show_requirement_message("Level " + str(required_level) + " required")
				return false
	
	# Check quest requirement
	if not required_quest.is_empty():
		if QuestManager:
			var quest_state = QuestManager.get_quest_state(required_quest)
			if quest_state != QuestManager.QuestState.ACTIVE and quest_state != QuestManager.QuestState.COMPLETED:
				_show_requirement_message("Quest required: " + required_quest)
				return false
	
	# Check item requirement
	if not required_item.is_empty():
		if player.has_method("has_item"):
			if not player.has_item(required_item):
				_show_requirement_message("Item required: " + required_item)
				return false
	
	return true

func _use_portal(player: Node) -> void:
	"""Player uses the portal"""
	if not can_use_portal(player):
		return
	
	# Consume required item if needed
	if consume_item and not required_item.is_empty():
		if player.has_method("remove_item"):
			player.remove_item(required_item, 1)
	
	# Mark as discovered
	is_discovered = true
	
	# Emit signal for portal system to handle
	player_entered.emit(player, self)
	
	# Visual feedback
	_play_activation_effect()

func _play_activation_effect() -> void:
	"""Play visual effect when portal is used"""
	# Flash effect
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		var original_energy = material.emission_energy_multiplier
		
		var tween = create_tween()
		tween.tween_property(material, "emission_energy_multiplier", original_energy * 3, 0.2)
		tween.tween_property(material, "emission_energy_multiplier", original_energy, 0.5)
	
	# Particle burst
	if particles:
		particles.amount_ratio = 2.0
		var tween = create_tween()
		tween.tween_property(particles, "amount_ratio", 1.0, 1.0)
	
	# Sound effect
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()

func _show_requirement_message(message: String) -> void:
	"""Show requirement message to player"""
	# You could emit a signal here for the UI to display
	print(message)  # Placeholder
	
	# Temporary label
	var temp_label = Label3D.new()
	temp_label.text = message
	temp_label.modulate = Color.RED
	temp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	temp_label.position.y = 3.0
	add_child(temp_label)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(temp_label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(temp_label.queue_free)

func get_spawn_point() -> Node3D:
	"""Get the spawn point for this portal"""
	# Look for a child spawn point
	for child in get_children():
		if child.is_in_group("spawn_points"):
			return child
	
	# Create a temporary node for the spawn position if no child found
	var spawn = Node3D.new()
	spawn.global_position = get_spawn_position()
	return spawn

func get_spawn_position() -> Vector3:
	"""Get the global position where players should spawn when arriving"""
	# If we have a child spawn point, use it
	for child in get_children():
		if child.is_in_group("spawn_points"):
			return child.global_position
	
	# Default to 2 meters in front of the portal
	return global_position + transform.basis.z * 2.0

# =============================================================================
# COLLISION DETECTION
# =============================================================================

func _on_body_entered(body: Node3D) -> void:
	"""Handle body entering portal area"""
	if body.is_in_group("player"):
		player_in_range = body
		
		if auto_enter:
			_use_portal(body)
		elif requires_interaction and interaction_prompt:
			if can_use_portal(body):
				interaction_prompt.text = "[E] Enter " + portal_name
				interaction_prompt.modulate = Color.WHITE
			else:
				interaction_prompt.text = "Locked"
				interaction_prompt.modulate = Color.RED
			interaction_prompt.visible = true

func _on_body_exited(body: Node3D) -> void:
	"""Handle body leaving portal area"""
	if body == player_in_range:
		player_in_range = null
		player_exited.emit(body)
		
		if interaction_prompt:
			interaction_prompt.visible = false
