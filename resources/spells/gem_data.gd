## GemData - Gem that modifies spell properties when slotted
## Gems can change element, add effects, or modify stats
class_name GemData
extends ItemData

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Gem Info") 
@export var gem_name: String = "Unnamed Gem"  ## Keep separate from item_name for clarity

@export_group("Element")
@export var element: Enums.Element = Enums.Element.NONE
@export var converts_element: bool = false  ## If true, changes spell element

@export_group("Stat Modifiers")
@export var damage_multiplier: float = 1.0
@export var cost_multiplier: float = 1.0
@export var cooldown_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var aoe_multiplier: float = 1.0
@export var projectile_speed_multiplier: float = 1.0
@export var projectile_count_bonus: int = 0

@export_group("Additional Effects")
@export var additional_effects: Array[SpellEffect] = []

@export_group("Special Properties")
@export var adds_pierce: int = 0
@export var adds_bounce: int = 0
@export var adds_chain: int = 0
@export var adds_homing: float = 0.0
@export var reduces_gravity: float = 0.0

# =============================================================================
# METHODS
# =============================================================================

func apply_to_spell(spell: SpellData) -> void:
	## Apply this gem's modifiers to a spell
	
	# Element conversion
	if converts_element and element != Enums.Element.NONE:
		spell.element = element
	
	# Stat multipliers
	spell.damage_multiplier *= damage_multiplier
	spell.cost_multiplier *= cost_multiplier
	spell.cooldown_multiplier *= cooldown_multiplier
	spell.range_multiplier *= range_multiplier
	spell.aoe_multiplier *= aoe_multiplier
	
	# Projectile modifiers
	spell.projectile_speed *= projectile_speed_multiplier
	spell.projectile_count += projectile_count_bonus
	spell.projectile_pierce += adds_pierce
	spell.projectile_bounce += adds_bounce
	spell.projectile_homing += adds_homing
	spell.projectile_gravity -= reduces_gravity
	
	# Chain modifiers
	spell.chain_count += adds_chain
	
	# Add effects
	for effect in additional_effects:
		if effect not in spell.effects:
			spell.effects.append(effect)


func get_modifier_description() -> String:
	var mods: Array[String] = []
	
	if damage_multiplier != 1.0:
		var percent = (damage_multiplier - 1.0) * 100
		mods.append("%+.0f%% Damage" % percent)
	
	if cost_multiplier != 1.0:
		var percent = (cost_multiplier - 1.0) * 100
		mods.append("%+.0f%% Magika Cost" % percent)
	
	if cooldown_multiplier != 1.0:
		var percent = (cooldown_multiplier - 1.0) * 100
		mods.append("%+.0f%% Cooldown" % percent)
	
	if range_multiplier != 1.0:
		var percent = (range_multiplier - 1.0) * 100
		mods.append("%+.0f%% Range" % percent)
	
	if aoe_multiplier != 1.0:
		var percent = (aoe_multiplier - 1.0) * 100
		mods.append("%+.0f%% AoE Size" % percent)
	
	if projectile_count_bonus > 0:
		mods.append("+%d Projectiles" % projectile_count_bonus)
	
	if adds_pierce > 0:
		mods.append("+%d Pierce" % adds_pierce)
	
	if adds_bounce > 0:
		mods.append("+%d Bounce" % adds_bounce)
	
	if adds_chain > 0:
		mods.append("+%d Chain" % adds_chain)
	
	if adds_homing > 0:
		mods.append("Adds Homing")
	
	return "\n".join(mods)


func get_tooltip() -> String:
	var tooltip = "[b]%s[/b]\n" % gem_name
	tooltip += "[color=%s]%s[/color]\n" % [Constants.RARITY_COLORS[rarity].to_html(), Enums.Rarity.keys()[rarity]]
	
	if element != Enums.Element.NONE:
		var elem_text = "Adds " if not converts_element else "Converts to "
		tooltip += elem_text + Enums.Element.keys()[element] + " element\n"
	
	tooltip += "\n" + description + "\n"
	
	var mods = get_modifier_description()
	if not mods.is_empty():
		tooltip += "\n" + mods
	
	if additional_effects.size() > 0:
		tooltip += "\n\nAdditional Effects:"
		for effect in additional_effects:
			tooltip += "\n- " + effect.effect_name
	
	return tooltip
