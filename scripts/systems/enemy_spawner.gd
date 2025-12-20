## EnemySpawner - Spawns waves of enemies in an area
## Used for combat encounters and dungeon progression
class_name EnemySpawner
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal enemy_spawned(enemy: Node)
signal enemy_killed(enemy: Node)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Spawn Settings")
@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_points: Array[Marker3D] = []
@export var spawn_radius: float = 2.0  ## Random offset from spawn point

@export_group("Wave Settings")
@export var waves: Array[Dictionary] = []
## Wave format: {"enemies": [{"scene_index": 0, "count": 3}], "delay": 2.0}
@export var auto_start: bool = false
@export var delay_between_waves: float = 3.0

@export_group("Limits")
@export var max_concurrent_enemies: int = 10

# =============================================================================
# PROPERTIES
# =============================================================================

var current_wave: int = 0
var active_enemies: Array = []
var is_spawning: bool = false
var _spawn_queue: Array = []
var _wave_in_progress: bool = false

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	if auto_start:
		start_spawning()

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func start_spawning() -> void:
	if is_spawning:
		return
	
	is_spawning = true
	current_wave = 0
	_start_next_wave()


func stop_spawning() -> void:
	is_spawning = false
	_spawn_queue.clear()


func despawn_all() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()


func get_active_enemy_count() -> int:
	# Clean up invalid references
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	return active_enemies.size()


func is_wave_complete() -> bool:
	return get_active_enemy_count() == 0 and _spawn_queue.is_empty()

# =============================================================================
# WAVE MANAGEMENT
# =============================================================================

func _start_next_wave() -> void:
	if current_wave >= waves.size():
		is_spawning = false
		all_waves_completed.emit()
		return
	
	_wave_in_progress = true
	var wave_data = waves[current_wave]
	
	wave_started.emit(current_wave + 1)
	
	# Build spawn queue for this wave
	_spawn_queue.clear()
	for enemy_config in wave_data.get("enemies", []):
		var scene_index = enemy_config.get("scene_index", 0)
		var count = enemy_config.get("count", 1)
		
		if scene_index < enemy_scenes.size():
			for i in range(count):
				_spawn_queue.append(enemy_scenes[scene_index])
	
	# Start spawning
	var spawn_delay = wave_data.get("delay", 0.5)
	_spawn_enemies_with_delay(spawn_delay)


func _spawn_enemies_with_delay(delay: float) -> void:
	while _spawn_queue.size() > 0 and is_spawning:
		if get_active_enemy_count() >= max_concurrent_enemies:
			# Wait for some enemies to die
			await get_tree().create_timer(0.5).timeout
			continue
		
		var enemy_scene = _spawn_queue.pop_front()
		_spawn_single_enemy(enemy_scene)
		
		if _spawn_queue.size() > 0:
			await get_tree().create_timer(delay).timeout
	
	# Wait for all enemies to be killed
	while get_active_enemy_count() > 0:
		await get_tree().create_timer(0.5).timeout
	
	_on_wave_complete()


func _on_wave_complete() -> void:
	_wave_in_progress = false
	wave_completed.emit(current_wave + 1)
	current_wave += 1
	
	if current_wave < waves.size() and is_spawning:
		await get_tree().create_timer(delay_between_waves).timeout
		_start_next_wave()
	elif current_wave >= waves.size():
		all_waves_completed.emit()

# =============================================================================
# ENEMY SPAWNING
# =============================================================================

func _spawn_single_enemy(enemy_scene: PackedScene) -> Node:
	var enemy = enemy_scene.instantiate()
	
	# Get spawn position
	var spawn_pos = _get_spawn_position()
	if enemy is Node3D:
		enemy.global_position = spawn_pos
	
	# Connect death signal
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))
	
	# Check if we can spawn more enemies
	if active_enemies.size() >= max_concurrent_enemies:
		push_warning("EnemySpawner: Max concurrent enemies reached (%d). Skipping spawn." % max_concurrent_enemies)
		enemy.queue_free()
		return null
	
	# Add to scene
	get_tree().current_scene.add_child(enemy)
	active_enemies.append(enemy)
	
	enemy_spawned.emit(enemy)
	return enemy


func _get_spawn_position() -> Vector3:
	var base_pos = global_position
	
	if spawn_points.size() > 0:
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		base_pos = spawn_point.global_position
	
	# Add random offset
	var offset = Vector3(
		randf_range(-spawn_radius, spawn_radius),
		0,
		randf_range(-spawn_radius, spawn_radius)
	)
	
	return base_pos + offset


func _on_enemy_died(enemy: Node) -> void:
	active_enemies.erase(enemy)
	enemy_killed.emit(enemy)

# =============================================================================
# UTILITY
# =============================================================================

func spawn_boss(boss_scene: PackedScene, position: Vector3 = Vector3.ZERO) -> Node:
	## Spawn a single boss enemy at a specific position
	var boss = boss_scene.instantiate()
	
	if boss is Node3D:
		boss.global_position = position if position != Vector3.ZERO else _get_spawn_position()
	
	if boss.has_signal("died"):
		boss.died.connect(_on_enemy_died.bind(boss))
	
	get_tree().current_scene.add_child(boss)
	active_enemies.append(boss)
	
	enemy_spawned.emit(boss)
	return boss
