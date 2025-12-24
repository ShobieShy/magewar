## BasiliskEnemyData - Template for basilisk enemy variants
class_name BasiliskEnemyData
extends Resource

enum BasiliskVariant {
	LESSER,
	GREATER,
	PETRIFYING
}

@export var variant: BasiliskVariant = BasiliskVariant.LESSER
@export var level: int = 1
@export var health: float = 300.0
@export var damage: float = 35.0
@export var speed: float = 3.0
@export var attack_range: float = 4.0
@export var detection_range: float = 15.0
@export var special_ability: String = "poison_bite"

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		BasiliskVariant.LESSER:
			health = 250.0
		BasiliskVariant.GREATER:
			health = 600.0
			damage = 60.0
		BasiliskVariant.PETRIFYING:
			health = 450.0
			special_ability = "petrifying_gaze"

func get_display_name() -> String:
	match variant:
		BasiliskVariant.LESSER: return "Lesser Basilisk"
		BasiliskVariant.GREATER: return "Greater Basilisk"
		BasiliskVariant.PETRIFYING: return "Petrifying Basilisk"
		_: return "Basilisk"

func get_threat_level() -> String:
	return "High"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "ambush",
		"slow_movement": true
	}

func get_loot_table() -> Array:
	return [
		{"item": "basilisk_eye", "weight": 20, "min": 1, "max": 1},
		{"item": "venom_gland", "weight": 30, "min": 1, "max": 2}
	]

func get_group_tactics() -> Array[String]:
	return ["stealth_approach", "paralyzing_strike"]
