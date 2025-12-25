class_name ProceduralDungeon
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal floor_completed(floor_number: int)
signal dungeon_completed()
signal dungeon_failed()
signal boss_spawned(boss_node: Node)
signal boss_defeated()

# =============================================================================
# PROPERTIES
# =============================================================================

@export var dungeon_id: int = 1
@export var dungeon_name: String = "Procedural Dungeon"

var current_floor: int = 1
var max_floors: int = 20
var enemies_remaining: int = 0
var is_boss_floor: bool = false
var scaling_data: Dictionary
var enemy_pool: Dictionary
var active_enemies: Array = []
var spawn_points: Array[Vector3] = []

# State
var player_entered: bool = false
var floor_cleared: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Defer setup to allow inheriting classes to set properties
	call_deferred("setup_dungeon")

func _process(_delta: float) -> void:
	if player_entered and not floor_cleared:
		check_floor_progress()

# =============================================================================
# SETUP
# =============================================================================

func setup_dungeon() -> void:
	print("Setting up %s (Floor %d)" % [dungeon_name, current_floor])
	
	# Load configuration from template system
	scaling_data = DungeonTemplateSystem.get_dungeon_scaling(dungeon_id)
	enemy_pool = DungeonTemplateSystem.get_enemy_pool(dungeon_id)
	
	max_floors = scaling_data.get("max_floors", 20)
	
	# Collect spawn points from the scene
	collect_spawn_points()
	
	# Connect signals
	connect_signals()
	
	# Spawn content for this floor
	spawn_floor_content()

func collect_spawn_points() -> void:
	spawn_points.clear()
	# Search all Node3D children
	var nodes = find_children("*", "Node3D", true, false)
	for node in nodes:
		if "spawn" in node.name.to_lower():
			spawn_points.append(node.global_position)
	
	# Fallback if no specific spawn points found
	if spawn_points.is_empty():
		print("No spawn points found, using fallback positions")
		spawn_points.append(Vector3(0, 0, 10))
		spawn_points.append(Vector3(-10, 0, 10))
		spawn_points.append(Vector3(10, 0, 10))

func connect_signals() -> void:
	# Connect entrance/exit portals if they exist
	var entrance = find_child("EntrancePortal", true, false)
	if entrance and not entrance.player_entered.is_connected(_on_player_entered):
		entrance.player_entered.connect(_on_player_entered)
		
	var exit = find_child("ExitPortal", true, false)
	if exit:
		if not exit.player_entered.is_connected(_on_player_exited):
			exit.player_entered.connect(_on_player_exited)
		exit.set_active(false) # Locked until floor clear

# =============================================================================
# GENERATION
# =============================================================================

func spawn_floor_content() -> void:
	# Clear previous enemies
	cleanup_enemies()
	
	is_boss_floor = (current_floor % 10 == 0) or (current_floor == max_floors)
	
	if is_boss_floor:
		spawn_boss_floor()
	else:
		spawn_regular_floor()

func spawn_regular_floor() -> void:
	var min_count = scaling_data.get("min_enemies", 10)
	var max_count = scaling_data.get("max_enemies", 20)
	var count = randi_range(min_count, max_count)
	
	print("Spawning %d enemies for floor %d" % [count, current_floor])
	
	for i in range(count):
		spawn_random_enemy()

func spawn_boss_floor() -> void:
	print("Spawning boss for floor %d" % current_floor)
	
	# Spawn the boss
	spawn_boss()
	
	# Spawn some minions
	var minion_count = 5
	for i in range(minion_count):
		spawn_random_enemy()

func spawn_random_enemy() -> void:
	if spawn_points.is_empty():
		return
		
	var spawn_pos = spawn_points.pick_random()
	# Add some random offset
	spawn_pos += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	
	var enemy_type = DungeonTemplateSystem.select_weighted_enemy(enemy_pool)
	
	spawn_enemy(enemy_type, spawn_pos)

func spawn_enemy(type: String, pos: Vector3) -> void:
	var enemy_scene: PackedScene
	
	if EnemySpawnSystem and EnemySpawnSystem.enemy_types.has(type):
		enemy_scene = EnemySpawnSystem.enemy_types[type]
	else:
		# Fallback
		enemy_scene = load("res://scenes/enemies/goblin.tscn")
		
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = pos
		enemy.died.connect(_on_enemy_died)
		
		# Apply scaling
		apply_enemy_scaling(enemy)
		
		active_enemies.append(enemy)
		enemies_remaining += 1

func spawn_boss() -> void:
	# Logic to pick boss based on dungeon ID and floor
	var boss_type = "troll_boss" # Default
	if dungeon_id == 2: boss_type = "crystal_golem"
	# ... logic for other dungeons
	
	# Check if it's the FINAL boss
	if current_floor == max_floors:
		print("FINAL BOSS SPAWNED")
		# Maybe spawn a specific final boss
	else:
		print("MINI BOSS SPAWNED")
		
	# For now, reuse spawn_enemy logic but with boss flag/type
	# Ideally we have specific boss scenes.
	# I'll rely on EnemySpawnSystem having boss types or fallback to a big enemy.
	
	spawn_enemy("troll", Vector3(0, 0, 0)) # Placeholder for boss spawn

func apply_enemy_scaling(enemy: Node) -> void:
	if enemy.has_node("StatsComponent"):
		var stats = enemy.get_node("StatsComponent")
		var health_mult = scaling_data.get("enemy_health_multiplier", 1.0)
		var damage_mult = scaling_data.get("enemy_damage_multiplier", 1.0)
		
		# Increase scaling per floor slightly
		var floor_mult = 1.0 + (current_floor * 0.05)
		
		if stats.has_method("scale_stats"):
			stats.scale_stats(health_mult * floor_mult, damage_mult * floor_mult)

# =============================================================================
# LOGIC
# =============================================================================

func check_floor_progress() -> void:
	if enemies_remaining <= 0 and not floor_cleared:
		complete_floor()

func complete_floor() -> void:
	floor_cleared = true
	print("Floor %d completed!" % current_floor)
	
	# Unlock exit
	var exit = find_child("ExitPortal", true, false)
	if exit:
		exit.set_active(true)
		
	floor_completed.emit(current_floor)
	
	# Rewards
	if SaveManager:
		SaveManager.add_gold(100 * current_floor)
		SaveManager.add_experience(50 * current_floor)

func next_floor() -> void:
	current_floor += 1
	if current_floor > max_floors:
		dungeon_completed.emit()
		return
		
	floor_cleared = false
	spawn_floor_content()
	
	# Move player to start?
	# Assume player entered logic handles position reset or we do it here.
	var start_pos = find_child("PlayerStart", true, false)
	if start_pos:
		# Reposition player
		pass 
	else:
		# Use entrance portal pos
		var entrance = find_child("EntrancePortal", true, false)
		# ...

# =============================================================================
# HANDLERS
# =============================================================================

func _on_player_entered(_player: Node, _portal: Node) -> void:
	player_entered = true
	print("Player entered floor %d" % current_floor)

func _on_player_exited(_player: Node, _portal: Node) -> void:
	if floor_cleared:
		next_floor()

func _on_enemy_died(enemy: Node) -> void:
	active_enemies.erase(enemy)
	enemies_remaining -= 1
	print("Enemy died. Remaining: %d" % enemies_remaining)

func cleanup_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	enemies_remaining = 0
