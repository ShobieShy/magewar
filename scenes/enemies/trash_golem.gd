## TrashGolem - Elite tutorial enemy
## Ranged attacker that throws debris
extends EnemyBase

# =============================================================================
# PROPERTIES
# =============================================================================

var projectile_scene: PackedScene = preload("res://scenes/spells/projectile.tscn")
var ranged_attack_range: float = 10.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Override base stats for Trash Golem
	enemy_name = "Trash Golem"
	enemy_type = Enums.EnemyType.ELITE
	level = 2
	
	max_health = 80.0
	damage = 15.0
	defense = 5.0
	move_speed = 2.5
	attack_range = 10.0  # Ranged attack
	attack_cooldown = 2.5
	detection_range = 15.0
	lose_target_range = 25.0
	
	experience_value = 15
	
	super._ready()
	
	# Set visual (larger, brown/gray)
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.35, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.2, 0.1)
		mat.emission_energy_multiplier = 0.2
		mesh.set_surface_override_material(0, mat)

# =============================================================================
# COMBAT
# =============================================================================

func _perform_attack() -> void:
	if current_target == null:
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	
	if distance <= 2.5:
		# Melee attack if too close
		_melee_attack()
	else:
		# Ranged debris throw
		_ranged_attack()


func _melee_attack() -> void:
	if current_target.has_node("StatsComponent"):
		var target_stats: StatsComponent = current_target.get_node("StatsComponent")
		target_stats.take_damage(damage * 1.5, Enums.DamageType.PHYSICAL)
		
		# Strong knockback
		if current_target is CharacterBody3D:
			var knockback_dir = (current_target.global_position - global_position).normalized()
			knockback_dir.y = 0.3
			current_target.velocity += knockback_dir * 8.0


func _ranged_attack() -> void:
	# Spawn debris projectile
	var projectile = projectile_scene.instantiate()
	
	var spawn_pos = global_position + Vector3.UP * 1.5
	projectile.global_position = spawn_pos
	
	var direction = (current_target.global_position + Vector3.UP - spawn_pos).normalized()
	
	# Configure projectile
	if projectile.has_method("initialize"):
		projectile.initialize({
			"caster": self,
			"spell": null,
			"direction": direction,
			"speed": 15.0,
			"gravity": 2.0,
			"homing": 0.0,
			"pierce": 0,
			"bounce": 0,
			"lifetime": 5.0,
			"effects": []
		})
	
	# Custom damage on hit
	projectile.body_entered.connect(_on_debris_hit)
	
	get_tree().current_scene.add_child(projectile)
	
	# Make projectile look like debris (brown)
	var mesh = projectile.get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.2)
		mesh.set_surface_override_material(0, mat)


func _on_debris_hit(body: Node) -> void:
	if body == self:
		return
	
	if body.has_node("StatsComponent"):
		var stats: StatsComponent = body.get_node("StatsComponent")
		stats.take_damage(damage, Enums.DamageType.PHYSICAL)
