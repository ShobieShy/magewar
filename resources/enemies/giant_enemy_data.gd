## GiantEnemyData - Template for giant enemy variants
class_name GiantEnemyData
extends Resource

enum GiantVariant {
	HILL,
	STONE,
	FROST,
	STORM
}

@export var variant: GiantVariant = GiantVariant.HILL
@export var level: int = 1
@export var health: float = 1200.0
@export var damage: float = 80.0
@export var speed: float = 2.5
@export var attack_range: float = 5.0
@export var detection_range: float = 25.0
@export var special_ability: String = "stomp"

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		GiantVariant.HILL:
			health = 1000.0
		GiantVariant.STONE:
			health = 2000.0
			damage = 100.0
			speed = 2.0
		GiantVariant.FROST:
			health = 1500.0
			damage = 90.0
			special_ability = "ice_shards"
		GiantVariant.STORM:
			health = 1800.0
			damage = 120.0
			special_ability = "lightning_strike"

func get_display_name() -> String:
	match variant:
		GiantVariant.HILL: return "Hill Giant"
		GiantVariant.STONE: return "Stone Giant"
		GiantVariant.FROST: return "Frost Giant"
		GiantVariant.STORM: return "Storm Giant"
		_: return "Giant"

func get_threat_level() -> String:
	return "High"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "heavy",
		"can_destroy_obstacles": true
	}

func get_loot_table() -> Array:
	return [
		{"item": "giant_toe", "weight": 20, "min": 1, "max": 1},
		{"item": "boulder", "weight": 10, "min": 1, "max": 1}
	]

func get_group_tactics() -> Array[String]:
	return ["ground_pound", "ranged_toss"]
