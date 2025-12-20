## Wand - Simpler secondary weapon with 2-3 parts
## Used alongside staff, typically faster but weaker
class_name Wand
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
@export var head: StaffPartData  ## Single gem slot
@export var exterior: StaffPartData
@export var handle: StaffPartData  ## Optional

@export_group("Gems")
@export var equipped_gem: GemData  ## Single gem slot

@export_group("Base Spell")
@export var base_spell: SpellData

# Default fallback spell for when base_spell isn't set
const DEFAULT_SPELL_PATH = "res://resources/spells/presets/arcane_bolt.tres"

# =============================================================================
# PROPERTIES
# =============================================================================

var owner_player: Player
var spell_caster: SpellCaster
var _computed_stats: Dictionary = {}
var _current_spell: SpellData

# Weapon progression
var leveling_system: WeaponLevelingSystem = null
var refinement_system: RefinementSystem = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_recompute_stats()


func _process(delta: float) -> void:
	if owner_player and owner_player.is_local_player:
		_handle_input()

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(player: Player) -> void:
	owner_player = player
	spell_caster = player.get_node_or_null("SpellCaster")
	if spell_caster == null:
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
	if not part.is_wand_part:
		push_warning("Part is not a wand part")
		return null
	
	var old_part: StaffPartData = null
	
	match part.part_type:
		Enums.StaffPart.HEAD:
			old_part = head
			head = part
		Enums.StaffPart.EXTERIOR:
			old_part = exterior
			exterior = part
		Enums.StaffPart.HANDLE:
			old_part = handle
			handle = part
	
	_recompute_stats()
	return old_part


func remove_part(part_type: Enums.StaffPart) -> StaffPartData:
	var old_part: StaffPartData = null
	
	match part_type:
		Enums.StaffPart.HEAD:
			old_part = head
			head = null
		Enums.StaffPart.EXTERIOR:
			old_part = exterior
			exterior = null
		Enums.StaffPart.HANDLE:
			old_part = handle
			handle = null
	
	_recompute_stats()
	return old_part

# =============================================================================
# GEM MANAGEMENT
# =============================================================================

func equip_gem(gem: GemData) -> GemData:
	var old_gem = equipped_gem
	equipped_gem = gem
	_recompute_stats()
	return old_gem


func remove_gem() -> GemData:
	var gem = equipped_gem
	equipped_gem = null
	_recompute_stats()
	return gem

# =============================================================================
# STATS COMPUTATION
# =============================================================================

func _recompute_stats() -> void:
	_computed_stats = {
		"gem_slots": 1,
		"fire_rate": 1.5,  ## Wands are faster by default
		"projectile_speed": 1.0,
		"damage": 0.7,  ## But weaker
		"magika_cost": 0.7,  ## And cheaper
		"handling": 10.0,  ## Better handling
		"stability": 5.0,
		"accuracy": 5.0,
		"effects": [],
		"element": Enums.Element.ARCANE
	}
	
	# Apply part stats
	if head:
		head.apply_to_weapon_stats(_computed_stats)
	if exterior:
		exterior.apply_to_weapon_stats(_computed_stats)
	if handle:
		handle.apply_to_weapon_stats(_computed_stats)
	
	_update_current_spell()
	weapon_stats_changed.emit()


func _update_current_spell() -> void:
	var spell_to_use = base_spell
	
	# Use default spell if none is assigned
	if spell_to_use == null:
		spell_to_use = load(DEFAULT_SPELL_PATH)
		if spell_to_use == null:
			push_error("Failed to load default spell for wand")
			return
	
	_current_spell = spell_to_use.duplicate(true)
	
	_current_spell.damage_multiplier *= _computed_stats.damage
	_current_spell.cost_multiplier *= _computed_stats.magika_cost
	_current_spell.cooldown_multiplier /= _computed_stats.fire_rate
	_current_spell.projectile_speed *= _computed_stats.projectile_speed
	
	for effect in _computed_stats.effects:
		if effect not in _current_spell.effects:
			_current_spell.effects.append(effect)
	
	if _computed_stats.element != Enums.Element.ARCANE:
		_current_spell.element = _computed_stats.element
	
	if equipped_gem:
		equipped_gem.apply_to_spell(_current_spell)


func get_stats() -> Dictionary:
	return _computed_stats.duplicate()


func get_current_spell() -> SpellData:
	return _current_spell

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _handle_input() -> void:
	# Wand uses secondary fire by default when equipped
	if Input.is_action_just_pressed("secondary_fire"):
		fire()


func fire() -> void:
	if _current_spell == null or spell_caster == null:
		return
	
	var aim_point = owner_player.get_aim_point()
	var aim_dir = owner_player.get_aim_direction()
	
	if spell_caster.cast_spell(_current_spell, aim_point, aim_dir):
		spell_cast.emit(_current_spell)

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"head": head.item_id if head else "",
		"exterior": exterior.item_id if exterior else "",
		"handle": handle.item_id if handle else "",
		"gem": equipped_gem.item_id if equipped_gem else ""
	}

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
	var base_damage = _computed_stats.get("damage", 0.7)
	var level_bonus = 0.0
	var refinement_bonus = 1.0
	
	if leveling_system:
		level_bonus = leveling_system.get_damage_bonus()
	
	if refinement_system:
		refinement_bonus = refinement_system.get_damage_multiplier()
	
	return (base_damage + level_bonus) * refinement_bonus
