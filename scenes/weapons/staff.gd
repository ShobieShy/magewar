## Staff - Modular magic staff weapon
## Composed of Head, Exterior, Interior, Handle, and optional Charm
class_name Staff
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal spell_cast(spell: SpellData)
signal weapon_stats_changed()

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Parts")
@export var head: StaffPartData
@export var exterior: StaffPartData
@export var interior: StaffPartData
@export var handle: StaffPartData
@export var charm: StaffPartData  ## Optional

@export_group("Gems")
@export var equipped_gems: Array[GemData] = []

@export_group("Base Spell")
@export var base_spell: SpellData  ## Default spell when no grimoire equipped

# Default fallback spell for when base_spell isn't set
const DEFAULT_SPELL_PATH = "res://resources/spells/presets/arcane_bolt.tres"

# =============================================================================
# PROPERTIES
# =============================================================================

var owner_player: Player
var spell_caster: SpellCaster
var _computed_stats: Dictionary = {}
var _current_spell: SpellData
var _staff_level: int = 1  ## Computed average of part levels

# Weapon progression
var leveling_system: WeaponLevelingSystem = null
var refinement_system: RefinementSystem = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_recompute_stats()
	_update_visual()


func _process(_delta: float) -> void:
	if owner_player and owner_player.is_local_player:
		_handle_input()

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(player: Player) -> void:
	owner_player = player
	spell_caster = player.get_node_or_null("SpellCaster")
	if spell_caster == null:
		# Create spell caster if player doesn't have one
		spell_caster = SpellCaster.new()
		spell_caster.name = "SpellCaster"
		player.add_child(spell_caster)
	
	spell_caster.projectile_spawn_point = get_node_or_null("SpawnPoint")
	
	# Initialize progression systems
	leveling_system = WeaponLevelingSystem.new(player)
	refinement_system = RefinementSystem.new()

# =============================================================================
# PART MANAGEMENT
# =============================================================================

func set_part(part: StaffPartData) -> StaffPartData:
	## Sets a part and returns the old part (if any)
	var old_part: StaffPartData = null
	
	match part.part_type:
		Enums.StaffPart.HEAD:
			old_part = head
			head = part
		Enums.StaffPart.EXTERIOR:
			old_part = exterior
			exterior = part
		Enums.StaffPart.INTERIOR:
			old_part = interior
			interior = part
		Enums.StaffPart.HANDLE:
			old_part = handle
			handle = part
		Enums.StaffPart.CHARM:
			old_part = charm
			charm = part
	
	_recompute_stats()
	_update_visual()
	return old_part


func remove_part(part_type: Enums.StaffPart) -> StaffPartData:
	## Removes and returns a part
	var old_part: StaffPartData = null
	
	match part_type:
		Enums.StaffPart.HEAD:
			old_part = head
			head = null
		Enums.StaffPart.EXTERIOR:
			old_part = exterior
			exterior = null
		Enums.StaffPart.INTERIOR:
			old_part = interior
			interior = null
		Enums.StaffPart.HANDLE:
			old_part = handle
			handle = null
		Enums.StaffPart.CHARM:
			old_part = charm
			charm = null
	
	_recompute_stats()
	_update_visual()
	return old_part


func get_part(part_type: Enums.StaffPart) -> StaffPartData:
	match part_type:
		Enums.StaffPart.HEAD:
			return head
		Enums.StaffPart.EXTERIOR:
			return exterior
		Enums.StaffPart.INTERIOR:
			return interior
		Enums.StaffPart.HANDLE:
			return handle
		Enums.StaffPart.CHARM:
			return charm
	return null

# =============================================================================
# GEM MANAGEMENT
# =============================================================================

func get_gem_slot_count() -> int:
	if head:
		return head.gem_slots
	return 0


func equip_gem(gem: GemData, slot_index: int) -> GemData:
	## Equips a gem and returns the old gem (if any)
	var max_slots = get_gem_slot_count()
	if slot_index >= max_slots:
		return null
	
	# Ensure array is large enough
	while equipped_gems.size() <= slot_index:
		equipped_gems.append(null)
	
	var old_gem = equipped_gems[slot_index]
	equipped_gems[slot_index] = gem
	
	_recompute_stats()
	return old_gem


func remove_gem(slot_index: int) -> GemData:
	if slot_index >= equipped_gems.size():
		return null
	
	var gem = equipped_gems[slot_index]
	equipped_gems[slot_index] = null
	
	_recompute_stats()
	return gem


func get_equipped_gems() -> Array[GemData]:
	var gems: Array[GemData] = []
	for gem in equipped_gems:
		if gem != null:
			gems.append(gem)
	return gems

# =============================================================================
# STATS COMPUTATION
# =============================================================================

func _recompute_stats() -> void:
	_computed_stats = {
		"gem_slots": 0,
		"fire_rate": 1.0,
		"projectile_speed": 1.0,
		"damage": 1.0,
		"magika_cost": 1.0,
		"handling": 0.0,
		"stability": 0.0,
		"accuracy": 0.0,
		"effects": [],
		"element": Enums.Element.FIRE  # (mapped from ARCANE)
	}
	
	# Apply part stats and calculate average level
	var total_level: int = 0
	var part_count: int = 0
	
	if head:
		head.apply_to_weapon_stats(_computed_stats)
		total_level += head.part_level
		part_count += 1
	if exterior:
		exterior.apply_to_weapon_stats(_computed_stats)
		total_level += exterior.part_level
		part_count += 1
	if interior:
		interior.apply_to_weapon_stats(_computed_stats)
		total_level += interior.part_level
		part_count += 1
	if handle:
		handle.apply_to_weapon_stats(_computed_stats)
		total_level += handle.part_level
		part_count += 1
	if charm:
		charm.apply_to_weapon_stats(_computed_stats)
		total_level += charm.part_level
		part_count += 1
	
	# Calculate average level (rounded down)
	_staff_level = int(float(total_level) / max(part_count, 1))
	
	# Update current spell with new stats
	_update_current_spell()
	
	weapon_stats_changed.emit()


func _update_current_spell() -> void:
	var spell_to_use = base_spell
	
	# Use default spell if none is assigned
	if spell_to_use == null:
		spell_to_use = load(DEFAULT_SPELL_PATH)
		if spell_to_use == null:
			push_error("Failed to load default spell for staff")
			return
	
	# Create modified copy of spell
	_current_spell = spell_to_use.duplicate(true)
	
	# Apply weapon stats
	_current_spell.damage_multiplier *= _computed_stats.damage
	_current_spell.cost_multiplier *= _computed_stats.magika_cost
	_current_spell.cooldown_multiplier /= _computed_stats.fire_rate
	_current_spell.projectile_speed *= _computed_stats.projectile_speed
	
	# Add effects from charm
	for effect in _computed_stats.effects:
		if effect not in _current_spell.effects:
			_current_spell.effects.append(effect)
	
	# Apply element if set
	if _computed_stats.element != Enums.Element.FIRE:  # (mapped from ARCANE)
		_current_spell.element = _computed_stats.element
	
	# Apply gem modifiers
	for gem in equipped_gems:
		if gem:
			gem.apply_to_spell(_current_spell)


func get_stats() -> Dictionary:
	return _computed_stats.duplicate()


func get_current_spell() -> SpellData:
	return _current_spell


func get_staff_level() -> int:
	return _staff_level


func get_level_requirement() -> int:
	## Staff level requirement equals the computed average level
	return _staff_level


func can_equip(player_level: int) -> bool:
	## Check if player meets level requirement to equip this staff
	return player_level >= _staff_level


func get_level_description() -> String:
	return "Staff Level: %d (Requires Level %d)" % [_staff_level, _staff_level]

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _handle_input() -> void:
	if Input.is_action_just_pressed("primary_fire"):
		fire_primary()
	
	if Input.is_action_just_pressed("secondary_fire"):
		fire_secondary()


func fire_primary() -> void:
	if _current_spell == null or spell_caster == null:
		return
	
	var aim_point = owner_player.get_aim_point()
	var aim_dir = owner_player.get_aim_direction()
	
	if spell_caster.cast_spell(_current_spell, aim_point, aim_dir):
		spell_cast.emit(_current_spell)


func fire_secondary() -> void:
	## Secondary fire - Charged heavy attack with increased damage and magika cost
	if _current_spell == null or spell_caster == null:
		return
	
	# Create a charged version of the spell
	var charged_spell = _create_charged_spell()
	if charged_spell == null:
		return
	
	var aim_point = owner_player.get_aim_point()
	var aim_dir = owner_player.get_aim_direction()
	
	if spell_caster.cast_spell(charged_spell, aim_point, aim_dir):
		spell_cast.emit(charged_spell)


func _create_charged_spell() -> SpellData:
	## Creates a charged version of the current spell with enhanced stats
	if _current_spell == null:
		return null
	
	var charged = _current_spell.duplicate(true)
	
	# Enhance the charged spell
	charged.damage_multiplier *= Constants.CHARGED_ATTACK_DAMAGE_MULT
	charged.cost_multiplier *= Constants.CHARGED_ATTACK_COST_MULT
	charged.cooldown_multiplier *= Constants.CHARGED_ATTACK_COOLDOWN_MULT
	
	# Increase projectile size/count for projectile spells
	if charged.delivery_type == Enums.SpellDelivery.PROJECTILE:
		charged.projectile_speed *= 0.8  # Slower but heavier
	
	# Increase AoE radius for AoE spells
	if charged.delivery_type == Enums.SpellDelivery.AOE:
		charged.aoe_radius *= 1.5
	
	charged.spell_name = charged.spell_name + "_charged"
	
	return charged

# =============================================================================
# VISUAL UPDATE
# =============================================================================

func _update_visual() -> void:
	# Update 3D mesh based on equipped parts
	# This would assemble the visual representation from part meshes
	
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance == null:
		return
	
	# For now, just update color based on rarity
	var highest_rarity = Enums.Rarity.BASIC
	for part in [head, exterior, interior, handle, charm]:
		if part and part.rarity > highest_rarity:
			highest_rarity = part.rarity
	
	# Color the mesh based on highest rarity part
	if mesh_instance.get_surface_override_material(0):
		var mat = mesh_instance.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.emission = Constants.RARITY_COLORS[highest_rarity]

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	var data = {
		"head": head.item_id if head else "",
		"exterior": exterior.item_id if exterior else "",
		"interior": interior.item_id if interior else "",
		"handle": handle.item_id if handle else "",
		"charm": charm.item_id if charm else "",
		"gems": [],
		"staff_level": _staff_level
	}
	
	for gem in equipped_gems:
		data.gems.append(gem.item_id if gem else "")
	
	return data


func get_parts_summary() -> String:
	var parts: Array[String] = []
	if head:
		parts.append("Head: %s (Lv.%d)" % [head.item_name, head.part_level])
	if exterior:
		parts.append("Exterior: %s (Lv.%d)" % [exterior.item_name, exterior.part_level])
	if interior:
		parts.append("Interior: %s (Lv.%d)" % [interior.item_name, interior.part_level])
	if handle:
		parts.append("Handle: %s (Lv.%d)" % [handle.item_name, handle.part_level])
	if charm:
		parts.append("Charm: %s (Lv.%d)" % [charm.item_name, charm.part_level])
	return "\n".join(parts)

# =============================================================================
# WEAPON PROGRESSION
# =============================================================================

## Grant experience to this weapon
func gain_experience(amount: float) -> void:
	if leveling_system:
		leveling_system.add_experience(amount)

## Get current weapon level
func get_weapon_level() -> int:
	if leveling_system:
		return leveling_system.weapon_level
	return 1

## Get weapon refinement level
func get_refinement_level() -> int:
	if refinement_system:
		return refinement_system.refinement_level
	return 0

## Get total damage with all bonuses applied
func get_total_damage() -> float:
	var base_damage = _computed_stats.get("damage", 1.0)
	var level_bonus = 0.0
	var refinement_bonus = 1.0
	
	if leveling_system:
		level_bonus = leveling_system.get_damage_bonus()
	
	if refinement_system:
		refinement_bonus = refinement_system.get_damage_multiplier()
	
	return (base_damage + level_bonus) * refinement_bonus
