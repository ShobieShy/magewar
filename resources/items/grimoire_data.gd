## GrimoireData - Spell book that grants additional spells
## When equipped, adds spells to the player's available spells
class_name GrimoireData
extends ItemData

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Grimoire")
@export var grimoire_name: String = "Unknown Grimoire"
@export var grimoire_element: Enums.Element = Enums.Element.FIRE  ## Primary element theme (FIRE, WATER, EARTH, AIR, LIGHT, or DARK)

@export_group("Spells")
@export var contained_spells: Array[SpellData] = []  ## Spells granted when equipped
@export var primary_spell_index: int = 0  ## Which spell is used as primary attack

@export_group("Stat Bonuses")
@export var spell_damage_bonus: float = 0.0  ## Flat bonus to all spell damage
@export var spell_damage_percent: float = 0.0  ## % bonus to all spell damage
@export var element_damage_bonus: float = 0.0  ## Bonus damage for grimoire's element
@export var cooldown_reduction: float = 0.0  ## Flat cooldown reduction (seconds)
@export var cooldown_reduction_percent: float = 0.0  ## % cooldown reduction
@export var magika_cost_reduction: float = 0.0  ## % magika cost reduction

@export_group("Special")
@export var passive_effect: SpellEffect  ## Passive effect while equipped
@export var on_cast_effect: SpellEffect  ## Effect triggered on each spell cast

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	item_type = Enums.ItemType.GRIMOIRE

# =============================================================================
# METHODS
# =============================================================================

func get_primary_spell() -> SpellData:
	if contained_spells.is_empty():
		return null
	return contained_spells[clamp(primary_spell_index, 0, contained_spells.size() - 1)]


func get_spell_count() -> int:
	return contained_spells.size()


func get_spell(index: int) -> SpellData:
	if index < 0 or index >= contained_spells.size():
		return null
	return contained_spells[index]


func apply_to_spell(spell: SpellData) -> void:
	## Modifies a spell with this grimoire's bonuses
	# Apply damage bonus
	spell.damage_multiplier *= (1.0 + spell_damage_percent)
	
	# Apply element-specific bonus
	if spell.element == grimoire_element:
		spell.damage_multiplier *= (1.0 + element_damage_bonus)
	
	# Apply cooldown reduction
	spell.cooldown_multiplier *= (1.0 - cooldown_reduction_percent)
	
	# Apply magika cost reduction
	spell.cost_multiplier *= (1.0 - magika_cost_reduction)


func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	
	tooltip += "\n\n[u]%s[/u]" % grimoire_name
	tooltip += "\nElement: %s" % Enums.Element.keys()[grimoire_element]
	
	# Stats
	var stats: Array[String] = []
	if spell_damage_percent != 0:
		stats.append("%+.0f%% Spell Damage" % (spell_damage_percent * 100))
	if element_damage_bonus != 0:
		stats.append("%+.0f%% %s Damage" % [element_damage_bonus * 100, Enums.Element.keys()[grimoire_element]])
	if cooldown_reduction_percent != 0:
		stats.append("%+.0f%% Cooldown Reduction" % (cooldown_reduction_percent * 100))
	if magika_cost_reduction != 0:
		stats.append("%+.0f%% Magika Cost Reduction" % (magika_cost_reduction * 100))
	
	if stats.size() > 0:
		tooltip += "\n\n" + "\n".join(stats)
	
	# Spells
	if contained_spells.size() > 0:
		tooltip += "\n\n[u]Contains %d Spell(s):[/u]" % contained_spells.size()
		for spell in contained_spells:
			tooltip += "\n- %s (%s)" % [spell.spell_name, Enums.Element.keys()[spell.element]]
	
	return tooltip
