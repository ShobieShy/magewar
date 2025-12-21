## SaveManagerExtension - Extends SaveManager with crafting-specific methods
## Adds data storage methods for crafting system
extends Node

# Extensions to SaveManager for crafting data

func add_gold(amount: int) -> void:
	## Add gold to player data
	if not SaveManager or not SaveManager.player_data:
		return

	if not SaveManager.player_data.has("gold"):
		SaveManager.player_data.gold = 0

	SaveManager.player_data.gold += amount
	SaveManager.gold_changed.emit(SaveManager.player_data.gold, amount)

func set_crafting_progress(weapon_name: String, completed: bool = true) -> void:
	## Save crafting progress for a specific weapon
	if not SaveManager or not SaveManager.player_data:
		return

	if not SaveManager.player_data.has("crafting_progress"):
		SaveManager.player_data.crafting_progress = {}

	SaveManager.player_data.crafting_progress[weapon_name] = {
		"completed": completed,
		"timestamp": Time.get_unix_time_from_system()
	}

func get_crafting_progress(weapon_name: String) -> Dictionary:
	## Get crafting progress for a specific weapon
	if not SaveManager or not SaveManager.player_data:
		return {}

	if not SaveManager.player_data.has("crafting_progress"):
		return {}

	return SaveManager.player_data.crafting_progress.get(weapon_name, {})

func set_data(key: String, data: Variant) -> void:
	## Set custom data in player data
	if SaveManager and SaveManager.player_data:
		SaveManager.player_data[key] = data

func get_data(key: String) -> Variant:
	## Get custom data from player data
	if SaveManager and SaveManager.player_data:
		return SaveManager.player_data.get(key, null)
	return null

func get_gold() -> int:
	## Get current gold amount
	if SaveManager and SaveManager.player_data:
		return SaveManager.player_data.get("gold", 0)
	return 0

func has_item(_item_id: String) -> bool:
	## Check if player has an item (simplified)
	# This would integrate with InventorySystem
	return false  # Placeholder

func get_player_level() -> int:
	## Get player level
	if SaveManager and SaveManager.player_data:
		return SaveManager.player_data.get("level", 1)
	return 1