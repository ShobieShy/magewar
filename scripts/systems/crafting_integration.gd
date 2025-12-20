## CraftingIntegration - Integration layer between Assembly UI and Crafting Logic
## Handles communication between UI and crafting systems
extends Node

signal crafting_complete(weapon: ItemData)
signal crafting_failed(error: String)

# Reference to main systems
var crafting_logic: CraftingLogic
var assembly_ui: Control
var inventory_system: InventorySystem

func _ready() -> void:
	# Get or create crafting logic
	crafting_logic = get_node_or_null("/root/CraftingLogic")
	if not crafting_logic:
		crafting_logic = CraftingLogic.new()
		get_tree().root.add_child(crafting_logic)
	
	# Connect signals
	crafting_logic.crafting_completed.connect(_on_crafting_completed)
	crafting_logic.crafting_failed.connect(_on_crafting_failed)
	
	# Get inventory system
	inventory_system = get_node_or_null("/root/InventorySystem")

## Initialize with Assembly UI
func initialize(assembly_ui_control: Control) -> void:
	assembly_ui = assembly_ui_control
	
	# Connect assembly UI signals
	if assembly_ui.has_signal("item_crafted"):
		assembly_ui.item_crafted.connect(_on_assembly_item_crafted)

## Handle Assembly UI crafting request
func _on_assembly_item_crafted(item_type: String) -> void:
	if not assembly_ui:
		return
	
	# Get current configuration from Assembly UI
	var config = _extract_configuration_from_ui()
	if not config:
		crafting_failed.emit("Invalid weapon configuration")
		return
	
	# Get player level
	var player_level = 1
	if SaveManager and SaveManager.player_data:
		player_level = SaveManager.player_data.get("level", 1)
	
	# Start crafting through CraftingLogic
	if not crafting_logic.start_crafting(config, player_level):
		# Crafting logic will emit failure signal
		pass

## Extract configuration from Assembly UI
func _extract_configuration_from_ui() -> WeaponConfiguration:
	if not assembly_ui:
		return null
	
	# This would extract the current parts and gems from the UI
	# For now, create a test configuration
	var config = WeaponConfiguration.new()
	
	# Get selected parts from UI (this would be implemented in AssemblyUI)
	var selected_parts = _get_selected_parts_from_ui()
	var selected_gems = _get_selected_gems_from_ui()
	
	# Configure based on UI state
	config.weapon_type = "staff" if _get_current_tab() == 0 else "wand"
	
	# Add parts
	for part in selected_parts:
		config.add_part(part)
	
	# Add gems
	for gem in selected_gems:
		config.add_gem(gem)
	
	return config

## Get selected parts from UI
func _get_selected_parts_from_ui() -> Array[StaffPartData]:
	var parts: Array[StaffPartData] = []
	
	# This would extract actual parts from Assembly UI slots
	# For now, return empty (AssemblyUI would implement this method)
	return parts

## Get selected gems from UI
func _get_selected_gems_from_ui() -> Array[GemData]:
	var gems: Array[GemData] = []
	
	# This would extract actual gems from Assembly UI slots
	# For now, return empty (AssemblyUI would implement this method)
	return gems

## Get current tab from UI
func _get_current_tab() -> int:
	# This would get the current tab from Assembly UI
	# For now, return 0 (staff tab)
	return 0

## Handle crafting completion
func _on_crafting_completed(weapon: ItemData, success: bool) -> void:
	if success and weapon:
		crafting_complete.emit(weapon)
		
		# Show success feedback in UI
		if assembly_ui:
			_show_crafting_success(weapon)
	else:
		crafting_failed.emit("Crafting failed")

## Handle crafting failure
func _on_crafting_failed(error: String) -> void:
	crafting_failed.emit(error)
	
	# Show error feedback in UI
	if assembly_ui:
		_show_crafting_error(error)

## Show crafting success in UI
func _show_crafting_success(weapon: ItemData) -> void:
	if not assembly_ui:
		return
	
	# This would show success animation/effects in AssemblyUI
	# AssemblyUI would have methods for showing success
	print("Crafting Success: %s" % weapon.item_name)

## Show crafting error in UI
func _show_crafting_error(error: String) -> void:
	if not assembly_ui:
		return
	
	# This would show error message in AssemblyUI
	print("Crafting Error: %s" % error)

## Get crafting status for UI updates
func get_crafting_status() -> Dictionary:
	if not crafting_logic:
		return {"is_crafting": false}
	
	return {
		"is_crafting": crafting_logic.is_crafting(),
		"progress": crafting_logic.get_crafting_progress(),
		"time_remaining": crafting_logic.get_crafting_time_remaining()
	}

## Cancel current crafting operation
func cancel_crafting() -> bool:
	if not crafting_logic:
		return false
	
	return crafting_logic.cancel_crafting()

## Get crafting statistics for UI display
func get_crafting_statistics() -> Dictionary:
	if not crafting_logic:
		return {}
	
	return crafting_logic.get_crafting_stats()

## Get recipe manager for recipe UI
func get_recipe_manager() -> CraftingRecipeManager:
	if not crafting_logic:
		return null
	
	return crafting_logic.get_recipe_manager()

## Get achievement manager for achievement UI
func get_achievement_manager() -> CraftingAchievementManager:
	if not crafting_logic:
		return null
	
	return crafting_logic.get_achievement_manager()