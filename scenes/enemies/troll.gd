## Troll Enemy - Implements the troll enemy with regeneration and rage mode
class_name TrollEnemy
extends EnemyBase

# =============================================================================
# SIGNALS
# =============================================================================

signal rage_activated()
signal ground_slammed(position: Vector3, radius: float)
signal regeneration_tick(amount: float)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Troll Config")
@export var troll_data: TrollEnemyData
@export var variant: TrollEnemyData.TrollVariant = TrollEnemyData.TrollVariant.BASIC

# =============================================================================
# PROPERTIES
# =============================================================================

var is_enraged: bool = false
var regeneration_timer: float = 0.0
var special_ability_timer: float = 0.0
var ground_slam_charge_time: float = 0.0
var is_charging_slam: bool = false

# Visual effects
var original_scale: Vector3
var rage_particles: GPUParticles3D
var slam_indicator: Node3D

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	super._ready()
	
	# Set up troll specific properties
	enemy_name = "Troll"
	enemy_type = Enums.EnemyType.ELITE
	
	# Load troll data if not set
	if not troll_data:
		troll_data = TrollEnemyData.new()
		troll_data.variant = variant
	
	# Apply troll stats from data
	_apply_troll_stats()
	
	# Store original scale for rage mode
	original_scale = scale
	
	# Create visual effects
	_setup_visual_effects()
	
	# Set up special abilities based on variant
	_setup_variant_abilities()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if stats and not stats.is_dead:
		# Handle regeneration
		_process_regeneration(delta)
		
		# Check for rage mode activation
		_check_rage_activation()
		
		# Process special abilities
		_process_special_abilities(delta)
		
		# Handle ground slam charging
		if is_charging_slam:
			_process_ground_slam(delta)

# =============================================================================
# TROLL SPECIFIC METHODS
# =============================================================================

func _apply_troll_stats() -> void:
	"""Apply stats from troll data"""
	max_health = troll_data.health * level
	damage = troll_data.damage
	defense = troll_data.damage * 0.2  # Trolls have natural armor
	move_speed = troll_data.speed
	attack_range = troll_data.attack_range
	detection_range = troll_data.detection_range
	attack_cooldown = 2.0  # Slower attacks but harder hitting
	
	# Update stats component
	if stats:
		stats.max_health = max_health
		stats.reset_stats()
	
	# Set loot table
	loot_table = troll_data.get_loot_table()
	gold_drop_base = troll_data.gold_drop_min
	
	# Update mesh appearance
	if has_node("MeshInstance3D"):
		var mesh_instance = $MeshInstance3D
		if mesh_instance.material_override:
			mesh_instance.material_override.albedo_color = troll_data.mesh_color
		# Scale the mesh for troll size
		mesh_instance.scale = troll_data.mesh_scale

func _setup_visual_effects() -> void:
	"""Create visual effect nodes"""
	# Rage particles
	rage_particles = GPUParticles3D.new()
	rage_particles.amount = 20
	rage_particles.lifetime = 1.0
	rage_particles.emitting = false
	# Configure particle material for rage effect
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 1.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 4.0
	mat.color = Color.RED
	rage_particles.process_material = mat
	rage_particles.draw_pass_1 = SphereMesh.new()
	rage_particles.draw_pass_1.radius = 0.1
	rage_particles.draw_pass_1.height = 0.2
	add_child(rage_particles)
	
	# Ground slam indicator
	slam_indicator = Node3D.new()
	var slam_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = 0.1
	cylinder.radial_segments = 32
	slam_mesh.mesh = cylinder
	var slam_material = StandardMaterial3D.new()
	slam_material.albedo_color = Color(1, 0.2, 0.2, 0.5)
	slam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slam_mesh.material_override = slam_material
	slam_indicator.add_child(slam_mesh)
	slam_indicator.visible = false
	add_child(slam_indicator)

func _setup_variant_abilities() -> void:
	"""Configure abilities based on troll variant"""
	match troll_data.variant:
		TrollEnemyData.TrollVariant.HILL:
			# Can throw rocks at range
			attack_range = 8.0
		TrollEnemyData.TrollVariant.CAVE:
			# Better in darkness
			if has_node("OmniLight3D"):
				$OmniLight3D.light_energy *= 0.5
		TrollEnemyData.TrollVariant.FROST:
			# Add frost visual effect
			if rage_particles:
				rage_particles.process_material.color = Color.LIGHT_BLUE
		TrollEnemyData.TrollVariant.ANCIENT:
			# Stronger regeneration and magic resistance
			defense *= 1.5

# =============================================================================
# REGENERATION SYSTEM
# =============================================================================

func _process_regeneration(delta: float) -> void:
	"""Handle health regeneration"""
	regeneration_timer += delta
	
	# Regenerate every second
	if regeneration_timer >= 1.0:
		regeneration_timer = 0.0
		
		var regen_amount = troll_data.regeneration_rate
		if is_enraged:
			regen_amount *= 1.5  # Faster regen when enraged
		
		# Don't regenerate if recently damaged (within 3 seconds)
		if stats.time_since_last_damage > 3.0:
			stats.heal(regen_amount)
			regeneration_tick.emit(regen_amount)
			
			# Visual feedback for regeneration
			if has_node("MeshInstance3D"):
				var mesh = $MeshInstance3D
				var material = mesh.get_surface_override_material(0)
				if material:
					var mat = material.duplicate()
					var tween = create_tween()
					tween.tween_property(mat, "albedo_color", Color.GREEN, 0.2)
					tween.tween_property(mat, "albedo_color", Color(0.4, 0.3, 0.2, 1), 0.3)
					mesh.set_surface_override_material(0, mat)

# =============================================================================
# RAGE MODE
# =============================================================================

func _check_rage_activation() -> void:
	"""Check if troll should enter rage mode"""
	if is_enraged:
		return
		
	var health_percentage = stats.current_health / stats.max_health
	if health_percentage <= troll_data.rage_threshold:
		_activate_rage_mode()

func _activate_rage_mode() -> void:
	"""Enter rage mode when health is low"""
	is_enraged = true
	rage_activated.emit()
	
	# Apply rage bonuses
	damage *= troll_data.rage_damage_bonus
	move_speed += troll_data.rage_speed_bonus
	attack_cooldown *= 0.75  # Attack faster
	
	# Visual effects
	if rage_particles:
		rage_particles.emitting = true
	
	# Scale up slightly
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.2, 0.5)
	
	# Change mesh color to show rage
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		if mesh.material_override:
			mesh.material_override.albedo_color = Color.RED
	
	# Play rage sound
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()

# =============================================================================
# SPECIAL ABILITIES
# =============================================================================

func _process_special_abilities(delta: float) -> void:
	"""Handle special ability cooldowns and activation"""
	if troll_data.special_ability.is_empty():
		return
	
	special_ability_timer -= delta
	
	# Only use abilities when in combat
	if ai_state != Enums.AIState.ATTACK or special_ability_timer > 0:
		return
	
	# Check if we can use the ability
	if current_target and is_instance_valid(current_target):
		var distance = global_position.distance_to(current_target.global_position)
		
		match troll_data.special_ability:
			"ground_slam":
				if distance <= 5.0:  # Close range for slam
					_start_ground_slam()
			"ice_breath":
				if distance <= 6.0:
					_use_ice_breath()
			"rock_throw":
				if distance > attack_range and distance <= 15.0:
					_throw_rock()

func _start_ground_slam() -> void:
	"""Begin charging ground slam attack"""
	is_charging_slam = true
	ground_slam_charge_time = 0.0
	special_ability_timer = 12.0  # Cooldown
	
	# Show indicator
	if slam_indicator:
		slam_indicator.visible = true
		slam_indicator.scale = Vector3(0.5, 1, 0.5)
		
		# Grow the indicator
		var tween = create_tween()
		tween.tween_property(slam_indicator, "scale", Vector3(6, 1, 6), 1.5)
	
	# Stop moving during charge
	ai_state = Enums.AIState.IDLE
	velocity = Vector3.ZERO

func _process_ground_slam(delta: float) -> void:
	"""Handle ground slam charging"""
	ground_slam_charge_time += delta
	
	# Slam after 1.5 seconds of charging
	if ground_slam_charge_time >= 1.5:
		_execute_ground_slam()
		is_charging_slam = false

func _execute_ground_slam() -> void:
	"""Execute the ground slam attack"""
	ground_slammed.emit(global_position, 5.0)
	
	# Hide indicator
	if slam_indicator:
		slam_indicator.visible = false
	
	# Damage and stun all nearby enemies
	var bodies = []
	if has_node("DetectionArea"):
		bodies = $DetectionArea.get_overlapping_bodies()
	
	for body in bodies:
		if body is Player:
			var distance = global_position.distance_to(body.global_position)
			if distance <= 5.0:
				# Damage based on proximity
				var slam_damage = damage * (1.0 - distance / 5.0) * 2.0
				if body.has_node("StatsComponent"):
					var target_stats: StatsComponent = body.get_node("StatsComponent")
					target_stats.take_damage(slam_damage, Enums.DamageType.PHYSICAL)
				
				# Apply knockback
				if body.has_method("apply_knockback"):
					var knockback_dir = (body.global_position - global_position).normalized()
					knockback_dir.y = 0.5
					body.apply_knockback(knockback_dir * 10.0)
				
				# Apply stun
				if body.has_method("apply_stun"):
					body.apply_stun(troll_data.stun_duration)
	
	# Resume normal AI after slam
	ai_state = Enums.AIState.CHASE

func _use_ice_breath() -> void:
	"""Frost troll ice breath attack"""
	special_ability_timer = 8.0
	
	# Create ice projectile spread
	for i in range(3):
		var projectile = preload("res://scenes/projectiles/ice_projectile.tscn").instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + Vector3(0, 1, 0)
		
		# Spread pattern
		var direction = (current_target.global_position - global_position).normalized()
		direction = direction.rotated(Vector3.UP, deg_to_rad((i - 1) * 15))
		
		projectile.setup(direction, damage * 0.8, Enums.Element.WATER, self)  # Frost/Ice

func _throw_rock() -> void:
	"""Hill troll rock throw attack"""
	special_ability_timer = 5.0
	
	# Create rock projectile
	var rock = RigidBody3D.new()
	var rock_mesh = MeshInstance3D.new()
	rock_mesh.mesh = SphereMesh.new()
	rock_mesh.mesh.radius = 0.3
	rock.add_child(rock_mesh)
	
	# Add collision
	var collision = CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	collision.shape.radius = 0.3
	rock.add_child(collision)
	
	get_tree().current_scene.add_child(rock)
	rock.global_position = global_position + Vector3(0, 2, 0)
	
	# Calculate throw trajectory
	var target_pos = current_target.global_position
	var direction = (target_pos - rock.global_position).normalized()
	var distance = rock.global_position.distance_to(target_pos)
	
	# Apply force with arc
	rock.linear_velocity = direction * min(distance * 2, 20) + Vector3(0, 5, 0)
	
	# Connect collision detection
	rock.body_entered.connect(_on_rock_hit.bind(rock))

func _on_rock_hit(body: Node, rock: RigidBody3D) -> void:
	"""Handle rock projectile hit"""
	if body is Player:
		if body.has_node("StatsComponent"):
			var target_stats: StatsComponent = body.get_node("StatsComponent")
			target_stats.take_damage(damage * 1.5, Enums.DamageType.PHYSICAL)
	
	# Remove rock after hit
	rock.queue_free()

# =============================================================================
# OVERRIDE COMBAT
# =============================================================================

func take_damage(amount: float, damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL, attacker: Node = null) -> void:
	"""Override to handle troll resistances"""
	# Ancient trolls have magic resistance
	if troll_data.variant == TrollEnemyData.TrollVariant.ANCIENT:
		if damage_type == Enums.DamageType.MAGICAL:
			amount *= 0.5
	
	# Frost trolls resist ice damage
	if troll_data.variant == TrollEnemyData.TrollVariant.FROST:
		if damage_type == Enums.DamageType.ELEMENTAL:
			amount *= 0.7
	
	super.take_damage(amount, damage_type, attacker)

func _on_died() -> void:
	"""Override death to stop effects"""
	# Stop rage particles
	if rage_particles:
		rage_particles.emitting = false
	
	# Hide slam indicator
	if slam_indicator:
		slam_indicator.visible = false
	
	super._on_died()
