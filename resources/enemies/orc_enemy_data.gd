## OrcEnemyData - Template for orc enemy variants
class_name OrcEnemyData
extends Resource

enum OrcVariant {
	WARRIOR,
	BERSERKER,
	WARLORD,
	SHAMAN
}

@export var variant: OrcVariant = OrcVariant.WARRIOR
@export var level: int = 1
@export var health: float = 200.0
@export var damage: float = 30.0
@export var speed: float = 3.5
@export var attack_range: float = 2.5
@export var detection_range: float = 12.0
@export var special_ability: String = ""

func _init() -> void:
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	match variant:
		OrcVariant.WARRIOR:
			health = 200.0
			damage = 30.0
		OrcVariant.BERSERKER:
			health = 150.0
			damage = 50.0
			speed = 4.5
			special_ability = "rage"
		OrcVariant.WARLORD:
			health = 500.0
			damage = 60.0
			speed = 3.0
			special_ability = "battle_cry"
		OrcVariant.SHAMAN:
			health = 180.0
			damage = 40.0
			special_ability = "bloodlust"

func get_display_name() -> String:
	match variant:
		OrcVariant.WARRIOR: return "Orc Warrior"
		OrcVariant.BERSERKER: return "Orc Berserker"
		OrcVariant.WARLORD: return "Orc Warlord"
		OrcVariant.SHAMAN: return "Orc Shaman"
		_: return "Orc"

func get_threat_level() -> String:
	var score = health * 0.1 + damage * 1.5
	if score > 150: return "High"
	return "Medium"

func get_ai_behavior_tree() -> Dictionary:
	return {
		"combat_preference": "aggressive",
		"group_coordination": true
	}

func get_loot_table() -> Array:
	return [
		{"item": "orc_ear", "weight": 40, "min": 1, "max": 1},
		{"item": "heavy_axe", "weight": 10, "min": 1, "max": 1}
	]

func get_group_tactics() -> Array[String]:
	return ["horde_charge", "flanking"]
