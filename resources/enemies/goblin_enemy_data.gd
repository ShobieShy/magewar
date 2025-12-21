## GoblinEnemyData - Template for goblin enemy variants
class_name GoblinEnemyData
extends Resource

# =============================================================================
# PROPERTIES
# =============================================================================

## Goblin variant types
enum GoblinVariant {
	BASIC,           ## Basic goblin warrior
	SCOUT,           ## Fast, ranged attacker
	BRUTE,           ## Heavy, tank goblin
	SHAMAN,          ## Elemental magic user
	CHIEF            ## Leader with boosted stats
}

## Enemy configuration
@export var variant: GoblinVariant = GoblinVariant.BASIC
@export var level: int = 1
@export var health: float = 100.0
@export var damage: float = 15.0
@export var speed: float = 3.0
@export var attack_range: float = 2.0
@export var detection_range: float = 8.0
@export var patrol_speed: float = 2.0
@export var group_size: int = 3  ## Preferred group size
@export var aggression: float = 0.7  ## Attack chance
@export var special_ability: String = ""  ## Goblin special moves

## Elemental variants (for Shamans)
@export var element: Enums.Element = Enums.Element.NONE
@export var elemental_power: float = 0.0

## Behavior preferences
@export var uses_weapon: bool = true
@export var weapon_type: String = "rusty_sword"  ## Item ID
@export var prefers_range: bool = false
@export var retreat_threshold: float = 0.3  ## Health % when to flee

## Visual customization
@export var mesh_color: Color = Color.GREEN
@export var mesh_scale: Vector3 = Vector3.ONE
@export var armor_color: Color = Color.DARK_GRAY
@export var weapon_color: Color = Color.SILVER

## Loot configuration
@export var gold_drop_min: int = 10
@export var gold_drop_max: int = 25
@export var item_drops: Array[String] = ["basic_potion", "rusty_dagger"]
@export var drop_chance: float = 0.6

## AI preferences
@export var group_coordination: bool = true
@export var flanking_bonus: float = 1.5  ## Damage multiplier for flanking
@export var tactical_retreat: bool = true
@export var calls_for_help: bool = true  ## yell for allies when health low

# =============================================================================
# METHODS
# =============================================================================

func _init() -> void:
	# Apply variant-specific modifications
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	## Adjust stats based on goblin variant
	match variant:
		GoblinVariant.BASIC:
			health = 80.0
			damage = 12.0
			speed = 2.8
			group_size = 2
			
		GoblinVariant.SCOUT:
			health = 60.0
			damage = 8.0
			speed = 4.5
			attack_range = 8.0
			uses_weapon = false
			prefers_range = true
			special_ability = "quick_shot"
			mesh_color = Color.BROWN
			
		GoblinVariant.BRUTE:
			health = 150.0
			damage = 20.0
			speed = 2.0
			attack_range = 1.5
			weapon_type = "heavy_hammer"
			armor_color = Color.DARK_GREEN
			mesh_scale = Vector3(1.3, 1.3, 1.0)
			special_ability = "ground_slam"
			
		GoblinVariant.SHAMAN:
			health = 70.0
			damage = 15.0
			speed = 3.0
			element = [Enums.Element.FIRE, Enums.Element.AIR, Enums.Element.DARK].pick_random()
			elemental_power = 25.0
			uses_weapon = false
			special_ability = "elemental_bolt"
			mesh_color = Color.PURPLE
			group_coordination = true
			
		GoblinVariant.CHIEF:
			health = 120.0
			damage = 25.0
			speed = 3.5
			health *= 1.5  ## Leadership bonus
			damage *= 1.3
			group_size = 5
			weapon_type = "chief_sword"
			mesh_color = Color.GOLD
			armor_color = Color.ORANGE
			calls_for_help = true
			group_coordination = true
			drop_chance = 0.8
			item_drops.append("boss_key_fragment")

func get_display_name() -> String:
	## Get localized display name
	match variant:
		GoblinVariant.BASIC:
			return "Goblin Warrior"
		GoblinVariant.SCOUT:
			return "Goblin Scout"
		GoblinVariant.BRUTE:
			return "Goblin Brute"
		GoblinVariant.SHAMAN:
			return "Goblin Shaman"
		GoblinVariant.CHIEF:
			return "Goblin Chief"
		_:
			return "Goblin"

func get_threat_level() -> String:
	## Calculate threat level for balancing
	var threat_score = (health * 0.1) + (damage * 2.0) + (speed * 1.0)
	if variant == GoblinVariant.CHIEF:
		threat_score *= 1.5  ## Leadership bonus
	
	if threat_score < 50:
		return "Low"
	elif threat_score < 100:
		return "Medium"
	elif threat_score < 200:
		return "High"
	else:
		return "Boss"

func get_ai_behavior_tree() -> Dictionary:
	## Get AI behavior preferences for this variant
	return {
		"patrol_behavior": "wander" if variant != GoblinVariant.BRUTE else "search",
		"combat_preference": "aggressive" if variant == GoblinVariant.BRUTE else "balanced",
		"group_coordination": group_coordination,
		"uses_formation": variant == GoblinVariant.CHIEF,
		"retreat_tactic": "strategic" if tactical_retreat else "panic",
		"special_cooldown": 8.0 if not special_ability.is_empty() else 0.0,
		"alert_range": detection_range * 1.2
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
			"weight": 20,
			"min": 1,
			"max": 1
		})
	
	# Special drops for elites
	if variant == GoblinVariant.CHIEF:
		loot_table.append({
			"item": "chief_horn",
			"weight": 10,
			"min": 1,
			"max": 1
		})
	
	return loot_table

func get_group_tactics() -> Array[String]:
	## Get preferred group tactics
	var tactics = []
	
	match variant:
		GoblinVariant.BASIC:
			tactics = ["surround", "numbers_advantage"]
			
		GoblinVariant.SCOUT:
			tactics = ["hit_and_run", "pinning_fire"]
			
		GoblinVariant.BRUTE:
			tactics = ["frontal_assault", "guard_the_rear"]
			
		GoblinVariant.SHAMAN:
			tactics = ["elemental_support", "area_denial"]
			
		GoblinVariant.CHIEF:
			tactics = ["coordinated_attack", "morale_boost"]
	
	# Add tactics based on behavior
	if tactical_retreat:
		tactics.append("strategic_retreat")
	if calls_for_help:
		tactics.append("call_reinforcements")
	
	return tactics