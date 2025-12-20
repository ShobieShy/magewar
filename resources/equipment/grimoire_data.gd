## GrimoireEquipmentData - Resource for grimoire equipment items
## Grimoires provide spell augmentations and passive bonuses
class_name GrimoireEquipmentData
extends EquipmentData

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Equipment")
@export var equipment_slot: Enums.EquipmentSlot = Enums.EquipmentSlot.NONE

@export_group("Grimoire Properties")
## Number of additional spell slots this grimoire provides
@export_range(0, 3) var bonus_spell_slots: int = 0

## Mana cost reduction for spells (percentage)
@export_range(0.0, 50.0) var mana_cost_reduction: float = 0.0

## Spell damage multiplier
@export_range(1.0, 2.0) var spell_damage_multiplier: float = 1.0

## Cooldown reduction for spells (percentage)
@export_range(0.0, 50.0) var cooldown_reduction: float = 0.0

## Cast time reduction (percentage)
@export_range(0.0, 50.0) var cast_time_reduction: float = 0.0

@export_group("Element Affinity")
## Elemental damage bonuses
@export var fire_damage_bonus: float = 0.0
@export var ice_damage_bonus: float = 0.0
@export var lightning_damage_bonus: float = 0.0
@export var earth_damage_bonus: float = 0.0
@export var arcane_damage_bonus: float = 0.0

@export_group("Special Effects")
## Chance to not consume mana on cast (percentage)
@export_range(0.0, 30.0) var free_cast_chance: float = 0.0

## Chance to double-cast a spell
@export_range(0.0, 20.0) var double_cast_chance: float = 0.0

## Lifesteal from spell damage (percentage)
@export_range(0.0, 30.0) var spell_lifesteal: float = 0.0

## Spell penetration (ignores resistance)
@export_range(0.0, 50.0) var spell_penetration: float = 0.0

@export_group("Knowledge Bonuses")
## Experience gain multiplier
@export_range(1.0, 2.0) var experience_multiplier: float = 1.0

## Skill point gain on level up
@export_range(0, 2) var bonus_skill_points: int = 0

## Chance to learn new spells from enemies
@export_range(0.0, 10.0) var spell_learn_chance: float = 0.0

@export_group("Spell List")
## Spells that this grimoire teaches/unlocks
@export var unlocked_spells: Array[String] = []

## Spell modifications (spell_id -> modification_data)
@export var spell_modifications: Dictionary = {}

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	equipment_slot = Enums.EquipmentSlot.GRIMOIRE
	item_type = Enums.ItemType.GRIMOIRE

# =============================================================================
# METHODS
# =============================================================================

func apply_to_spell_cast(spell_data: Dictionary) -> Dictionary:
	## Apply grimoire modifications to a spell being cast
	var modified = spell_data.duplicate()
	
	# Apply mana cost reduction
	if modified.has("mana_cost"):
		modified["mana_cost"] *= (1.0 - mana_cost_reduction / 100.0)
	
	# Apply damage multiplier
	if modified.has("damage"):
		modified["damage"] *= spell_damage_multiplier
		
		# Apply elemental bonuses
		if modified.has("element"):
			match modified["element"]:
				"fire":
					modified["damage"] += fire_damage_bonus
				"ice":
					modified["damage"] += ice_damage_bonus
				"lightning":
					modified["damage"] += lightning_damage_bonus
				"earth":
					modified["damage"] += earth_damage_bonus
				"arcane":
					modified["damage"] += arcane_damage_bonus
	
	# Apply cooldown reduction
	if modified.has("cooldown"):
		modified["cooldown"] *= (1.0 - cooldown_reduction / 100.0)
	
	# Apply cast time reduction
	if modified.has("cast_time"):
		modified["cast_time"] *= (1.0 - cast_time_reduction / 100.0)
	
	# Apply spell-specific modifications if they exist
	if spell_modifications.has(modified.get("spell_id", "")):
		var mods = spell_modifications[modified["spell_id"]]
		for key in mods:
			modified[key] = mods[key]
	
	# Apply special effects
	modified["free_cast_chance"] = free_cast_chance
	modified["double_cast_chance"] = double_cast_chance
	modified["lifesteal"] = spell_lifesteal
	modified["penetration"] = spell_penetration
	
	return modified

func get_tooltip_text() -> String:
	var text = super.get_tooltip()
	
	text += "\n[color=purple]── Grimoire Properties ──[/color]\n"
	
	if bonus_spell_slots > 0:
		text += "• +%d Spell Slots\n" % bonus_spell_slots
	
	if mana_cost_reduction > 0:
		text += "• -%d%% Mana Cost\n" % int(mana_cost_reduction)
	
	if spell_damage_multiplier > 1.0:
		text += "• +%d%% Spell Damage\n" % int((spell_damage_multiplier - 1.0) * 100)
	
	if cooldown_reduction > 0:
		text += "• -%d%% Cooldowns\n" % int(cooldown_reduction)
	
	if cast_time_reduction > 0:
		text += "• -%d%% Cast Time\n" % int(cast_time_reduction)
	
	# Elemental bonuses
	var elements = []
	if fire_damage_bonus > 0:
		elements.append("[color=orange]+%.0f Fire[/color]" % fire_damage_bonus)
	if ice_damage_bonus > 0:
		elements.append("[color=cyan]+%.0f Ice[/color]" % ice_damage_bonus)
	if lightning_damage_bonus > 0:
		elements.append("[color=yellow]+%.0f Lightning[/color]" % lightning_damage_bonus)
	if earth_damage_bonus > 0:
		elements.append("[color=brown]+%.0f Earth[/color]" % earth_damage_bonus)
	if arcane_damage_bonus > 0:
		elements.append("[color=purple]+%.0f Arcane[/color]" % arcane_damage_bonus)
	
	if elements.size() > 0:
		text += "• Elemental: %s\n" % ", ".join(elements)
	
	# Special effects
	if free_cast_chance > 0:
		text += "• %d%% Free Cast Chance\n" % int(free_cast_chance)
	
	if double_cast_chance > 0:
		text += "• %d%% Double Cast Chance\n" % int(double_cast_chance)
	
	if spell_lifesteal > 0:
		text += "• %d%% Spell Lifesteal\n" % int(spell_lifesteal)
	
	if spell_penetration > 0:
		text += "• %d%% Spell Penetration\n" % int(spell_penetration)
	
	# Knowledge bonuses
	if experience_multiplier > 1.0:
		text += "• +%d%% Experience Gain\n" % int((experience_multiplier - 1.0) * 100)
	
	if bonus_skill_points > 0:
		text += "• +%d Skill Points per Level\n" % bonus_skill_points
	
	if spell_learn_chance > 0:
		text += "• %d%% Spell Learn Chance\n" % int(spell_learn_chance)
	
	# Unlocked spells
	if unlocked_spells.size() > 0:
		text += "\n[color=gold]Teaches Spells:[/color]\n"
		for spell in unlocked_spells:
			text += "• %s\n" % spell.capitalize()
	
	return text

func get_value() -> int:
	## Calculate grimoire value based on properties
	var value = base_value
	
	# Add value for bonuses
	value += bonus_spell_slots * 500
	value += int(mana_cost_reduction * 20)
	value += int((spell_damage_multiplier - 1.0) * 1000)
	value += int(cooldown_reduction * 15)
	value += int(cast_time_reduction * 15)
	
	# Elemental bonuses
	value += int(fire_damage_bonus * 10)
	value += int(ice_damage_bonus * 10)
	value += int(lightning_damage_bonus * 10)
	value += int(earth_damage_bonus * 10)
	value += int(arcane_damage_bonus * 10)
	
	# Special effects
	value += int(free_cast_chance * 50)
	value += int(double_cast_chance * 100)
	value += int(spell_lifesteal * 30)
	value += int(spell_penetration * 25)
	
	# Knowledge bonuses
	value += int((experience_multiplier - 1.0) * 500)
	value += bonus_skill_points * 1000
	value += int(spell_learn_chance * 200)
	
	# Unlocked spells
	value += unlocked_spells.size() * 300
	
	# Apply rarity multiplier
	match rarity:
		Enums.Rarity.BASIC:
			value = int(value * 1.0)
		Enums.Rarity.UNCOMMON:
			value = int(value * 1.5)
		Enums.Rarity.RARE:
			value = int(value * 2.5)
		Enums.Rarity.MYTHIC:
			value = int(value * 5.0)
		Enums.Rarity.PRIMORDIAL:
			value = int(value * 10.0)
		Enums.Rarity.UNIQUE:
			value = int(value * 20.0)
	
	return value