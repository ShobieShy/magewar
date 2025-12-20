## FilthSlime - Basic tutorial enemy
## Slow melee attacker, weak but numerous
extends EnemyBase

func _ready() -> void:
	# Override base stats for Filth Slime
	enemy_name = "Filth Slime"
	enemy_type = Enums.EnemyType.BASIC
	level = 1
	
	max_health = 30.0
	damage = 5.0
	defense = 0.0
	move_speed = 2.0
	attack_range = 1.5
	attack_cooldown = 2.0
	detection_range = 12.0
	lose_target_range = 20.0
	
	experience_value = 5
	
	# Call parent ready
	super._ready()
	
	# Set visual color (green slime)
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.5, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.3, 0.1)
		mat.emission_energy_multiplier = 0.3
		mesh.set_surface_override_material(0, mat)


func _perform_attack() -> void:
	if current_target == null:
		return
	
	# Simple melee attack
	if current_target.has_node("StatsComponent"):
		var target_stats: StatsComponent = current_target.get_node("StatsComponent")
		target_stats.take_damage(damage, Enums.DamageType.PHYSICAL)
		
		# Small knockback
		if current_target is CharacterBody3D:
			var knockback_dir = (current_target.global_position - global_position).normalized()
			knockback_dir.y = 0.2
			current_target.velocity += knockback_dir * 3.0
