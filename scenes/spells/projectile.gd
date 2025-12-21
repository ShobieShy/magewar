## Projectile - Spell projectile that travels and applies effects on hit
class_name SpellProjectile
extends Area3D

# =============================================================================
# PROPERTIES
# =============================================================================

var caster: Node
var spell
var direction: Vector3 = Vector3(0, 0, -1)
var speed: float = 30.0
var projectile_gravity: float = 0.0
var homing_strength: float = 0.0
var pierce_remaining: int = 0
var bounce_remaining: int = 0
var lifetime: float = 5.0
var effects: Array = []

var _velocity: Vector3 = Vector3.ZERO
var _hit_targets: Array = []
var _homing_target: Node = null
var _age: float = 0.0
var _projectile_pool = null  # Reference to object pool

# Maximum allowed bounces to prevent infinite recursion
const MAX_BOUNCES: int = 10

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Set up collision layers properly (using bit masks)
	# Layer 4 = Projectiles (bit position 4 = value 8)
	collision_layer = 1 << (Constants.LAYER_PROJECTILES - 1)  # Projectile layer
	# Mask for World (1), Players (2), and Enemies (3)
	collision_mask = (1 << (Constants.LAYER_WORLD - 1)) | (1 << (Constants.LAYER_PLAYERS - 1)) | (1 << (Constants.LAYER_ENEMIES - 1))
	monitoring = true
	monitorable = false
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	
	# Lifetime check
	if _age >= lifetime:
		_on_projectile_destroy()
		return
	
	# Apply gravity
	if projectile_gravity != 0.0:
		_velocity.y -= projectile_gravity * delta
	
	# Homing behavior
	if homing_strength > 0.0:
		_update_homing(delta)
	
	# Move projectile with collision detection
	var new_position = global_position + _velocity * delta
	_check_collision_during_movement(global_position, new_position)
	global_position = new_position
	
	# Update rotation to match velocity
	if _velocity.length_squared() > 0.01:
		look_at(global_position + _velocity)

# =============================================================================
# INITIALIZATION
# =============================================================================

func set_pool(pool) -> void:
	"""Set the object pool manager for this projectile"""
	_projectile_pool = pool


func initialize(config: Dictionary) -> void:
	caster = config.get("caster")
	spell = config.get("spell")
	direction = config.get("direction", Vector3(0, 0, -1)).normalized()
	speed = config.get("speed", 30.0)
	projectile_gravity = config.get("gravity", 0.0)
	homing_strength = config.get("homing", 0.0)
	_projectile_pool = config.get("pool", _projectile_pool)  # Allow pool to be set via config
	pierce_remaining = config.get("pierce", 0)
	
	# Clamp bounce count to prevent infinite recursion
	var requested_bounces = config.get("bounce", 0)
	bounce_remaining = mini(requested_bounces, MAX_BOUNCES)
	if requested_bounces > MAX_BOUNCES:
		push_warning("Projectile bounce count %d clamped to max %d" % [requested_bounces, MAX_BOUNCES])
	
	lifetime = config.get("lifetime", 5.0)
	effects = config.get("effects", [])
	
	# Initialize velocity based on the direction and speed
	_velocity = direction * speed
	
	# Apply visual based on spell element if available
	if spell:
		_apply_element_visual(spell.element)


func _check_collision_during_movement(_from_pos: Vector3, to_pos: Vector3) -> void:
	"""Check for collisions while moving from _from_pos to to_pos"""
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
	
	# Check the end position
	_check_collision_at_position(space_state, to_pos)
	
	# Also check the current position to catch fast-moving projectiles
	_check_collision_at_position(space_state, global_position)


func _check_collision_at_position(space_state: PhysicsDirectSpaceState3D, pos: Vector3) -> void:
	"""Check for collisions at a specific position"""
	# Create shape query to detect objects at the given position
	var shape = SphereShape3D.new()
	shape.radius = 0.3  # Projectile collision radius
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, pos)
	query.collision_mask = collision_mask
	
	var results = space_state.intersect_shape(query)
	
	# Check all collisions found
	for result in results:
		var target = result.collider
		if target and target != self:  # Don't hit ourselves
			_handle_hit(target)


func _apply_element_visual(element: Enums.Element) -> void:
	var color: Color
	match element:
		Enums.Element.FIRE:
			color = Color.ORANGE_RED
		Enums.Element.WATER:
			color = Color.DEEP_SKY_BLUE
		Enums.Element.EARTH:
			color = Color.SADDLE_BROWN
		Enums.Element.AIR:
			color = Color.PALE_GREEN
		Enums.Element.LIGHT:
			color = Color.WHITE
		Enums.Element.DARK:
			color = Color.DARK_VIOLET
		_:
			color = Color.MEDIUM_PURPLE  # Default
	
	# Update mesh material
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh and mesh.get_surface_override_material(0):
		var mat = mesh.get_surface_override_material(0).duplicate()
		mat.emission = color
		mesh.set_surface_override_material(0, mat)
	
	# Update light
	var light = get_node_or_null("OmniLight3D")
	if light:
		light.light_color = color

# =============================================================================
# COLLISION
# =============================================================================

func _on_body_entered(body: Node3D) -> void:
	_handle_hit(body)


func _on_area_entered(area: Area3D) -> void:
	# Handle area-based hitboxes
	if area.is_in_group("hitbox"):
		var target_owner = area.get_parent()
		if target_owner:
			_handle_hit(target_owner)


func _handle_hit(target: Node) -> void:
	# Skip caster and caster's team
	if target == caster:
		return
	
	# Skip if target doesn't exist or was freed
	if not is_instance_valid(target):
		return
	
	# Skip already hit targets (for pierce)
	if target in _hit_targets:
		return
	
	# Check collision layers more safely
	var is_world = false
	var is_enemy = false
	var is_player = false
	
	if target is Node3D:
		is_world = (target.collision_layer & (1 << (Constants.LAYER_WORLD - 1))) != 0  # Check world layer bit
	
	is_enemy = target.is_in_group("enemies")
	is_player = target.is_in_group("player") or target.has_method("is_player")
	
	# Determine if we should hit this target based on caster type
	var should_hit = false
	var caster_is_player = caster and (caster.is_in_group("player") or caster.has_method("is_player"))
	var caster_is_enemy = caster and caster.is_in_group("enemies")
	
	if is_world:
		# Always hit world geometry
		should_hit = true
	elif caster_is_player and is_enemy:
		# Player projectile hits enemies
		should_hit = true
	elif caster_is_enemy and is_player:
		# Enemy projectile hits players
		should_hit = true
	elif SaveManager and SaveManager.settings_data and SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false):
		# Friendly fire enabled - can hit same team
		if (caster_is_player and is_player) or (caster_is_enemy and is_enemy):
			should_hit = true
	
	if not should_hit:
		return
	
	# Handle world collision
	if is_world:
		# Only bounce if we have bounces remaining
		if bounce_remaining > 0:
			_bounce(target)
			# Check if bounce consumed the last bounce
			if bounce_remaining <= 0:
				_impact(global_position)
		else:
			_impact(global_position)
		return
	
	# Handle entity hit
	if is_enemy or is_player:
		_hit_targets.append(target)
		
		# Apply spell effects (including damage)
		for effect in effects:
			if effect and effect.has_method("apply"):
				effect.apply(caster, target, global_position, spell)
		
		# Check pierce
		if pierce_remaining > 0:
			pierce_remaining -= 1
		else:
			_impact(global_position)


func _bounce(surface: Node) -> void:
	bounce_remaining -= 1
	
	# Get surface normal via raycast
	var surface_normal = _get_surface_normal(surface)
	
	# Reflect velocity using surface normal: v' = v - 2(v·n)n
	var dot_product = _velocity.dot(surface_normal)
	_velocity = _velocity - (2.0 * dot_product * surface_normal)
	
	# Reduce bounce velocity by 80% (energy loss)
	_velocity *= 0.8
	
	direction = _velocity.normalized()
	
	# Slightly move projectile away from surface to prevent overlap
	global_position += surface_normal * 0.1


func _get_surface_normal(_surface: Node) -> Vector3:
	## Determine surface normal using raycast
	var space_state = get_world_3d().direct_space_state
	var from_pos = global_position
	var to_pos = global_position - direction * 2.0  # Raycast backwards
	
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [self, caster]
	query.collision_mask = Constants.LAYER_WORLD
	
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.normal
	
	# Fallback: simple reflection based on direction
	# Assume flat surface perpendicular to gravity
	return Vector3.UP


func _impact(impact_position: Vector3) -> void:
	# Spawn impact effect
	if spell and spell.impact_effect:
		var effect = spell.impact_effect.instantiate()
		if effect is Node3D:
			effect.global_position = impact_position
		get_tree().current_scene.add_child(effect)
	
	_on_projectile_destroy()


func _on_projectile_destroy() -> void:
	"""Destroy projectile - uses pool if available, otherwise queue_free"""
	if _projectile_pool and is_instance_valid(_projectile_pool):
		# Return to pool for reuse
		_projectile_pool.return_projectile(self)
	else:
		# Fallback: destroy normally if pool not available
		queue_free()

# =============================================================================
# HOMING
# =============================================================================

func _update_homing(delta: float) -> void:
	# Find target if we don't have one
	if _homing_target == null or not is_instance_valid(_homing_target):
		_homing_target = _find_homing_target()
	
	if _homing_target == null:
		return
	
	# Steer toward target
	var target_pos = _homing_target.global_position
	var desired_dir = (target_pos - global_position).normalized()
	
	direction = direction.lerp(desired_dir, homing_strength * delta).normalized()
	_velocity = direction * speed


func _find_homing_target() -> Node:
	# Find nearest valid target
	var nearest: Node = null
	var nearest_dist: float = INF
	
	# Check enemies
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in _hit_targets:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	# Check players (if friendly fire)
	var friendly_fire = false
	if SaveManager and SaveManager.settings_data:
		friendly_fire = SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false)
	if friendly_fire:
		for player in get_tree().get_nodes_in_group("players"):
			if player == caster or player in _hit_targets:
				continue
			var dist = global_position.distance_to(player.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = player
	
	return nearest
