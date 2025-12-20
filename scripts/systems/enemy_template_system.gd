## EnemyTemplateSystem - Template-based enemy creation system
## Enables rapid enemy creation with consistent behavior and balance
class_name EnemyTemplateSystem
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal enemy_created(enemy_data: Resource, enemy_node: Node)
signal template_registered(template_name: String, template_data: Resource)

# =============================================================================
# PROPERTIES
# =============================================================================

## Registered enemy templates
var _templates: Dictionary = {}  ## template_name -> EnemyTemplate

## Enemy type registry for quick access
var _enemy_types: Dictionary = {}  ## Enums.EnemyType -> Array[EnemyTemplate]

## Generated instances
var _active_instances: Array = []  ## Currently spawned enemies

## Enemy difficulty scaling factors
var difficulty_multipliers: Dictionary = {
	"easy": {"health": 0.7, "damage": 0.8, "speed": 0.9},
	"normal": {"health": 1.0, "damage": 1.0, "speed": 1.0},
	"hard": {"health": 1.3, "damage": 1.2, "speed": 1.1},
	"extreme": {"health": 1.5, "damage": 1.4, "speed": 1.2}
}

var current_difficulty: String = "normal"

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Auto-register all template resources
	_auto_register_templates()

# =============================================================================
# TEMPLATE MANAGEMENT
# =============================================================================

func register_template(template_name: String, template_data: Resource) -> void:
	## Register an enemy template for use
	_templates[template_name] = template_data
	
	# Update enemy type registry
	if template_data.has_method("get_enemy_type"):
		var enemy_type = template_data.get_enemy_type()
		if not _enemy_types.has(enemy_type):
			_enemy_types[enemy_type] = []
		_enemy_types[enemy_type].append(template_data)
	
	template_registered.emit(template_name, template_data)
	print("Registered enemy template: %s" % template_name)

func get_template(template_name: String) -> Resource:
	## Get a registered template
	return _templates.get(template_name)

func get_templates_by_type(enemy_type: Enums.EnemyType) -> Array:
	## Get all templates for a specific enemy type
	return _enemy_types.get(enemy_type, [])

func get_all_templates() -> Dictionary:
	## Get all registered templates
	return _templates.duplicate()

# =============================================================================
# ENEMY CREATION
# =============================================================================

func create_enemy(template_name: String, level: int = 1, difficulty: String = "") -> Node:
	## Create an enemy instance from template
	var template_data = _templates.get(template_name)
	if not template_data:
		push_error("Template not found: %s" % template_name)
		return null
	
	# Clone template for instance-specific configuration
	var enemy_config = template_data.duplicate()
	enemy_config.level = level
	
	# Apply difficulty scaling if specified
	if not difficulty.is_empty():
		_apply_difficulty_scaling(enemy_config, difficulty)
	else:
		_apply_difficulty_scaling(enemy_config, current_difficulty)
	
	# Create enemy scene
	var enemy_scene = _get_enemy_scene(enemy_config)
	if not enemy_scene:
		push_error("Enemy scene not found for template: %s" % template_name)
		return null
	
	var enemy_instance = enemy_scene.instantiate()
	
	# Configure enemy with template data
	_configure_enemy_instance(enemy_instance, enemy_config)
	
	# Track the instance
	_active_instances.append(enemy_instance)
	
	enemy_created.emit(enemy_config, enemy_instance)
	
	return enemy_instance

func create_enemy_group(template_name: String, count: int, level: int = 1, spread_area: Vector3 = Vector3.ZERO, spread_radius: float = 5.0) -> Array:
	## Create a group of enemies with random positions
	var enemies: Array = []
	
	for i in range(count):
		var offset = Vector3(
			randf() * spread_area.x - spread_area.x / 2.0,
			0.0,
			randf() * spread_area.z - spread_area.z / 2.0
		)
		
		var enemy = create_enemy(template_name, level)
		if enemy:
			enemy.global_position = spread_area + offset
			enemies.append(enemy)
	
	return enemies

func create_boss(template_name: String, boss_level: int = 3) -> Node:
	## Create a boss-level enemy from template
	var template_data = _templates.get(template_name)
	if not template_data:
		return null
	
	# Enhance for boss encounter
	var boss_config = template_data.duplicate()
	boss_config.level = boss_level
	boss_config.health *= 2.5  ## Boss health multiplier
	boss_config.damage *= 1.8
	boss_config.drop_chance = 1.0  ## Always drop
	
	# Add boss-specific abilities
	if boss_config.has_method("add_boss_abilities"):
		boss_config.add_boss_abilities()
	
	return create_enemy(template_name + "_boss", boss_level, "hard")

# =============================================================================
# TEMPLATE CUSTOMIZATION
# =============================================================================

func customize_template(template_name: String, modifications: Dictionary) -> Resource:
	## Create a modified template with custom properties
	var base_template = _templates.get(template_name)
	if not base_template:
		return null
	
	var custom_template = base_template.duplicate()
	
	# Apply modifications
	for key in modifications:
		if custom_template.set(key, modifications[key]):
			print("Applied modification to %s: %s = %s" % [template_name, key, modifications[key]])
		else:
			push_warning("Cannot modify property: %s" % key)
	
	return custom_template

# =============================================================================
# DIFFICULTY SCALING
# =============================================================================

func set_difficulty(difficulty: String) -> void:
	## Set global difficulty for new enemies
	if difficulty_multipliers.has(difficulty):
		current_difficulty = difficulty
		print("Enemy difficulty set to: %s" % difficulty)
	else:
		push_warning("Invalid difficulty: %s" % difficulty)

func get_difficulty_multipliers(difficulty: String) -> Dictionary:
	## Get scaling factors for difficulty
	return difficulty_multipliers.get(difficulty, difficulty_multipliers["normal"])

func _apply_difficulty_scaling(enemy_config: Resource, difficulty: String) -> void:
	## Apply difficulty scaling to enemy configuration
	var multipliers = get_difficulty_multipliers(difficulty)
	
	# Scale core stats
	if enemy_config.has_method("set") and enemy_config.get("health"):
		enemy_config.set("health", enemy_config.get("health") * multipliers.health)
		enemy_config.set("damage", enemy_config.get("damage") * multipliers.damage)
		enemy_config.set("speed", enemy_config.get("speed") * multipliers.speed)
	
	# Scale loot
	if enemy_config.has_method("get_loot_table"):
		var loot_table = enemy_config.get_loot_table()
		enemy_config.set("gold_drop_min", int((enemy_config.get("gold_drop_min") or 10) * multipliers.health))
		enemy_config.set("gold_drop_max", int((enemy_config.get("gold_drop_max") or 25) * multipliers.health))

# =============================================================================
# INSTANCE CONFIGURATION
# =============================================================================

func _configure_enemy_instance(enemy: Node, config: Resource) -> void:
	## Configure enemy instance with template data
	if enemy.has_method("initialize_from_template"):
		enemy.initialize_from_template(config)
	
	# Set up collision layers
	if enemy.has_method("set_collision_layer"):
		enemy.set_collision_layer_value(Constants.LAYER_ENEMIES)
		enemy.set_collision_mask_value(Constants.LAYER_PLAYERS | Constants.LAYER_ENVIRONMENT)

# =============================================================================
# SCENE MANAGEMENT
# =============================================================================

func _get_enemy_scene(template_data: Resource) -> PackedScene:
	## Get the appropriate enemy scene based on template type
	if template_data.get_script() == GoblinEnemyData:
		return preload("res://scenes/enemies/goblin.tscn")
	elif template_data.get_script() == TrollEnemyData:
		return preload("res://scenes/enemies/troll.tscn")
	elif template_data.get_script() == WraithEnemyData:
		return preload("res://scenes/enemies/wraith.tscn")
	elif template_data.get_script() == SkeletonEnemyData:
		return preload("res://scenes/enemies/skeleton.tscn")
	elif template_data.get_script() == SlimeEnemyData:
		return preload("res://scenes/enemies/filth_slime.tscn")
	else:
		# Default enemy scene
		return preload("res://scenes/enemies/enemy_base.tscn")

# =============================================================================
# AUTO-REGISTRATION
# =============================================================================

func _auto_register_templates() -> void:
	## Automatically register all template resources in enemy templates folder
	var templates_dir = "res://resources/enemies/templates/"
	var dir = DirAccess.open(templates_dir)
	
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var template_path = templates_dir + file_name
			var template_data = load(template_path)
			if template_data:
				register_template(file_name.get_basename(), template_data)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

# =============================================================================
# CLEANUP
# =============================================================================

func cleanup_enemy_instance(enemy: Node) -> void:
	## Clean up enemy when destroyed
	_active_instances.erase(enemy)
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)

func get_active_enemy_count() -> int:
	## Get current number of active enemies
	return _active_instances.size()

func clear_all_enemies() -> void:
	## Remove all enemy instances
	for enemy in _active_instances.duplicate():
		cleanup_enemy_instance(enemy)
	_active_instances.clear()