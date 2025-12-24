## EnemySpawnSystem - Manages enemy spawning and patrol routes in dungeons
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal enemy_spawned(enemy: Node, spawn_point: Vector3)
signal enemy_despawned(enemy: Node)
signal wave_completed(wave_number: int)
signal all_waves_completed()

# =============================================================================
# PROPERTIES
# =============================================================================

var dungeon_scene: Node3D = null
var active_enemies: Array = []
var spawn_points: Array = []
var patrol_routes: Array = []

# Configuration
var max_enemies: int = 10
var respawn_delay: float = 30.0
var cleanup_distance: float = 50.0

# Wave system
var current_wave: int = 0
var waves_completed: int = 0
var wave_active: bool = false

# Enemy types available for spawning
var enemy_types: Dictionary = {
		# Existing enemies
		"troll": preload("res://scenes/enemies/troll.tscn"),
		"wraith": preload("res://scenes/enemies/wraith.tscn"),
		"troll_basic": preload("res://scenes/enemies/troll.tscn"),
		"troll_hill": preload("res://scenes/enemies/troll.tscn"),
		"troll_cave": preload("res://scenes/enemies/troll.tscn"),
		"troll_frost": preload("res://scenes/enemies/troll.tscn"),
		"troll_ancient": preload("res://scenes/enemies/troll.tscn"),
		"wraith_basic": preload("res://scenes/enemies/wraith.tscn"),
		"wraith_shadow": preload("res://scenes/enemies/wraith.tscn"),
		"wraith_frost": preload("res://scenes/enemies/wraith.tscn"),
		"wraith_ancient": preload("res://scenes/enemies/wraith.tscn"),
		# New goblin enemies
		"goblin": preload("res://scenes/enemies/goblin.tscn"),
		"goblin_scout": preload("res://scenes/enemies/goblin_scout.tscn"),
		"goblin_brute": preload("res://scenes/enemies/goblin_brute.tscn"),
		"goblin_shaman": preload("res://scenes/enemies/goblin_shaman.tscn"),
		# New skeleton enemies
		"skeleton": preload("res://scenes/enemies/skeleton.tscn"),
		"skeleton_archer": preload("res://scenes/enemies/skeleton_archer.tscn"),
		"skeleton_berserker": preload("res://scenes/enemies/skeleton_berserker.tscn"),
		"skeleton_commander": preload("res://scenes/enemies/skeleton_commander.tscn"),
		"dragon": preload("res://scenes/enemies/enemy_base.tscn"),
		"orc": preload("res://scenes/enemies/enemy_base.tscn"),
		"vampire": preload("res://scenes/enemies/enemy_base.tscn"),
		"werewolf": preload("res://scenes/enemies/enemy_base.tscn"),
		"zombie": preload("res://scenes/enemies/enemy_base.tscn"),
		"giant": preload("res://scenes/enemies/enemy_base.tscn"),
		"harpy": preload("res://scenes/enemies/enemy_base.tscn"),
		"basilisk": preload("res://scenes/enemies/enemy_base.tscn")
	}

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	setup_timers()

func _process(delta: float) -> void:
	if dungeon_scene:
		update_enemy_management(delta)
		update_patrol_routes(delta)

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(dungeon: Node3D) -> void:
	"""Initialize the spawn system for a dungeon"""
	dungeon_scene = dungeon
	active_enemies.clear()
	current_wave = 0
	waves_completed = 0
	wave_active = false
	
	# Collect spawn points and patrol routes
	collect_spawn_points()
	collect_patrol_routes()
	
	print("EnemySpawnSystem initialized for dungeon with " + str(spawn_points.size()) + " spawn points")

func setup_timers() -> void:
	"""Set up recurring timers"""
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 5.0  # Check every 5 seconds
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(_on_cleanup_timer)
	add_child(cleanup_timer)

func collect_spawn_points() -> void:
	"""Find all spawn points in the dungeon"""
	spawn_points.clear()
	
	# Look for spawn point nodes
	var spawn_nodes = dungeon_scene.find_children("*", "Node3D", true, false)
	for node in spawn_nodes:
		if node.name.to_lower().contains("spawn") or node.is_in_group("spawn_points"):
			spawn_points.append({
				"position": node.global_position,
				"node": node,
				"occupied": false,
				"last_used": 0.0
			})
	
	# If no spawn points found, create default ones
	if spawn_points.size() == 0:
		create_default_spawn_points()

func create_default_spawn_points() -> void:
	"""Create default spawn points if none exist"""
	var areas = ["EntranceArea", "EnemyRoom1", "EnemyRoom2", "BossArea"]
	
	for area_name in areas:
		var area = dungeon_scene.get_node_or_null(area_name)
		if area:
			var spawn_point = {
				"position": area.global_position,
				"node": area,
				"occupied": false,
				"last_used": 0.0
			}
			spawn_points.append(spawn_point)

func collect_patrol_routes() -> void:
	"""Find patrol routes defined in the dungeon"""
	patrol_routes.clear()
	
	# Look for patrol route nodes
	var route_nodes = dungeon_scene.find_children("*", "Node3D", true, false)
	for node in route_nodes:
		if node.name.to_lower().contains("patrol"):
			var route = extract_patrol_points(node)
			if route.size() >= 2:
				patrol_routes.append(route)

	# Function must have at least one statement
	pass

func extract_patrol_points(route_node: Node3D) -> Array:
	"""Extract patrol waypoints from a route node"""
	var points = []
	
	# Check if node has patrol_points property (from enemy)
	if route_node.has_meta("patrol_points"):
		points = route_node.get_meta("patrol_points")
	else:
		# Use child nodes as waypoints
		for child in route_node.get_children():
			if child is Node3D:
				points.append(child.global_position)
	
	# If no points found, create a simple patrol around the node
	if points.size() == 0:
		var center = route_node.global_position
		var radius = 5.0
		points = [
			center + Vector3(radius, 0, 0),
			center + Vector3(0, 0, radius),
			center + Vector3(-radius, 0, 0),
			center + Vector3(0, 0, -radius)
		]
	
	return points

# =============================================================================
# ENEMY SPAWNING
# =============================================================================

func spawn_enemy(enemy_type: String, spawn_pos: Vector3 = Vector3.ZERO, patrol_route: Array = []) -> Node:
	"""Spawn a single enemy"""
	if not enemy_types.has(enemy_type):
		push_error("Unknown enemy type: " + enemy_type)
		return null
	
	if active_enemies.size() >= max_enemies:
		return null
	
	# Find spawn position
	if spawn_pos == Vector3.ZERO:
		spawn_pos = get_available_spawn_point()
		if spawn_pos == Vector3.ZERO:
			return null
	
	# Create enemy
	var enemy_scene = enemy_types[enemy_type]
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_pos
	
	# Set enemy variant if specified
	if enemy_type.contains("_"):
		var split_parts = enemy_type.split("_")
		if split_parts.size() > 1:
			var variant_name = split_parts[1]
			if "variant" in enemy:
				match variant_name:
					"basic": enemy.variant = 0
					"hill": enemy.variant = 1
					"cave": enemy.variant = 2
					"frost": enemy.variant = 3
					"ancient": enemy.variant = 4
					"shadow": enemy.variant = 1
		else:
			push_warning("enemy_spawn_system: Invalid enemy_type format: %s" % enemy_type)
	
	# Assign patrol route
	if patrol_route.size() > 0:
		enemy.patrol_points = patrol_route
	
	# Add to dungeon
	dungeon_scene.add_child(enemy)
	active_enemies.append(enemy)
	
	# Connect signals
	enemy.died.connect(_on_enemy_died.bind(enemy))
	
	# Mark spawn point as occupied
	mark_spawn_point_occupied(spawn_pos)
	
	enemy_spawned.emit(enemy, spawn_pos)
	return enemy

func spawn_wave(wave_config: Dictionary) -> void:
	"""Spawn a wave of enemies"""
	if wave_active:
		return
	
	wave_active = true
	current_wave += 1
	
	print("Spawning wave " + str(current_wave))
	
	# Spawn enemies
	var enemies_in_wave = wave_config.get("enemies", [])
	var spawn_delay = wave_config.get("spawn_delay", 1.0)
	
	for i in range(enemies_in_wave.size()):
		var enemy_config = enemies_in_wave[i]
		var enemy_type = enemy_config.get("type", "troll")
		var spawn_pos = enemy_config.get("position", Vector3.ZERO)
		var patrol_route = enemy_config.get("patrol", [])
		
		# Delay spawn
		await get_tree().create_timer(spawn_delay * i).timeout
		
		spawn_enemy(enemy_type, spawn_pos, patrol_route)
	
	wave_active = false

func get_available_spawn_point() -> Vector3:
	"""Find an available spawn point"""
	for spawn_data in spawn_points:
		if not spawn_data.occupied:
			spawn_data.occupied = true
			spawn_data.last_used = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
			return spawn_data.position
	
	return Vector3.ZERO

func mark_spawn_point_occupied(position: Vector3) -> void:
	"""Mark a spawn point as occupied"""
	for spawn_data in spawn_points:
		if spawn_data.position.distance_to(position) < 1.0:
			spawn_data.occupied = true
			break

# =============================================================================
# ENEMY MANAGEMENT
# =============================================================================

func update_enemy_management(delta: float) -> void:
	"""Update enemy management systems"""
	# Check for enemies that wandered too far
	check_cleanup_distance()
	
	# Respawn logic if needed
	check_respawn_logic(delta)

func check_cleanup_distance() -> void:
	"""Remove enemies that are too far from the dungeon"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var to_remove = []
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(player.global_position)
			if distance > cleanup_distance:
				to_remove.append(enemy)
	
	# Remove distant enemies
	for enemy in to_remove:
		despawn_enemy(enemy)

func check_respawn_logic(delta: float) -> void:
	"""Handle enemy respawning"""
	# Update spawn point timers
	for spawn_data in spawn_points:
		if spawn_data.occupied:
			spawn_data.last_used += delta
	
	# Free up spawn points after delay
	for spawn_data in spawn_points:
		var time_since_used = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"] - spawn_data.last_used
		if time_since_used > respawn_delay:
			spawn_data.occupied = false

func despawn_enemy(enemy: Node) -> void:
	"""Remove an enemy from the dungeon"""
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		enemy_despawned.emit(enemy)
		enemy.queue_free()

# =============================================================================
# PATROL SYSTEM
# =============================================================================

func update_patrol_routes(_delta: float) -> void:
	"""Update patrol route assignments"""
	# Assign patrols to enemies that don't have them
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy) and enemy.patrol_points.size() == 0:
			assign_patrol_route(enemy)

func assign_patrol_route(enemy: Node) -> void:
	"""Assign a patrol route to an enemy"""
	if patrol_routes.size() == 0:
		return
	
	# Find closest patrol route
	var closest_route = null
	var closest_distance = INF
	
	for route in patrol_routes:
		if route.size() > 0:
			var distance = enemy.global_position.distance_to(route[0])
			if distance < closest_distance:
				closest_distance = distance
				closest_route = route
	
	if closest_route:
		enemy.patrol_points = closest_route

func create_patrol_route(center: Vector3, radius: float, points: int = 4) -> Array:
	"""Create a circular patrol route"""
	var route = []
	
	for i in range(points):
		var angle = (i * 2.0 * PI) / points
		var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		route.append(center + offset)
	
	return route

# =============================================================================
# WAVE SYSTEM
# =============================================================================

func start_wave_system(wave_configs: Array) -> void:
	"""Start the wave spawning system"""
	for i in range(wave_configs.size()):
		var wave_config = wave_configs[i]

		# Wait for previous wave to complete
		if i > 0:
			await wave_completed

		# Spawn wave
		spawn_wave(wave_config)

		# Wait for wave completion
		await wave_completed

		waves_completed += 1
		wave_completed.emit(waves_completed)

	all_waves_completed.emit()

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_enemy_died(enemy: Node) -> void:
	"""Handle enemy death"""
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	
	# Free up spawn point
	free_spawn_point_near(enemy.global_position)

func _on_cleanup_timer() -> void:
	"""Periodic cleanup check"""
	cleanup_distant_enemies()

# =============================================================================
# UTILITY
# =============================================================================

func free_spawn_point_near(position: Vector3) -> void:
	"""Free spawn point near a position"""
	for spawn_data in spawn_points:
		if spawn_data.position.distance_to(position) < 3.0:
			spawn_data.occupied = false
			break

func cleanup_distant_enemies() -> void:
	"""Remove enemies that are too far from any player"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	
	var to_remove = []
	for enemy in active_enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		
		var too_far = true
		for player in players:
			if enemy.global_position.distance_to(player.global_position) <= cleanup_distance:
				too_far = false
				break
		
		if too_far:
			to_remove.append(enemy)
	
	for enemy in to_remove:
		despawn_enemy(enemy)

func get_active_enemy_count() -> int:
	"""Get number of currently active enemies"""
	return active_enemies.size()

func get_spawn_point_count() -> int:
	"""Get number of available spawn points"""
	return spawn_points.size()

func set_max_enemies(count: int) -> void:
	"""Set maximum number of enemies"""
	max_enemies = count

func set_respawn_delay(delay: float) -> void:
	"""Set respawn delay in seconds"""
	respawn_delay = delay