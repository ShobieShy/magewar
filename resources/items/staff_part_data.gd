## StaffPartData - Data for staff/wand parts
## Parts combine to create staffs and wands with different stats
class_name StaffPartData
extends ItemData

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Part Type")
@export var part_type: Enums.StaffPart = Enums.StaffPart.HEAD
@export var is_wand_part: bool = false  ## Can be used in wands
@export var part_level: int = 1  ## Level of this part (1-50)

@export_group("Head Stats (if HEAD)")
@export var gem_slots: int = 1  ## 1-3 for staff heads, 1 for wand
@export var gem_slot_types: Array[Enums.Element] = []  ## Empty = any element

@export_group("Exterior Stats (if EXTERIOR)")
@export var fire_rate_modifier: float = 0.0  ## Percentage change
@export var projectile_speed_modifier: float = 0.0

@export_group("Interior Stats (if INTERIOR)")
@export var damage_modifier: float = 0.0  ## Percentage change
@export var magika_efficiency: float = 0.0  ## Reduces magika cost

@export_group("Handle Stats (if HANDLE)")
@export var handling: float = 0.0  ## Affects weapon sway
@export var stability: float = 0.0  ## Affects recoil
@export var accuracy: float = 0.0  ## Affects spread

@export_group("Charm Stats (if CHARM)")
@export var charm_effect: SpellEffect  ## Special effect added to spells
@export var charm_element: Enums.Element = Enums.Element.NONE

@export_group("Visual")
@export var mesh: Mesh  ## 3D mesh for this part
@export var material_override: Material

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	item_type = Enums.ItemType.STAFF_PART


# =============================================================================
# METHODS
# =============================================================================

func get_stat_description() -> String:
	var stats: Array[String] = []
	
	# Always show part level
	stats.append("Part Level: %d" % part_level)
	
	match part_type:
		Enums.StaffPart.HEAD:
			stats.append("Gem Slots: %d" % gem_slots)
			if gem_slot_types.size() > 0:
				var types = gem_slot_types.map(func(e): return Enums.Element.keys()[e])
				stats.append("Accepts: " + ", ".join(types))
		
		Enums.StaffPart.EXTERIOR:
			if fire_rate_modifier != 0.0:
				stats.append("%+.0f%% Fire Rate" % (fire_rate_modifier * 100))
			if projectile_speed_modifier != 0.0:
				stats.append("%+.0f%% Projectile Speed" % (projectile_speed_modifier * 100))
		
		Enums.StaffPart.INTERIOR:
			if damage_modifier != 0.0:
				stats.append("%+.0f%% Damage" % (damage_modifier * 100))
			if magika_efficiency != 0.0:
				stats.append("%+.0f%% Magika Efficiency" % (magika_efficiency * 100))
		
		Enums.StaffPart.HANDLE:
			if handling != 0.0:
				stats.append("%+.0f Handling" % handling)
			if stability != 0.0:
				stats.append("%+.0f Stability" % stability)
			if accuracy != 0.0:
				stats.append("%+.0f Accuracy" % accuracy)
		
		Enums.StaffPart.CHARM:
			if charm_effect:
				stats.append("Effect: " + charm_effect.effect_name)
			if charm_element != Enums.Element.NONE:
				stats.append("Element: " + Enums.Element.keys()[charm_element])
	
	return "\n".join(stats)


func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	tooltip += "\n\n[u]%s[/u]\n" % Enums.StaffPart.keys()[part_type]
	tooltip += get_stat_description()
	return tooltip


func apply_to_weapon_stats(stats: Dictionary) -> void:
	## Modify weapon stats dictionary based on this part
	match part_type:
		Enums.StaffPart.HEAD:
			stats["gem_slots"] = stats.get("gem_slots", 0) + gem_slots
		
		Enums.StaffPart.EXTERIOR:
			stats["fire_rate"] = stats.get("fire_rate", 1.0) * (1.0 + fire_rate_modifier)
			stats["projectile_speed"] = stats.get("projectile_speed", 1.0) * (1.0 + projectile_speed_modifier)
		
		Enums.StaffPart.INTERIOR:
			stats["damage"] = stats.get("damage", 1.0) * (1.0 + damage_modifier)
			stats["magika_cost"] = stats.get("magika_cost", 1.0) * (1.0 - magika_efficiency)
		
		Enums.StaffPart.HANDLE:
			stats["handling"] = stats.get("handling", 0.0) + handling
			stats["stability"] = stats.get("stability", 0.0) + stability
			stats["accuracy"] = stats.get("accuracy", 0.0) + accuracy
		
		Enums.StaffPart.CHARM:
			if charm_effect:
				var effects = stats.get("effects", [])
				effects.append(charm_effect)
				stats["effects"] = effects
			if charm_element != Enums.Element.NONE:
				stats["element"] = charm_element
