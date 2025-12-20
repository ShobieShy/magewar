## TrollEnemyData - Template for troll enemy variants
class_name TrollEnemyData
extends Resource

# =============================================================================
# PROPERTIES
# =============================================================================

## Troll variant types
enum TrollVariant {
	BASIC,           ## Regular troll
	HILL,           ## Mountain troll
	CAVE,           ## Cave-adapted troll
	FROST,          ## Ice-environmental troll
	ANCIENT,        ## Elder troll with magic resistance
}

## Enemy configuration
@export var variant: TrollVariant = TrollVariant.BASIC
@export var level: int = 1
@export var health: float = 200.0
@export var damage: float = 30.0
@export var speed: float = 2.0
@export var attack_range: float = 3.0
@export var detection_range: float = 12.0
@export var patrol_speed: float = 1.5

## Troll special abilities
@export var regeneration_rate: float = 5.0  ## HP per second
@export var special_ability: String = ""  ## Troll special moves
@export var rage_threshold: float = 0.5  ## Health % to trigger rage
@export var rage_damage_bonus: float = 1.5  ## Damage multiplier in rage
@export var rage_speed_bonus: float = 0.5  ## Speed multiplier in rage
@export var stun_duration: float = 2.0  ## Stun duration for hammer swing

## Environmental adaptations
@export var environmental_resistance: String = ""  ## Special resistances
@export var terrain_bonus: String = ""  ## Terrain advantages

## Visual customization
@export var mesh_color: Color = Color.BROWN
@export var mesh_scale: Vector3 = Vector3(1.2, 1.2, 1.0)
@export var armor_color: Color = Color(0.4, 0.2, 0.1, 1.0)
@export var weapon_color: Color = Color.GRAY

## Loot configuration
@export var gold_drop_min: int = 25
@export var gold_drop_max: int = 50
@export var item_drops: Array[String] = ["healing_potion", "troll_hide_armor"]
@export var drop_chance: float = 0.7

# =============================================================================
# METHODS
# =============================================================================

func _init() -> void:
	# Apply variant-specific modifications
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	## Adjust stats based on troll variant
	match variant:
		TrollVariant.BASIC:
			health = 150.0
			damage = 25.0
			speed = 2.0
			regeneration_rate = 3.0
			
		TrollVariant.HILL:
			health = 250.0
			damage = 35.0
			speed = 1.8
			terrain_bonus = "mountain_climbing"
			mesh_color = Color.DARK_GREEN
			armor_color = Color.GREEN
			
		TrollVariant.CAVE:
			health = 180.0
			damage = 28.0
			speed = 2.2
			environmental_resistance = "dark_vision"
			terrain_bonus = "cave_advantage"
			mesh_color = Color.DARK_GRAY
			
		TrollVariant.FROST:
			health = 160.0
			damage = 30.0
			speed = 1.5
			regeneration_rate = 4.0
			special_ability = "ice_breath"
			environmental_resistance = "cold_resistance"
			mesh_color = Color.LIGHT_BLUE
			
		TrollVariant.ANCIENT:
			health = 300.0
			damage = 40.0
			speed = 1.2
			regeneration_rate = 6.0
			special_ability = "ground_slam"
			environmental_resistance = "magic_resistance"
			mesh_color = Color.PURPLE
			armor_color = Color.GOLD
			drop_chance = 0.85
			item_drops.append("elder_rune")

func get_display_name() -> String:
	## Get localized display name
	match variant:
		TrollVariant.BASIC:
			return "Troll"
		TrollVariant.HILL:
			return "Mountain Troll"
		TrollVariant.CAVE:
			return "Cave Troll"
		TrollVariant.FROST:
			return "Frost Troll"
		TrollVariant.ANCIENT:
			return "Elder Troll"
		_:
			return "Troll"

func get_threat_level() -> String:
	## Calculate threat level for balancing
	var threat_score = (health * 0.08) + (damage * 1.5) + (regeneration_rate * 2.0)
	if variant == TrollVariant.ANCIENT:
		threat_score *= 1.3  ## Elder bonus
	
	if threat_score < 100:
		return "Low"
	elif threat_score < 250:
		return "Medium"
	elif threat_score < 400:
		return "High"
	else:
		return "Boss"

func get_ai_behavior_tree() -> Dictionary:
	## Get AI behavior preferences for this variant
	return {
		"patrol_behavior": "lazy_patrol" if variant != TrollVariant.HILL else "territorial",
		"combat_preference": "tanky" if variant == TrollVariant.HILL else "aggressive",
		"uses_cover": variant != TrollVariant.BASIC,
		"has_throw_attack": variant == TrollVariant.CAVE,
		"special_cooldown": 12.0 if not special_ability.is_empty() else 0.0,
		"alert_range": detection_range * 1.1,
		"healing_behavior": "passive_regen",
		"healing_rate": regeneration_rate
	}

func get_loot_table() -> Array:
	## Generate loot table based on variant
	var loot_table = []
	
	# Base gold drop
	loot_table.append({
		"item": "gold",
		"weight": 25,
		"min": gold_drop_min,
		"max": gold_drop_max
	})
	
	# Item drops
	for item_id in item_drops:
		loot_table.append({
			"item": item_id,
			"weight": 15,
			"min": 1,
			"max": 1
		})
	
	# Special drops for ancient trolls
	if variant == TrollVariant.ANCIENT:
		loot_table.append({
			"item": "ancient_scroll",
			"weight": 8,
			"min": 1,
			"max": 1
		})
	
	return loot_table

func get_group_tactics() -> Array[String]:
	## Get preferred group tactics
	var tactics = []
	
	match variant:
		TrollVariant.BASIC:
			tactics = ["brute_force", "numbers_advantage"]
			
		TrollVariant.HILL:
			tactics = ["terrain_advantage", "rock_throw"]
			
		TrollVariant.CAVE:
			tactics = ["ambush_attack", "block_exits"]
			
		TrollVariant.FROST:
			tactics = ["area_control", "ice_traps"]
			
		TrollVariant.ANCIENT:
			tactics = ["strategic_attack", "召唤_allies"]  ## Summon allies
	
	return tactics

func trigger_rage_mode() -> void:
	## Enter rage mode when health is low
	if health < (get_max_health() * rage_threshold):
		print("%s enters rage mode!" % get_display_name())
		# Visual and stat modifications would be handled by enemy script
		return

func get_max_health() -> float:
	## Get maximum health for calculations
	return health * (1.5 if variant == TrollVariant.ANCIENT else 1.0)

func has_terrain_advantage(terrain_type: String) -> bool:
	## Check if troll has advantage on this terrain
	return terrain_bonus == terrain_type

func has_environmental_resistance(damage_type: String) -> bool:
	## Check if troll resists this damage type
	return environmental_resistance == damage_type