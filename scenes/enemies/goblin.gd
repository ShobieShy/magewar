## Goblin - Goblin enemy implementation
## Handles goblin-specific behaviors, variants, and tactics
class_name Goblin
extends EnemyBase

# =============================================================================
# PROPERTIES
# =============================================================================

@export var goblin_data: GoblinEnemyData = GoblinEnemyData.new()
@export var variant: GoblinEnemyData.GoblinVariant = GoblinEnemyData.GoblinVariant.BASIC

## Group coordination
var _group_members: Array[Goblin] = []
var _group_leader: Goblin = null
var _is_flanking: bool = false
var _special_ability_cooldown: float = 0.0

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Apply variant configuration
	goblin_data.variant = variant
	_apply_goblin_config()
	
	# Call parent ready
	super._ready()
	
	# Add to goblins group
	add_to_group("goblins")
	add_to_group("goblin_variant_" + str(variant))
	
	# Register as available group member
	_register_with_group()


func _physics_process(delta: float) -> void:
	# Update special ability cooldown
	if _special_ability_cooldown > 0:
		_special_ability_cooldown -= delta
	
	# Call parent physics
	super._physics_process(delta)


# =============================================================================
# CONFIGURATION & INITIALIZATION
# =============================================================================

func _apply_goblin_config() -> void:
	"""Apply goblin data to enemy properties"""
	enemy_name = goblin_data.get_display_name()
	enemy_type = Enums.EnemyType.GOBLIN
	level = goblin_data.level
	max_health = goblin_data.health
	damage = goblin_data.damage
	move_speed = goblin_data.speed
	attack_range = goblin_data.attack_range
	detection_range = goblin_data.detection_range
	experience_value = int(goblin_data.health * 0.5)
	
	# Apply loot table
	loot_table = goblin_data.get_loot_table()


func _register_with_group() -> void:
	"""Find and register with nearby goblin groups"""
	var goblins_in_area = get_tree().get_nodes_in_group("goblins")
	
	# Find nearby goblins for group coordination
	for goblin in goblins_in_area:
		if goblin != self and goblin.position.distance_to(position) < 15.0:
			_group_members.append(goblin)
			if goblin._group_leader == null:
				_group_leader = self
				goblin._group_leader = self
	
	# Limit group size
	if _group_members.size() > goblin_data.group_size:
		_group_members = _group_members.slice(0, goblin_data.group_size)


# =============================================================================
# COMBAT BEHAVIOR
# =============================================================================

func _process_attack(delta: float) -> void:
	"""Process attack state with goblin-specific tactics"""
	if not current_target:
		_change_state(Enums.AIState.IDLE)
		return
	
	var distance_to_target = position.distance_to(current_target.position)
	
	# Check for special abilities
	if _can_use_special_ability():
		_try_use_special_ability()
		return
	
	# Standard attack behavior
	if distance_to_target <= attack_range:
		# Try flanking tactic
		if goblin_data.group_coordination and _should_attempt_flanking():
			_attempt_flanking_maneuver(delta)
		else:
			# Normal attack
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
			var damage_dealt = damage
			
			# Apply damage type
			var damage_type = Enums.DamageType.PHYSICAL
			if goblin_data.element != Enums.Element.NONE:
				damage_type = Enums.DamageType.ELEMENTAL
			
			target_stats.take_damage(damage_dealt, damage_type, self)
			damaged.emit(damage_dealt, self)
		
		_attack_timer = attack_cooldown


func _should_attempt_flanking() -> bool:
	"""Determine if goblin should try flanking maneuver"""
	if not goblin_data.uses_weapon and goblin_data.variant == GoblinEnemyData.GoblinVariant.BRUTE:
		return true
	if _group_leader == self and _group_members.size() > 1:
		return true
	return false


func _attempt_flanking_maneuver(_delta: float) -> void:
	"""Execute flanking tactic"""
	if not current_target:
		return
	
	# Calculate flanking position (90 degrees from target)
	var direction_to_target = (current_target.position - position).normalized()
	var flanking_vector = direction_to_target.rotated(Vector3.UP, PI / 2.0)
	var target_position = current_target.position + flanking_vector * 3.0
	
	navigation.target_position = target_position
	velocity = navigation.get_next_path_position() - global_position
	velocity = velocity.normalized() * move_speed
	_is_flanking = true


func _can_use_special_ability() -> bool:
	"""Check if special ability can be used"""
	return (
		_special_ability_cooldown <= 0 and
		not goblin_data.special_ability.is_empty() and
		current_target != null
	)


func _try_use_special_ability() -> void:
	"""Attempt to use goblin's special ability"""
	match goblin_data.special_ability:
		"quick_shot":
			_use_quick_shot()
		"ground_slam":
			_use_ground_slam()
		"elemental_bolt":
			_use_elemental_bolt()
	
	# Set cooldown
	var cooldown = goblin_data.get_ai_behavior_tree().get("special_cooldown", 8.0)
	_special_ability_cooldown = cooldown


func _use_quick_shot() -> void:
	"""Scout's rapid attack ability"""
	if current_target and current_target.has_node("StatsComponent"):
		var target_stats = current_target.get_node("StatsComponent")
		target_stats.take_damage(damage * 0.7, Enums.DamageType.PHYSICAL, self)


func _use_ground_slam() -> void:
	"""Brute's area attack ability"""
	# Damage all nearby enemies
	var nearby = get_tree().get_nodes_in_group("players")
	for player in nearby:
		if player.position.distance_to(position) <= 5.0:
			if player.has_node("StatsComponent"):
				var player_stats = player.get_node("StatsComponent")
				player_stats.take_damage(damage * 1.5, Enums.DamageType.PHYSICAL, self)


func _use_elemental_bolt() -> void:
	"""Shaman's elemental attack"""
	if current_target and current_target.has_node("StatsComponent"):
		var target_stats = current_target.get_node("StatsComponent")
		target_stats.take_damage(
			damage + goblin_data.elemental_power,
			Enums.DamageType.ELEMENTAL,
			self
		)


# =============================================================================
# AI BEHAVIOR
# =============================================================================

func _process_chase(_delta: float) -> void:
	"""Chase behavior with group tactics"""
	if not current_target:
		_change_state(Enums.AIState.IDLE)
		return
	
	var distance = position.distance_to(current_target.position)
	
	# Check if should retreat
	if stats.current_health / stats.max_health < goblin_data.retreat_threshold:
		if goblin_data.tactical_retreat:
			_change_state(Enums.AIState.FLEE)
			return
	
	# Check if target lost
	if distance > detection_range:
		current_target = null
		_change_state(Enums.AIState.PATROL)
		return
	
	# Move toward target
	if navigation:
		navigation.target_position = current_target.position
		velocity = navigation.get_next_path_position() - global_position
		velocity = velocity.normalized() * move_speed
	
	# Enter attack range
	if distance <= attack_range:
		_change_state(Enums.AIState.ATTACK)


func _process_flee(_delta: float) -> void:
	"""Flee behavior"""
	if not current_target:
		_change_state(Enums.AIState.IDLE)
		return
	
	# Move away from target
	var away_direction = (position - current_target.position).normalized()
	velocity = away_direction * move_speed * 0.8
	
	# Call for reinforcements if available
	if goblin_data.calls_for_help:
		_call_for_help()
	
	# Try to escape further if health recovers
	if stats.current_health / stats.max_health > goblin_data.retreat_threshold + 0.2:
		_change_state(Enums.AIState.PATROL)


func _call_for_help() -> void:
	"""Call nearby goblins for assistance"""
	for goblin in _group_members:
		if goblin and goblin.current_target == null:
			goblin.current_target = current_target
			goblin._change_state(Enums.AIState.CHASE)


func _on_detection_body_entered(body: Node3D) -> void:
	"""Handle detection of new targets"""
	if body.is_in_group("players") and current_target == null:
		current_target = body
		_change_state(Enums.AIState.CHASE)
		
		# Alert group members
		if goblin_data.group_coordination:
			for goblin in _group_members:
				if goblin and goblin.current_target == null:
					goblin.current_target = body
					goblin._change_state(Enums.AIState.CHASE)


# =============================================================================
# UTILITY
# =============================================================================

func get_threat_level() -> String:
	"""Return threat level for balancing"""
	return goblin_data.get_threat_level()


func is_elite() -> bool:
	"""Check if this is an elite variant"""
	return variant == GoblinEnemyData.GoblinVariant.CHIEF
