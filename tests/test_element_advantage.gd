## Test suite for Element Advantage system
## Verifies that element advantage calculations work correctly
extends Node

class_name TestElementAdvantage

func _ready() -> void:
	print("Running Element Advantage Tests...")
	test_element_advantage_system()
	print("All tests passed!")

## Test the element advantage system
func test_element_advantage_system() -> void:
	# We need to create a SpellCaster to test
	var spell_caster = Node.new()
	spell_caster.set_script(load("res://scripts/components/spell_caster.gd"))
	
	# Check that the methods exist
	assert(spell_caster.has_method("get_element_advantage"), "SpellCaster should have get_element_advantage method")
	assert(spell_caster.has_method("apply_element_advantage"), "SpellCaster should have apply_element_advantage method")
	
	print("✓ Element advantage methods exist")
	
	# Test rock-paper-scissors matchups
	# FIRE beats AIR, loses to WATER
	var fire_vs_air = spell_caster.get_element_advantage(Enums.Element.FIRE, Enums.Element.AIR)
	assert(fire_vs_air == Constants.ELEMENT_ADVANTAGE, "FIRE should have advantage vs AIR")
	
	var fire_vs_water = spell_caster.get_element_advantage(Enums.Element.FIRE, Enums.Element.WATER)
	assert(fire_vs_water == Constants.ELEMENT_DISADVANTAGE, "FIRE should have disadvantage vs WATER")
	
	print("✓ FIRE element matchups correct (beats AIR, loses to WATER)")
	
	# AIR beats EARTH, loses to FIRE
	var air_vs_earth = spell_caster.get_element_advantage(Enums.Element.AIR, Enums.Element.EARTH)
	assert(air_vs_earth == Constants.ELEMENT_ADVANTAGE, "AIR should have advantage vs EARTH")
	
	var air_vs_fire = spell_caster.get_element_advantage(Enums.Element.AIR, Enums.Element.FIRE)
	assert(air_vs_fire == Constants.ELEMENT_DISADVANTAGE, "AIR should have disadvantage vs FIRE")
	
	print("✓ AIR element matchups correct (beats EARTH, loses to FIRE)")
	
	# EARTH beats WATER, loses to AIR
	var earth_vs_water = spell_caster.get_element_advantage(Enums.Element.EARTH, Enums.Element.WATER)
	assert(earth_vs_water == Constants.ELEMENT_ADVANTAGE, "EARTH should have advantage vs WATER")
	
	var earth_vs_air = spell_caster.get_element_advantage(Enums.Element.EARTH, Enums.Element.AIR)
	assert(earth_vs_air == Constants.ELEMENT_DISADVANTAGE, "EARTH should have disadvantage vs AIR")
	
	print("✓ EARTH element matchups correct (beats WATER, loses to AIR)")
	
	# WATER beats FIRE, loses to EARTH
	var water_vs_fire = spell_caster.get_element_advantage(Enums.Element.WATER, Enums.Element.FIRE)
	assert(water_vs_fire == Constants.ELEMENT_ADVANTAGE, "WATER should have advantage vs FIRE")
	
	var water_vs_earth = spell_caster.get_element_advantage(Enums.Element.WATER, Enums.Element.EARTH)
	assert(water_vs_earth == Constants.ELEMENT_DISADVANTAGE, "WATER should have disadvantage vs EARTH")
	
	print("✓ WATER element matchups correct (beats FIRE, loses to EARTH)")
	
	# LIGHT and DARK are neutral to each other
	var light_vs_dark = spell_caster.get_element_advantage(Enums.Element.LIGHT, Enums.Element.DARK)
	assert(light_vs_dark == 1.0, "LIGHT should be neutral vs DARK")
	
	var dark_vs_light = spell_caster.get_element_advantage(Enums.Element.DARK, Enums.Element.LIGHT)
	assert(dark_vs_light == 1.0, "DARK should be neutral vs LIGHT")
	
	print("✓ LIGHT/DARK neutral matchups correct")
	
	# Test damage application
	var base_damage = 100.0
	var advantaged = spell_caster.apply_element_advantage(base_damage, Enums.Element.FIRE, Enums.Element.AIR)
	assert(advantaged == 125.0, "Advantage should multiply by 1.25")
	
	var disadvantaged = spell_caster.apply_element_advantage(base_damage, Enums.Element.FIRE, Enums.Element.WATER)
	assert(disadvantaged == 75.0, "Disadvantage should multiply by 0.75")
	
	var neutral = spell_caster.apply_element_advantage(base_damage, Enums.Element.LIGHT, Enums.Element.DARK)
	assert(neutral == 100.0, "Neutral should remain 1.0 multiplier")
	
	print("✓ Damage application calculations correct")
	
	# Test neutral cases
	var none_vs_fire = spell_caster.get_element_advantage(Enums.Element.NONE, Enums.Element.FIRE)
	assert(none_vs_fire == 1.0, "NONE element should be neutral")
	
	var fire_vs_none = spell_caster.get_element_advantage(Enums.Element.FIRE, Enums.Element.NONE)
	assert(fire_vs_none == 1.0, "vs NONE element should be neutral")
	
	print("✓ NONE element neutral cases correct")
	
	print("\n✅ All element advantage tests passed!")
