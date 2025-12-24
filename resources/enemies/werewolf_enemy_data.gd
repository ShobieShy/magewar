## WerewolfEnemyData - Template for werewolf enemy variants
class_name WerewolfEnemyData
extends Resource

enum WerewolfVariant {
	STALKER,
	ALPHA,
	FRENZIED
}

@export var variant: WerewolfVariant = WerewolfVariant.STALKER
@export var level: int = 1
@export var health: float = 400.0
@export var damage: float = 50.0
@export var speed: float = 6.5
@export var attack_range: float = 2.5
@export var detection_range: float = 20.0
@export var special_ability: String = "howl"

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		WerewolfVariant.STALKER:
			speed = 7.5
			damage = 40.0
		WerewolfVariant.ALPHA:
			health = 800.0
			damage = 80.0
			special_ability = "leader_howl"
		WerewolfVariant.FRENZIED:
			damage = 100.0
			speed = 8.0
			health = 300.0

func get_display_name() -> String:
	match variant:
		WerewolfVariant.STALKER: return "Werewolf Stalker"
		WerewolfVariant.ALPHA: return "Alpha Werewolf"
		WerewolfVariant.FRENZIED: return "Frenzied Werewolf"
		_: return "Werewolf"

func get_threat_level() -> String:
	return "High"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "aggressive",
		"pack_mentality": true
	}

func get_loot_table() -> Array:
	return [
		{"item": "wolf_pelt", "weight": 50, "min": 1, "max": 1},
		{"item": "werewolf_claw", "weight": 20, "min": 1, "max": 2}
	]

func get_group_tactics() -> Array[String]:
	return ["pack_hunt", "surround"]
