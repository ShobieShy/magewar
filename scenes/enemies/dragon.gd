## Dragon Enemy
class_name DragonEnemy
extends EnemyBase

@export var dragon_data: DragonEnemyData

func _ready() -> void:
	super._ready()
	enemy_name = "Dragon"
	enemy_type = Enums.EnemyType.BOSS
	if not dragon_data:
		dragon_data = DragonEnemyData.new()
	
	max_health = dragon_data.health * level
	damage = dragon_data.damage
	move_speed = dragon_data.speed
	attack_range = dragon_data.attack_range
	detection_range = dragon_data.detection_range
	
	if stats:
		stats.max_health = max_health
		stats.reset_stats()
	
	loot_table = dragon_data.get_loot_table()
