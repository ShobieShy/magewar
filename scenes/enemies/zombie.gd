## Zombie Enemy
class_name ZombieEnemy
extends EnemyBase

@export var zombie_data: ZombieEnemyData

func _ready() -> void:
	super._ready()
	enemy_name = "Zombie"
	enemy_type = Enums.EnemyType.ZOMBIE
	if not zombie_data:
		zombie_data = ZombieEnemyData.new()
	
	max_health = zombie_data.health * level
	damage = zombie_data.damage
	move_speed = zombie_data.speed
	attack_range = zombie_data.attack_range
	detection_range = zombie_data.detection_range
	
	if stats:
		stats.max_health = max_health
		stats.reset_stats()
	
	loot_table = zombie_data.get_loot_table()
