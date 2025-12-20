## Skeleton - Skeleton enemy implementation
## Handles skeleton-specific behaviors, formations, and coordination
class_name Skeleton
extends EnemyBase

# =============================================================================
# PROPERTIES
# =============================================================================

@export var skeleton_data: SkeletonEnemyData = SkeletonEnemyData.new()
@export var variant: SkeletonEnemyData.SkeletonVariant = SkeletonEnemyData.SkeletonVariant.BASIC

## Formation and coordination
var _formation_group: Array[Skeleton] = []
var _group_commander: Skeleton = null
var _formation_position_index: int = 0
var _special_ability_cooldown: float = 0.0
var _is_in_formation: bool = false
var _coordination_damage_bonus: float = 1.0

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Apply variant configuration
	skeleton_data.variant = variant
	_apply_skeleton_config()
	
	# Call parent ready
	super._ready()
	
	# Add to skeletons group
	add_to_group("skeletons")
	add_to_group("skeleton_variant_" + str(variant))
	
	# Find formation partners
	_find_formation_group()


func _physics_process(delta: float) -> void:
	# Update special ability cooldown
	if _special_ability_cooldown > 0:
		_special_ability_cooldown -= delta
	
	# Update coordination bonus based on nearby allies
	_update_coordination_bonus()
	
	# Call parent physics
	super._physics_process(delta)


# =============================================================================
# CONFIGURATION & INITIALIZATION
# =============================================================================

func _apply_skeleton_config() -> void:
	"""Apply skeleton data to enemy properties"""
	enemy_name = skeleton_data.get_display_name()
	enemy_type = Enums.EnemyType.SKELETON
	level = skeleton_data.level
	max_health = skeleton_data.health
	damage = skeleton_data.damage
	move_speed = skeleton_data.speed
	attack_range = skeleton_data.attack_range
	detection_range = skeleton_data.detection_range
	experience_value = int(skeleton_data.health * 0.6)
	
	# Apply loot table
	loot_table = skeleton_data.get_loot_table()


func _find_formation_group() -> void:
	"""Find nearby skeletons for formation"""
	var skeletons_in_area = get_tree().get_nodes_in_group("skeletons")
	
	# Find nearby skeletons for formation
	for skeleton in skeletons_in_area:
		if skeleton != self and skeleton.position.distance_to(position) < 15.0:
			_formation_group.append(skeleton)
			if skeleton.variant == SkeletonEnemyData.SkeletonVariant.COMMANDER:
				_group_commander = skeleton
			elif _group_commander == null and variant == SkeletonEnemyData.SkeletonVariant.COMMANDER:
				_group_commander = self
	
	# Set formation position
	_formation_position_index = _formation_group.size()


# =============================================================================
# COMBAT BEHAVIOR
# =============================================================================

func _process_attack(delta: float) -> void:
	"""Process attack state with skeleton-specific tactics"""
	if not current_target:
		_change_state(Enums.AIState.IDLE)
		return
	
	var distance_to_target = position.distance_to(current_target.position)
	
	# Check for special abilities
	if _can_use_special_ability():
		_try_use_special_ability()
		return
	
	# Formation-based behavior
	if _is_in_formation and _group_commander:
		_maintain_formation_attack(delta)
	else:
		# Standard attack behavior
		if distance_to_target <= attack_range:
			_attempt_attack()
		else:
			# Move closer
			if navigation:
				navigation.target_position = current_target.position
				velocity = navigation.get_next_path_position() - global_position
				velocity = velocity.normalized() * move_speed


func _attempt_attack() -> void:
	"""Perform a basic attack on the target"""
	velocity = Vector3.ZERO  # Stop moving to attack
	
	if _attack_timer <= 0:
		if current_target and current_target.has_node("StatsComponent"):
			var target_stats = current_target.get_node("StatsComponent")
			var damage_dealt = damage * _coordination_damage_bonus
			
			# Apply damage type
			var damage_type = Enums.DamageType.PHYSICAL
			
			target_stats.take_damage(damage_dealt, damage_type, self)
			damaged.emit(damage_dealt, self)
		
		_attack_timer = attack_cooldown


func _maintain_formation_attack(delta: float) -> void:
	"""Attack while maintaining formation with group"""
	# Calculate formation position relative to commander
	var formation_positions = skeleton_data.get_formation_positions(
		_formation_group.size() + 1,
		_group_commander.position
	)
	
	if _formation_position_index < formation_positions.size():
		var target_position = formation_positions[_formation_position_index]
		
		# Move to maintain formation
		if position.distance_to(target_position) > 1.0:
			navigation.target_position = target_position
			velocity = navigation.get_next_path_position() - global_position
			velocity = velocity.normalized() * move_speed * 0.8
		
		# Attack from formation position
		if current_target:
			var distance_to_target = position.distance_to(current_target.position)
			if distance_to_target <= attack_range:
				_attempt_attack()


func _can_use_special_ability() -> bool:
	"""Check if special ability can be used"""
	return (
		_special_ability_cooldown <= 0 and
		not skeleton_data.special_ability.is_empty() and
		current_target != null
	)


func _try_use_special_ability() -> void:
	"""Attempt to use skeleton's special ability"""
	match skeleton_data.special_ability:
		"multi_shot":
			_use_multi_shot()
		"rage_mode":
			_use_rage_mode()
		"rally_cry":
			_use_rally_cry()
	
	# Set cooldown
	var cooldown = skeleton_data.get_ai_behavior_tree().get("special_cooldown", 10.0)
	_special_ability_cooldown = cooldown


func _use_multi_shot() -> void:
	"""Archer's multi-shot ability"""
	if current_target and current_target.has_node("StatsComponent"):
		var target_stats = current_target.get_node("StatsComponent")
		# Fire 3 shots
		for i in range(3):
			target_stats.take_damage(damage * 0.6, Enums.DamageType.PHYSICAL, self)


func _use_rage_mode() -> void:
	"""Berserker's rage mode - increased damage for duration"""
	# Temporary damage boost
	var old_damage = damage
	damage *= 2.0
	
	# Attack immediately
	if current_target and current_target.has_node("StatsComponent"):
		var target_stats = current_target.get_node("StatsComponent")
		target_stats.take_damage(damage, Enums.DamageType.PHYSICAL, self)
	
	# Reset damage after a moment
	await get_tree().create_timer(2.0).timeout
	damage = old_damage


func _use_rally_cry() -> void:
	"""Commander's rally cry - boost nearby allies"""
	# Boost all nearby skeletons
	var nearby_skeletons = get_tree().get_nodes_in_group("skeletons")
	for skeleton in nearby_skeletons:
		if skeleton != self and skeleton.position.distance_to(position) <= 10.0:
			skeleton._coordination_damage_bonus = 1.3
			# Duration: 5 seconds
			await get_tree().create_timer(5.0).timeout
			skeleton._coordination_damage_bonus = 1.0


# =============================================================================
# AI BEHAVIOR
# =============================================================================

func _process_chase(delta: float) -> void:
	"""Chase behavior with formation support"""
	if not current_target:
		_change_state(Enums.AIState.IDLE)
		return
	
	var distance = position.distance_to(current_target.position)
	
	# Check if target lost
	if distance > detection_range:
		current_target = null
		_change_state(Enums.AIState.PATROL)
		return
	
	# Move toward target (with formation if commander)
	if _group_commander == self and skeleton_data.variant == SkeletonEnemyData.SkeletonVariant.COMMANDER:
		# Lead the formation
		if navigation:
			navigation.target_position = current_target.position
			velocity = navigation.get_next_path_position() - global_position
			velocity = velocity.normalized() * move_speed
	else:
		# Follow as part of formation
		if navigation:
			navigation.target_position = current_target.position
			velocity = navigation.get_next_path_position() - global_position
			velocity = velocity.normalized() * move_speed
	
	# Enter attack range
	if distance <= attack_range:
		_change_state(Enums.AIState.ATTACK)


func _on_detection_body_entered(body: Node3D) -> void:
	"""Handle detection of new targets"""
	if body.is_in_group("players") and current_target == null:
		current_target = body
		_change_state(Enums.AIState.CHASE)
		
		# Alert formation group
		if skeleton_data.has_coordination_bonus():
			for skeleton in _formation_group:
				if skeleton and skeleton.current_target == null:
					skeleton.current_target = body
					skeleton._change_state(Enums.AIState.CHASE)


# =============================================================================
# COORDINATION
# =============================================================================

func _update_coordination_bonus() -> void:
	"""Update damage bonus based on nearby allies"""
	if not skeleton_data.has_coordination_bonus():
		_coordination_damage_bonus = 1.0
		return
	
	# Count nearby friendly skeletons
	var nearby_count = 0
	for skeleton in _formation_group:
		if skeleton and skeleton.position.distance_to(position) <= 10.0:
			nearby_count += 1
	
	# Apply coordination bonus for each nearby ally
	_coordination_damage_bonus = 1.0 + (nearby_count * 0.1)
	_coordination_damage_bonus = clamp(_coordination_damage_bonus, 1.0, 1.5)


# =============================================================================
# UTILITY
# =============================================================================

func get_threat_level() -> String:
	"""Return threat level for balancing"""
	return skeleton_data.get_threat_level()


func is_commander() -> bool:
	"""Check if this is the group commander"""
	return variant == SkeletonEnemyData.SkeletonVariant.COMMANDER or _group_commander == self
