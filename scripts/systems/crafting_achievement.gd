## CraftingAchievement - Achievement tracking for crafting accomplishments
class_name CraftingAchievement
extends Resource

@export var achievement_id: String = ""
@export var achievement_name: String = ""
@export var description: String = ""

@export var icon: Texture2D
@export var rarity: Enums.Rarity = Enums.Rarity.BASIC

# Achievement criteria
@export var weapons_crafted_required: int = 0
@export var weapon_type_required: String = ""  ## "staff", "wand", or "" for any
@export var minimum_rarity: Enums.Rarity = Enums.Rarity.BASIC
@export var specific_parts_required: Array[String] = []  ## Item IDs
@export var specific_gems_required: Array[String] = []  ## Item IDs
@export var recipes_discovered_required: int = 0

# Achievement state
@export var is_unlocked: bool = false
@export var progress: int = 0
@export var unlocked_time: int = 0  ## Unix timestamp
@export var unlock_notification_shown: bool = false

# Rewards
@export var experience_reward: int = 0
@export var gold_reward: int = 0
@export var unlocks_recipe_ids: Array[String] = []  ## Recipes unlocked when this achievement is unlocked

func _init() -> void:
	achievement_id = "achievement_" + str(Time.get_unix_time_from_system())

## Check if crafting event should progress this achievement
func check_crafting_event(weapon_data: ItemData, config: WeaponConfiguration, inventory_system: InventorySystem) -> bool:
	if is_unlocked:
		return false  ## Already unlocked
	
	var should_progress = false
	
	# Check weapon count requirement
	if weapons_crafted_required > 0:
		progress += 1
		should_progress = true
	
	# Check weapon type requirement
	if not weapon_type_required.is_empty():
		if config.weapon_type == weapon_type_required:
			progress += 1
			should_progress = true
	
	# Check rarity requirement
	if float(weapon_data.rarity) >= float(minimum_rarity):
		if not should_progress:  ## Don't double-count
			progress += 1
			should_progress = true
	
	# Check specific parts requirement
	if specific_parts_required.size() > 0:
		var has_all_parts = true
		var config_parts = _get_config_part_ids(config)
		
		for part_id in specific_parts_required:
			if part_id not in config_parts:
				has_all_parts = false
				break
		
		if has_all_parts:
			if not should_progress:
				progress += 1
				should_progress = true
	
	# Check specific gems requirement
	if specific_gems_required.size() > 0:
		var config_gems = config.gems.map(func(g): return g.item_id)
		var has_all_gems = true
		
		for gem_id in specific_gems_required:
			if gem_id not in config_gems:
				has_all_gems = false
				break
		
		if has_all_gems:
			if not should_progress:
				progress += 1
				should_progress = true
	
	# Check if should unlock
	if should_progress and _check_unlock_conditions():
		unlock()
		return true
	
	return should_progress

## Check recipe discovery progress
func check_recipe_discovery(recipe_count: int) -> bool:
	if is_unlocked or recipes_discovered_required == 0:
		return false
	
	if recipe_count >= recipes_discovered_required:
		progress = recipes_discovered_required
		unlock()
		return true
	
	progress = recipe_count
	return false

## Check if achievement should be unlocked
func _check_unlock_conditions() -> bool:
	# Check weapon count
	if weapons_crafted_required > 0 and progress < weapons_crafted_required:
		return false
	
	# Check recipe discovery (handled separately)
	if recipes_discovered_required > 0 and progress < recipes_discovered_required:
		return false
	
	return true

## Unlock the achievement
func unlock() -> void:
	if is_unlocked:
		return
	
	is_unlocked = true
	unlocked_time = Time.get_unix_time_from_system()
	
	print("Achievement Unlocked: %s" % achievement_name)
	
	# Give rewards
	_give_rewards()

func _give_rewards() -> void:
	# Give experience reward
	if experience_reward > 0:
		# This would interface with the skill/leveling system
		SkillManager.add_experience(experience_reward)
		print("Awarded %d experience from achievement!" % experience_reward)
	
	# Give gold reward
	if gold_reward > 0 and SaveManager:
		SaveManager.add_gold(gold_reward)
		print("Awarded %d gold from achievement!" % gold_reward)
	
	# Unlock recipes
	for recipe_id in unlocks_recipe_ids:
		var recipe = CraftingRecipeManager.get_recipe(recipe_id)
		if recipe:
			recipe.discover()
			print("Unlocked recipe: %s" % recipe.recipe_name)

## Get progress as percentage
func get_progress_percentage() -> float:
	var target = get_target_value()
	if target == 0:
		return 100.0 if is_unlocked else 0.0
	
	return float(progress) / float(target) * 100.0

## Get target value for progress calculation
func get_target_value() -> int:
	if weapons_crafted_required > 0:
		return weapons_crafted_required
	elif recipes_discovered_required > 0:
		return recipes_discovered_required
	else:
		return 1  ## Single event achievements

## Get progress text for UI
func get_progress_text() -> String:
	if is_unlocked:
		return "Completed!"
	
	var target = get_target_value()
	if target == 0:
		return "In progress..."
	
	return "%d / %d" % [progress, target]

## Get formatted requirement text
func get_requirements_text() -> String:
	var requirements = []
	
	if weapons_crafted_required > 0:
		requirements.append("Craft %d weapons" % weapons_crafted_required)
	
	if not weapon_type_required.is_empty():
		requirements.append("Craft a %s" % weapon_type_required)
	
	if minimum_rarity != Enums.Rarity.BASIC:
		requirements.append("Craft a %s rarity weapon" % Enums.Rarity.keys()[minimum_rarity])
	
	if specific_parts_required.size() > 0:
		var parts_text = []
		for part_id in specific_parts_required:
			var item = ItemDatabase.get_item(part_id)
			if item:
				parts_text.append(item.item_name)
		if parts_text.size() > 0:
			requirements.append("Use parts: %s" % ", ".join(parts_text))
	
	if specific_gems_required.size() > 0:
		var gems_text = []
		for gem_id in specific_gems_required:
			var item = ItemDatabase.get_item(gem_id)
			if item:
				gems_text.append(item.item_name)
		if gems_text.size() > 0:
			requirements.append("Use gems: %s" % ", ".join(gems_text))
	
	if recipes_discovered_required > 0:
		requirements.append("Discover %d recipes" % recipes_discovered_required)
	
	if requirements.size() == 0:
		return "Complete the requirement"
	
	return requirements[0] if requirements.size() == 1 else "Multiple requirements"

## Get formatted reward text
func get_rewards_text() -> String:
	var rewards = []
	
	if experience_reward > 0:
		rewards.append("%d XP" % experience_reward)
	
	if gold_reward > 0:
		rewards.append("%d Gold" % gold_reward)
	
	if unlocks_recipe_ids.size() > 0:
		var recipe_count = unlocks_recipe_ids.size()
		rewards.append("%d Recipe%s" % [recipe_count, "s" if recipe_count != 1 else ""])
	
	if rewards.size() == 0:
		return "No rewards"
	
	return "Rewards: " + ", ".join(rewards)

## Get rarity color for UI
func get_rarity_color() -> Color:
	return Constants.RARITY_COLORS.get(rarity, Color.WHITE)

## Helper to get part IDs from configuration
func _get_config_part_ids(config: WeaponConfiguration) -> Array[String]:
	var part_ids = []
	
	if config.head:
		part_ids.append(config.head.item_id)
	if config.exterior:
		part_ids.append(config.exterior.item_id)
	if config.interior:
		part_ids.append(config.interior.item_id)
	if config.handle:
		part_ids.append(config.handle.item_id)
	if config.charm:
		part_ids.append(config.charm.item_id)
	
	return part_ids

## Save achievement state
func get_save_data() -> Dictionary:
	return {
		"achievement_id": achievement_id,
		"is_unlocked": is_unlocked,
		"progress": progress,
		"unlocked_time": unlocked_time,
		"unlock_notification_shown": unlock_notification_shown
	}

## Load achievement state
func load_save_data(data: Dictionary) -> void:
	if data.has("is_unlocked"):
		is_unlocked = data.is_unlocked
	if data.has("progress"):
		progress = data.progress
	if data.has("unlocked_time"):
		unlocked_time = data.unlocked_time
	if data.has("unlock_notification_shown"):
		unlock_notification_shown = data.unlock_notification_shown