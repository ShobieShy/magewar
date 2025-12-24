## Orc Enemy
class_name OrcEnemy
extends EnemyBase

@export var orc_data: OrcEnemyData

func _ready() -> void:
	super._ready()
	enemy_name = "Orc"
	enemy_type = Enums.EnemyType.ORC
	if not orc_data:
		orc_data = OrcEnemyData.new()
	
	max_health = orc_data.health * level
	damage = orc_data.damage
	move_speed = orc_data.speed
	attack_range = orc_data.attack_range
	detection_range = orc_data.detection_range
	
	if stats:
		stats.max_health = max_health
		stats.reset_stats()
	
	loot_table = orc_data.get_loot_table()
