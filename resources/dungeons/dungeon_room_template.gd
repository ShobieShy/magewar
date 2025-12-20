## DungeonRoomTemplate - Template for modular dungeon room creation
class_name DungeonRoomTemplate
extends Resource

# =============================================================================
# PROPERTIES
# =============================================================================

## Room types
enum RoomType {
	ENTRANCE,        ## Starting room
	COMBAT,          ## Enemy encounter room
	PUZZLE,          ## Puzzle room
	TREASURE,        ## Treasure room
	BOSS_PREP,       ## Before boss fight
	BOSS,            ## Boss fight room
	EXIT,           ## Exit room
	CORRIDOR,       ## Connecting corridor
	INTERSECTION,     ## Multiple path junction
}

## Room shapes and layouts
enum RoomShape {
	SQUARE,          ## Square room
	RECTANGLE,        ## Rectangular room
	L_SHAPE,         ## L-shaped room
	T_SHAPE,         ## T-shaped room
	CROSS,           ## Cross-shaped room
	CIRCLE,           ## Circular room
	IRREGULAR,        ## Random polygon shape
}

## Room sizes
enum RoomSize {
	TINY,            ## 3x3 to 5x5
	SMALL,           ## 5x5 to 8x8
	MEDIUM,          ## 8x8 to 12x12
	LARGE,           ## 12x12 to 16x16
	HUGE,            ## 16x16 to 20x20
}

## Environment themes
enum EnvironmentTheme {
	CAVE,            ## Underground cave
	DUNGEON,         ## Stone dungeon
	RUINS,           ## Ancient ruins
	UNDERGROUND,      ## Deep underground
	FORTRESS,         ## Fortified structure
	NATURAL_CAVE,    ## Natural cave formation
	ABANDONED_MINE,  ## Old mine shaft
}

## Difficulty modifiers
enum DifficultyLevel {
	EASY,            ## Few enemies, simple layout
	NORMAL,          ## Standard difficulty
	HARD,            ## More enemies, complex layout
	EXTREME,         ## Maximum difficulty
}

## Enemy and loot configuration
@export var room_type: RoomType = RoomType.COMBAT
@export var room_shape: RoomShape = RoomShape.SQUARE
@export var room_size: RoomSize = RoomSize.SMALL
@export var environment_theme: EnvironmentTheme = EnvironmentTheme.CAVE
@export var difficulty_level: DifficultyLevel = DifficultyLevel.NORMAL

## Room dimensions
@export var width: int = 8
@export var height: int = 8
@export var corridor_width: int = 3
@export var door_positions: Array[Vector2] = []

## Enemy spawn configuration
@export var enemy_types: Array[String] = ["goblin_basic"]  ## Enemy templates to use
@export var enemy_count_min: int = 2
@export var enemy_count_max: int = 4
@export var enemy_spawn_points: Array[Vector3] = []
@export var enemy_spawn_rules: String = "random"  ## "random", "patrol", "ambush"

## Treasure and loot configuration
@export var has_treasure: bool = true
@export var chest_count: int = 1
@export var gold_piles_min: int = 1
@export var gold_piles_max: int = 3
@export var item_containers: Array[String] = ["weapon_chest", "armor_chest"]

## Puzzle configuration
@export var puzzle_type: String = ""  ## Puzzle type identifier
@export var puzzle_solution: String = ""  ## Solution method
@export var puzzle_rewards: Array[String] = []

## Visual and atmosphere
@export var lighting_type: String = "ambient"  ## "ambient", "flickering", "dark"
@export var fog_density: float = 0.0  ## 0.0 to 1.0
@export var decoration_objects: Array[String] = []  ## Props and decorations
@export var ambient_sounds: Array[String] = []  ## Background sounds
@export var special_effects: Array[String] = []  ## Particles, etc.

## Connectivity
@export var required_keys: Array[String] = []  ## Keys needed to open/enter
@export var one_way_doors: Array[Vector2] = []  ## Doors that only work one way
@export var secret_passage: Vector2 = Vector2.ZERO  ## Hidden exit coordinates

# =============================================================================
# METHODS
# =============================================================================

func _init() -> void:
	# Set default dimensions based on room size
	_apply_size_modifiers()

func _apply_size_modifiers() -> void:
	## Adjust dimensions based on room size
	match room_size:
		RoomSize.TINY:
			width = 5
			height = 5
		RoomSize.SMALL:
			width = 8
			height = 8
		RoomSize.MEDIUM:
			width = 12
			height = 12
		RoomSize.LARGE:
			width = 16
			height = 16
		RoomSize.HUGE:
			width = 20
			height = 20

func get_room_dimensions() -> Vector2:
	## Get room width and height
	return Vector2(width, height)

func get_room_area() -> float:
	## Calculate total room area
	return width * height

func get_center_position() -> Vector2:
	## Get center of room
	return Vector2(width / 2.0, height / 2.0)

func generate_enemy_positions() -> Array[Vector3]:
	## Generate enemy spawn positions within room
	var positions: Array[Vector3] = []
	var room_center = get_center_position()
	
	# Use predefined spawn points if available
	if enemy_spawn_points.size() > 0:
		for i in range(min(enemy_count_max, enemy_spawn_points.size())):
			positions.append(Vector3(enemy_spawn_points[i].x, 0.0, enemy_spawn_points[i].y))
		return positions
	
	# Generate positions based on spawn rules
	var enemy_count = randi_range(enemy_count_min, enemy_count_max)
	
	match enemy_spawn_rules:
		"random":
			for i in range(enemy_count):
				var random_pos = _get_random_room_position()
				positions.append(Vector3(random_pos.x, 0.0, random_pos.y))
		
		"patrol":
			var patrol_positions = _generate_patrol_positions(enemy_count)
			for pos in patrol_positions:
				positions.append(Vector3(pos.x, 0.0, pos.y))
		
		"ambush":
			var ambush_positions = _generate_ambush_positions(enemy_count)
			for pos in ambush_positions:
				positions.append(Vector3(pos.x, 0.0, pos.y))
	
	return positions

func _get_random_room_position() -> Vector2:
	## Get random position within room boundaries
	var margin = 1.0  ## Keep away from walls
	var x_range = width - (margin * 2.0)
	var y_range = height - (margin * 2.0)
	
	return Vector2(
		margin + randf() * x_range,
		margin + randf() * y_range
	)

func _generate_patrol_positions(count: int) -> Array[Vector2]:
	## Generate patrol positions around room perimeter
	var positions: Array[Vector2] = []
	var perimeter_distance = min(width, height) * 0.3
	
	for i in range(count):
		var angle = (PI * 2.0 * i) / count
		var center = get_center_position()
		var pos = center + Vector2(
			cos(angle) * perimeter_distance,
			sin(angle) * perimeter_distance
		)
		positions.append(pos)
	
	return positions

func _generate_ambush_positions(count: int) -> Array[Vector2]:
	## Generate ambush positions near room center
	var positions: Array[Vector2] = []
	var center = get_center_position()
	var ambush_radius = min(width, height) * 0.2
	
	for i in range(count):
		var angle = randf() * PI * 2.0
		var pos = center + Vector2(
			cos(angle) * ambush_radius,
			sin(angle) * ambush_radius
		)
		positions.append(pos)
	
	return positions

func get_enemy_spawning_data() -> Dictionary:
	## Get complete enemy spawning configuration
	return {
		"enemy_types": enemy_types.duplicate(),
		"count_min": enemy_count_min,
		"count_max": enemy_count_max,
		"spawn_rules": enemy_spawn_rules,
		"spawn_points": enemy_spawn_points.duplicate()
	}

func get_loot_configuration() -> Dictionary:
	## Get treasure and loot configuration
	return {
		"has_treasure": has_treasure,
		"chest_count": chest_count,
		"gold_piles": {
			"min": gold_piles_min,
			"max": gold_piles_max
		},
		"item_containers": item_containers.duplicate()
	}

func get_puzzle_configuration() -> Dictionary:
	## Get puzzle configuration
	return {
		"type": puzzle_type,
		"solution": puzzle_solution,
		"rewards": puzzle_rewards.duplicate()
	}

func get_atmosphere_settings() -> Dictionary:
	## Get visual and audio atmosphere settings
	return {
		"lighting": lighting_type,
		"fog_density": fog_density,
		"decorations": decoration_objects.duplicate(),
		"ambient_sounds": ambient_sounds.duplicate(),
		"special_effects": special_effects.duplicate()
	}

func get_connectivity_data() -> Dictionary:
	## Get room connectivity configuration
	return {
		"required_keys": required_keys.duplicate(),
		"one_way_doors": one_way_doors.duplicate(),
		"secret_passage": secret_passage
	}

func is_combat_room() -> bool:
	## Check if this is a combat encounter room
	return room_type in [RoomType.COMBAT, RoomType.BOSS_PREP, RoomType.BOSS]

func is_treasure_room() -> bool:
	## Check if this is a treasure room
	return room_type == RoomType.TREASURE or has_treasure

func is_puzzle_room() -> bool:
	## Check if this is a puzzle room
	return room_type == RoomType.PUZZLE or not puzzle_type.is_empty()

func get_difficulty_modifier() -> float:
	## Get difficulty modifier for balancing
	match difficulty_level:
		DifficultyLevel.EASY:
			return 0.8
		DifficultyLevel.NORMAL:
			return 1.0
		DifficultyLevel.HARD:
			return 1.3
		DifficultyLevel.EXTREME:
			return 1.6
		_:
			return 1.0