## SummonEffect - Spawns entities (minions, turrets, objects)
class_name SummonEffect
extends SpellEffect

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Summon")
@export var summon_scene: PackedScene
@export var summon_count: int = 1
@export var summon_duration: float = 30.0  ## 0 = permanent
@export var summon_at_cursor: bool = true

@export_group("Positioning")
@export var spawn_offset: Vector3 = Vector3.ZERO
@export var spawn_radius: float = 0.0  ## Random spread radius
@export var spawn_height_offset: float = 0.5

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	effect_type = Enums.SpellEffectType.SUMMON
	effect_name = "Summon"
	target_type = Enums.TargetType.GROUND

# =============================================================================
# EFFECT APPLICATION
# =============================================================================

func apply(caster: Node, _target: Node, hit_point: Vector3, _spell_data: SpellData) -> void:
	if summon_scene == null:
		push_error("SummonEffect: No summon_scene assigned")
		return
	
	var spawn_position: Vector3
	if summon_at_cursor and hit_point != Vector3.ZERO:
		spawn_position = hit_point
	elif caster is Node3D:
		spawn_position = caster.global_position + spawn_offset
	else:
		spawn_position = Vector3.ZERO
	
	spawn_position.y += spawn_height_offset
	
	for i in range(summon_count):
		var summon = summon_scene.instantiate()
		
		# Calculate position with spread
		var pos = spawn_position
		if spawn_radius > 0.0:
			var angle = randf() * TAU
			var dist = randf() * spawn_radius
			pos.x += cos(angle) * dist
			pos.z += sin(angle) * dist
		
		if summon is Node3D:
			summon.global_position = pos
		
		# Set owner/caster reference if the summon supports it
		if summon.has_method("set_owner_caster"):
			summon.set_owner_caster(caster)
		
		# Add to scene
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			scene_tree.current_scene.add_child(summon)
		
		# Set up auto-despawn if duration > 0
		if summon_duration > 0.0:
			_schedule_despawn(summon, summon_duration)
	
	spawn_impact_effect(spawn_position)


func _schedule_despawn(summon: Node, despawn_duration: float) -> void:
	if summon.has_method("despawn"):
		var timer = summon.get_tree().create_timer(despawn_duration)
		timer.timeout.connect(func(): 
			if is_instance_valid(summon):
				summon.despawn()
		)
	else:
		var timer = summon.get_tree().create_timer(duration)
		timer.timeout.connect(func(): 
			if is_instance_valid(summon):
				summon.queue_free()
		)
