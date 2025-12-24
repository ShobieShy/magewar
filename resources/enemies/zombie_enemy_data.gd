## ZombieEnemyData - Template for zombie enemy variants
class_name ZombieEnemyData
extends Resource

enum ZombieVariant {
	WALKER,
	SHAMBLER,
	INFECTED,
	BLOATED
}

@export var variant: ZombieVariant = ZombieVariant.WALKER
@export var level: int = 1
@export var health: float = 120.0
@export var damage: float = 15.0
@export var speed: float = 1.5
@export var attack_range: float = 1.5
@export var detection_range: float = 10.0
@export var special_ability: String = "grab"

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		ZombieVariant.WALKER:
			health = 100.0
		ZombieVariant.SHAMBLER:
			health = 150.0
			speed = 1.0
		ZombieVariant.INFECTED:
			speed = 3.5
			damage = 25.0
			special_ability = "viral_bite"
		ZombieVariant.BLOATED:
			health = 300.0
			special_ability = "explosion"

func get_display_name() -> String:
	match variant:
		ZombieVariant.WALKER: return "Zombie Walker"
		ZombieVariant.SHAMBLER: return "Zombie Shambler"
		ZombieVariant.INFECTED: return "Infected Zombie"
		ZombieVariant.BLOATED: return "Bloated Zombie"
		_: return "Zombie"

func get_threat_level() -> String:
	return "Low"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "relentless",
		"fearless": true
	}

func get_loot_table() -> Array:
	return [
		{"item": "rotten_flesh", "weight": 60, "min": 1, "max": 3},
		{"item": "tattered_clothes", "weight": 20, "min": 1, "max": 1}
	]

func get_group_tactics() -> Array[String]:
	return ["swarming", "persistent_chase"]
