## PotionData - Resource for consumable potion items
class_name PotionData
extends ItemData

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Instant Effects")
## Health restored instantly
@export var instant_health: int = 0
## Mana restored instantly  
@export var instant_mana: int = 0
## Stamina restored instantly
@export var instant_stamina: int = 0

@export_group("Over Time Effects")
## Duration of buff effects in seconds
@export var buff_duration: float = 0.0
## Health regenerated per second
@export var health_regen_per_second: float = 0.0
## Mana regenerated per second
@export var mana_regen_per_second: float = 0.0
## Stamina regenerated per second
@export var stamina_regen_per_second: float = 0.0

@export_group("Stat Modifiers")
## Damage multiplier while buff is active
@export_range(0.5, 3.0) var damage_multiplier: float = 1.0
## Defense multiplier while buff is active
@export_range(0.5, 3.0) var defense_multiplier: float = 1.0
## Movement speed multiplier
@export_range(0.5, 2.0) var movement_speed_multiplier: float = 1.0
## Attack speed multiplier
@export_range(0.5, 2.0) var attack_speed_multiplier: float = 1.0

@export_group("Resistances")
## Physical damage resistance buff (percentage)
@export_range(-50.0, 50.0) var physical_resistance_buff: float = 0.0
## Magical damage resistance buff (percentage)
@export_range(-50.0, 50.0) var magical_resistance_buff: float = 0.0
## Elemental resistance buffs
@export var fire_resistance_buff: float = 0.0
@export var ice_resistance_buff: float = 0.0
@export var lightning_resistance_buff: float = 0.0
@export var poison_resistance_buff: float = 0.0

@export_group("Special Effects")
## Remove all debuffs on use
@export var remove_debuffs: bool = false
## Grant immunity to debuffs for duration
@export var grant_immunity_duration: float = 0.0
## Revive from death (Phoenix potion)
@export var can_revive: bool = false
## Revive with this much health (percentage)
@export_range(0.1, 1.0) var revive_health_percent: float = 0.25

@export_group("Potion Properties")
## Cooldown before this potion can be used again
@export var cooldown: float = 5.0
## Can be used in combat
@export var usable_in_combat: bool = true
## Can be used while moving
@export var usable_while_moving: bool = true
## Time to consume (0 for instant)
@export var cast_time: float = 0.0
## Animation to play when consuming
@export var consume_animation: String = "drink_potion"

@export_group("Visual Effects")
## Color of the potion liquid
@export var liquid_color: Color = Color.RED
## Particle effect on consumption
@export var effect_scene_path: String = ""
## Sound effect on consumption
@export var consume_sound_path: String = "res://assets/audio/sfx/potion_drink.ogg"

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	item_type = Enums.ItemType.CONSUMABLE
	stackable = true
	max_stack = 99

# =============================================================================
# METHODS
# =============================================================================

func get_tooltip_text() -> String:
	var text = "[b]%s[/b]\n" % item_name
	text += "[color=gray]%s[/color]\n" % description
	
	text += "\n[color=yellow]Effects:[/color]\n"
	
	# Instant effects
	if instant_health > 0:
		text += "• Restores %d Health\n" % instant_health
	if instant_mana > 0:
		text += "• Restores %d Mana\n" % instant_mana
	if instant_stamina > 0:
		text += "• Restores %d Stamina\n" % instant_stamina
	
	# Buff effects
	if buff_duration > 0:
		text += "\n[color=cyan]Buff (%.1fs):[/color]\n" % buff_duration
		
		if health_regen_per_second > 0:
			text += "• +%.1f Health/sec\n" % health_regen_per_second
		if mana_regen_per_second > 0:
			text += "• +%.1f Mana/sec\n" % mana_regen_per_second
		if stamina_regen_per_second > 0:
			text += "• +%.1f Stamina/sec\n" % stamina_regen_per_second
		
		if damage_multiplier != 1.0:
			var percent = int((damage_multiplier - 1.0) * 100)
			text += "• %+d%% Damage\n" % percent
		if defense_multiplier != 1.0:
			var percent = int((defense_multiplier - 1.0) * 100)
			text += "• %+d%% Defense\n" % percent
		if movement_speed_multiplier != 1.0:
			var percent = int((movement_speed_multiplier - 1.0) * 100)
			text += "• %+d%% Move Speed\n" % percent
		if attack_speed_multiplier != 1.0:
			var percent = int((attack_speed_multiplier - 1.0) * 100)
			text += "• %+d%% Attack Speed\n" % percent
		
		# Resistances
		if physical_resistance_buff != 0:
			text += "• %+.0f%% Physical Resist\n" % physical_resistance_buff
		if magical_resistance_buff != 0:
			text += "• %+.0f%% Magical Resist\n" % magical_resistance_buff
		if fire_resistance_buff != 0:
			text += "• %+.0f%% Fire Resist\n" % fire_resistance_buff
		if ice_resistance_buff != 0:
			text += "• %+.0f%% Ice Resist\n" % ice_resistance_buff
		if lightning_resistance_buff != 0:
			text += "• %+.0f%% Lightning Resist\n" % lightning_resistance_buff
		if poison_resistance_buff != 0:
			text += "• %+.0f%% Poison Resist\n" % poison_resistance_buff
	
	# Special effects
	if remove_debuffs:
		text += "• [color=gold]Removes Debuffs[/color]\n"
	if grant_immunity_duration > 0:
		text += "• [color=gold]Immunity (%.1fs)[/color]\n" % grant_immunity_duration
	if can_revive:
		text += "• [color=gold]Revive on Death (%d%% HP)[/color]\n" % int(revive_health_percent * 100)
	
	# Usage info
	text += "\n[color=gray]"
	if cooldown > 0:
		text += "Cooldown: %.1fs\n" % cooldown
	if cast_time > 0:
		text += "Cast Time: %.1fs\n" % cast_time
	if not usable_in_combat:
		text += "Cannot use in combat\n"
	if not usable_while_moving:
		text += "Cannot use while moving\n"
	text += "[/color]"
	
	# Rarity color
	text = apply_rarity_color(text)
	
	return text

func apply_rarity_color(text: String) -> String:
	var color_tag = ""
	match rarity:
		Enums.Rarity.BASIC:
			color_tag = "[color=white]"
		Enums.Rarity.UNCOMMON:
			color_tag = "[color=green]"
		Enums.Rarity.RARE:
			color_tag = "[color=blue]"
		Enums.Rarity.MYTHIC:
			color_tag = "[color=purple]"
		Enums.Rarity.PRIMORDIAL:
			color_tag = "[color=orange]"
		Enums.Rarity.UNIQUE:
			color_tag = "[color=red]"
	
	# Apply color to item name (first line)
	var lines = text.split("\n")
	if lines.size() > 0:
		lines[0] = color_tag + lines[0] + "[/color]"
	return "\n".join(lines)

func get_value() -> int:
	## Calculate potion value based on effects
	var value = base_value
	
	# Instant effects
	value += instant_health * 2
	value += instant_mana * 2
	value += instant_stamina * 1
	
	# Over time effects
	if buff_duration > 0:
		value += int(health_regen_per_second * buff_duration * 2)
		value += int(mana_regen_per_second * buff_duration * 2)
		value += int(stamina_regen_per_second * buff_duration * 1)
		
		# Stat modifiers
		value += int(abs(damage_multiplier - 1.0) * 500)
		value += int(abs(defense_multiplier - 1.0) * 500)
		value += int(abs(movement_speed_multiplier - 1.0) * 300)
		value += int(abs(attack_speed_multiplier - 1.0) * 300)
		
		# Resistances
		value += int(abs(physical_resistance_buff) * 10)
		value += int(abs(magical_resistance_buff) * 10)
	
	# Special effects
	if remove_debuffs:
		value += 200
	if grant_immunity_duration > 0:
		value += int(grant_immunity_duration * 100)
	if can_revive:
		value += 1000
	
	# Apply rarity multiplier
	match rarity:
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