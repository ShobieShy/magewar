## Dungeon1 - Abandoned Mine dungeon implementation
## Features troll enemies, wraith enemies, and an ancient troll boss
class_name Dungeon1
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal dungeon_completed()
signal dungeon_failed()
signal boss_defeated()

# =============================================================================
# PROPERTIES
# =============================================================================

var dungeon_id: String = "dungeon_1"
var dungeon_name: String = "Abandoned Mine"
var difficulty: int = 1
var max_enemies: int = 12  # Increased for more variety
var current_enemies: int = 0
var boss_defeated_flag: bool = false

# Enemy tracking
var enemies: Array = []
var enemy_spawn_points: Array = []
var boss_spawn_point: Vector3 = Vector3(0, 0, 35)

# Dungeon state
var player_entered: bool = false
var treasure_opened: bool = false

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	setup_dungeon()
	connect_signals()

func _process(_delta: float) -> void:
	if player_entered and not treasure_opened:
		check_dungeon_progress()

# =============================================================================
# DUNGEON SETUP
# =============================================================================

func setup_dungeon() -> void:
	"""Initialize dungeon elements"""
	print("Setting up " + dungeon_name)

	# Initialize enemy spawn system
	if EnemySpawnSystem:
		EnemySpawnSystem.initialize(self)

	# Collect enemy spawn points
	collect_spawn_points()

	# Initial enemy spawn
	spawn_initial_enemies()

	# Set up treasure room
	setup_treasure_room()

	# Bake navigation mesh
	bake_navigation_mesh()

func collect_spawn_points() -> void:
	"""Collect all enemy spawn points in the dungeon"""
	enemy_spawn_points = []

	# Collect spawn point nodes from the scene
	var spawn_nodes = find_children("*", "Node3D", true, false)
	for node in spawn_nodes:
		if node.name.to_lower().contains("spawn"):
			enemy_spawn_points.append(node.global_position)

	# Add fallback predefined spawn positions (in case no nodes found)
	if enemy_spawn_points.is_empty():
		enemy_spawn_points.append_array([
			Vector3(-15, 0, 15),  # Troll room 1
			Vector3(-17, 0, 17),  # Troll room 1 secondary
			Vector3(15, 0, 15),   # Wraith room 1
			Vector3(17, 0, 13),   # Wraith room 1 secondary
			Vector3(0, 0, 15),    # Corridor
			Vector3(0, 0, 20),    # Corridor secondary
		])

	print("Found " + str(enemy_spawn_points.size()) + " enemy spawn points")

func setup_treasure_room() -> void:
	"""Set up all dungeon chests with appropriate loot"""

	# Main treasure chest - best rewards
	var treasure_chest = $TreasureRoom/TreasureChest
	if treasure_chest:
		treasure_chest.connect("opened", Callable(self, "_on_treasure_opened"))
		if treasure_chest.has_method("set_loot_table"):
			treasure_chest.set_loot_table([
				{"item": "gold", "weight": 40, "min": 150, "max": 300},
				{"item": "health_potion", "weight": 25, "min": 2, "max": 4},
				{"item": "mana_potion", "weight": 25, "min": 2, "max": 4},
				{"item": "troll_hide_armor", "weight": 15, "min": 1, "max": 1},
				{"item": "shadow_essence", "weight": 10, "min": 1, "max": 1},
				{"item": "ancient_scroll", "weight": 8, "min": 1, "max": 1},
				{"item": "journeyman_hat", "weight": 5, "min": 1, "max": 1}
			])

	# Corridor chest - moderate rewards
	var corridor_chest = $MainCorridor/CorridorChest
	if corridor_chest:
		if corridor_chest.has_method("set_loot_table"):
			corridor_chest.set_loot_table([
				{"item": "gold", "weight": 35, "min": 50, "max": 100},
				{"item": "health_potion", "weight": 25, "min": 1, "max": 2},
				{"item": "mana_potion", "weight": 25, "min": 1, "max": 2},
				{"item": "basic_potion", "weight": 20, "min": 1, "max": 3},
				{"item": "bone_fragments", "weight": 15, "min": 2, "max": 5},
				{"item": "rusty_dagger", "weight": 10, "min": 1, "max": 1}
			])

	# Room 1 chest - early game rewards
	var room1_chest = $EnemyRoom1/Room1Chest
	if room1_chest:
		if room1_chest.has_method("set_loot_table"):
			room1_chest.set_loot_table([
				{"item": "gold", "weight": 40, "min": 25, "max": 75},
				{"item": "health_potion", "weight": 30, "min": 1, "max": 2},
				{"item": "mana_potion", "weight": 30, "min": 1, "max": 2},
				{"item": "bone_fragments", "weight": 20, "min": 1, "max": 3},
				{"item": "rusty_dagger", "weight": 15, "min": 1, "max": 1},
				{"item": "apprentice_robes", "weight": 5, "min": 1, "max": 1}
			])

func bake_navigation_mesh() -> void:
	"""Bake the navigation mesh for pathfinding"""
	var nav_region = $NavigationRegion3D
	if nav_region:
		nav_region.bake_navigation_mesh()

# =============================================================================
# ENEMY SPAWNING
# =============================================================================

func spawn_initial_enemies() -> void:
	"""Spawn the initial set of enemies"""
	# Trolls and wraiths are already placed in the scene, just track them
	track_existing_enemies()

	# Spawn additional random enemies for variety
	spawn_random_enemies(4)  # Increased from 2 to 4

func track_existing_enemies() -> void:
	"""Track enemies that are already placed in the scene"""
	var troll1 = $EnemyRoom1/Troll1
	var troll2 = $EnemyRoom1/Troll2
	var wraith1 = $EnemyRoom2/Wraith1
	var wraith2 = $EnemyRoom2/Wraith2
	
	enemies.append_array([troll1, troll2, wraith1, wraith2])
	current_enemies = enemies.size()
	
	# Connect to death signals
	for enemy in enemies:
		if enemy and enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)

func spawn_random_enemies(count: int) -> void:
	"""Spawn random enemies at available spawn points"""
	# Define available enemy types with weights for variety
	var enemy_weights = {
		"goblin": 25,           # Common goblin warriors
		"goblin_scout": 15,     # Fast ranged goblins
		"goblin_brute": 10,     # Tanky goblins
		"goblin_shaman": 5,     # Rare elemental goblins
		"skeleton": 20,         # Basic skeleton warriors
		"skeleton_archer": 10,  # Ranged skeletons
		"skeleton_berserker": 8,# Aggressive skeletons
		"skeleton_commander": 2,# Rare elite skeletons
		"troll": 3,             # Rare trolls (existing)
		"wraith": 2             # Rare wraiths (existing)
	}

	for i in range(min(count, enemy_spawn_points.size())):
		if current_enemies >= max_enemies:
			break

		var spawn_pos = enemy_spawn_points[i]

		# Select enemy type based on weights
		var selected_type = select_weighted_enemy(enemy_weights)
		var enemy_scene: PackedScene

		# Get the appropriate enemy scene
		if EnemySpawnSystem and EnemySpawnSystem.enemy_types.has(selected_type):
			enemy_scene = EnemySpawnSystem.enemy_types[selected_type]
		else:
			# Fallback to basic goblin if spawn system not available
			enemy_scene = preload("res://scenes/enemies/goblin.tscn")

		# Spawn enemy
		var enemy = enemy_scene.instantiate()
		enemy.position = spawn_pos

		# Add some patrol points for dynamic behavior
		if enemy.has_method("set"):
			enemy.set("patrol_points", generate_patrol_points(spawn_pos))

		add_child(enemy)

		enemies.append(enemy)
		current_enemies += 1

		# Connect signals
		enemy.died.connect(_on_enemy_died)

	print("Spawned " + str(count) + " random enemies")

func spawn_boss() -> void:
	"""Spawn the ancient troll boss"""
	print("Spawning Ancient Troll Boss!")
	
	var boss = $BossArea/AncientTroll
	if boss:
		enemies.append(boss)
		current_enemies += 1
		boss.died.connect(_on_boss_died)

# =============================================================================
# DUNGEON LOGIC
# =============================================================================

func check_dungeon_progress() -> void:
	"""Check dungeon completion conditions"""
	# Count remaining enemies
	var alive_enemies = 0
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.stats and not enemy.stats.is_dead:
			alive_enemies += 1
	
	current_enemies = alive_enemies
	
	# If all initial enemies are dead and boss not spawned, spawn boss
	if alive_enemies == 0 and not boss_defeated_flag:
		spawn_boss()
	
	# If boss is dead and treasure opened, dungeon complete
	if boss_defeated_flag and treasure_opened:
		complete_dungeon()

func complete_dungeon() -> void:
	"""Handle dungeon completion"""
	print("Dungeon " + dungeon_name + " completed!")
	
	# Award completion rewards
	award_completion_rewards()
	
	# Unlock treasure room exit
	unlock_treasure_exit()
	
	dungeon_completed.emit()

func award_completion_rewards() -> void:
	"""Give players completion rewards"""
	# XP reward
	var xp_reward = 500 * difficulty
	SaveManager.add_experience(xp_reward)
	
	# Gold reward
	var gold_reward = 250 * difficulty
	SaveManager.add_gold(gold_reward)
	
	# Quest progress
	if QuestManager:
		QuestManager.report_dungeon_completed(dungeon_id)

func unlock_treasure_exit() -> void:
	"""Unlock the exit portal in treasure room"""
	var exit_portal = $TreasureRoom/ExitPortal
	if exit_portal:
		exit_portal.set_active(true)
		# Visual effect
		create_completion_effect()

func create_completion_effect() -> void:
	"""Create visual effect for dungeon completion"""
	var effect_pos = Vector3(0, 2, 50)  # Treasure room center
	
	# Spawn particle effect
	var particles = GPUParticles3D.new()
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 2.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 3.0
	material.color = Color.GOLD
	material.scale_min = 0.5
	material.scale_max = 1.0
	particles.process_material = material
	particles.amount = 100
	particles.lifetime = 3.0
	particles.one_shot = true
	particles.position = effect_pos
	add_child(particles)
	particles.emitting = true
	
	# Auto-remove after effect
	await get_tree().create_timer(4.0).timeout
	particles.queue_free()

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func connect_signals() -> void:
	"""Connect to relevant signals"""
	# Portal signals
	var entrance_portal = $EntranceArea/EntrancePortal
	if entrance_portal:
		entrance_portal.player_entered.connect(_on_player_entered)
	
	var exit_portal = $TreasureRoom/ExitPortal
	if exit_portal:
		exit_portal.player_entered.connect(_on_player_exited)
		exit_portal.set_active(false)  # Initially locked

func _on_player_entered(_player: Node, _portal: Node) -> void:
	"""Player entered the dungeon"""
	player_entered = true
	print("Player entered " + dungeon_name)
	if QuestManager:
		QuestManager.report_area_entered(dungeon_id)

func _on_player_exited(_player: Node, _portal: Node) -> void:
	"""Player exited the dungeon"""
	print("Player exited " + dungeon_name)
	
	# Clean up dungeon
	cleanup_dungeon()

func _on_enemy_died(enemy: Node) -> void:
	"""Handle enemy death"""
	current_enemies -= 1
	enemies.erase(enemy)
	
	print("Enemy died. Remaining: " + str(current_enemies))

func _on_boss_died(_enemy: Node) -> void:
	"""Handle boss death"""
	boss_defeated_flag = true
	boss_defeated.emit()
	
	print("Boss defeated! Treasure room unlocked.")
	
	if QuestManager:
		QuestManager.report_kill(Enums.EnemyType.BOSS, "ancient_troll")

	# Unlock treasure room
	unlock_treasure_room()

func _on_treasure_opened() -> void:
	"""Treasure chest was opened"""
	treasure_opened = true
	print("Treasure opened!")

func unlock_treasure_room() -> void:
	"""Unlock access to treasure room"""
	# For now, the boss death unlocks it
	# Could add doors/gates here later
	pass

# =============================================================================
# CLEANUP
# =============================================================================

func cleanup_dungeon() -> void:
	"""Clean up dungeon when player leaves"""
	# Remove all enemies
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	
	enemies.clear()
	current_enemies = 0
	
	# Reset state
	player_entered = false
	boss_defeated_flag = false
	treasure_opened = false
	
	# Could save dungeon state here for persistence
	print("Dungeon cleaned up")

# =============================================================================
# UTILITY
# =============================================================================

func get_enemy_count() -> int:
	"""Get current number of alive enemies"""
	return current_enemies

func is_boss_alive() -> bool:
	"""Check if the boss is still alive"""
	var boss = $BossArea/AncientTroll
	return boss and is_instance_valid(boss) and boss.stats and not boss.stats.is_dead

func select_weighted_enemy(weights: Dictionary) -> String:
	"""Select an enemy type based on weighted probabilities"""
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight

	var random_value = randi() % total_weight

	for enemy_type in weights.keys():
		random_value -= weights[enemy_type]
		if random_value <= 0:
			return enemy_type

	return "goblin"  # Default fallback


func generate_patrol_points(center: Vector3) -> Array[Vector3]:
	"""Generate patrol points around a center position"""
	var points: Array[Vector3] = []
	var radius = 3.0
	var num_points = randi() % 3 + 2  # 2-4 patrol points

	for i in range(num_points):
		var angle = (i * 2.0 * PI) / num_points
		var offset = Vector3(
			cos(angle) * radius * randf_range(0.5, 1.5),
			0,
			sin(angle) * radius * randf_range(0.5, 1.5)
		)
		points.append(center + offset)

	return points


func get_dungeon_info() -> Dictionary:
	"""Get dungeon information"""
	return {
		"id": dungeon_id,
		"name": dungeon_name,
		"difficulty": difficulty,
		"enemies_remaining": current_enemies,
		"boss_alive": is_boss_alive(),
		"treasure_opened": treasure_opened,
		"completed": boss_defeated_flag and treasure_opened
	}
