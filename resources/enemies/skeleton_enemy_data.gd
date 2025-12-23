## SkeletonEnemyData - Template for skeleton warrior enemy variants
class_name SkeletonEnemyData
extends Resource

# =============================================================================
# PROPERTIES
# =============================================================================

## Skeleton variant types
enum SkeletonVariant {
	BASIC,           ## Standard skeleton
	ARCHER,         ## Ranged skeleton
	BERSERKER,       ## Melee-focused skeleton
	COMMANDER,      ## Leader skeleton
}

## Enemy configuration
@export var variant: SkeletonVariant = SkeletonVariant.BASIC
@export var level: int = 1
@export var health: float = 60.0
@export var damage: float = 20.0
@export var speed: float = 3.0
@export var attack_range: float = 2.5
@export var detection_range: float = 10.0
@export var patrol_speed: float = 2.0

## Skeleton special abilities
@export var special_ability: String = ""  ## Skeleton special moves
@export var coordination_bonus: float = 1.0  ## Damage bonus when coordinating
@export var formation_preference: String = "line"  ## Preferred formation
@export var resistance_type: String = "crushing"  ## Damage type resistance

## Visual customization
@export var mesh_color: Color = Color.WHITE
@export var mesh_scale: Vector3 = Vector3.ONE
@export var armor_color: Color = Color.LIGHT_GRAY
@export var weapon_color: Color = Color.GRAY

## Loot configuration
@export var gold_drop_min: int = 20
@export var gold_drop_max: int = 40
@export var item_drops: Array[String] = ["apprentice_robes", "reinforced_belt"]
@export var drop_chance: float = 0.5

# =============================================================================
# METHODS
# =============================================================================

func _init() -> void:
	# Apply variant-specific modifications
	_apply_variant_modifiers()

func _apply_variant_modifiers() -> void:
	## Adjust stats based on skeleton variant
	match variant:
		SkeletonVariant.BASIC:
			health = 50.0
			damage = 18.0
			speed = 3.0
			formation_preference = "loose_formation"
			
		SkeletonVariant.ARCHER:
			health = 45.0
			damage = 15.0
			speed = 3.5
			attack_range = 8.0
			special_ability = "multi_shot"
			weapon_color = Color.BROWN
			formation_preference = "ranked_back"
			
		SkeletonVariant.BERSERKER:
			health = 80.0
			damage = 30.0
			speed = 4.0
			special_ability = "rage_mode"
			mesh_color = Color.DARK_RED
			coordination_bonus = 1.5
			formation_preference = "wedge"
			
		SkeletonVariant.COMMANDER:
			health = 60.0
			damage = 22.0
			speed = 2.8
			special_ability = "rally_cry"
			health *= 1.2  ## Commander health bonus
			formation_preference = "shield_wall"
			item_drops.append("commander_helmet")

func get_display_name() -> String:
	## Get localized display name
	match variant:
		SkeletonVariant.BASIC:
			return "Skeleton Warrior"
		SkeletonVariant.ARCHER:
			return "Skeleton Archer"
		SkeletonVariant.BERSERKER:
			return "Berserker Skeleton"
		SkeletonVariant.COMMANDER:
			return "Skeleton Commander"
		_:
			return "Skeleton"

func get_threat_level() -> String:
	## Calculate threat level for balancing
	var threat_score = (health * 0.12) + (damage * 1.8) + (speed * 1.0)
	if variant == SkeletonVariant.COMMANDER:
		threat_score *= 1.2  ## Commander bonus
	
	if threat_score < 60:
		return "Low"
	elif threat_score < 120:
		return "Medium"
	elif threat_score < 250:
		return "High"
	else:
		return "Boss"

func get_ai_behavior_tree() -> Dictionary:
	## Get AI behavior preferences for this variant
	return {
		"patrol_behavior": "coordinated_patrol" if variant == SkeletonVariant.COMMANDER else "solo_patrol",
		"combat_preference": "defensive" if variant == SkeletonVariant.BERSERKER else "balanced",
		"group_coordination": true,
		"formation_type": formation_preference,
		"coordination_range": detection_range * 1.5,
		"special_cooldown": 10.0 if not special_ability.is_empty() else 0.0,
		"uses_formations": variant in [SkeletonVariant.ARCHER, SkeletonVariant.COMMANDER],
		"ranged_preference": variant == SkeletonVariant.ARCHER,
		"shield_behavior": variant == SkeletonVariant.COMMANDER
	}

func get_loot_table() -> Array:
	## Generate loot table based on variant
	var loot_table = []
	
	# Item drops (gold is handled separately by _drop_gold())
	for item_id in item_drops:
		loot_table.append({
			"item": item_id,
			"weight": 15,
			"min": 1,
			"max": 1
		})
	
	# Special drops for commanders
	if variant == SkeletonVariant.COMMANDER:
		loot_table.append({
			"item": "legendary_belt",
			"weight": 8,
			"min": 1,
			"max": 1
		})
	
	return loot_table

func get_group_tactics() -> Array[String]:
	## Get preferred group tactics
	var tactics = []
	
	match variant:
		SkeletonVariant.BASIC:
			tactics = ["surround_attack", "numbers_advantage"]
			
		SkeletonVariant.ARCHER:
			tactics = ["suppressive_fire", "flanking_maneuver"]
			
		SkeletonVariant.BERSERKER:
			tactics = ["frontal_assault", "intimidation"]
			
		SkeletonVariant.COMMANDER:
			tactics = ["coordinated_attack", "shield_wall", "rally_support"]
	
	return tactics

func has_coordination_bonus() -> bool:
	## Check if skeleton gets coordination bonus
	return variant in [SkeletonVariant.ARCHER, SkeletonVariant.BERSERKER, SkeletonVariant.COMMANDER]

func get_formation_positions(group_size: int, leader_position: Vector3) -> Array[Vector3]:
	## Calculate formation positions for group
	var positions: Array[Vector3] = []
	
	match formation_preference:
		"line":
			for i in range(group_size):
				positions.append(leader_position + Vector3(i * 2.0, 0.0, 0.0))
		"ranked_back":
			for i in range(group_size):
				positions.append(leader_position + Vector3(i * 2.0, 0.0, -i * 1.0))
		"wedge":
			var half_size = int(group_size / 2.0)
			for i in range(half_size):
				positions.append(leader_position + Vector3(i * 3.0, 0.0, i * 2.0))
			if group_size % 2 == 1:
				positions.append(leader_position + Vector3(half_size * 3.0, 0.0, half_size * 1.0))
		"shield_wall":
			var half_size = int(group_size / 2.0)
			for i in range(half_size):
				positions.append(leader_position + Vector3(-2.0, 0.0, i * 2.0))
			for i in range(half_size, group_size):
				positions.append(leader_position + Vector3(2.0, 0.0, i * 2.0))
		"loose_formation":
			for i in range(group_size):
				var offset = Vector3(
					randf() * 4.0 - 2.0,
					0.0,
					randf() * 4.0 - 2.0
				)
				positions.append(leader_position + offset)
		_:
			# Default to line formation
			for i in range(group_size):
				positions.append(leader_position + Vector3(i * 2.0, 0.0, 0.0))
	
	return positions
