## EnemyBase - Base class for all enemies
## Handles AI, movement, combat, and loot drops
class_name EnemyBase
extends CharacterBody3D

# =============================================================================
# SIGNALS
# =============================================================================

signal died(enemy: EnemyBase)
signal damaged(amount: float, attacker: Node)
signal target_changed(new_target: Node)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Enemy Info")
@export var enemy_name: String = "Enemy"
@export var enemy_type: Enums.EnemyType = Enums.EnemyType.BASIC
@export var level: int = 1

@export_group("Stats")
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var defense: float = 0.0
@export var move_speed: float = 3.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 15.0
@export var lose_target_range: float = 25.0

@export_group("Loot")
@export var experience_value: int = 10
@export var gold_drop_base: int = 0  ## 0 = use Constants default
@export var loot_table: Array = []  # Array of {item: ItemData, weight: float}

@export_group("Identification")
@export var enemy_id: String = ""  ## Unique ID for quest tracking

@export_group("AI")
@export var patrol_points: Array[Vector3] = []
@export var patrol_wait_time: float = 2.0

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var stats: StatsComponent = $StatsComponent
@onready var navigation: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea

# =============================================================================
# PROPERTIES
# =============================================================================

var current_target: Node = null
var ai_state: Enums.AIState = Enums.AIState.IDLE
var _attack_timer: float = 0.0
var _patrol_index: int = 0
var _patrol_wait_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	add_to_group("enemies")
	
	# Initialize stats
	if stats:
		stats.max_health = max_health
		stats.reset_stats()
		stats.died.connect(_on_died)
	
	# Set up detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
		_update_detection_radius()
	
	# Initialize navigation
	if navigation:
		navigation.velocity_computed.connect(_on_velocity_computed)
		navigation.target_reached.connect(_on_target_reached)


func _physics_process(delta: float) -> void:
	if stats and stats.is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	
	# Process AI state
	_process_ai(delta)
	
	move_and_slide()

# =============================================================================
# AI STATE MACHINE
# =============================================================================

func _process_ai(delta: float) -> void:
	match ai_state:
		Enums.AIState.IDLE:
			_process_idle(delta)
		Enums.AIState.PATROL:
			_process_patrol(delta)
		Enums.AIState.CHASE:
			_process_chase(delta)
		Enums.AIState.ATTACK:
			_process_attack(delta)
		Enums.AIState.FLEE:
			_process_flee(delta)


func _process_idle(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	
	# Check for targets
	if current_target:
		_change_state(Enums.AIState.CHASE)
	elif patrol_points.size() > 0:
		_patrol_wait_timer += delta
		if _patrol_wait_timer >= patrol_wait_time:
			_change_state(Enums.AIState.PATROL)


func _process_patrol(delta: float) -> void:
	if current_target:
		_change_state(Enums.AIState.CHASE)
		return
	
	if patrol_points.size() == 0:
		_change_state(Enums.AIState.IDLE)
		return
	
	# Validate patrol index is in bounds
	if _patrol_index < 0 or _patrol_index >= patrol_points.size():
		_patrol_index = 0  # Reset to start if out of bounds
	
	var target_pos = patrol_points[_patrol_index]
	navigation.target_position = target_pos
	
	var next_pos = navigation.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	direction.y = 0
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	# Rotate to face movement direction
	if direction.length() > 0.1:
		look_at(global_position + direction)


func _process_chase(delta: float) -> void:
	if current_target == null or not is_instance_valid(current_target):
		current_target = null
		_change_state(Enums.AIState.IDLE)
		return
	
	var target_pos = current_target.global_position
	var distance = global_position.distance_to(target_pos)
	
	# Check if target too far
	if distance > lose_target_range:
		current_target = null
		_change_state(Enums.AIState.IDLE)
		return
	
	# Check if in attack range
	if distance <= attack_range:
		_change_state(Enums.AIState.ATTACK)
		return
	
	# Navigate to target
	navigation.target_position = target_pos
	
	var next_pos = navigation.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	direction.y = 0
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	if direction.length() > 0.1:
		look_at(global_position + direction)


func _process_attack(delta: float) -> void:
	if current_target == null or not is_instance_valid(current_target):
		current_target = null
		_change_state(Enums.AIState.IDLE)
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	
	# Out of attack range, chase
	if distance > attack_range * 1.2:
		_change_state(Enums.AIState.CHASE)
		return
	
	# Face target
	var look_pos = current_target.global_position
	look_pos.y = global_position.y
	look_at(look_pos)
	
	# Stop moving
	velocity.x = 0
	velocity.z = 0
	
	# Attack cooldown
	_attack_timer -= delta
	if _attack_timer <= 0:
		_perform_attack()
		_attack_timer = attack_cooldown


func _process_flee(delta: float) -> void:
	if current_target == null:
		_change_state(Enums.AIState.IDLE)
		return
	
	# Move away from target
	var away_dir = (global_position - current_target.global_position).normalized()
	away_dir.y = 0
	
	velocity.x = away_dir.x * move_speed
	velocity.z = away_dir.z * move_speed


func _change_state(new_state: Enums.AIState) -> void:
	var old_state = ai_state
	ai_state = new_state
	
	# State enter logic
	match new_state:
		Enums.AIState.IDLE:
			_patrol_wait_timer = 0.0
		Enums.AIState.PATROL:
			# Only advance patrol index if we have patrol points (prevent modulo by zero)
			if patrol_points.size() > 0:
				_patrol_index = (_patrol_index + 1) % patrol_points.size()
			else:
				_patrol_index = 0
		Enums.AIState.ATTACK:
			_attack_timer = 0.0  # Attack immediately when entering

# =============================================================================
# COMBAT
# =============================================================================

func _perform_attack() -> void:
	if current_target == null or not is_instance_valid(current_target):
		return
	
	# Check if target has stats component with null validation
	if current_target.has_node("StatsComponent"):
		var target_stats = current_target.get_node_or_null("StatsComponent")
		if target_stats and target_stats is StatsComponent:
			target_stats.take_damage(damage, Enums.DamageType.PHYSICAL)
		else:
			push_warning("_perform_attack: Invalid StatsComponent on target")
		
		# Play attack animation/sound here


func take_damage(amount: float, damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL, attacker: Node = null) -> void:
	if stats:
		var actual = stats.take_damage(amount, damage_type)
		damaged.emit(actual, attacker)

		# Aggro on attacker
		if attacker and current_target == null:
			set_target(attacker)


func set_target(target: Node) -> void:
	if target != current_target:
		current_target = target
		target_changed.emit(target)
		
		if target:
			_change_state(Enums.AIState.CHASE)

# =============================================================================
# DEATH & LOOT
# =============================================================================

func _on_died() -> void:
	ai_state = Enums.AIState.DEAD
	velocity = Vector3.ZERO
	
	# Report kill to QuestManager
	QuestManager.report_kill(enemy_type, enemy_id)
	
	# Drop loot and gold
	_drop_loot()
	_drop_gold()
	
	# Award experience to killer
	_award_experience()
	
	died.emit(self)
	
	# Despawn after delay
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)


func _drop_loot() -> void:
	if loot_table.size() == 0:
		return
	
	# Find LootSystem
	var loot_system = get_tree().current_scene.get_node_or_null("LootSystem")
	if loot_system == null:
		# Create temporary one
		loot_system = LootSystem.new()
		add_child(loot_system)
	
	# Calculate drop count based on enemy type
	var drop_count = 1
	match enemy_type:
		Enums.EnemyType.ELITE:
			drop_count = 2
		Enums.EnemyType.MINIBOSS:
			drop_count = 3
		Enums.EnemyType.BOSS:
			drop_count = 5
		Enums.EnemyType.DEMON_LORD:
			drop_count = 8
	
	loot_system.drop_loot_from_table(loot_table, global_position, drop_count)


func _drop_gold() -> void:
	## Calculate gold based on enemy type and level
	var base_gold = gold_drop_base if gold_drop_base > 0 else Constants.GOLD_DROP_BASE
	var gold_amount = base_gold * level
	
	# Apply enemy type multiplier
	match enemy_type:
		Enums.EnemyType.ELITE:
			gold_amount = int(gold_amount * Constants.GOLD_DROP_ELITE_MULT)
		Enums.EnemyType.MINIBOSS:
			gold_amount = int(gold_amount * Constants.GOLD_DROP_ELITE_MULT * 2)
		Enums.EnemyType.BOSS:
			gold_amount = int(gold_amount * Constants.GOLD_DROP_BOSS_MULT)
		Enums.EnemyType.DEMON_LORD:
			gold_amount = int(gold_amount * Constants.GOLD_DROP_BOSS_MULT * 2)
	
	# Add some variance
	gold_amount = int(gold_amount * randf_range(0.8, 1.2))
	
	if gold_amount > 0:
		SaveManager.add_gold(gold_amount)


func _award_experience() -> void:
	## Award XP based on enemy level and type
	var xp_amount = experience_value * level
	
	# Bonus XP for harder enemies
	match enemy_type:
		Enums.EnemyType.ELITE:
			xp_amount = int(xp_amount * 1.5)
		Enums.EnemyType.MINIBOSS:
			xp_amount = int(xp_amount * 2.5)
		Enums.EnemyType.BOSS:
			xp_amount = int(xp_amount * 5.0)
		Enums.EnemyType.DEMON_LORD:
			xp_amount = int(xp_amount * 10.0)
	
	SaveManager.add_experience(xp_amount)

# =============================================================================
# NAVIGATION CALLBACKS
# =============================================================================

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity


func _on_target_reached() -> void:
	if ai_state == Enums.AIState.PATROL:
		_change_state(Enums.AIState.IDLE)

# =============================================================================
# DETECTION
# =============================================================================

func _update_detection_radius() -> void:
	if detection_area:
		var collision = detection_area.get_node_or_null("CollisionShape3D")
		if collision and collision.shape is SphereShape3D:
			collision.shape.radius = detection_range


func _on_detection_body_entered(body: Node3D) -> void:
	if body is Player and current_target == null:
		set_target(body)


func _on_detection_body_exited(body: Node3D) -> void:
	if body == current_target:
		var distance = global_position.distance_to(body.global_position)
		if distance > lose_target_range:
			current_target = null
			_change_state(Enums.AIState.IDLE)

# =============================================================================
# NETWORK
# =============================================================================

func get_sync_data() -> Dictionary:
	return {
		"position": position,
		"rotation": rotation,
		"velocity": velocity,
		"ai_state": ai_state,
		"health": stats.current_health if stats else max_health,
		"target": current_target.get_path() if current_target else ""
	}


func apply_sync_data(data: Dictionary) -> void:
	if data.has("position"):
		position = data.position
	if data.has("rotation"):
		rotation = data.rotation
	if data.has("ai_state"):
		ai_state = data.ai_state
