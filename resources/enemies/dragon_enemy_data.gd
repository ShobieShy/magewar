## DragonEnemyData - Template for dragon enemy variants
class_name DragonEnemyData
extends Resource

enum DragonVariant {
	YOUNG,           ## Faster, less health
	ADULT,           ## Balanced
	ANCIENT,         ## Boss-level, slow but deadly
	ELEMENTAL        ## Fire/Frost/Storm variants
}

@export var variant: DragonVariant = DragonVariant.ADULT
@export var level: int = 1
@export var health: float = 1000.0
@export var damage: float = 100.0
@export var speed: float = 5.0
@export var attack_range: float = 10.0
@export var detection_range: float = 30.0
@export var special_ability: String = "fire_breath"

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		DragonVariant.YOUNG:
			health = 500.0
			damage = 50.0
			speed = 7.0
			special_ability = "fireball"
		DragonVariant.ANCIENT:
			health = 5000.0
			damage = 250.0
			speed = 3.0
			special_ability = "inferno"
		DragonVariant.ELEMENTAL:
			health = 1200.0
			damage = 120.0
			special_ability = "elemental_blast"

func get_display_name() -> String:
	match variant:
		DragonVariant.YOUNG: return "Young Dragon"
		DragonVariant.ADULT: return "Adult Dragon"
		DragonVariant.ANCIENT: return "Ancient Dragon"
		DragonVariant.ELEMENTAL: return "Elemental Dragon"
		_: return "Dragon"

func get_threat_level() -> String:
	return "Boss"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "aggressive",
		"special_cooldown": 15.0
	}

func get_loot_table() -> Array:
	return [
		{"item": "dragon_scale", "weight": 50, "min": 1, "max": 5},
		{"item": "dragon_heart", "weight": 10, "min": 1, "max": 1}
	]

func get_group_tactics() -> Array[String]:
	return ["aerial_assault", "fear_aura"]
