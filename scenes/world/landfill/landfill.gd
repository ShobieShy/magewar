## Landfill - Tutorial combat area
## Players fight through waves of enemies to reach The Filth boss
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal area_cleared()
signal boss_spawned()
signal boss_defeated()

# =============================================================================
# CONSTANTS
# =============================================================================

const FILTH_SLIME_SCENE = preload("res://scenes/enemies/filth_slime.tscn")
const TRASH_GOLEM_SCENE = preload("res://scenes/enemies/trash_golem.tscn")
const THE_FILTH_SCENE = preload("res://scenes/enemies/the_filth.tscn")
const JOES_TRASH = preload("res://resources/items/misc/joes_trash.tres")

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var auto_start_combat: bool = true

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var boss_spawn_point: Marker3D = $BossSpawnPoint
@onready var portal: Node3D = $Portal
@onready var player_spawn: Marker3D = $PlayerSpawn

# =============================================================================
# PROPERTIES
# =============================================================================

var is_cleared: bool = false
var boss_active: bool = false
var _boss_instance: Node = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Configure enemy spawner
	_setup_spawner()
	
	# Connect signals
	enemy_spawner.all_waves_completed.connect(_on_waves_completed)
	
	# Portal starts inactive
	if portal:
		_set_portal_active(false)
	
	# Auto-start if configured
	if auto_start_combat:
		# Delay to let players get ready
		await get_tree().create_timer(2.0).timeout
		start_combat()

# =============================================================================
# SPAWNER SETUP
# =============================================================================

func _setup_spawner() -> void:
	enemy_spawner.enemy_scenes = [FILTH_SLIME_SCENE, TRASH_GOLEM_SCENE]
	
	# Define waves
	# Wave 1: 3 slimes
	# Wave 2: 5 slimes + 1 golem
	# Wave 3: 4 slimes + 2 golems
	enemy_spawner.waves = [
		{
			"enemies": [{"scene_index": 0, "count": 3}],
			"delay": 1.0
		},
		{
			"enemies": [
				{"scene_index": 0, "count": 5},
				{"scene_index": 1, "count": 1}
			],
			"delay": 0.8
		},
		{
			"enemies": [
				{"scene_index": 0, "count": 4},
				{"scene_index": 1, "count": 2}
			],
			"delay": 0.6
		}
	]
	
	enemy_spawner.delay_between_waves = 3.0
	enemy_spawner.max_concurrent_enemies = 8

# =============================================================================
# COMBAT FLOW
# =============================================================================

func start_combat() -> void:
	print("Landfill: Combat started!")
	enemy_spawner.start_spawning()


func _on_waves_completed() -> void:
	print("Landfill: All waves cleared! Spawning boss...")
	await get_tree().create_timer(2.0).timeout
	_spawn_boss()


func _spawn_boss() -> void:
	boss_active = true
	boss_spawned.emit()
	
	_boss_instance = THE_FILTH_SCENE.instantiate()
	_boss_instance.global_position = boss_spawn_point.global_position
	
	# Connect boss death
	_boss_instance.boss_defeated.connect(_on_boss_defeated)
	
	add_child(_boss_instance)
	
	print("The Filth has appeared!")


func _on_boss_defeated() -> void:
	print("The Filth has been defeated!")
	boss_active = false
	is_cleared = true
	
	# Drop Joe's Trash
	_drop_boss_loot()
	
	# Activate portal and unlock in FastTravelManager
	_activate_portal()
	
	# Mark boss as defeated in save data
	SaveManager.mark_boss_defeated("the_filth")
	
	boss_defeated.emit()
	area_cleared.emit()


func _drop_boss_loot() -> void:
	# Find or create loot system
	var loot_system = get_node_or_null("/root/LootSystem")
	if loot_system == null:
		loot_system = LootSystem.new()
		add_child(loot_system)
	
	# Drop Joe's Trash at boss location
	var drop_pos = boss_spawn_point.global_position + Vector3.UP
	loot_system.drop_loot(JOES_TRASH.duplicate(), drop_pos, Vector3(0, 5, 0))
	
	# Drop some basic loot
	# In a full implementation, this would use the boss's loot table

# =============================================================================
# PORTAL
# =============================================================================

func _activate_portal() -> void:
	if portal == null:
		return
	
	# Activate the portal (this also unlocks it in FastTravelManager)
	if portal.has_method("activate"):
		portal.activate()
	elif portal.has_method("set_active"):
		portal.set_active(true)
		# Also manually unlock in FastTravelManager
		FastTravelManager.unlock_portal("landfill")
	else:
		# Fallback: just toggle visibility
		portal.visible = true


func _set_portal_active(active: bool) -> void:
	if portal == null:
		return
	
	if portal.has_method("set_active"):
		portal.set_active(active)
	else:
		# Fallback: just toggle visibility
		portal.visible = active


func get_player_spawn_position() -> Vector3:
	if player_spawn:
		return player_spawn.global_position
	return Vector3(0, 1, 0)
