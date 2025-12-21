## Wraith Enemy - Implements the wraith enemy with phasing and life drain abilities
class_name WraithEnemy
extends EnemyBase

# =============================================================================
# SIGNALS
# =============================================================================

signal phased_out()
signal phased_in()
signal life_drained(amount: float, target: Node)
signal teleported(from: Vector3, to: Vector3)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Wraith Config")
@export var wraith_data: WraithEnemyData
@export var variant: WraithEnemyData.WraithVariant = WraithEnemyData.WraithVariant.BASIC

# =============================================================================
# PROPERTIES
# =============================================================================

var is_phased: bool = false
var is_invisible: bool = false
var life_drain_target: Node = null
var life_drain_timer: float = 0.0
var teleport_timer: float = 0.0
var invisibility_timer: float = 0.0
var phase_timer: float = 0.0
var special_ability_timer: float = 0.0

# Visual effects
var phase_particles: GPUParticles3D
var drain_beam: Node3D
var teleport_effect: GPUParticles3D
var original_transparency: float = 0.0

# Movement
var float_offset: float = 0.0
var float_speed: float = 2.0
var dodge_cooldown: float = 0.0

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	super._ready()
	
	# Set up wraith specific properties
	enemy_name = "Wraith"
	enemy_type = Enums.EnemyType.ELITE
	
	# Load wraith data if not set
	if not wraith_data:
		wraith_data = WraithEnemyData.new()
		wraith_data.variant = variant
	
	# Apply wraith stats from data
	_apply_wraith_stats()
	
	# Create visual effects
	_setup_visual_effects()
	
	# Set up special abilities based on variant
	_setup_variant_abilities()
	
	# Wraiths float above ground
	position.y += 0.5

func _physics_process(delta: float) -> void:
	# Handle floating animation
	_process_floating(delta)
	
	# Don't use normal physics when phased
	if is_phased:
		_process_phased_movement(delta)
		return
	
	super._physics_process(delta)
	
	if stats and not stats.is_dead:
		# Handle life drain
		_process_life_drain(delta)
		
		# Process special abilities
		_process_special_abilities(delta)
		
		# Update timers
		_update_timers(delta)
		
		# Handle invisibility
		_process_invisibility(delta)
		
		# Smart dodging
		_process_dodging(delta)

# =============================================================================
# WRAITH SPECIFIC METHODS
# =============================================================================

func _apply_wraith_stats() -> void:
	"""Apply stats from wraith data"""
	max_health = wraith_data.health * level
	damage = wraith_data.damage
	defense = 0  # Wraiths have no physical defense
	move_speed = wraith_data.speed
	attack_range = wraith_data.attack_range
	detection_range = wraith_data.detection_range
	attack_cooldown = 1.2  # Fast attacks
	
	# Update stats component
	if stats:
		stats.max_health = max_health
		stats.reset_stats()
	
	# Set loot table
	loot_table = wraith_data.get_loot_table()
	gold_drop_base = wraith_data.gold_drop_min
	
	# Update mesh appearance
	if has_node("MeshInstance3D"):
		var mesh_instance = $MeshInstance3D
		if mesh_instance.material_override:
			mesh_instance.material_override.albedo_color = wraith_data.mesh_color
			mesh_instance.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_instance.material_override.albedo_color.a = 0.7  # Semi-transparent
			original_transparency = 0.7
		mesh_instance.scale = wraith_data.mesh_scale

func _setup_visual_effects() -> void:
	"""Create visual effect nodes"""
	# Phase particles
	phase_particles = GPUParticles3D.new()
	phase_particles.amount = 30
	phase_particles.lifetime = 1.5
	phase_particles.emitting = false
	var phase_mat = ParticleProcessMaterial.new()
	phase_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	phase_mat.emission_sphere_radius = 0.5
	phase_mat.initial_velocity_min = 1.0
	phase_mat.initial_velocity_max = 2.0
	phase_mat.color = Color(0.4, 0.0, 0.8)  # Dark purple color
	phase_mat.scale_min = 0.5
	phase_mat.scale_max = 1.0
	phase_particles.process_material = phase_mat
	phase_particles.draw_pass_1 = SphereMesh.new()
	phase_particles.draw_pass_1.radius = 0.05
	phase_particles.draw_pass_1.height = 0.1
	add_child(phase_particles)
	
	# Teleport effect
	teleport_effect = GPUParticles3D.new()
	teleport_effect.amount = 50
	teleport_effect.lifetime = 0.5
	teleport_effect.emitting = false
	teleport_effect.one_shot = true
	var teleport_mat = ParticleProcessMaterial.new()
	teleport_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	teleport_mat.initial_velocity_min = 3.0
	teleport_mat.initial_velocity_max = 5.0
	teleport_mat.color = Color.VIOLET
	teleport_effect.process_material = teleport_mat
	teleport_effect.draw_pass_1 = SphereMesh.new()
	teleport_effect.draw_pass_1.radius = 0.03
	teleport_effect.draw_pass_1.height = 0.06
	add_child(teleport_effect)
	
	# Life drain beam (simple line for now)
	drain_beam = Node3D.new()
	var beam_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = 1.0
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	beam_mesh.mesh = cylinder
	var beam_material = StandardMaterial3D.new()
	beam_material.albedo_color = Color(0.8, 0.2, 0.8, 0.8)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.emission_enabled = true
	beam_material.emission = Color.PURPLE
	beam_material.emission_energy = 2.0
	beam_mesh.material_override = beam_material
	drain_beam.add_child(beam_mesh)
	drain_beam.visible = false
	add_child(drain_beam)

func _setup_variant_abilities() -> void:
	"""Configure abilities based on wraith variant"""
	match wraith_data.variant:
		WraithEnemyData.WraithVariant.SHADOW:
			# Increased stealth capabilities
			invisibility_timer = 0.0
		WraithEnemyData.WraithVariant.FROST_WRAITH:
			# Ice element effects
			if phase_particles:
				phase_particles.process_material.color = Color.LIGHT_BLUE
		WraithEnemyData.WraithVariant.ANCIENT:
			# Enhanced all abilities
			detection_range *= 1.2
			move_speed *= 1.1

# =============================================================================
# FLOATING ANIMATION
# =============================================================================

func _process_floating(delta: float) -> void:
	"""Create floating effect"""
	float_offset += delta * float_speed
	
	# Sinusoidal floating
	var float_height = sin(float_offset) * 0.2
	
	# Apply to mesh only, not collision
	if has_node("MeshInstance3D"):
		$MeshInstance3D.position.y = 1.0 + float_height

# =============================================================================
# PHASING ABILITIES
# =============================================================================

func _enter_phase() -> void:
	"""Enter phase state - become intangible"""
	if is_phased:
		return
	
	is_phased = true
	phased_out.emit()
	phase_timer = wraith_data.phase_duration
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Visual effect
	if phase_particles:
		phase_particles.emitting = true
	
	# Make more transparent
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		if mesh.material_override:
			var tween = create_tween()
			tween.tween_property(mesh.material_override, "albedo_color:a", 0.2, 0.3)

func _exit_phase() -> void:
	"""Exit phase state"""
	if not is_phased:
		return
	
	is_phased = false
	phased_in.emit()
	
	# Re-enable collision
	collision_layer = 4  # Enemy layer
	collision_mask = 3  # Player and environment
	
	# Visual effect
	if phase_particles:
		phase_particles.emitting = false
	
	# Restore transparency
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		if mesh.material_override:
			var tween = create_tween()
			tween.tween_property(mesh.material_override, "albedo_color:a", original_transparency, 0.3)

func _process_phased_movement(delta: float) -> void:
	"""Special movement when phased"""
	if not current_target:
		_exit_phase()
		return
	
	# Move directly toward target, ignoring obstacles
	var direction = (current_target.global_position - global_position).normalized()
	velocity = direction * move_speed * 1.5  # Move faster when phased
	
	# Still apply some gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta * 0.5
	
	move_and_slide()
	
	# Exit phase when timer expires
	phase_timer -= delta
	if phase_timer <= 0:
		_exit_phase()

# =============================================================================
# LIFE DRAIN
# =============================================================================

func _process_life_drain(delta: float) -> void:
	"""Handle life drain ability"""
	if not wraith_data.has_life_drain():
		return
	
	# Only drain during attack
	if ai_state != Enums.AIState.ATTACK or not current_target:
		if drain_beam:
			drain_beam.visible = false
		life_drain_target = null
		return
	
	# Start draining
	if not life_drain_target:
		life_drain_target = current_target
		life_drain_timer = 0.0
	
	# Update drain beam visual
	if drain_beam and life_drain_target:
		drain_beam.visible = true
		drain_beam.look_at(life_drain_target.global_position, Vector3.UP)
		var distance = global_position.distance_to(life_drain_target.global_position)
		drain_beam.scale.z = distance
		drain_beam.position = Vector3(0, 1, 0)
	
	# Apply drain damage
	life_drain_timer += delta
	if life_drain_timer >= 0.5:  # Drain tick every 0.5 seconds
		life_drain_timer = 0.0
		
		var drain_amount = wraith_data.life_drain_rate * 0.5
		
		if life_drain_target.has_node("StatsComponent"):
			var target_stats: StatsComponent = life_drain_target.get_node("StatsComponent")
			target_stats.take_damage(drain_amount, Enums.DamageType.SHADOW)
			
			# Heal self for portion of damage
			if stats:
				stats.heal(drain_amount * 0.5)
				life_drained.emit(drain_amount * 0.5, life_drain_target)

# =============================================================================
# TELEPORTATION
# =============================================================================

func _teleport() -> void:
	"""Teleport to a new position"""
	if not wraith_data.can_teleport():
		return
	
	var old_position = global_position
	var teleport_range = wraith_data.get_teleport_range()
	
	# Find teleport position
	var target_pos: Vector3
	
	if current_target:
		# Teleport behind target
		var behind_dir = -current_target.transform.basis.z
		target_pos = current_target.global_position + behind_dir * 3.0
	else:
		# Random teleport
		var angle = randf() * TAU
		var distance = randf_range(3.0, teleport_range)
		target_pos = global_position + Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	
	# Teleport effect at origin
	if teleport_effect:
		teleport_effect.global_position = old_position
		teleport_effect.restart()
		teleport_effect.emitting = true
	
	# Move to new position
	global_position = target_pos
	
	# Teleport effect at destination
	if teleport_effect:
		var dest_effect = teleport_effect.duplicate()
		get_tree().current_scene.add_child(dest_effect)
		dest_effect.global_position = target_pos
		dest_effect.emitting = true
		dest_effect.queue_free()  # Auto cleanup
	
	teleported.emit(old_position, target_pos)
	teleport_timer = wraith_data.teleport_cooldown

# =============================================================================
# INVISIBILITY
# =============================================================================

func _enter_invisibility() -> void:
	"""Become invisible"""
	if is_invisible:
		return
	
	is_invisible = true
	invisibility_timer = wraith_data.invisibility_duration
	
	# Make nearly invisible
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		if mesh.material_override:
			var tween = create_tween()
			tween.tween_property(mesh.material_override, "albedo_color:a", 0.05, 0.5)

func _exit_invisibility() -> void:
	"""Become visible again"""
	if not is_invisible:
		return
	
	is_invisible = false
	
	# Restore visibility
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		if mesh.material_override:
			var tween = create_tween()
			tween.tween_property(mesh.material_override, "albedo_color:a", original_transparency, 0.3)

func _process_invisibility(delta: float) -> void:
	"""Handle invisibility timer"""
	if is_invisible:
		invisibility_timer -= delta
		if invisibility_timer <= 0:
			_exit_invisibility()

# =============================================================================
# SPECIAL ABILITIES
# =============================================================================

func _process_special_abilities(delta: float) -> void:
	"""Handle special ability usage"""
	special_ability_timer -= delta
	
	if special_ability_timer > 0:
		return
	
	# Use abilities based on situation
	match ai_state:
		Enums.AIState.CHASE:
			# Use teleport to close distance
			if current_target and wraith_data.can_teleport():
				var distance = global_position.distance_to(current_target.global_position)
				if distance > 8.0 and teleport_timer <= 0:
					_teleport()
					special_ability_timer = 2.0
			
			# Shadow wraiths go invisible when chasing
			if wraith_data.variant == WraithEnemyData.WraithVariant.SHADOW:
				if not is_invisible and randf() < 0.3:
					_enter_invisibility()
					special_ability_timer = 5.0
		
		Enums.AIState.ATTACK:
			# Phase strike for shadow wraiths
			if wraith_data.special_ability == "phase_strike" and not is_phased:
				if randf() < 0.4:
					_enter_phase()
					special_ability_timer = 8.0
			
			# Frost breath for frost wraiths
			elif wraith_data.special_ability == "frost_breath":
				if current_target:
					_use_frost_breath()
					special_ability_timer = 6.0
			
			# Dimensional shift for ancient wraiths
			elif wraith_data.special_ability == "dimensional_shift":
				_use_dimensional_shift()
				special_ability_timer = 10.0

func _use_frost_breath() -> void:
	"""Frost wraith special attack"""
	if not current_target:
		return
	
	# Create frost cone effect
	for i in range(5):
		var projectile = preload("res://scenes/projectiles/ice_projectile.tscn").instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + Vector3(0, 1, 0)
		
		# Cone spread
		var base_dir = (current_target.global_position - global_position).normalized()
		var spread_angle = deg_to_rad((i - 2) * 10)
		var direction = base_dir.rotated(Vector3.UP, spread_angle)
		
		projectile.setup(direction, damage * 0.6, Enums.Element.ICE, self)

func _use_dimensional_shift() -> void:
	"""Ancient wraith ultimate ability"""
	# Enter phase
	_enter_phase()
	
	# Become invisible
	_enter_invisibility()
	
	# Summon shadow copies
	for i in range(2):
		var copy = preload("res://scenes/enemies/wraith_shadow_copy.tscn").instantiate()
		get_tree().current_scene.add_child(copy)
		
		var offset_angle = deg_to_rad(120 * (i + 1))
		var offset = Vector3(cos(offset_angle) * 3, 0, sin(offset_angle) * 3)
		copy.global_position = global_position + offset
		copy.setup(current_target, 10.0)  # Copies last 10 seconds

# =============================================================================
# SMART DODGING
# =============================================================================

func _process_dodging(delta: float) -> void:
	"""Smart dodge incoming attacks"""
	dodge_cooldown -= delta
	
	if dodge_cooldown > 0 or is_phased:
		return
	
	# Check for incoming projectiles
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3(0, 0, 5)
	)
	query.collision_mask = 8  # Projectile layer
	
	var result = space_state.intersect_ray(query)
	if result:
		# Dodge incoming projectile
		if wraith_data.can_teleport() and teleport_timer <= 0:
			_teleport()
		elif not is_phased and wraith_data.variant == WraithEnemyData.WraithVariant.SHADOW:
			_enter_phase()
		
		dodge_cooldown = 2.0

func _update_timers(delta: float) -> void:
	"""Update all ability timers"""
	if teleport_timer > 0:
		teleport_timer -= delta

# =============================================================================
# OVERRIDE COMBAT
# =============================================================================

func take_damage(amount: float, damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL, attacker: Node = null) -> void:
	"""Override to handle wraith defenses"""
	# Wraiths take extra damage from holy/light
	if damage_type == Enums.DamageType.HOLY:
		amount *= 1.5
	
	# Reduced damage when phased
	if is_phased:
		amount *= 0.2
	
	# Shadow wraiths take less damage when invisible
	if is_invisible:
		amount *= 0.5
		_exit_invisibility()  # Reveal when hit
	
	# Frost wraiths resist ice
	if wraith_data.variant == WraithEnemyData.WraithVariant.FROST_WRAITH:
		if damage_type == Enums.DamageType.ELEMENTAL and wraith_data.element == Enums.Element.ICE:
			amount *= 0.3
	
	super.take_damage(amount, damage_type, attacker)

func _perform_attack() -> void:
	"""Override attack to include special wraith attacks"""
	if life_drain_target:
		# Already draining, don't do normal attack
		return
	
	super._perform_attack()
	
	# Chance to phase after attack
	if wraith_data.variant == WraithEnemyData.WraithVariant.SHADOW and randf() < 0.3:
		_enter_phase()

func _on_died() -> void:
	"""Override death to clean up effects"""
	# Stop all effects
	if phase_particles:
		phase_particles.emitting = false
	if drain_beam:
		drain_beam.visible = false
	
	# Exit phase if phased
	if is_phased:
		_exit_phase()
	
	# Exit invisibility
	if is_invisible:
		_exit_invisibility()
	
	super._on_died()