## SlimeEnemyData - Template for slime enemy variants
class_name SlimeEnemyData
extends Resource

# =============================================================================
# PROPERTIES
# =============================================================================

## Slime variant types
enum SlimeVariant {
	BASIC,           ## Standard slime
	FIRE,           ## Fire slime
	ICE,            ## Ice slime
	POISON,         ## Poison slime
	ELECTRIC,       ## Electric slime
}

## Enemy configuration
@export var variant: SlimeVariant = SlimeVariant.BASIC
@export var level: int = 1
@export var health: float = 40.0
@export var damage: float = 8.0
@export var speed: float = 2.5
@export var attack_range: float = 1.5
@export var detection_range: float = 6.0
@export var patrol_speed: float = 1.8

## Slime special abilities
@export var special_ability: String = ""  ## Slime special moves
@export var jump_cooldown: float = 3.0  ## Jump attack cooldown
@export var split_cooldown: float = 8.0  ## Split ability cooldown
@export var elemental_effect_radius: float = 2.0  ## Radius of elemental effects

## Elemental variants (for element slimes)
@export var element: Enums.Element = Enums.Element.NONE
@export var elemental_power: float = 0.0

## Behavior preferences
@export var uses_weapon: bool = false
@export var can_split: bool = true  ## Can split into smaller slimes
@export var split_threshold: float = 0.5  ## Health % to trigger split
@export var max_splits: int = 2  ## Maximum number of splits
@export var leaves_trail: bool = true  ## Leaves damaging trail

## Visual customization
@export var mesh_color: Color = Color.GREEN
@export var mesh_scale: Vector3 = Vector3.ONE
@export var armor_color: Color = Color.TRANSPARENT  ## Slimes are transparent
@export var weapon_color: Color = Color.GREEN
@export var emissive_color: Color = Color.GREEN  ## Glow color

## Loot configuration
@export var gold_drop_min: int = 5
@export var gold_drop_max: int = 15
@export var item_drops: Array[String] = ["apprentice_hat", "arcane_robes"]
@export var drop_chance: float = 0.4

## AI preferences
@export var aggression: float = 0.6  ## Base aggression
@export var pack_mentality: bool = true  ## Joins other slimes
@export var elemental_behavior: String = ""  ## Special elemental behavior

# =============================================================================
# METHODS
# =============================================================================

func _init() -> void:
	# Apply variant-specific modifications
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	## Adjust stats based on slime variant
	match variant:
		SlimeVariant.BASIC:
			health = 30.0
			damage = 6.0
			speed = 2.0
			
		SlimeVariant.FIRE:
			health = 35.0
			damage = 10.0
			element = Enums.Element.FIRE
			elemental_power = 15.0
			elemental_behavior = "burning_trail"
			emissive_color = Color.RED
			mesh_color = Color.ORANGE
			
		SlimeVariant.ICE:
			health = 35.0
			damage = 8.0
			element = Enums.Element.WATER  # Frost/Ice → Water element
			elemental_power = 12.0
			elemental_behavior = "freezing_ground"
			emissive_color = Color.CYAN
			mesh_color = Color.LIGHT_BLUE
			
		SlimeVariant.POISON:
			health = 40.0
			damage = 7.0
			element = Enums.Element.DARK  # Poison → Dark element
			elemental_power = 18.0
			elemental_behavior = "poison_cloud"
			emissive_color = Color.DARK_GREEN
			mesh_color = Color.GREEN
			
		SlimeVariant.ELECTRIC:
			health = 30.0
			damage = 12.0
			element = Enums.Element.AIR  # Lightning → Air element
			elemental_power = 20.0
			elemental_behavior = "shock_burst"
			jump_cooldown = 2.0
			emissive_color = Color.YELLOW
			mesh_color = Color.LIGHT_YELLOW

func get_display_name() -> String:
	## Get localized display name
	match variant:
		SlimeVariant.BASIC:
			return "Slime"
		SlimeVariant.FIRE:
			return "Fire Slime"
		SlimeVariant.ICE:
			return "Ice Slime"
		SlimeVariant.POISON:
			return "Poison Slime"
		SlimeVariant.ELECTRIC:
			return "Electric Slime"
		_:
			return "Slime"

func get_threat_level() -> String:
	## Calculate threat level for balancing
	var threat_score = (health * 0.1) + (damage * 1.5) + (speed * 0.8)
	
	if threat_score < 30:
		return "Minion"
	elif threat_score < 60:
		return "Low"
	elif threat_score < 120:
		return "Medium"
	else:
		return "High"

func get_ai_behavior_tree() -> Dictionary:
	## Get AI behavior preferences for this variant
	return {
		"patrol_behavior": "wander" if variant != SlimeVariant.ELECTRIC else "search",
		"combat_preference": "opportunistic" if variant == SlimeVariant.FIRE else "defensive",
		"group_coordination": pack_mentality,
		"special_cooldown": jump_cooldown if not jump_cooldown == 0.0 else split_cooldown,
		"split_behavior": {
			"enabled": can_split,
			"threshold": split_threshold,
			"max_splits": max_splits,
			"health_per_split": health / (max_splits + 1)
		},
		"elemental_effect": {
			"radius": elemental_effect_radius,
			"type": element,
			"power": elemental_power,
			"behavior": elemental_behavior
		}
	}

func get_loot_table() -> Array:
	## Generate loot table based on variant
	var loot_table = []
	
	# Item drops (gold is handled separately by _drop_gold())
	for item_id in item_drops:
		var weight = 15
		if element != Enums.Element.NONE:
			weight = 20  ## Element slimes more likely to drop essence
			
		loot_table.append({
			"item": item_id,
			"weight": weight,
			"min": 1,
			"max": 1
		})
	
	# Special elemental drops
	if element != Enums.Element.NONE:
		var element_name = Enums.element_to_string(element).to_lower()
		loot_table.append({
			"item": element_name + "_essence",
			"weight": 25,
			"min": 1,
			"max": 1
		})
	
	return loot_table

func should_split() -> bool:
	## Check if slime can split
	# Get max health from variant modifiers
	var max_health = health
	match variant:
		SlimeVariant.BASIC:
			max_health = 30.0
		SlimeVariant.FIRE:
			max_health = 35.0
		SlimeVariant.ICE:
			max_health = 35.0
		SlimeVariant.POISON:
			max_health = 40.0
		SlimeVariant.ELECTRIC:
			max_health = 30.0
	
	return can_split and health > (split_threshold * max_health)

func should_trigger_elemental_effect() -> bool:
	## Check if slime should trigger elemental effect
	return element != Enums.Element.NONE and randf() < 0.3  ## 30% chance

func get_split_spawn_positions(current_position: Vector3, count: int) -> Array[Vector3]:
	## Get positions for slime splits
	var positions: Array[Vector3] = []
	var spawn_radius = 1.0
	
	for i in range(count):
		var angle = (PI * 2.0 * i) / count
		var offset = Vector3(
			cos(angle) * spawn_radius,
			0.0,
			sin(angle) * spawn_radius
		)
		positions.append(current_position + offset)
	
	return positions

func get_elemental_damage() -> float:
	## Get damage including elemental bonus
	return damage + elemental_power

func leaves_elemental_trail() -> bool:
	## Check if slime leaves elemental trail
	match elemental_behavior:
		"burning_trail", "freezing_ground", "poison_cloud":
			return true
		_:
			return false