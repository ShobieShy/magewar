## HarpyEnemyData - Template for harpy enemy variants
class_name HarpyEnemyData
extends Resource

enum HarpyVariant {
	SCAVENGER,
	SCREECHER,
	QUEEN
}

@export var variant: HarpyVariant = HarpyVariant.SCAVENGER
@export var level: int = 1
@export var health: float = 150.0
@export var damage: float = 25.0
@export var speed: float = 6.0
@export var attack_range: float = 3.0
@export var detection_range: float = 20.0
@export var special_ability: String = "swoop"

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		HarpyVariant.SCAVENGER:
			health = 120.0
		HarpyVariant.SCREECHER:
			health = 180.0
			special_ability = "sonic_scream"
		HarpyVariant.QUEEN:
			health = 600.0
			damage = 60.0
			special_ability = "call_the_flock"

func get_display_name() -> String:
	match variant:
		HarpyVariant.SCAVENGER: return "Harpy Scavenger"
		HarpyVariant.SCREECHER: return "Harpy Screecher"
		HarpyVariant.QUEEN: return "Harpy Queen"
		_: return "Harpy"

func get_threat_level() -> String:
	if variant == HarpyVariant.QUEEN: return "Boss"
	return "Medium"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "hit_and_run",
		"is_flying": true
	}

func get_loot_table() -> Array:
	return [
		{"item": "harpy_feather", "weight": 50, "min": 1, "max": 4},
		{"item": "shiny_trinket", "weight": 10, "min": 1, "max": 1}
	]

func get_group_tactics() -> Array[String]:
	return ["dive_bomb", "distraction"]
