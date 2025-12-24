## Dungeon Template System
## Provides reusable templates for populating dungeons 2-5
extends Node

# =============================================================================
# DUNGEON SCALING TEMPLATES
# =============================================================================

## Enemy scaling per dungeon level
const DUNGEON_SCALING = {
	1: {
		"difficulty": 1,
		"max_floors": 20,
		"max_enemies": 20,
		"min_enemies": 10,
		"initial_spawn": 5,
		"enemy_health_multiplier": 1.0,
		"enemy_damage_multiplier": 1.0,
		"gold_multiplier": 1.0,
		"experience_multiplier": 1.0
	},
	2: {
		"difficulty": 2,
		"max_floors": 40,
		"max_enemies": 20,
		"min_enemies": 10,
		"initial_spawn": 6,
		"enemy_health_multiplier": 1.3,
		"enemy_damage_multiplier": 1.2,
		"gold_multiplier": 1.5,
		"experience_multiplier": 1.4
	},
	3: {
		"difficulty": 3,
		"max_floors": 60,
		"max_enemies": 20,
		"min_enemies": 10,
		"initial_spawn": 7,
		"enemy_health_multiplier": 1.6,
		"enemy_damage_multiplier": 1.4,
		"gold_multiplier": 2.0,
		"experience_multiplier": 1.8
	},
	4: {
		"difficulty": 4,
		"max_floors": 80,
		"max_enemies": 20,
		"min_enemies": 10,
		"initial_spawn": 8,
		"enemy_health_multiplier": 2.0,
		"enemy_damage_multiplier": 1.7,
		"gold_multiplier": 2.5,
		"experience_multiplier": 2.2
	},
	5: {
		"difficulty": 5,
		"max_floors": 100,
		"max_enemies": 20,
		"min_enemies": 10,
		"initial_spawn": 9,
		"enemy_health_multiplier": 2.5,
		"enemy_damage_multiplier": 2.0,
		"gold_multiplier": 3.0,
		"experience_multiplier": 2.5
	}
}

## Enemy type availability per dungeon
const DUNGEON_ENEMY_POOLS = {
	1: {
		"goblin": 25,
		"goblin_scout": 15,
		"goblin_brute": 10,
		"goblin_shaman": 5,
		"skeleton": 20,
		"skeleton_archer": 10,
		"skeleton_berserker": 8,
		"skeleton_commander": 2,
		"troll": 3,
		"wraith": 2
	},
	2: {
		"goblin": 20,
		"goblin_scout": 12,
		"goblin_brute": 8,
		"goblin_shaman": 8,
		"skeleton": 18,
		"skeleton_archer": 12,
		"skeleton_berserker": 10,
		"skeleton_commander": 4,
		"troll": 5,
		"wraith": 3
	},
	3: {
		"goblin": 15,
		"goblin_scout": 10,
		"goblin_brute": 10,
		"goblin_shaman": 12,
		"skeleton": 15,
		"skeleton_archer": 15,
		"skeleton_berserker": 12,
		"skeleton_commander": 6,
		"troll": 3,
		"wraith": 2
	},
	4: {
		"goblin": 10,
		"goblin_scout": 8,
		"goblin_brute": 12,
		"goblin_shaman": 15,
		"skeleton": 12,
		"skeleton_archer": 18,
		"skeleton_berserker": 15,
		"skeleton_commander": 8,
		"troll": 1,
		"wraith": 1
	},
	5: {
		"goblin": 5,
		"goblin_scout": 5,
		"goblin_brute": 15,
		"goblin_shaman": 18,
		"skeleton": 8,
		"skeleton_archer": 20,
		"skeleton_berserker": 18,
		"skeleton_commander": 10,
		"troll": 0,
		"wraith": 1
	}
}

# =============================================================================
# ENCOUNTER TEMPLATES
# =============================================================================

## Pre-defined encounter templates
const ENCOUNTER_TEMPLATES = {
	"entrance_guard": {
		"name": "Entrance Guard",
		"description": "Small group guarding the dungeon entrance",
		"enemy_count": 3,
		"enemy_types": ["goblin", "skeleton"],
		"formation": "line",
		"loot_tier": "early"
	},
	"patrol_group": {
		"name": "Patrol Group",
		"description": "Mobile enemies patrolling corridors",
		"enemy_count": 2,
		"enemy_types": ["goblin_scout", "skeleton_archer"],
		"formation": "patrol",
		"loot_tier": "early"
	},
	"elite_ambush": {
		"name": "Elite Ambush",
		"description": "Powerful enemies lying in wait",
		"enemy_count": 2,
		"enemy_types": ["goblin_brute", "skeleton_berserker"],
		"formation": "ambush",
		"loot_tier": "mid"
	},
	"mage_encounter": {
		"name": "Mage Encounter",
		"description": "Magical enemies with special abilities",
		"enemy_count": 1,
		"enemy_types": ["goblin_shaman"],
		"formation": "isolated",
		"loot_tier": "mid"
	},
	"commander_group": {
		"name": "Commander Group",
		"description": "Elite commander with minions",
		"enemy_count": 3,
		"enemy_types": ["skeleton_commander", "skeleton", "skeleton_archer"],
		"formation": "command",
		"loot_tier": "high"
	}
}

## Room size templates
const ROOM_TEMPLATES = {
	"small_room": {
		"name": "Small Room",
		"spawn_points": 2,
		"possible_encounters": ["entrance_guard", "patrol_group"],
		"chest_count": 0
	},
	"medium_room": {
		"name": "Medium Room",
		"spawn_points": 4,
		"possible_encounters": ["elite_ambush", "mage_encounter"],
		"chest_count": 1
	},
	"large_room": {
		"name": "Large Room",
		"spawn_points": 6,
		"possible_encounters": ["commander_group", "elite_ambush"],
		"chest_count": 1
	},
	"corridor": {
		"name": "Corridor",
		"spawn_points": 1,
		"possible_encounters": ["patrol_group"],
		"chest_count": 0
	},
	"boss_room": {
		"name": "Boss Room",
		"spawn_points": 3,
		"possible_encounters": ["commander_group"],
		"chest_count": 1
	}
}

# =============================================================================
# LOOT TABLE TEMPLATES
# =============================================================================

## Loot scaling per dungeon level
const LOOT_SCALING = {
	1: {
		"gold_range": [25, 300],
		"potion_count": [1, 4],
		"rare_drop_chance": 0.05,
		"epic_drop_chance": 0.01
	},
	2: {
		"gold_range": [40, 450],
		"potion_count": [2, 5],
		"rare_drop_chance": 0.08,
		"epic_drop_chance": 0.02
	},
	3: {
		"gold_range": [60, 600],
		"potion_count": [2, 6],
		"rare_drop_chance": 0.12,
		"epic_drop_chance": 0.04
	},
	4: {
		"gold_range": [80, 800],
		"potion_count": [3, 7],
		"rare_drop_chance": 0.15,
		"epic_drop_chance": 0.06
	},
	5: {
		"gold_range": [100, 1000],
		"potion_count": [3, 8],
		"rare_drop_chance": 0.20,
		"epic_drop_chance": 0.08
	}
}

## Material drops per dungeon
const MATERIAL_DROPS = {
	1: ["bone_fragments"],
	2: ["bone_fragments", "ectoplasm"],
	3: ["bone_fragments", "ectoplasm", "rune_stone"],
	4: ["bone_fragments", "ectoplasm", "rune_stone", "crystal_shard"],
	5: ["bone_fragments", "ectoplasm", "rune_stone", "crystal_shard", "ancient_rune"]
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

## Get scaling data for a dungeon level
func get_dungeon_scaling(dungeon_level: int) -> Dictionary:
	return DUNGEON_SCALING.get(dungeon_level, DUNGEON_SCALING[1])

## Get enemy pool for a dungeon level
func get_enemy_pool(dungeon_level: int) -> Dictionary:
	return DUNGEON_ENEMY_POOLS.get(dungeon_level, DUNGEON_ENEMY_POOLS[1])

## Get loot scaling for a dungeon level
func get_loot_scaling(dungeon_level: int) -> Dictionary:
	return LOOT_SCALING.get(dungeon_level, LOOT_SCALING[1])

## Get material drops for a dungeon level
func get_material_drops(dungeon_level: int) -> Array:
	return MATERIAL_DROPS.get(dungeon_level, MATERIAL_DROPS[1])

## Select random encounter template
func get_random_encounter(room_type: String = "medium_room") -> Dictionary:
	var room_template = ROOM_TEMPLATES.get(room_type, ROOM_TEMPLATES["medium_room"])
	var encounters = room_template.possible_encounters
	var encounter_name = encounters[randi() % encounters.size()]
	return ENCOUNTER_TEMPLATES[encounter_name]

## Generate loot table for dungeon level and tier
func generate_loot_table(dungeon_level: int, tier: String) -> Array:
	var loot_table = []
	var scaling = get_loot_scaling(dungeon_level)

	match tier:
		"early":
			loot_table = [
				{"item": "gold", "weight": 40, "min": scaling.gold_range[0], "max": scaling.gold_range[0] * 3},
				{"item": "health_potion", "weight": 25, "min": 1, "max": 2},
				{"item": "mana_potion", "weight": 25, "min": 1, "max": 2},
				{"item": "bone_fragments", "weight": 10, "min": 1, "max": 3}
			]
		"mid":
			loot_table = [
				{"item": "gold", "weight": 35, "min": scaling.gold_range[0] * 2, "max": scaling.gold_range[1] * 0.6},
				{"item": "health_potion", "weight": 20, "min": 1, "max": 3},
				{"item": "mana_potion", "weight": 20, "min": 1, "max": 3},
				{"item": "bone_fragments", "weight": 15, "min": 2, "max": 5},
				{"item": "rusty_dagger", "weight": 10, "min": 1, "max": 1}
			]
		"high":
			var materials = get_material_drops(dungeon_level)
			loot_table = [
				{"item": "gold", "weight": 30, "min": scaling.gold_range[1] * 0.5, "max": scaling.gold_range[1]},
				{"item": "health_potion", "weight": 20, "min": 2, "max": scaling.potion_count[1]},
				{"item": "mana_potion", "weight": 20, "min": 2, "max": scaling.potion_count[1]},
				{"item": "troll_hide_armor", "weight": 10, "min": 1, "max": 1},
				{"item": "shadow_essence", "weight": 8, "min": 1, "max": 1},
				{"item": "ancient_scroll", "weight": 6, "min": 1, "max": 1},
				{"item": "journeyman_hat", "weight": 4, "min": 1, "max": 1}
			]

			# Add random material drops
			for material in materials:
				loot_table.append({
					"item": material,
					"weight": 2,
					"min": 1,
					"max": 2
				})

	return loot_table