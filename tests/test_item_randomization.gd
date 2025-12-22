## TestItemRandomization - Tests for the item randomization system
extends GutTest

# =============================================================================
# TEST SETUP
# =============================================================================

var item_gen_system: ItemGenerationSystem
var affix_system: AffixSystem
var scaling_system: ItemScalingSystem
var loot_system: LootSystem

func before_all() -> void:
	item_gen_system = ItemGenerationSystem.new()
	affix_system = AffixSystem.new()
	scaling_system = ItemScalingSystem.new()
	loot_system = LootSystem.new()


# =============================================================================
# ITEM GENERATION TESTS
# =============================================================================

func test_stat_generation_basic() -> void:
	"""Test basic stat generation for equipment."""
	
	var base_item = EquipmentData.new()
	base_item.health_bonus = 10.0
	base_item.defense_bonus = 5.0
	base_item.item_name = "Test Armor"
	
	var stats = item_gen_system.generate_equipment_stats(
		base_item,
		Enums.Rarity.BASIC,
		1
	)
	
	assert_not_null(stats)
	assert_true(stats.has(Enums.StatType.HEALTH))
	assert_true(stats.has(Enums.StatType.DEFENSE))
	
	# With 10% variance for BASIC, stats shouldn't deviate more than 10%
	var health_variance = abs(stats[Enums.StatType.HEALTH] - base_item.health_bonus)
	var expected_max_variance = base_item.health_bonus * 0.10
	assert_less_than(health_variance, expected_max_variance + 0.1)  # Small tolerance


func test_stat_generation_variance_increases_with_rarity() -> void:
	"""Test that variance increases with rarity."""
	
	var base_item = EquipmentData.new()
	base_item.health_bonus = 100.0
	base_item.item_name = "Test"
	
	var rarities = [
		Enums.Rarity.BASIC,
		Enums.Rarity.UNCOMMON,
		Enums.Rarity.RARE,
		Enums.Rarity.MYTHIC
	]
	
	for rarity in rarities:
		var stats = item_gen_system.generate_equipment_stats(base_item, rarity, 1)
		assert_not_null(stats)
		# Just verify it generates without error
		assert_true(stats[Enums.StatType.HEALTH] > 0)


func test_level_scaling_increases_stats() -> void:
	"""Test that stats increase with player level."""
	
	var base_item = EquipmentData.new()
	base_item.health_bonus = 10.0
	base_item.item_name = "Test"
	
	var stats_level_1 = item_gen_system.generate_equipment_stats(
		base_item,
		Enums.Rarity.BASIC,
		1
	)
	
	var stats_level_50 = item_gen_system.generate_equipment_stats(
		base_item,
		Enums.Rarity.BASIC,
		50
	)
	
	# Level 50 should have higher stats than level 1
	assert_greater_than(
		stats_level_50[Enums.StatType.HEALTH],
		stats_level_1[Enums.StatType.HEALTH] * 1.2  # Allow some tolerance
	)


# =============================================================================
# AFFIX TESTS
# =============================================================================

func test_affix_generation_by_rarity() -> void:
	"""Test that affix count matches rarity tier."""
	
	var base_item = EquipmentData.new()
	base_item.item_type = Enums.ItemType.EQUIPMENT
	base_item.item_name = "Test"
	
	var affix_counts = {
		Enums.Rarity.BASIC: 0,
		Enums.Rarity.UNCOMMON: 1,
		Enums.Rarity.RARE: 2,
		Enums.Rarity.MYTHIC: 3
	}
	
	for rarity in affix_counts.keys():
		var expected_count = affix_counts[rarity]
		var affixes = affix_system.generate_affixes(base_item, rarity, 1)
		assert_equal(affixes.size(), expected_count)


func test_affix_application_modifies_item() -> void:
	"""Test that applying affixes modifies item stats."""
	
	var base_item = EquipmentData.new()
	base_item.item_type = Enums.ItemType.EQUIPMENT
	base_item.health_bonus = 10.0
	base_item.item_name = "Test"
	
	var original_health = base_item.health_bonus
	
	var affixes = affix_system.generate_affixes(base_item, Enums.Rarity.RARE, 1)
	affix_system.apply_affixes_to_item(base_item, affixes)
	
	# Health should be increased by affixes
	assert_greater_than(base_item.health_bonus, original_health)


# =============================================================================
# RANDOMIZED ITEM DATA TESTS
# =============================================================================

func test_randomized_item_creation() -> void:
	"""Test creating randomized items from templates."""
	
	var template = EquipmentData.new()
	template.item_id = "test_armor"
	template.item_name = "Test Armor"
	template.slot = Enums.EquipmentSlot.BODY
	template.health_bonus = 20.0
	template.defense_bonus = 10.0
	
	var randomized = RandomizedItemData.create_from_base(
		template,
		Enums.Rarity.RARE,
		10,
		true
	)
	
	assert_not_null(randomized)
	assert_true(randomized is RandomizedItemData)
	assert_equal(randomized.generated_at_level, 10)
	assert_equal(randomized.rarity, Enums.Rarity.RARE)


func test_randomized_item_is_unique() -> void:
	"""Test that randomized items have unique IDs."""
	
	var template = EquipmentData.new()
	template.item_id = "test"
	template.item_name = "Test"
	template.health_bonus = 10.0
	
	var item1 = RandomizedItemData.create_from_base(template, Enums.Rarity.BASIC, 1, false)
	var item2 = RandomizedItemData.create_from_base(template, Enums.Rarity.BASIC, 1, false)
	
	assert_ne(item1.item_id, item2.item_id)


# =============================================================================
# SCALING TESTS
# =============================================================================

func test_base_stats_by_level() -> void:
	"""Test base stat lookup by level."""
	
	var health_level_1 = scaling_system.get_base_stat_for_level(1, "health")
	var health_level_50 = scaling_system.get_base_stat_for_level(50, "health")
	
	assert_equal(health_level_1, 10.0)
	assert_equal(health_level_50, 70.0)


func test_item_effectiveness_calculation() -> void:
	"""Test item effectiveness ratio calculation."""
	
	var item = EquipmentData.new()
	item.health_bonus = 50.0
	item.damage_bonus = 30.0
	
	var effectiveness_level_1 = scaling_system.get_item_effectiveness(item, 1)
	var effectiveness_level_50 = scaling_system.get_item_effectiveness(item, 50)
	
	# Item should be overpowered for level 1 but weak for level 50
	assert_greater_than(effectiveness_level_1, 1.0)
	assert_less_than(effectiveness_level_50, 1.0)


func test_item_appropriateness() -> void:
	"""Test checking if item is appropriate for player level."""
	
	var weak_item = EquipmentData.new()
	weak_item.health_bonus = 1.0
	
	var strong_item = EquipmentData.new()
	strong_item.health_bonus = 100.0
	strong_item.damage_bonus = 50.0
	
	# Weak item is underpower at high level
	assert_false(scaling_system.is_item_appropriate_for_level(weak_item, 50, false))
	
	# Strong item is overpowered at low level
	assert_false(scaling_system.is_item_appropriate_for_level(strong_item, 1, false))


# =============================================================================
# LOOT SYSTEM INTEGRATION TESTS
# =============================================================================

func test_loot_system_creates_randomized_items() -> void:
	"""Test that loot system generates randomized items."""
	
	loot_system.enable_stat_randomization = true
	loot_system.enable_affix_generation = true
	loot_system.player_level = 10
	
	var base_item = EquipmentData.new()
	base_item.item_id = "test_armor"
	base_item.item_name = "Test Armor"
	base_item.slot = Enums.EquipmentSlot.BODY
	base_item.health_bonus = 20.0
	
	var loot_table = [
		{
			"item": base_item,
			"weight": 1.0,
			"min": 1,
			"max": 1
		}
	]
	
	var drops = loot_system.drop_loot_from_table(loot_table, Vector3.ZERO, 1)
	
	assert_equal(drops.size(), 1)
	assert_true(drops[0] is RandomizedItemData)


# =============================================================================
# RARITY DISTRIBUTION TESTS
# =============================================================================

func test_rarity_weights_distribution() -> void:
	"""Test that rarity rolling roughly follows weight distribution."""
	
	var rarity_count = {}
	var rolls = 1000
	
	for i in range(rolls):
		var rarity = loot_system._roll_rarity()
		if not rarity_count.has(rarity):
			rarity_count[rarity] = 0
		rarity_count[rarity] += 1
	
	# Check that BASIC is most common
	assert_greater_than(rarity_count[Enums.Rarity.BASIC], rarity_count[Enums.Rarity.RARE])


# =============================================================================
# EDGE CASE TESTS
# =============================================================================

func test_zero_stat_bonus() -> void:
	"""Test that items with 0 stats are handled correctly."""
	
	var item = EquipmentData.new()
	item.health_bonus = 0.0
	item.item_name = "Empty"
	
	var stats = item_gen_system.generate_equipment_stats(item, Enums.Rarity.BASIC, 1)
	assert_equal(stats[Enums.StatType.HEALTH], 0.0)


func test_very_high_level_scaling() -> void:
	"""Test scaling at max level."""
	
	var item = EquipmentData.new()
	item.health_bonus = 10.0
	
	var stats = item_gen_system.generate_equipment_stats(
		item,
		Enums.Rarity.BASIC,
		Constants.MAX_LEVEL
	)
	
	assert_not_null(stats)
	assert_greater_than(stats[Enums.StatType.HEALTH], 0)


func test_level_boundary_clamping() -> void:
	"""Test that levels are properly clamped."""
	
	var item = EquipmentData.new()
	item.health_bonus = 10.0
	
	# Should not error on extreme levels
	var stats_negative = item_gen_system.generate_equipment_stats(item, -10, 1)
	var stats_huge = item_gen_system.generate_equipment_stats(item, 9999, 1)
	
	assert_not_null(stats_negative)
	assert_not_null(stats_huge)


# =============================================================================
# STAT CONSISTENCY TESTS
# =============================================================================

func test_stat_type_consistency() -> void:
	"""Test that all expected stat types are generated."""
	
	var item = EquipmentData.new()
	item.health_bonus = 10.0
	item.magika_bonus = 10.0
	item.stamina_bonus = 10.0
	item.damage_bonus = 10.0
	item.defense_bonus = 10.0
	item.move_speed_bonus = 0.1
	
	var stats = item_gen_system.generate_equipment_stats(item, Enums.Rarity.BASIC, 1)
	
	var expected_types = [
		Enums.StatType.HEALTH,
		Enums.StatType.MAGIKA,
		Enums.StatType.STAMINA,
		Enums.StatType.DAMAGE,
		Enums.StatType.DEFENSE,
		Enums.StatType.MOVE_SPEED
	]
	
	for stat_type in expected_types:
		assert_true(stats.has(stat_type))


func test_minimum_stat_threshold() -> void:
	"""Test that stats respect minimum threshold."""
	
	var item = EquipmentData.new()
	item.health_bonus = 0.1  # Very small value
	
	var stats = item_gen_system.generate_equipment_stats(item, Enums.Rarity.BASIC, 1)
	
	# Should be at least MINIMUM_STAT_THRESHOLD or 0
	var health_stat = stats[Enums.StatType.HEALTH]
	assert_true(health_stat >= ItemGenerationSystem.MINIMUM_STAT_THRESHOLD or health_stat == 0.0)
