## WraithEnemyData - Template for wraith enemy variants
class_name WraithEnemyData
extends Resource

# =============================================================================
# PROPERTIES
# =============================================================================

## Wraith variant types
enum WraithVariant {
	BASIC,           ## Standard wraith
	SHADOW,          ## Stealthy wraith
	FROST_WRAITH,    ## Ice-based wraith
	ANCIENT,        ## Elder wraith with advanced powers
}

## Enemy configuration
@export var variant: WraithVariant = WraithVariant.BASIC
@export var level: int = 1
@export var health: float = 80.0
@export var damage: float = 25.0
@export var speed: float = 5.0
@export var attack_range: float = 4.0
@export var detection_range: float = 15.0
@export var patrol_speed: float = 3.0

## Wraith special abilities
@export var special_ability: String = ""  ## Wraith special moves
@export var life_drain_rate: float = 5.0  ## HP drain per second
@export var phase_duration: float = 2.0  ## Duration of phase ability
@export var teleport_cooldown: float = 8.0  ## Cooldown for teleport
@export var invisibility_duration: float = 3.0  ## Duration of invisibility

## Elemental variants
@export var element: Enums.Element = Enums.Element.NONE
@export var elemental_power: float = 0.0

## Visual customization
@export var mesh_color: Color = Color(0.3, 0.0, 0.3, 1.0)
@export var mesh_scale: Vector3 = Vector3.ONE
@export var armor_color: Color = Color.BLACK
@export var weapon_color: Color = Color.VIOLET

## Loot configuration
@export var gold_drop_min: int = 30
@export var gold_drop_max: int = 60
@export var item_drops: Array[String] = ["shadow_essence", "wraith_cloak"]
@export var drop_chance: float = 0.4

# =============================================================================
# METHODS
# =============================================================================

func _init() -> void:
	# Apply variant-specific modifications
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	## Adjust stats based on wraith variant
	match variant:
		WraithVariant.BASIC:
			health = 60.0
			damage = 20.0
			speed = 4.0
			special_ability = "life_drain"
			
		WraithVariant.SHADOW:
			health = 70.0
			damage = 22.0
			speed = 6.0
			special_ability = "phase_strike"
			teleport_cooldown = 6.0
			mesh_color = Color.DARK_GRAY
			
		WraithVariant.FROST_WRAITH:
			health = 65.0
			damage = 25.0
			speed = 5.0
			element = Enums.Element.ICE
			elemental_power = 20.0
			special_ability = "frost_breath"
			mesh_color = Color.LIGHT_BLUE
			
		WraithVariant.ANCIENT:
			health = 100.0
			damage = 35.0
			speed = 4.5
			life_drain_rate = 8.0
			invisibility_duration = 5.0
			element = Enums.Element.SHADOW
			elemental_power = 30.0
			special_ability = "dimensional_shift"
			mesh_color = Color.DARK_RED
			drop_chance = 0.6
			item_drops.append("soul_fragment")

func get_display_name() -> String:
	## Get localized display name
	match variant:
		WraithVariant.BASIC:
			return "Wraith"
		WraithVariant.SHADOW:
			return "Shadow Wraith"
		WraithVariant.FROST_WRAITH:
			return "Frost Wraith"
		WraithVariant.ANCIENT:
			return "Elder Wraith"
		_:
			return "Wraith"

func get_threat_level() -> String:
	## Calculate threat level for balancing
	var threat_score = (health * 0.15) + (damage * 2.0) + (speed * 1.2)
	if variant == WraithVariant.ANCIENT:
		threat_score *= 1.4  ## Elder bonus
	
	if threat_score < 80:
		return "Low"
	elif threat_score < 160:
		return "Medium"
	elif threat_score < 300:
		return "High"
	else:
		return "Boss"

func get_ai_behavior_tree() -> Dictionary:
	## Get AI behavior preferences for this variant
	return {
		"patrol_behavior": "stealthy" if variant == WraithVariant.SHADOW else "spectral",
		"combat_preference": "hit_and_run" if variant == WraithVariant.SHADOW else "opportunistic",
		"uses_teleportation": true,
		"uses_phase": true,
		"prefers_backstab": true,
		"special_cooldown": teleport_cooldown,
		"life_drain_rate": life_drain_rate,
		"ambush_tendency": 1.2 if variant == WraithVariant.SHADOW else 0.8,
		"group_coordination": true
	}

func get_loot_table() -> Array:
	## Generate loot table based on variant
	var loot_table = []
	
	# Base gold drop
	loot_table.append({
		"item": "gold",
		"weight": 30,
		"min": gold_drop_min,
		"max": gold_drop_max
	})
	
	# Item drops
	for item_id in item_drops:
		loot_table.append({
			"item": item_id,
			"weight": 12,
			"min": 1,
			"max": 1
		})
	
	# Special drops for ancient wraiths
	if variant == WraithVariant.ANCIENT:
		loot_table.append({
			"item": "soul_crystal",
			"weight": 6,
			"min": 1,
			"max": 1
		})
	
	return loot_table

func can_phase_through_walls() -> bool:
	## Check if wraith can phase through solid objects
	return variant in [WraithVariant.SHADOW, WraithVariant.ANCIENT]

func has_life_drain() -> bool:
	## Check if wraith has life drain ability
	return not special_ability.is_empty() and "drain" in special_ability

func can_teleport() -> bool:
	## Check if wraith can teleport
	return variant in [WraithVariant.SHADOW, WraithVariant.ANCIENT]

func get_teleport_range() -> float:
	## Get teleport range for AI
	return 8.0 if variant == WraithVariant.ANCIENT else 6.0