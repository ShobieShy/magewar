## WeaponConfiguration - Configuration for crafting weapons
## Defines the parts, gems, and settings for weapon creation
class_name WeaponConfiguration
extends RefCounted

# =============================================================================
# PROPERTIES
# =============================================================================

@export var weapon_type: String = "staff"  ## "staff" or "wand"
@export var weapon_name: String = ""
@export var weapon_rarity: Enums.Rarity = Enums.Rarity.BASIC

# Staff parts
var head: StaffPartData = null
var exterior: StaffPartData = null
var interior: StaffPartData = null  ## Staff only
var handle: StaffPartData = null
var charm: StaffPartData = null     ## Optional

var gems: Array[GemData] = []
var weapon_level: int = 1
var crafting_difficulty: String = "normal"

# Requirements
var require_all_parts: bool = false
var require_head: bool = true
var require_exterior: bool = true
var require_handle: bool = true
var require_charm: bool = false

# Computed stats
var stats: Dictionary = {}
var success_chance: float = 0.0
var craft_time: float = 0.0
var craft_cost: int = 0

# =============================================================================
# METHODS
# =============================================================================

func _init() -> void:
	_reset_stats()

func _reset_stats() -> void:
	stats = {
		"damage": 0,
		"fire_rate": 1.0,
		"projectile_speed": 1.0,
		"magika_cost": 1.0,
		"handling": 0.0,
		"stability": 0.0,
		"accuracy": 0.0,
		"gem_slots": 0,
		"effects": []
	}

func add_part(part: StaffPartData) -> bool:
	## Add a part to the configuration
	if not part is StaffPartData:
		return false
	
	match part.part_type:
		Enums.StaffPart.HEAD:
			head = part
		Enums.StaffPart.EXTERIOR:
			exterior = part
		Enums.StaffPart.INTERIOR:
			if weapon_type == "staff":
				interior = part
			else:
				return false
		Enums.StaffPart.HANDLE:
			handle = part
		Enums.StaffPart.CHARM:
			charm = part
		_:
			return false
	
	_recalculate_stats()
	return true

func add_gem(gem: GemData) -> bool:
	## Add a gem to available slots
	if not gem is GemData:
		return false
	
	var max_gems = get_max_gem_slots()
	if gems.size() >= max_gems:
		return false
	
	gems.append(gem)
	_recalculate_stats()
	return true

func remove_gem(index: int) -> bool:
	## Remove gem at index
	if index < 0 or index >= gems.size():
		return false
	
	gems.remove_at(index)
	_recalculate_stats()
	return true

func get_max_gem_slots() -> int:
	## Get maximum gem slots for this weapon type
	if weapon_type == "staff":
		return Constants.STAFF_GEM_SLOTS_MAX
	else:
		return Constants.WAND_GEM_SLOTS

func get_required_parts() -> Array:
	## Get list of required parts for this weapon type
	var required = []
	
	if require_head:
		required.append(Enums.StaffPart.HEAD)
	if require_exterior:
		required.append(Enums.StaffPart.EXTERIOR)
	if require_handle:
		required.append(Enums.StaffPart.HANDLE)
	if weapon_type == "staff" and interior:
		required.append(Enums.StaffPart.INTERIOR)
	
	return required

func get_optional_parts() -> Array[Enums.StaffPart]:
	## Get list of optional parts
	var optional = []
	
	if not require_charm:
		optional.append(Enums.StaffPart.CHARM)
	if weapon_type == "wand" and not require_handle:
		optional.append(Enums.StaffPart.HANDLE)
	
	return optional

func get_total_part_count() -> int:
	## Get total number of parts in configuration
	var count = 0
	if head:
		count += 1
	if exterior:
		count += 1
	if interior:
		count += 1
	if handle:
		count += 1
	if charm:
		count += 1
	return count

func get_required_part_count() -> int:
	## Get number of required parts
	return get_required_parts().size()

func is_complete() -> bool:
	## Check if configuration has all required parts
	var required = get_required_parts()
	
	for part_type in required:
		if not _has_part_of_type(part_type):
			return false
	
	return true

func _has_part_of_type(part_type: Enums.StaffPart) -> bool:
	## Check if configuration has a part of specific type
	match part_type:
		Enums.StaffPart.HEAD:
			return head != null
		Enums.StaffPart.EXTERIOR:
			return exterior != null
		Enums.StaffPart.INTERIOR:
			return interior != null
		Enums.StaffPart.HANDLE:
			return handle != null
		Enums.StaffPart.CHARM:
			return charm != null
		_:
			return false

func _recalculate_stats() -> void:
	## Recalculate weapon stats from parts and gems
	_reset_stats()
	
	# Apply part stats
	if head:
		head.apply_to_weapon_stats(stats)
	if exterior:
		exterior.apply_to_weapon_stats(stats)
	if interior:
		interior.apply_to_weapon_stats(stats)
	if handle:
		handle.apply_to_weapon_stats(stats)
	if charm:
		charm.apply_to_weapon_stats(stats)
	
	# Apply gem effects
	for gem in gems:
		_apply_gem_stats(gem)
	
	# Calculate derived stats
	weapon_level = _calculate_weapon_level()
	weapon_rarity = _calculate_weapon_rarity()
	craft_time = _calculate_craft_time()
	craft_cost = _calculate_craft_cost()
	success_chance = _calculate_success_chance()

func _apply_gem_stats(gem: GemData) -> void:
	## Apply gem stat modifiers to weapon
	stats.damage *= gem.damage_multiplier
	stats.magika_cost *= gem.cost_multiplier
	stats.fire_rate *= gem.cooldown_multiplier  # Cooldown affects fire rate
	
	if gem.additional_effects.size() > 0:
		for effect in gem.additional_effects:
			stats.effects.append(effect)

func _calculate_weapon_level() -> int:
	## Calculate weapon level from parts
	var total_level = 0
	var part_count = 0
	
	if head:
		total_level += head.part_level
		part_count += 1
	if exterior:
		total_level += exterior.part_level
		part_count += 1
	if interior:
		total_level += interior.part_level
		part_count += 1
	if handle:
		total_level += handle.part_level
		part_count += 1
	if charm:
		total_level += charm.part_level
		part_count += 1
	
	# Add gem levels
	for gem in gems:
		total_level += gem.level_required
		part_count += 1
	
	return int(float(total_level) / max(part_count, 1))

func _calculate_weapon_rarity() -> Enums.Rarity:
	## Calculate weapon rarity from parts and gems
	var total_rarity = 0.0
	var part_count = 0
	
	if head:
		total_rarity += float(head.rarity)
		part_count += 1
	if exterior:
		total_rarity += float(exterior.rarity)
		part_count += 1
	if interior:
		total_rarity += float(interior.rarity)
		part_count += 1
	if handle:
		total_rarity += float(handle.rarity)
		part_count += 1
	if charm:
		total_rarity += float(charm.rarity)
		part_count += 1
	
	# Add gem rarities
	for gem in gems:
		total_rarity += float(gem.rarity)
		part_count += 1
	
	if part_count == 0:
		return Enums.Rarity.BASIC
	
	var avg_rarity = total_rarity / part_count
	
	# Upgrade rarity slightly for crafted weapons
	if avg_rarity < 1.5:
		return Enums.Rarity.UNCOMMON
	elif avg_rarity < 2.5:
		return Enums.Rarity.RARE
	elif avg_rarity < 3.5:
		return Enums.Rarity.MYTHIC
	elif avg_rarity < 4.5:
		return Enums.Rarity.PRIMORDIAL
	else:
		return Enums.Rarity.UNIQUE

func _calculate_craft_time() -> float:
	## Calculate crafting time based on complexity
	var base_time = 3.0
	var part_count = get_total_part_count()
	var gem_count = gems.size()
	
	# Add time per part and gem
	var part_time = part_count * 0.5
	var gem_time = gem_count * 0.3
	
	# Rarity modifier
	var rarity_mult = 1.0 + (float(weapon_rarity) * 0.2)
	
	return (base_time + part_time + gem_time) * rarity_mult

func _calculate_craft_cost() -> int:
	## Calculate gold cost for crafting
	var base_cost = 50
	var part_cost = get_total_part_count() * 25
	var gem_cost = gems.size() * 40
	
	# Rarity modifier
	var rarity_mult = Constants.RARITY_STAT_MULTIPLIERS.get(weapon_rarity, 1.0)
	
	return int((base_cost + part_cost + gem_cost) * rarity_mult)

func _calculate_success_chance() -> float:
	## Calculate base success chance (before player modifiers)
	var base_chance = 0.6  ## 60% base success
	
	# Reduce for higher rarity
	match weapon_rarity:
		Enums.Rarity.UNCOMMON:
			base_chance = 0.7
		Enums.Rarity.RARE:
			base_chance = 0.6
		Enums.Rarity.MYTHIC:
			base_chance = 0.4
		Enums.Rarity.PRIMORDIAL:
			base_chance = 0.3
		Enums.Rarity.UNIQUE:
			base_chance = 0.2
	
	# Reduce for more parts
	var part_count = get_total_part_count()
	if part_count > 4:
		base_chance *= 0.9
	if part_count > 6:
		base_chance *= 0.8
	
	return clamp(base_chance, 0.1, 0.9)

func generate_weapon_name() -> String:
	## Generate a weapon name based on parts and rarity
	var prefixes = {
		Enums.Rarity.BASIC: ["Simple", "Basic", "Plain"],
		Enums.Rarity.UNCOMMON:["Arcane", "Mystic", "Charmed"],
		Enums.Rarity.RARE: ["Enchanted", "Glimmering", "Warding"],
		Enums.Rarity.MYTHIC: ["Ethereal", "Celestial", "Divine"],
		Enums.Rarity.PRIMORDIAL: ["Primordial", "Ancient", "Eternal"],
		Enums.Rarity.UNIQUE: ["Legendary", "Mythic", "Fabled"]
	}
	
	var suffixes = ["of Power", "of Wisdom", "of Elements", "of Destruction", "of Creation", "of Protection"]
	
	var prefix_list = prefixes.get(weapon_rarity, ["Mystic"])
	var prefix = prefix_list.pick_random()
	var type = weapon_type.capitalize()
	var suffix = suffixes.pick_random() if get_total_part_count() > 3 else ""
	
	var name = prefix + " " + type
	if not suffix.is_empty():
		name += " " + suffix
	
	return name

func generate_weapon_description() -> String:
	## Generate weapon description based on configuration
	var desc = "A magically crafted %s forged from %d parts." % [weapon_type, get_total_part_count()]
	
	if gems.size() > 0:
		desc += "\nSocketed with %d gem%s." % [gems.size(), "s" if gems.size() != 1 else ""]
	
	# Add special properties
	if charm and charm.charm_effect:
		desc += "\nGrants %s." % charm.charm_effect.effect_name
	
	# Add stats preview
	if stats.damage != 0:
		desc += "\nDamage bonus: %+.0f%%" % ((stats.damage - 1.0) * 100)
	if stats.fire_rate != 1.0:
		desc += "\nFire rate: %+.0f%%" % ((stats.fire_rate - 1.0) * 100)
	
	return desc

func get_validation_errors() -> Array[String]:
	## Get list of validation errors
	var errors = []
	
	var required = get_required_parts()
	for part_type in required:
		if not _has_part_of_type(part_type):
			errors.append("Missing required part: %s" % Enums.StaffPart.keys()[part_type])
	
	# Check gem slots
	if gems.size() > get_max_gem_slots():
		errors.append("Too many gems (max: %d)" % get_max_gem_slots())
	
	# Check wand-specific requirements
	if weapon_type == "wand" and interior:
		errors.append("Wands cannot have interior parts")
	
	return errors

func to_dict() -> Dictionary:
	## Convert configuration to dictionary for saving
	return {
		"weapon_type": weapon_type,
		"weapon_name": weapon_name,
		"weapon_rarity": weapon_rarity,
		"head": head.item_id if head else "",
		"exterior": exterior.item_id if exterior else "",
		"interior": interior.item_id if interior else "",
		"handle": handle.item_id if handle else "",
		"charm": charm.item_id if charm else "",
		"gems": gems.map(func(g): return g.item_id),
		"weapon_level": weapon_level,
		"crafting_difficulty": crafting_difficulty,
		"stats": stats,
		"success_chance": success_chance,
		"craft_time": craft_time,
		"craft_cost": craft_cost
	}