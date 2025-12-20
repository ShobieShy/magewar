## SpellManager - Manages spell loading, registration, and access
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal spell_registered(spell_id: String, spell_data: SpellData)
signal spell_learned(spell_id: String)
signal spell_forgotten(spell_id: String)
signal spell_cast_started(spell_id: String, caster: Node)
signal spell_cast_completed(spell_id: String, caster: Node, success: bool)

# =============================================================================
# CONSTANTS
# =============================================================================

const SPELL_PRESETS_PATH = "res://resources/spells/presets/"
const DEFAULT_SPELLS = [
	"arcane_bolt",
	"fireball_enhanced",
	"ice_shard_piercing", 
	"lightning_chain",
	"earth_shield",
	"healing_light",
	"arcane_missile"
]

# =============================================================================
# PROPERTIES
# =============================================================================

## All available spells in the game
var spell_database: Dictionary = {}  # spell_id -> SpellData

## Player's learned spells
var learned_spells: Array[String] = []

## Currently equipped spells (hotbar)
var equipped_spells: Dictionary = {}  # slot_number -> spell_id

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_load_spell_presets()
	_register_default_spells()

# =============================================================================
# SPELL DATABASE
# =============================================================================

func _load_spell_presets() -> void:
	"""Load all spell presets from the presets folder"""
	var dir = DirAccess.open(SPELL_PRESETS_PATH)
	if not dir:
		push_error("Failed to open spell presets directory")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var spell_id = file_name.get_basename()
			var spell_path = SPELL_PRESETS_PATH + file_name
			var spell_data = load(spell_path) as SpellData
			
			if spell_data:
				register_spell(spell_id, spell_data)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Loaded %d spells into database" % spell_database.size())

func _register_default_spells() -> void:
	"""Register core spells that should always be available"""
	for spell_id in DEFAULT_SPELLS:
		if spell_database.has(spell_id):
			# Auto-learn basic spell for testing
			if spell_id == "arcane_bolt":
				learn_spell(spell_id)

func register_spell(spell_id: String, spell_data: SpellData) -> void:
	"""Register a spell in the database"""
	spell_database[spell_id] = spell_data
	spell_registered.emit(spell_id, spell_data)

func get_spell(spell_id: String) -> SpellData:
	"""Get spell data by ID"""
	return spell_database.get(spell_id, null)

func get_all_spells() -> Dictionary:
	"""Get all registered spells"""
	return spell_database

# =============================================================================
# SPELL LEARNING
# =============================================================================

func learn_spell(spell_id: String) -> bool:
	"""Learn a new spell"""
	if not spell_database.has(spell_id):
		push_warning("Trying to learn unknown spell: " + spell_id)
		return false
	
	if spell_id in learned_spells:
		push_warning("Spell already learned: " + spell_id)
		return false
	
	learned_spells.append(spell_id)
	spell_learned.emit(spell_id)
	
	# Auto-equip if there's an empty slot
	for slot in range(1, 9):  # 8 spell slots
		if not equipped_spells.has(slot):
			equip_spell(slot, spell_id)
			break
	
	return true

func forget_spell(spell_id: String) -> bool:
	"""Forget a learned spell"""
	if not spell_id in learned_spells:
		return false
	
	learned_spells.erase(spell_id)
	
	# Remove from equipped slots
	for slot in equipped_spells:
		if equipped_spells[slot] == spell_id:
			equipped_spells.erase(slot)
	
	spell_forgotten.emit(spell_id)
	return true

func has_learned_spell(spell_id: String) -> bool:
	"""Check if a spell has been learned"""
	return spell_id in learned_spells

func get_learned_spells() -> Array[String]:
	"""Get all learned spells"""
	return learned_spells

# =============================================================================
# SPELL EQUIPPING
# =============================================================================

func equip_spell(slot: int, spell_id: String) -> bool:
	"""Equip a spell to a hotbar slot"""
	if slot < 1 or slot > 8:
		push_warning("Invalid spell slot: " + str(slot))
		return false
	
	if not spell_id in learned_spells:
		push_warning("Cannot equip unlearned spell: " + spell_id)
		return false
	
	equipped_spells[slot] = spell_id
	return true

func unequip_spell(slot: int) -> void:
	"""Remove a spell from a hotbar slot"""
	equipped_spells.erase(slot)

func get_equipped_spell(slot: int) -> SpellData:
	"""Get the spell equipped in a slot"""
	var spell_id = equipped_spells.get(slot, "")
	if spell_id.is_empty():
		return null
	return get_spell(spell_id)

func get_equipped_spells() -> Dictionary:
	"""Get all equipped spells"""
	return equipped_spells

# =============================================================================
# SPELL DISCOVERY
# =============================================================================

func discover_spell_from_grimoire(grimoire: GrimoireEquipmentData) -> void:
	"""Learn spells from a grimoire"""
	if not grimoire:
		return
	
	for spell_id in grimoire.unlocked_spells:
		if spell_database.has(spell_id):
			learn_spell(spell_id)

func get_spells_by_element(element: Enums.Element) -> Array[SpellData]:
	"""Get all spells of a specific element"""
	var spells: Array[SpellData] = []
	for spell_id in spell_database:
		var spell = spell_database[spell_id]
		if spell.element == element:
			spells.append(spell)
	return spells

# =============================================================================
# SPELL CASTING NOTIFICATIONS
# =============================================================================

func notify_spell_cast_started(spell_id: String, caster: Node) -> void:
	"""Notify that a spell casting has started (called by SpellCaster)"""
	spell_cast_started.emit(spell_id, caster)


func notify_spell_cast_completed(spell_id: String, caster: Node, success: bool) -> void:
	"""Notify that a spell casting has completed (called by SpellCaster)"""
	spell_cast_completed.emit(spell_id, caster, success)

func get_spell_requirements(spell_id: String) -> Dictionary:
	"""Get requirements to learn a spell"""
	# This could be expanded with level requirements, prerequisite spells, etc.
	return {
		"level": 1,
		"prerequisites": [],
		"cost": 0
	}

# =============================================================================
# SPELL MODIFICATIONS
# =============================================================================

func apply_grimoire_modifiers(spell_data: SpellData, grimoire: GrimoireEquipmentData) -> SpellData:
	"""Apply grimoire modifications to a spell"""
	if not grimoire:
		return spell_data
	
	var modified = spell_data.duplicate(true)
	
	# Apply grimoire bonuses
	modified.damage_multiplier *= grimoire.spell_damage_multiplier
	modified.cost_multiplier *= (1.0 - grimoire.mana_cost_reduction / 100.0)
	modified.cooldown_multiplier *= (1.0 - grimoire.cooldown_reduction / 100.0)
	
	# Apply elemental bonuses
	match spell_data.element:
		Enums.Element.FIRE:
			if grimoire.fire_damage_bonus > 0:
				modified.damage_multiplier *= (1.0 + grimoire.fire_damage_bonus / 100.0)
		Enums.Element.ICE:
			if grimoire.ice_damage_bonus > 0:
				modified.damage_multiplier *= (1.0 + grimoire.ice_damage_bonus / 100.0)
		Enums.Element.LIGHTNING:
			if grimoire.lightning_damage_bonus > 0:
				modified.damage_multiplier *= (1.0 + grimoire.lightning_damage_bonus / 100.0)
		Enums.Element.EARTH:
			if grimoire.earth_damage_bonus > 0:
				modified.damage_multiplier *= (1.0 + grimoire.earth_damage_bonus / 100.0)
		Enums.Element.ARCANE:
			if grimoire.arcane_damage_bonus > 0:
				modified.damage_multiplier *= (1.0 + grimoire.arcane_damage_bonus / 100.0)
	
	return modified

# =============================================================================
# SAVE/LOAD
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"learned_spells": learned_spells,
		"equipped_spells": equipped_spells
	}

func load_save_data(data: Dictionary) -> void:
	learned_spells = data.get("learned_spells", [])
	equipped_spells = data.get("equipped_spells", {})

# =============================================================================
# DEBUG
# =============================================================================

func unlock_all_spells() -> void:
	"""Debug function to learn all spells"""
	for spell_id in spell_database:
		learn_spell(spell_id)
	print("All spells unlocked!")

func print_spell_info(spell_id: String) -> void:
	"""Debug function to print spell details"""
	var spell = get_spell(spell_id)
	if spell:
		print("=== %s ===" % spell.spell_name)
		print("Element: %s" % Enums.Element.keys()[spell.element])
		print("Mana Cost: %d" % spell.get_final_magika_cost())
		print("Cooldown: %.1fs" % spell.get_final_cooldown())
		print("Range: %.1fm" % spell.get_final_range())
		print("Description: %s" % spell.description)