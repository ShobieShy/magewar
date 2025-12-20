## TheFilth - Tutorial boss
## Single phase: Melee swipes + Ground slam AoE
extends EnemyBase

# =============================================================================
# SIGNALS
# =============================================================================

signal boss_defeated()

# =============================================================================
# PROPERTIES
# =============================================================================

var slam_cooldown: float = 5.0
var _slam_timer: float = 0.0
var slam_radius: float = 6.0
var slam_damage: float = 30.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Override base stats for The Filth
	enemy_name = "The Filth"
	enemy_type = Enums.EnemyType.BOSS
	level = 3
	
	max_health = 300.0
	damage = 20.0
	defense = 5.0
	move_speed = 3.0
	attack_range = 3.0
	attack_cooldown = 1.5
	detection_range = 20.0
	lose_target_range = 30.0
	
	experience_value = 50
	
	super._ready()
	
	# Boss visual (large, dark purple/black)
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.1, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.1, 0.4)
		mat.emission_energy_multiplier = 0.5
		mesh.set_surface_override_material(0, mat)

# =============================================================================
# PROCESS
# =============================================================================

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Track slam cooldown
	if _slam_timer > 0:
		_slam_timer -= delta

# =============================================================================
# COMBAT
# =============================================================================

func _perform_attack() -> void:
	if current_target == null:
		return
	
	# Check if should do ground slam
	if _slam_timer <= 0:
		_ground_slam()
		_slam_timer = slam_cooldown
	else:
		_melee_swipe()


func _melee_swipe() -> void:
	## Standard melee attack
	if current_target.has_node("StatsComponent"):
		var target_stats: StatsComponent = current_target.get_node("StatsComponent")
		target_stats.take_damage(damage, Enums.DamageType.PHYSICAL)
		
		# Moderate knockback
		if current_target is CharacterBody3D:
			var knockback_dir = (current_target.global_position - global_position).normalized()
			knockback_dir.y = 0.2
			current_target.velocity += knockback_dir * 5.0


func _ground_slam() -> void:
	## AoE ground slam attack
	print("The Filth performs Ground Slam!")
	
	# Find all players in radius
	var space_state = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = slam_radius
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = Constants.LAYER_PLAYERS
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var target = result.collider
		if target.has_node("StatsComponent"):
			var target_stats: StatsComponent = target.get_node("StatsComponent")
			
			# Damage falls off with distance
			var dist = global_position.distance_to(target.global_position)
			var falloff = 1.0 - (dist / slam_radius) * 0.5
			var actual_damage = slam_damage * falloff
			
			target_stats.take_damage(actual_damage, Enums.DamageType.MAGICAL)
			
			# Strong upward knockback
			if target is CharacterBody3D:
				var knockback_dir = (target.global_position - global_position).normalized()
				knockback_dir.y = 1.0
				knockback_dir = knockback_dir.normalized()
				target.velocity += knockback_dir * 12.0
	
	# Visual feedback (shake, particles would go here)
	_slam_visual_effect()


func _slam_visual_effect() -> void:
	# Simple scale pulse for now
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.2)

# =============================================================================
# DEATH
# =============================================================================

func _on_died() -> void:
	boss_defeated.emit()
	super._on_died()
