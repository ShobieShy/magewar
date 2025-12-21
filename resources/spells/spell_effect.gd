## SpellEffect - Base class for all spell effects
## Effects are modular components that define what a spell does
class_name SpellEffect
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var effect_type: Enums.SpellEffectType = Enums.SpellEffectType.DAMAGE
@export var effect_name: String = ""
@export var description: String = ""

## Target filter
@export var target_type: Enums.TargetType = Enums.TargetType.ENEMY

## Timing
@export var delay: float = 0.0  ## Delay before effect triggers
@export var duration: float = 0.0  ## Duration for over-time effects

## Visual/Audio
@export var impact_effect: PackedScene  ## Visual effect on impact
@export var impact_sound: AudioStream

# =============================================================================
# VIRTUAL METHODS
# =============================================================================

func apply(_caster: Node, _target: Node, _hit_point: Vector3, _spell_data: SpellData) -> void:
	## Override in subclasses to implement effect logic
	pass


func can_affect_target(caster: Node, target: Node) -> bool:
	## Check if this effect can affect the target based on target_type
	if target == null:
		return target_type == Enums.TargetType.GROUND
	
	var is_player = target is Player
	var is_enemy = target.is_in_group("enemies")
	var is_self = target == caster
	
	match target_type:
		Enums.TargetType.ENEMY:
			if is_player:
				# Check friendly fire - access via SaveManager settings
				var friendly_fire = SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false)
				return friendly_fire
			return is_enemy
		Enums.TargetType.ALLY:
			return is_player and not is_self
		Enums.TargetType.SELF:
			return is_self
		Enums.TargetType.ALL:
			return true
		Enums.TargetType.GROUND:
			return true
	
	return false


func spawn_impact_effect(position: Vector3, normal: Vector3 = Vector3.UP) -> void:
	if impact_effect:
		var effect = impact_effect.instantiate()
		if effect is Node3D:
			effect.global_position = position
			effect.look_at(position + normal)
		var scene_tree = Engine.get_main_loop() as SceneTree
		if scene_tree:
			scene_tree.current_scene.add_child(effect)
