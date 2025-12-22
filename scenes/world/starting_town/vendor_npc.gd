## Vendor NPC - Shop keeper that opens shop on interaction
## Simple merchant that sells and buys items
extends NPC

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var vendor_shop_id: String = "town_shop"

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	npc_name = "Merchant"
	npc_id = "vendor"
	interaction_prompt = "[E] Shop with %s" % npc_name
	open_shop_on_dialogue_end = true
	shop_id = vendor_shop_id
	
	# Basic introduction dialogue
	dialogue_lines = [
		"Welcome, adventurer! Looking for supplies?",
		"I have a fine selection of potions, weapons, and more.",
		"Take a look around!"
	]
	
	super._ready()
