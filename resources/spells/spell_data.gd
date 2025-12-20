## SpellData - Complete spell definition resource
## Combines delivery method with effects for data-driven spells
class_name SpellData
extends Resource

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Basic Info")
@export var spell_name: String = "Unnamed Spell"
@export var description: String = ""
@export var icon: Texture2D
@export var element: Enums.Element = Enums.Element.ARCANE

@export_group("Casting")
@export var magika_cost: float = 10.0
@export var cooldown: float = 1.0
@export var cast_time: float = 0.0  ## 0 = instant cast
@export var can_move_while_casting: bool = true
@export var can_be_interrupted: bool = true

@export_group("Delivery")
@export var delivery_type: Enums.SpellDelivery = Enums.SpellDelivery.PROJECTILE
@export var range: float = 50.0
@export var target_type: Enums.TargetType = Enums.TargetType.ENEMY

@export_subgroup("Projectile Settings")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = Constants.DEFAULT_PROJECTILE_SPEED
@export var projectile_count: int = 1
@export var projectile_spread: float = 0.0  ## Degrees
@export var projectile_gravity: float = 0.0
@export var projectile_homing: float = 0.0  ## Homing strength (0 = none)
@export var projectile_pierce: int = 0  ## Number of targets to pierce (0 = none)
@export var projectile_bounce: int = 0  ## Number of bounces
@export var projectile_lifetime: float = 5.0

@export_subgroup("AoE Settings")
@export var aoe_radius: float = 5.0
@export var aoe_falloff: bool = true  ## Damage reduces at edge
@export var aoe_delay: float = 0.0  ## Delay before AoE triggers
@export var aoe_persist_duration: float = 0.0  ## 0 = instant, >0 = persists

@export_subgroup("Beam Settings")
@export var beam_width: float = 0.5
@export var beam_tick_rate: float = 0.1  ## Damage tick interval
@export var beam_max_duration: float = 3.0

@export_subgroup("Chain Settings")
@export var chain_count: int = 3  ## Number of chains
@export var chain_range: float = 10.0  ## Max distance between chains
@export var chain_damage_falloff: float = 0.8  ## Damage multiplier per chain

@export_group("Effects")
@export var effects: Array[SpellEffect] = []

@export_group("Visual/Audio")
@export var cast_effect: PackedScene
@export var cast_sound: AudioStream
@export var travel_effect: PackedScene  ## For projectiles/beams
@export var impact_effect: PackedScene
@export var impact_sound: AudioStream

@export_group("Modifiers (Applied by Gems)")
## These are base values that gems can modify
@export var damage_multiplier: float = 1.0
@export var cost_multiplier: float = 1.0
@export var cooldown_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var aoe_multiplier: float = 1.0

# =============================================================================
# COMPUTED PROPERTIES
# =============================================================================

func get_final_magika_cost() -> float:
	return magika_cost * cost_multiplier


func get_final_cooldown() -> float:
	return cooldown * cooldown_multiplier


func get_final_range() -> float:
	return range * range_multiplier


func get_final_aoe_radius() -> float:
	return aoe_radius * aoe_multiplier

# =============================================================================
# METHODS
# =============================================================================

func create_modified_copy() -> SpellData:
	## Creates a copy of this spell with current modifiers baked in
	var copy = duplicate(true)
	copy.magika_cost = get_final_magika_cost()
	copy.cooldown = get_final_cooldown()
	copy.range = get_final_range()
	copy.aoe_radius = get_final_aoe_radius()
	
	# Reset multipliers on copy
	copy.damage_multiplier = 1.0
	copy.cost_multiplier = 1.0
	copy.cooldown_multiplier = 1.0
	copy.range_multiplier = 1.0
	copy.aoe_multiplier = 1.0
	
	return copy


func apply_gem_modifiers(gems: Array) -> void:
	## Apply modifiers from equipped gems
	for gem in gems:
		if gem is GemData:
			damage_multiplier *= gem.damage_multiplier
			cost_multiplier *= gem.cost_multiplier
			cooldown_multiplier *= gem.cooldown_multiplier
			range_multiplier *= gem.range_multiplier
			aoe_multiplier *= gem.aoe_multiplier
			
			# Add gem effects to spell
			for effect in gem.additional_effects:
				if effect not in effects:
					effects.append(effect)


func get_delivery_description() -> String:
	match delivery_type:
		Enums.SpellDelivery.HITSCAN:
			return "Instant hit at range"
		Enums.SpellDelivery.PROJECTILE:
			var desc = "Fires projectile"
			if projectile_count > 1:
				desc += " x" + str(projectile_count)
			if projectile_pierce > 0:
				desc += ", pierces " + str(projectile_pierce)
			return desc
		Enums.SpellDelivery.AOE:
			return "Area effect (%.1fm radius)" % get_final_aoe_radius()
		Enums.SpellDelivery.BEAM:
			return "Continuous beam"
		Enums.SpellDelivery.SELF:
			return "Self-cast"
		Enums.SpellDelivery.SUMMON:
			return "Summons entity"
		Enums.SpellDelivery.CONE:
			return "Cone attack"
		Enums.SpellDelivery.CHAIN:
			return "Chains to %d targets" % chain_count
	return ""


func get_tooltip() -> String:
	var tooltip = "[b]%s[/b]\n" % spell_name
	tooltip += description + "\n\n"
	tooltip += "Element: %s\n" % Enums.Element.keys()[element]
	tooltip += "Cost: %.0f Magika\n" % get_final_magika_cost()
	tooltip += "Cooldown: %.1fs\n" % get_final_cooldown()
	if cast_time > 0:
		tooltip += "Cast Time: %.1fs\n" % cast_time
	tooltip += "Range: %.0fm\n" % get_final_range()
	tooltip += "\n" + get_delivery_description()
	
	# List effects
	if effects.size() > 0:
		tooltip += "\n\nEffects:"
		for effect in effects:
			tooltip += "\n- " + effect.effect_name
	
	return tooltip
