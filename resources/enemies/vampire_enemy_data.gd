## VampireEnemyData - Template for vampire enemy variants
class_name VampireEnemyData
extends Resource

enum VampireVariant {
	FLEDGLING,
	NOBLE,
	LORD,
	ANCIENT
}

@export var variant: VampireVariant = VampireVariant.FLEDGLING
@export var level: int = 1
@export var health: float = 300.0
@export var damage: float = 40.0
@export var speed: float = 5.0
@export var attack_range: float = 2.0
@export var detection_range: float = 15.0
@export var special_ability: String = "life_steal"

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		VampireVariant.FLEDGLING:
			health = 200.0
			damage = 30.0
		VampireVariant.NOBLE:
			health = 450.0
			damage = 60.0
			special_ability = "mist_form"
		VampireVariant.LORD:
			health = 800.0
			damage = 100.0
			special_ability = "charm"
		VampireVariant.ANCIENT:
			health = 1500.0
			damage = 150.0
			speed = 6.0
			special_ability = "blood_nova"

func get_display_name() -> String:
	match variant:
		VampireVariant.FLEDGLING: return "Vampire Fledgling"
		VampireVariant.NOBLE: return "Vampire Noble"
		VampireVariant.LORD: return "Vampire Lord"
		VampireVariant.ANCIENT: return "Ancient Vampire"
		_: return "Vampire"

func get_threat_level() -> String:
	if variant == VampireVariant.ANCIENT: return "Boss"
	return "High"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "strategic",
		"prefers_night": true
	}

func get_loot_table() -> Array:
	return [
		{"item": "vampire_dust", "weight": 30, "min": 1, "max": 2},
		{"item": "blood_gem", "weight": 5, "min": 1, "max": 1}
	]

func get_group_tactics() -> Array[String]:
	return ["ambush", "drain_life"]
