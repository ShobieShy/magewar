## SpellCaster - Handles spell casting, cooldowns, and delivery
## Attach to entities that can cast spells
class_name SpellCaster
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal spell_cast_started(spell: SpellData)
signal spell_cast_completed(spell: SpellData)
signal spell_cast_interrupted(spell: SpellData)
signal cooldown_updated(spell: SpellData, remaining: float)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var stats_component: StatsComponent
@export var projectile_spawn_point: Node3D

# =============================================================================
# PROPERTIES
# =============================================================================

var _cooldowns: Dictionary = {}  # spell_name -> remaining cooldown
var _casting_spell: SpellData = null
var _cast_timer: float = 0.0
var _global_cooldown: float = 0.0
var _active_beams: Array = []

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	if stats_component == null:
		stats_component = get_parent().get_node_or_null("StatsComponent")


func _process(delta: float) -> void:
	_process_cooldowns(delta)
	_process_casting(delta)

# =============================================================================
# CASTING
# =============================================================================

func can_cast_spell(spell: SpellData) -> bool:
	# Check global cooldown
	if _global_cooldown > 0.0:
		return false
	
	# Check spell cooldown
	if _cooldowns.get(spell.spell_name, 0.0) > 0.0:
		return false
	
	# Check magika
	if stats_component and not stats_component.has_magika(spell.get_final_magika_cost()):
		return false
	
	# Check if already casting
	if _casting_spell != null and not spell.can_be_interrupted:
		return false
	
	return true


func cast_spell(spell: SpellData, aim_point: Vector3 = Vector3.ZERO, aim_direction: Vector3 = Vector3.FORWARD) -> bool:
	if not can_cast_spell(spell):
		return false

	# Interrupt current cast if any
	if _casting_spell != null:
		interrupt_cast()

	# Use magika
	if stats_component:
		stats_component.use_magika(spell.get_final_magika_cost())

	# Network synchronization - notify other players
	if get_node_or_null("/root/SpellNetworkManager") and NetworkManager and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE:
		var caster = get_parent()
		if caster and caster is Player:
			var prediction_id = randi() if NetworkManager.is_server else 0
			get_node("/root/SpellNetworkManager").cast_spell_network(
				spell.spell_name,
				caster.global_position,
				aim_point,
				aim_direction,
				prediction_id
			)

	# Start cast
	if spell.cast_time > 0.0:
		_casting_spell = spell
		_cast_timer = spell.cast_time
		spell_cast_started.emit(spell)
		# Store aim data for when cast completes
		_casting_spell.set_meta("aim_point", aim_point)
		_casting_spell.set_meta("aim_direction", aim_direction)
	else:
		# Instant cast
		_execute_spell(spell, aim_point, aim_direction)

	return true


func interrupt_cast() -> void:
	if _casting_spell != null:
		spell_cast_interrupted.emit(_casting_spell)
		_casting_spell = null
		_cast_timer = 0.0


func _process_casting(delta: float) -> void:
	if _casting_spell == null:
		return
	
	_cast_timer -= delta
	
	if _cast_timer <= 0.0:
		var spell = _casting_spell
		var aim_point = spell.get_meta("aim_point", Vector3.ZERO)
		var aim_direction = spell.get_meta("aim_direction", Vector3.FORWARD)
		_casting_spell = null
		_execute_spell(spell, aim_point, aim_direction)

# =============================================================================
# SPELL EXECUTION
# =============================================================================

func _execute_spell(spell: SpellData, aim_point: Vector3, aim_direction: Vector3) -> void:
	var caster = get_parent()
	
	# Validate caster is still valid and in tree
	if not is_instance_valid(caster) or not caster.is_inside_tree():
		push_warning("Cannot execute spell: caster invalid or not in scene tree")
		return
	
	# Set cooldowns
	_cooldowns[spell.spell_name] = spell.get_final_cooldown()
	_global_cooldown = Constants.GLOBAL_COOLDOWN
	
	# Spawn cast effect
	if spell.cast_effect:
		var effect = spell.cast_effect.instantiate()
		if effect and is_instance_valid(effect):
			if effect is Node3D and projectile_spawn_point:
				effect.global_position = projectile_spawn_point.global_position
			get_tree().current_scene.add_child(effect)
		else:
			push_warning("Failed to instantiate cast effect")
	
	# Play cast sound
	if spell.cast_sound:
		_play_sound(spell.cast_sound, projectile_spawn_point.global_position if projectile_spawn_point else get_parent().global_position)
	
	# Execute based on delivery type
	match spell.delivery_type:
		Enums.SpellDelivery.HITSCAN:
			_execute_hitscan(spell, aim_direction)
		Enums.SpellDelivery.PROJECTILE:
			_execute_projectile(spell, aim_point, aim_direction)
		Enums.SpellDelivery.AOE:
			_execute_aoe(spell, aim_point)
		Enums.SpellDelivery.BEAM:
			_execute_beam(spell, aim_direction)
		Enums.SpellDelivery.SELF:
			_execute_self(spell)
		Enums.SpellDelivery.CONE:
			_execute_cone(spell, aim_direction)
		Enums.SpellDelivery.CHAIN:
			_execute_chain(spell, aim_direction)
		Enums.SpellDelivery.SUMMON:
			_execute_summon(spell, aim_point)
	
	spell_cast_completed.emit(spell)
	
	# Grant experience to active weapon
	_grant_weapon_xp_from_spell(spell)

# =============================================================================
# DELIVERY IMPLEMENTATIONS
# =============================================================================

func _execute_hitscan(spell: SpellData, direction: Vector3) -> void:
	var caster = get_parent()
	if caster == null:
		push_error("_execute_hitscan: Caster is null")
		return
	
	var start_pos = projectile_spawn_point.global_position if projectile_spawn_point else caster.global_position
	
	# Get physics space with validation
	var world_3d = caster.get_world_3d()
	if world_3d == null:
		push_error("_execute_hitscan: Could not get world 3d")
		return
	
	var space_state = world_3d.direct_space_state
	if space_state == null:
		push_error("_execute_hitscan: Could not get space state")
		return
	
	var end_pos = start_pos + direction * spell.get_final_range()
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	
	# Properly exclude caster to avoid self-collision
	if caster is CollisionObject3D:
		query.exclude = [caster.get_rid()]
	
	# Configure collision layers for hitscan: enemies, players, and world geometry
	query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS | Constants.LAYER_WORLD
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var target = result.collider
		if target == null or not is_instance_valid(target):
			return
		
		var hit_point = result.position
		var hit_normal = result.normal
		
		# Apply effects
		for effect in spell.effects:
			if effect and is_instance_valid(effect):
				effect.apply(caster, target, hit_point, spell)
		
		# Spawn impact effect
		_spawn_impact(spell, hit_point, hit_normal)


func _execute_projectile(spell: SpellData, aim_point: Vector3, direction: Vector3) -> void:
	var caster = get_parent()
	var start_pos = projectile_spawn_point.global_position if projectile_spawn_point else caster.global_position

	# Create unique projectile ID for network sync
	var projectile_id = str(randi()) + "_" + str(Time.get_ticks_msec())
	
	for i in range(spell.projectile_count):
		var proj_dir = direction
		
		# Apply spread
		if spell.projectile_spread > 0.0 and spell.projectile_count > 1:
			var spread_angle = deg_to_rad(spell.projectile_spread)
			var spread_offset = (float(i) / (spell.projectile_count - 1) - 0.5) * spread_angle
			proj_dir = proj_dir.rotated(Vector3.UP, spread_offset)
		
		# Spawn projectile
		var projectile: Node3D
		var scene_to_use: PackedScene = null
		
		if spell.projectile_scene:
			scene_to_use = spell.projectile_scene
		else:
			# Use default projectile - load dynamically
			scene_to_use = load("res://scenes/spells/projectile.tscn")
			if not scene_to_use:
				push_error("Failed to load default projectile scene: res://scenes/spells/projectile.tscn")
				continue
		
		projectile = scene_to_use.instantiate()
		
		# Validate projectile was created
		if not projectile:
			push_error("Failed to instantiate projectile for spell: %s - instantiate() returned null" % spell.spell_name)
			continue
		
		# Add to scene tree FIRST, then configure
		var current_scene = get_tree().current_scene
		if not current_scene:
			push_error("Cannot cast projectile: no current scene")
			return
		
		current_scene.add_child(projectile)

		# Now we can safely set global properties
		projectile.global_position = start_pos
		projectile.look_at(start_pos + proj_dir)

		# Configure projectile
		if projectile.has_method("initialize"):
			projectile.initialize({
				"caster": caster,
				"spell": spell,
				"direction": proj_dir,
				"speed": spell.projectile_speed,
				"gravity": spell.projectile_gravity,
				"homing": spell.projectile_homing,
				"pierce": spell.projectile_pierce,
				"bounce": spell.projectile_bounce,
				"lifetime": spell.projectile_lifetime,
				"effects": spell.effects
			})

		# Network synchronization - notify other players about projectile creation
		if get_node_or_null("/root/SpellNetworkManager") and NetworkManager and NetworkManager.network_mode != Enums.NetworkMode.OFFLINE:
			var projectile_data = {
				"spell_id": spell.spell_name,
				"speed": spell.projectile_speed,
				"lifetime": spell.projectile_lifetime
			}
			get_node("/root/SpellNetworkManager").synchronize_projectile(
				projectile_id + "_" + str(i),
				"projectile",
				start_pos,
				proj_dir * spell.projectile_speed,
				projectile_data
			)


func _execute_aoe(spell: SpellData, center: Vector3) -> void:
	var caster = get_parent()
	if caster == null:
		push_error("_execute_aoe: Caster is null")
		return
	
	# Get physics space with validation
	var world_3d = caster.get_world_3d()
	if world_3d == null:
		push_error("_execute_aoe: Could not get world 3d")
		return
	
	var space_state = world_3d.direct_space_state
	if space_state == null:
		push_error("_execute_aoe: Could not get space state")
		return
	
	# Find all targets in radius
	var shape = SphereShape3D.new()
	shape.radius = spell.get_final_aoe_radius()
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	
	# AOE should only hit characters, not world geometry
	query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var target = result.collider
		if target == null or not is_instance_valid(target):
			continue
		
		# Skip caster if in AoE range
		if target == caster:
			continue
		
		var hit_point = target.global_position if target is Node3D else center
		
		# Calculate falloff
		var damage_mult = 1.0
		if spell.aoe_falloff:
			var dist = center.distance_to(hit_point)
			damage_mult = 1.0 - (dist / spell.get_final_aoe_radius()) * 0.5
		
		# Apply effects
		for effect in spell.effects:
			# Modify damage for falloff (if applicable)
			effect.apply(caster, target, hit_point, spell)
	
	# Spawn impact effect at center
	_spawn_impact(spell, center)


func _execute_beam(spell: SpellData, direction: Vector3) -> void:
	# Beam is continuous - create beam object
	var beam: Node = null
	if ResourceLoader.exists("res://scenes/spells/beam.tscn"):
		var beam_scene = load("res://scenes/spells/beam.tscn")
		if beam_scene:
			beam = beam_scene.instantiate()
	
	if beam == null:
		# Fallback: just do repeated hitscan
		_execute_hitscan(spell, direction)
		return
	
	var caster = get_parent()
	beam.initialize({
		"caster": caster,
		"spell": spell,
		"spawn_point": projectile_spawn_point,
		"direction": direction,
		"width": spell.beam_width,
		"range": spell.get_final_range(),
		"tick_rate": spell.beam_tick_rate,
		"max_duration": spell.beam_max_duration,
		"effects": spell.effects
	})
	
	get_tree().current_scene.add_child(beam)
	_active_beams.append(beam)


func _execute_self(spell: SpellData) -> void:
	var caster = get_parent()
	var hit_point = caster.global_position if caster is Node3D else Vector3.ZERO
	
	for effect in spell.effects:
		effect.apply(caster, caster, hit_point, spell)
	
	_spawn_impact(spell, hit_point)


func _execute_cone(spell: SpellData, direction: Vector3) -> void:
	var caster = get_parent()
	if caster == null:
		push_error("_execute_cone: Caster is null")
		return
	
	var start_pos = projectile_spawn_point.global_position if projectile_spawn_point else caster.global_position
	
	# Get physics space with validation
	var world_3d = caster.get_world_3d()
	if world_3d == null:
		push_error("_execute_cone: Could not get world 3d")
		return
	
	var space_state = world_3d.direct_space_state
	if space_state == null:
		push_error("_execute_cone: Could not get space state")
		return
	
	var cone_angle = deg_to_rad(spell.cone_angle)
	var ray_count = max(3, int(spell.get_final_aoe_radius() * 2))
	
	var hit_targets: Array = []
	
	for i in range(ray_count):
		var angle_offset = (float(i) / (ray_count - 1) - 0.5) * cone_angle
		var ray_dir = direction.rotated(Vector3.UP, angle_offset)
		var end_pos = start_pos + ray_dir * spell.get_final_range()
		
		var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
		
		# Exclude caster from cone
		if caster is CollisionObject3D:
			query.exclude = [caster.get_rid()]
		
		# Cone should hit characters, world geometry can block it
		query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS | Constants.LAYER_WORLD
		
		var result = space_state.intersect_ray(query)
		if result and result.collider not in hit_targets:
			var target = result.collider
			if target == null or not is_instance_valid(target):
				continue
			
			hit_targets.append(target)
			
			for effect in spell.effects:
				if effect and is_instance_valid(effect):
					effect.apply(caster, target, result.position, spell)


func _execute_chain(spell: SpellData, direction: Vector3) -> void:
	var caster = get_parent()
	if caster == null:
		push_error("_execute_chain: Caster is null")
		return
	
	var start_pos = projectile_spawn_point.global_position if projectile_spawn_point else caster.global_position
	
	# Get physics space with validation
	var world_3d = caster.get_world_3d()
	if world_3d == null:
		push_error("_execute_chain: Could not get world 3d")
		return
	
	var space_state = world_3d.direct_space_state
	if space_state == null:
		push_error("_execute_chain: Could not get space state")
		return
	
	# First target via raycast
	var query = PhysicsRayQueryParameters3D.create(start_pos, start_pos + direction * spell.get_final_range())
	
	# Exclude caster from chain
	if caster is CollisionObject3D:
		query.exclude = [caster.get_rid()]
	
	# Chain starts with line-of-sight to first target
	query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS | Constants.LAYER_WORLD
	
	var result = space_state.intersect_ray(query)
	if not result:
		return
	
	var chain_targets: Array = [result.collider]
	var current_pos = result.position
	var damage_mult = 1.0
	
	# Apply to first target
	for effect in spell.effects:
		effect.apply(caster, result.collider, current_pos, spell)
	
	# Chain to additional targets
	for i in range(spell.chain_count - 1):
		damage_mult *= spell.chain_damage_falloff
		
		# Find next closest target
		var shape = SphereShape3D.new()
		shape.radius = spell.chain_range
		
		var shape_query = PhysicsShapeQueryParameters3D.new()
		shape_query.shape = shape
		shape_query.transform = Transform3D(Basis.IDENTITY, current_pos)
		shape_query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS
		
		var nearby = space_state.intersect_shape(shape_query)
		var next_target: Node = null
		var next_dist: float = INF
		
		for nearby_result in nearby:
			var target = nearby_result.collider
			if target in chain_targets:
				continue
			
			var dist = current_pos.distance_to(target.global_position)
			if dist < next_dist:
				next_dist = dist
				next_target = target
		
		if next_target == null:
			break
		
		chain_targets.append(next_target)
		current_pos = next_target.global_position
		
		# Apply effects with damage falloff
		for effect in spell.effects:
			effect.apply(caster, next_target, current_pos, spell)


func _execute_summon(spell: SpellData, position: Vector3) -> void:
	# Summon is handled by SummonEffect
	for effect in spell.effects:
		if effect is SummonEffect:
			effect.apply(get_parent(), null, position, spell)

# =============================================================================
# COOLDOWN MANAGEMENT
# =============================================================================

func _process_cooldowns(delta: float) -> void:
	# Global cooldown
	if _global_cooldown > 0.0:
		_global_cooldown -= delta
	
	# Spell cooldowns
	var to_remove: Array = []
	for spell_name in _cooldowns.keys():
		_cooldowns[spell_name] -= delta
		if _cooldowns[spell_name] <= 0.0:
			to_remove.append(spell_name)
	
	for spell_name in to_remove:
		_cooldowns.erase(spell_name)


func get_cooldown_remaining(spell: SpellData) -> float:
	return maxf(_cooldowns.get(spell.spell_name, 0.0), _global_cooldown)


func is_on_cooldown(spell: SpellData) -> bool:
	return get_cooldown_remaining(spell) > 0.0

# =============================================================================
# UTILITY
# =============================================================================

func _spawn_impact(spell: SpellData, position: Vector3, normal: Vector3 = Vector3.UP) -> void:
	if spell.impact_effect:
		var effect = spell.impact_effect.instantiate()
		if effect is Node3D:
			effect.global_position = position
			if normal != Vector3.UP:
				effect.look_at(position + normal)
		get_tree().current_scene.add_child(effect)
	
	if spell.impact_sound:
		_play_sound(spell.impact_sound, position)


func _play_sound(sound: AudioStream, position: Vector3) -> void:
	var player = AudioStreamPlayer3D.new()
	player.stream = sound
	player.global_position = position
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.play()

# =============================================================================
# WEAPON PROGRESSION
# =============================================================================

## Grant weapon XP from spell cast
## Formula: 5 + (mana_cost / 10)
func _grant_weapon_xp_from_spell(spell: SpellData) -> void:
	var caster = get_parent()
	if not caster or not caster.has_method("grant_weapon_xp"):
		return
	
	# Calculate XP based on spell mana cost
	var base_xp = 5.0
	var spell_cost = spell.get_final_magika_cost() if spell else 0
	var xp_amount = base_xp + (spell_cost / 10.0)
	
	caster.grant_weapon_xp(xp_amount)
