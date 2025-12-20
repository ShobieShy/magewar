## SkillManager - Global skill tree and ability management
## Handles skill unlocks, passive effects, active ability usage, and spell augments
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal skill_unlocked(skill: SkillData)
signal skill_points_changed(new_amount: int)
signal active_ability_changed(skill: SkillData)
signal active_ability_used(skill: SkillData)
signal active_ability_ready(skill: SkillData)

# =============================================================================
# PROPERTIES
# =============================================================================

## All skill definitions
var _skill_database: Dictionary = {}  ## skill_id -> SkillData

## Currently unlocked skills (references to database entries)
var _unlocked_skills: Dictionary = {}  ## skill_id -> SkillData

## Currently equipped active ability
var _active_ability: SkillData = null
var _active_ability_cooldown: float = 0.0
var _active_ability_ready: bool = true

## Reference to local player's stats (set during gameplay)
var _player_stats: Node = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_load_skill_database()


func _process(delta: float) -> void:
	_update_active_cooldown(delta)

# =============================================================================
# DATABASE MANAGEMENT
# =============================================================================

func _load_skill_database() -> void:
	## Load all skill resources
	var skill_path = "res://resources/skills/definitions/"
	var dir = DirAccess.open(skill_path)
	
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var skill = load(skill_path + file_name) as SkillData
			if skill:
				register_skill(skill)
		file_name = dir.get_next()
	
	dir.list_dir_end()


func register_skill(skill: SkillData) -> void:
	_skill_database[skill.skill_id] = skill


func get_skill(skill_id: String) -> SkillData:
	return _skill_database.get(skill_id)


func get_all_skills() -> Array[SkillData]:
	var result: Array[SkillData] = []
	for skill in _skill_database.values():
		result.append(skill)
	return result


func get_skills_by_category(category: Enums.SkillCategory) -> Array[SkillData]:
	var result: Array[SkillData] = []
	for skill in _skill_database.values():
		if skill.category == category:
			result.append(skill)
	return result


func get_skills_by_type(skill_type: Enums.SkillType) -> Array[SkillData]:
	var result: Array[SkillData] = []
	for skill in _skill_database.values():
		if skill.skill_type == skill_type:
			result.append(skill)
	return result

# =============================================================================
# SKILL UNLOCKING
# =============================================================================

func can_unlock_skill(skill_id: String) -> bool:
	if skill_id in _unlocked_skills:
		return false  # Already unlocked
	
	var skill = _skill_database.get(skill_id)
	if skill == null:
		return false
	
	if SaveManager.get_skill_points() < skill.skill_points_cost:
		return false
	
	var player_level = SaveManager.player_data.level
	var unlocked_ids = _unlocked_skills.keys()
	
	return skill.can_unlock(player_level, unlocked_ids)


func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false
	
	var skill = _skill_database.get(skill_id)
	
	# Spend skill points
	for i in range(skill.skill_points_cost):
		if not SaveManager.use_skill_point():
			push_error("Failed to use skill point for skill: %s" % skill_id)
			return false
	
	# Add to unlocked
	_unlocked_skills[skill_id] = skill
	
	# Save to SaveManager
	if skill_id not in SaveManager.player_data.unlocked_skills:
		SaveManager.player_data.unlocked_skills.append(skill_id)
	
	# Apply passive effects if we have a player reference
	if skill.skill_type == Enums.SkillType.PASSIVE and _player_stats:
		skill.apply_passive_to_stats(_player_stats)
	
	skill_unlocked.emit(skill)
	skill_points_changed.emit(SaveManager.get_skill_points())
	
	return true


func is_skill_unlocked(skill_id: String) -> bool:
	return skill_id in _unlocked_skills


func get_unlocked_skills() -> Array[SkillData]:
	var result: Array[SkillData] = []
	for skill in _unlocked_skills.values():
		result.append(skill)
	return result

# =============================================================================
# PASSIVE SKILLS
# =============================================================================

func set_player_stats(stats_component: Node) -> void:
	## Called when player is ready to receive stat modifications
	_player_stats = stats_component
	_apply_all_passives()


func _apply_all_passives() -> void:
	if _player_stats == null:
		return
	
	for skill in _unlocked_skills.values():
		if skill.skill_type == Enums.SkillType.PASSIVE:
			skill.apply_passive_to_stats(_player_stats)


func _remove_all_passives() -> void:
	if _player_stats == null:
		return
	
	for skill in _unlocked_skills.values():
		if skill.skill_type == Enums.SkillType.PASSIVE:
			skill.remove_passive_from_stats(_player_stats)

# =============================================================================
# ACTIVE ABILITY
# =============================================================================

func set_active_ability(skill_id: String) -> bool:
	if skill_id.is_empty():
		_active_ability = null
		SaveManager.set_active_ability("")
		active_ability_changed.emit(null)
		return true
	
	if skill_id not in _unlocked_skills:
		push_warning("Cannot set active ability - skill not unlocked: %s" % skill_id)
		return false
	
	var skill = _unlocked_skills[skill_id]
	if skill.skill_type != Enums.SkillType.ACTIVE:
		push_warning("Cannot set non-active skill as active ability: %s" % skill_id)
		return false
	
	_active_ability = skill
	_active_ability_cooldown = 0.0
	_active_ability_ready = true
	
	SaveManager.set_active_ability(skill_id)
	active_ability_changed.emit(skill)
	
	return true


func get_active_ability() -> SkillData:
	return _active_ability


func can_use_active_ability() -> bool:
	if _active_ability == null:
		return false
	
	if not _active_ability_ready:
		return false
	
	if _player_stats:
		if _active_ability.magika_cost > 0:
			if not _player_stats.has_magika(_active_ability.magika_cost):
				return false
		if _active_ability.stamina_cost > 0:
			if not _player_stats.has_stamina(_active_ability.stamina_cost):
				return false
	
	return true


func use_active_ability(caster: Node) -> bool:
	if not can_use_active_ability():
		return false
	
	# Consume resources
	if _player_stats:
		if _active_ability.magika_cost > 0:
			_player_stats.use_magika(_active_ability.magika_cost)
		if _active_ability.stamina_cost > 0:
			_player_stats.use_stamina(_active_ability.stamina_cost)
	
	# Apply effect
	if _active_ability.ability_effect:
		# Create temporary spell data for effect application
		var temp_spell = SpellData.new()
		_active_ability.ability_effect.apply(caster, caster, caster.global_position, temp_spell)
	
	# Start cooldown
	_active_ability_cooldown = _active_ability.cooldown
	_active_ability_ready = false
	
	active_ability_used.emit(_active_ability)
	
	return true


func get_active_ability_cooldown() -> float:
	return _active_ability_cooldown


func get_active_ability_cooldown_percent() -> float:
	if _active_ability == null or _active_ability.cooldown <= 0:
		return 0.0
	return _active_ability_cooldown / _active_ability.cooldown


func _update_active_cooldown(delta: float) -> void:
	if _active_ability == null or _active_ability_ready:
		return
	
	_active_ability_cooldown -= delta
	
	if _active_ability_cooldown <= 0:
		_active_ability_cooldown = 0.0
		_active_ability_ready = true
		active_ability_ready.emit(_active_ability)

# =============================================================================
# SPELL AUGMENTS
# =============================================================================

func apply_augments_to_spell(spell: SpellData) -> void:
	## Apply all unlocked spell augments to a spell
	for skill in _unlocked_skills.values():
		if skill.skill_type == Enums.SkillType.SPELL_AUGMENT:
			skill.apply_augment_to_spell(spell)


func get_augments_for_spell(spell: SpellData) -> Array[SkillData]:
	## Get list of augments that would affect this spell
	var result: Array[SkillData] = []
	for skill in _unlocked_skills.values():
		if skill.skill_type == Enums.SkillType.SPELL_AUGMENT:
			if skill.matches_spell(spell):
				result.append(skill)
	return result

# =============================================================================
# SAVE/LOAD
# =============================================================================

func initialize_from_save() -> void:
	## Load unlocked skills from SaveManager
	_unlocked_skills.clear()
	
	for skill_id in SaveManager.get_unlocked_skills():
		var skill = _skill_database.get(skill_id)
		if skill:
			_unlocked_skills[skill_id] = skill
	
	# Set active ability
	var active_id = SaveManager.get_active_ability()
	if not active_id.is_empty() and active_id in _unlocked_skills:
		_active_ability = _unlocked_skills[active_id]


func get_save_data() -> Dictionary:
	return {
		"unlocked_skills": _unlocked_skills.keys(),
		"active_ability": _active_ability.skill_id if _active_ability else ""
	}


func load_save_data(data: Dictionary) -> void:
	_unlocked_skills.clear()
	
	var unlocked_ids = data.get("unlocked_skills", [])
	for skill_id in unlocked_ids:
		var skill = _skill_database.get(skill_id)
		if skill:
			_unlocked_skills[skill_id] = skill
	
	var active_id = data.get("active_ability", "")
	if active_id in _unlocked_skills:
		_active_ability = _unlocked_skills[active_id]
	else:
		_active_ability = null

# =============================================================================
# UTILITY
# =============================================================================

func get_skill_tree_layout() -> Dictionary:
	## Returns skill data organized for tree display
	var layout = {
		Enums.SkillCategory.OFFENSE: [],
		Enums.SkillCategory.DEFENSE: [],
		Enums.SkillCategory.UTILITY: [],
		Enums.SkillCategory.ELEMENTAL: []
	}
	
	for skill in _skill_database.values():
		layout[skill.category].append({
			"skill": skill,
			"unlocked": skill.skill_id in _unlocked_skills,
			"can_unlock": can_unlock_skill(skill.skill_id)
		})
	
	return layout


func reset_skills() -> void:
	## Refund all skill points (for respec feature)
	var refund_count = 0
	
	for skill in _unlocked_skills.values():
		refund_count += skill.skill_points_cost
		if skill.skill_type == Enums.SkillType.PASSIVE and _player_stats:
			skill.remove_passive_from_stats(_player_stats)
	
	_unlocked_skills.clear()
	_active_ability = null
	
	# Refund skill points
	SaveManager.player_data.skill_points += refund_count
	SaveManager.player_data.unlocked_skills.clear()
	SaveManager.set_active_ability("")
	
	skill_points_changed.emit(SaveManager.get_skill_points())
	active_ability_changed.emit(null)
