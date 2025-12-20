## CraftingAchievementManager - Manages crafting achievements
## Handles achievement tracking, unlocking, and rewards
class_name CraftingAchievementManager
extends Node

signal achievement_unlocked(achievement: CraftingAchievement)
signal achievement_progressed(achievement: CraftingAchievement)
signal achievements_updated()

# Achievement database
var _achievements: Dictionary = {}  ## achievement_id -> CraftingAchievement
var _unlocked_achievements: Array[String] = []  ## List of unlocked achievement IDs

# Global crafting statistics
var _total_weapons_crafted: int = 0
var _staffs_crafted: int = 0
var _wands_crafted: int = 0
var _recipes_discovered: int = 0
var _rarest_weapon_crafted: Enums.Rarity = Enums.Rarity.BASIC

func _ready() -> void:
	_load_default_achievements()
	_load_achievement_progress()

## Register a new achievement
func register_achievement(achievement: CraftingAchievement) -> void:
	if not achievement or achievement.achievement_id.is_empty():
		push_error("Cannot register achievement without valid ID")
		return
	
	_achievements[achievement.achievement_id] = achievement
	achievements_updated.emit()

## Get achievement by ID
func get_achievement(achievement_id: String) -> CraftingAchievement:
	return _achievements.get(achievement_id, null)

## Get all achievements
func get_all_achievements() -> Array[CraftingAchievement]:
	var all_achievements: Array[CraftingAchievement] = []
	for achievement in _achievements.values():
		all_achievements.append(achievement)
	return all_achievements

## Get unlocked achievements
func get_unlocked_achievements() -> Array[CraftingAchievement]:
	var unlocked: Array[CraftingAchievement] = []
	for achievement_id in _unlocked_achievements:
		var achievement = _achievements.get(achievement_id)
		if achievement:
			unlocked.append(achievement)
	return unlocked

## Get locked achievements
func get_locked_achievements() -> Array[CraftingAchievement]:
	var locked: Array[CraftingAchievement] = []
	for achievement in _achievements.values():
		if not achievement.is_unlocked:
			locked.append(achievement)
	return locked

## Get achievements by rarity
func get_achievements_by_rarity(rarity: Enums.Rarity) -> Array[CraftingAchievement]:
	var rarity_achievements: Array[CraftingAchievement] = []
	
	for achievement in _achievements.values():
		if achievement.rarity == rarity:
			rarity_achievements.append(achievement)
	
	return rarity_achievements

## Process crafting event for achievement progress
func process_crafting_event(weapon_data: ItemData, config: WeaponConfiguration, inventory_system: InventorySystem) -> Array[CraftingAchievement]:
	# Update global statistics
	_total_weapons_crafted += 1
	
	if config.weapon_type == "staff":
		_staffs_crafted += 1
	elif config.weapon_type == "wand":
		_wands_crafted += 1
	
	# Update rarest weapon crafted
	if float(weapon_data.rarity) > float(_rarest_weapon_crafted):
		_rarest_weapon_crafted = weapon_data.rarity
	
	# Check all achievements for progress
	var progressed_achievements: Array[CraftingAchievement] = []
	
	for achievement in _achievements.values():
		if achievement.check_crafting_event(weapon_data, config, inventory_system):
			progressed_achievements.append(achievement)
			
			if achievement.is_unlocked and achievement.achievement_id not in _unlocked_achievements:
				_unlock_achievement(achievement)
			else:
				achievement_progressed.emit(achievement)
	
	_save_achievement_progress()
	achievements_updated.emit()
	
	return progressed_achievements

## Process recipe discovery for achievement progress
func process_recipe_discovery(discovered_count: int) -> Array[CraftingAchievement]:
	# Update global statistics
	_recipes_discovered = discovered_count
	
	# Check achievements for progress
	var progressed_achievements: Array[CraftingAchievement] = []
	
	for achievement in _achievements.values():
		if achievement.check_recipe_discovery(discovered_count):
			progressed_achievements.append(achievement)
			
			if achievement.is_unlocked and achievement.achievement_id not in _unlocked_achievements:
				_unlock_achievement(achievement)
			else:
				achievement_progressed.emit(achievement)
	
	_save_achievement_progress()
	achievements_updated.emit()
	
	return progressed_achievements

## Unlock an achievement
func _unlock_achievement(achievement: CraftingAchievement) -> void:
	if achievement.achievement_id in _unlocked_achievements:
		return  ## Already unlocked
	
	_unlocked_achievements.append(achievement.achievement_id)
	achievement.unlock()
	
	print("Achievement Unlocked: %s" % achievement.achievement_name)
	achievement_unlocked.emit(achievement)

## Force unlock an achievement (for debugging/rewards)
func unlock_achievement(achievement_id: String) -> bool:
	var achievement = _achievements.get(achievement_id)
	if not achievement:
		return false
	
	if achievement.is_unlocked:
		return false  ## Already unlocked
	
	_unlock_achievement(achievement)
	return true

## Get achievement completion statistics
func get_achievement_stats() -> Dictionary:
	var total = _achievements.size()
	var unlocked = _unlocked_achievements.size()
	var completion_rate = float(unlocked) / float(max(total, 1)) * 100.0
	
	return {
		"total_achievements": total,
		"unlocked_achievements": unlocked,
		"locked_achievements": total - unlocked,
		"completion_rate": completion_rate,
		"total_weapons_crafted": _total_weapons_crafted,
		"staffs_crafted": _staffs_crafted,
		"wands_crafted": _wands_crafted,
		"recipes_discovered": _recipes_discovered,
		"rarest_weapon": Enums.Rarity.keys()[_rarest_weapon_crafted]
	}

## Get next achievements player is close to completing
func get_near_completion_achievements(threshold: float = 0.8) -> Array[CraftingAchievement]:
	var near_completion: Array[CraftingAchievement] = []
	
	for achievement in _achievements.values():
		if not achievement.is_unlocked and achievement.get_progress_percentage() >= threshold * 100.0:
			near_completion.append(achievement)
	
	# Sort by progress (highest first)
	near_completion.sort_custom(func(a, b): return a.get_progress_percentage() > b.get_progress_percentage())
	
	return near_completion

## Get achievements by category/group
func get_achievements_by_category(category: String) -> Array[CraftingAchievement]:
	var category_achievements: Array[CraftingAchievement] = []
	
	# Categorize based on achievement criteria
	for achievement in _achievements.values():
		var achievement_category = _get_achievement_category(achievement)
		if achievement_category == category:
			category_achievements.append(achievement)
	
	return category_achievements

## Determine achievement category based on criteria
func _get_achievement_category(achievement: CraftingAchievement) -> String:
	if achievement.weapons_crafted_required > 0:
		return "quantity"
	elif achievement.weapon_type_required != "":
		return "type"
	elif achievement.minimum_rarity != Enums.Rarity.BASIC:
		return "quality"
	elif achievement.specific_parts_required.size() > 0 or achievement.specific_gems_required.size() > 0:
		return "materials"
	elif achievement.recipes_discovered_required > 0:
		return "discovery"
	else:
		return "general"

## Reset all achievements (for debugging/new game)
func reset_all_achievements() -> void:
	_unlocked_achievements.clear()
	_total_weapons_crafted = 0
	_staffs_crafted = 0
	_wands_crafted = 0
	_recipes_discovered = 0
	_rarest_weapon_crafted = Enums.Rarity.BASIC
	
	# Reset all achievements
	for achievement in _achievements.values():
		achievement.is_unlocked = false
		achievement.progress = 0
		achievement.unlocked_time = 0
		achievement.unlock_notification_shown = false
	
	_save_achievement_progress()
	achievements_updated.emit()

## Check for milestone achievements
func check_milestone_achievements() -> void:
	# These are automatic achievements based on global stats
	var milestones = [
		{"id": "craft_10_weapons", "count": 10, "name": "Novice Crafter"},
		{"id": "craft_25_weapons", "count": 25, "name": "Apprentice Crafter"},
		{"id": "craft_50_weapons", "count": 50, "name": "Journeyman Crafter"},
		{"id": "craft_100_weapons", "count": 100, "name": "Master Crafter"},
		{"id": "craft_250_weapons", "count": 250, "name": "Grandmaster Crafter"}
	]
	
	for milestone in milestones:
		var achievement = _achievements.get(milestone.id)
		if achievement and not achievement.is_unlocked:
			if _total_weapons_crafted >= milestone.count:
				unlock_achievement(milestone.id)

## Save achievement progress
func _save_achievement_progress() -> void:
	var save_data = {
		"unlocked_achievements": _unlocked_achievements,
		"total_weapons_crafted": _total_weapons_crafted,
		"staffs_crafted": _staffs_crafted,
		"wands_crafted": _wands_crafted,
		"recipes_discovered": _recipes_discovered,
		"rarest_weapon_crafted": _rarest_weapon_crafted
	}
	
	if SaveManager:
		SaveManager.set_data("crafting_achievements", save_data)

## Load achievement progress
func _load_achievement_progress() -> void:
	var save_data = null
	if SaveManager:
		save_data = SaveManager.get_data("crafting_achievements")
	if not save_data:
		return
	
	if save_data.has("unlocked_achievements"):
		_unlocked_achievements = save_data.unlocked_achievements
	
	if save_data.has("total_weapons_crafted"):
		_total_weapons_crafted = save_data.total_weapons_crafted
	
	if save_data.has("staffs_crafted"):
		_staffs_crafted = save_data.staffs_crafted
	
	if save_data.has("wands_crafted"):
		_wands_crafted = save_data.wands_crafted
	
	if save_data.has("recipes_discovered"):
		_recipes_discovered = save_data.recipes_discovered
	
	if save_data.has("rarest_weapon_crafted"):
		_rarest_weapon_crafted = save_data.rarest_weapon_crafted
	
	# Apply unlocked state to achievements
	for achievement_id in _unlocked_achievements:
		var achievement = _achievements.get(achievement_id)
		if achievement:
			achievement.is_unlocked = true

## Load default achievements
func _load_default_achievements() -> void:
	# Quantity Achievements
	var craft_1_weapon = CraftingAchievement.new()
	craft_1_weapon.achievement_id = "craft_1_weapon"
	craft_1_weapon.achievement_name = "First Creation"
	craft_1_weapon.description = "Craft your first weapon"
	craft_1_weapon.rarity = Enums.Rarity.BASIC
	craft_1_weapon.weapons_crafted_required = 1
	craft_1_weapon.experience_reward = 25
	register_achievement(craft_1_weapon)
	
	var craft_10_weapons = CraftingAchievement.new()
	craft_10_weapons.achievement_id = "craft_10_weapons"
	craft_10_weapons.achievement_name = "Novice Crafter"
	craft_10_weapons.description = "Craft 10 weapons"
	craft_10_weapons.rarity = Enums.Rarity.UNCOMMON
	craft_10_weapons.weapons_crafted_required = 10
	craft_10_weapons.experience_reward = 100
	register_achievement(craft_10_weapons)
	
	var craft_25_weapons = CraftingAchievement.new()
	craft_25_weapons.achievement_id = "craft_25_weapons"
	craft_25_weapons.achievement_name = "Apprentice Crafter"
	craft_25_weapons.description = "Craft 25 weapons"
	craft_25_weapons.rarity = Enums.Rarity.RARE
	craft_25_weapons.weapons_crafted_required = 25
	craft_25_weapons.experience_reward = 250
	register_achievement(craft_25_weapons)
	
	# Type Achievements
	var craft_5_staffs = CraftingAchievement.new()
	craft_5_staffs.achievement_id = "craft_5_staffs"
	craft_5_staffs.achievement_name = "Staff Specialist"
	craft_5_staffs.description = "Craft 5 staffs"
	craft_5_staffs.rarity = Enums.Rarity.UNCOMMON
	craft_5_staffs.weapon_type_required = "staff"
	craft_5_staffs.weapons_crafted_required = 5
	craft_5_staffs.experience_reward = 75
	register_achievement(craft_5_staffs)
	
	var craft_5_wands = CraftingAchievement.new()
	craft_5_wands.achievement_id = "craft_5_wands"
	craft_5_wands.achievement_name = "Wand Specialist"
	craft_5_wands.description = "Craft 5 wands"
	craft_5_wands.rarity = Enums.Rarity.UNCOMMON
	craft_5_wands.weapon_type_required = "wand"
	craft_5_wands.weapons_crafted_required = 5
	craft_5_wands.experience_reward = 75
	register_achievement(craft_5_wands)
	
	# Quality Achievements
	var craft_rare_weapon = CraftingAchievement.new()
	craft_rare_weapon.achievement_id = "craft_rare_weapon"
	craft_rare_weapon.achievement_name = "Quality Craftsman"
	craft_rare_weapon.description = "Craft a rare quality weapon"
	craft_rare_weapon.rarity = Enums.Rarity.RARE
	craft_rare_weapon.minimum_rarity = Enums.Rarity.RARE
	craft_rare_weapon.experience_reward = 150
	register_achievement(craft_rare_weapon)
	
	var craft_mythic_weapon = CraftingAchievement.new()
	craft_mythic_weapon.achievement_id = "craft_mythic_weapon"
	craft_mythic_weapon.achievement_name = "Mythic Artisan"
	craft_mythic_weapon.description = "Craft a mythic quality weapon"
	craft_mythic_weapon.rarity = Enums.Rarity.MYTHIC
	craft_mythic_weapon.minimum_rarity = Enums.Rarity.MYTHIC
	craft_mythic_weapon.experience_reward = 500
	register_achievement(craft_mythic_weapon)
	
	# Discovery Achievements
	var discover_5_recipes = CraftingAchievement.new()
	discover_5_recipes.achievement_id = "discover_5_recipes"
	discover_5_recipes.achievement_name = "Recipe Hunter"
	discover_5_recipes.description = "Discover 5 crafting recipes"
	discover_5_recipes.rarity = Enums.Rarity.UNCOMMON
	discover_5_recipes.recipes_discovered_required = 5
	discover_5_recipes.experience_reward = 200
	register_achievement(discover_5_recipes)
	
	var discover_10_recipes = CraftingAchievement.new()
	discover_10_recipes.achievement_id = "discover_10_recipes"
	discover_10_recipes.achievement_name = "Master Discoverer"
	discover_10_recipes.description = "Discover 10 crafting recipes"
	discover_10_recipes.rarity = Enums.Rarity.RARE
	discover_10_recipes.recipes_discovered_required = 10
	discover_10_recipes.experience_reward = 400
	register_achievement(discover_10_recipes)
	
	print("Loaded %d default crafting achievements" % _achievements.size())