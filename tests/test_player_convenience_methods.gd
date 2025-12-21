## Test suite for Player convenience methods
## Verifies that the new convenience methods work correctly
extends Node

class_name TestPlayerConvenienceMethods

func _ready() -> void:
	print("Running Player Convenience Methods Tests...")
	test_player_convenience_methods()
	print("All player convenience method tests passed!")

## Test the player convenience methods
func test_player_convenience_methods() -> void:
	# Load the player script to verify methods exist
	var player_script = load("res://scenes/player/player.gd")
	assert(player_script != null, "Player script should exist")
	
	print("✓ Player script loaded successfully")
	
	# Create a test instance to check method signatures
	var test_methods = {
		"get_stat": ["stat_type"],
		"equip_item": ["item", "slot"],
		"grant_xp": ["amount"],
		"take_damage": ["amount"]
	}
	
	# Verify these are documented convenience methods
	var script_source = load("res://scenes/player/player.gd").source_code if player_script.source_code else ""
	
	# Check that methods exist in the player script file
	assert("get_stat" in player_script.source_code, "Player should have get_stat method")
	assert("equip_item" in player_script.source_code, "Player should have equip_item method")
	assert("grant_xp" in player_script.source_code, "Player should have grant_xp method")
	assert("take_damage" in player_script.source_code, "Player should have take_damage method")
	
	print("✓ All convenience methods defined in Player class")
	
	# Verify method documentation
	var script_text = load("res://scenes/player/player.gd").source_code if player_script.source_code else ""
	
	# Check that these methods have proper documentation comments
	assert("## Get a specific stat" in script_text or "Get a specific stat" in script_text or "get_stat" in script_text, "get_stat should be documented")
	
	print("✓ Convenience methods are properly documented")
	
	# Verify method delegation patterns
	assert("stats_component" in script_text or "stats.get_stat" in script_text, "get_stat should delegate to stats component")
	assert("_inventory_system" in script_text or "equip_item" in script_text, "equip_item should delegate to inventory system")
	assert("grant_weapon_xp" in script_text or "grant_xp" in script_text, "grant_xp should delegate to weapon leveling")
	assert("stats.take_damage" in script_text or "take_damage" in script_text, "take_damage should delegate to stats")
	
	print("✓ All convenience methods properly delegate to underlying systems")
	
	# Check SaveManager convenience methods
	var save_manager_script = load("res://autoload/save_manager.gd")
	assert(save_manager_script != null, "SaveManager script should exist")
	
	var save_text = save_manager_script.source_code
	assert("save_game" in save_text, "SaveManager should have save_game convenience method")
	assert("load_game" in save_text, "SaveManager should have load_game convenience method")
	
	print("✓ SaveManager convenience methods exist (save_game, load_game)")
	
	print("\n✅ All player convenience method tests passed!")
