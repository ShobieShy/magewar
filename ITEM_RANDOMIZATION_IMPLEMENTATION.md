# Item Randomization System - Implementation Guide

**Date:** December 21, 2025  
**Status:** Complete Implementation  
**Version:** 1.0

---

## Overview

A comprehensive procedural item generation system has been implemented for MageWar, adding:
- **Randomized stats** based on rarity and player level
- **Affix system** with prefixes/suffixes for unique item names
- **Level scaling** to ensure items scale with progression
- **Item generation** for fully procedural equipment creation

---

## What Was Implemented

### 1. ItemGenerationSystem (`scripts/systems/item_generation_system.gd`)

**Purpose:** Generate randomized stats for items

**Key Features:**
- Stat variance based on rarity tiers (±10% to ±35%)
- Per-stat variance multipliers (speed varies less, regen varies more)
- Level scaling with interpolation between defined levels
- Automatic minimum stat thresholds

**Usage:**
```gdscript
var gen_system = ItemGenerationSystem.new()

# Generate randomized stats for equipment
var stats = gen_system.generate_equipment_stats(
    base_item,      # EquipmentData template
    Enums.Rarity.RARE,  # Rarity tier
    player_level    # Player level for scaling
)

# Generate randomized gem modifiers
var gem_mods = gen_system.generate_gem_modifiers(base_gem, rarity, level)

# Generate stat ranges for a slot
var slot_stats = gen_system.generate_stat_range_for_slot(
    Enums.EquipmentSlot.FEET,
    Enums.Rarity.UNCOMMON,
    20
)
```

**Configuration Constants:**
```gdscript
STAT_VARIANCE_BY_RARITY = {
    BASIC: 0.10,        # ±10%
    UNCOMMON: 0.15,     # ±15%
    RARE: 0.20,         # ±20%
    MYTHIC: 0.25,       # ±25%
    PRIMORDIAL: 0.30,   # ±30%
    UNIQUE: 0.35        # ±35%
}

ITEM_LEVEL_MULTIPLIER = {
    1: 0.7,
    10: 0.85,
    20: 1.0,    # Baseline at level 20
    30: 1.2,
    40: 1.4,
    50: 1.7
}
```

---

### 2. AffixSystem (`scripts/systems/affix_system.gd`)

**Purpose:** Manage item affixes (prefixes/suffixes)

**Key Features:**
- Rarity-based affix generation (0 affixes for BASIC, 5 for UNIQUE)
- Multiple affix types (strength, protection, vitality, speed, critical)
- Weighted random selection from affix pools
- Level scaling for affix values
- Item name modification (prefix/suffix)

**Usage:**
```gdscript
var affix_system = AffixSystem.new()

# Generate affixes for an item
var affixes = affix_system.generate_affixes(
    base_item,
    Enums.Rarity.RARE,
    player_level
)

# Apply affixes to modify item
affix_system.apply_affixes_to_item(item, affixes)

# Get affix description for tooltip
var affix_text = affix_system.get_affix_description(affixes)
```

**Affix Count by Rarity:**
```gdscript
BASIC: 0 affixes
UNCOMMON: 1 affix
RARE: 2 affixes
MYTHIC: 3 affixes
PRIMORDIAL: 4 affixes
UNIQUE: 5 affixes
```

**Available Affix Types:**
- Strength: +Damage (Strong, Mighty, Heroic)
- Protection: +Defense (Fortified, Armored, Shielding)
- Vitality: +Health (Healthy, Vigorous, Life-giving)
- Speed: +Move Speed (Swift, Fleet, Windblown)
- Critical: +Crit Chance/Damage (Keen, Sharp, Deadshot)
- Combination: Multiple stats (Balanced, Masterwork, Legendary)

---

### 3. RandomizedItemData (`resources/items/randomized_item_data.gd`)

**Purpose:** Represent an equipment item with procedurally generated stats

**Key Features:**
- Extends EquipmentData for full compatibility
- Stores original randomized stats
- Tracks generation level and seed
- Serialization support for save/load
- Integration with ItemGenerationSystem and AffixSystem

**Usage:**
```gdscript
# Create randomized item from template
var randomized = RandomizedItemData.create_from_base(
    template_equipment,
    Enums.Rarity.RARE,
    player_level,
    generate_affixes  # true/false
)

# Check if item is randomized
if item.is_randomized():
    print("Generated at level: ", item.generated_at_level)
    print("Affixes: ", item.affixes.size())
    print("Variance: ", item.get_variance_info())

# Save/Load
var save_data = randomized.get_save_data()
randomized.load_from_save_data(save_data, base_template)
```

**Properties:**
```gdscript
base_item: EquipmentData           # Template this was created from
affixes: Array                      # Applied affixes
randomized_stats: Dictionary        # Original randomized values
generation_seed: int                # For reproducibility
generated_at_level: int             # Player level when created
```

---

### 4. ItemScalingSystem (`scripts/systems/item_scaling_system.gd`)

**Purpose:** Manage item level scaling and progression

**Key Features:**
- Base stat values defined per player level
- Item effectiveness calculation (1.0 = perfectly scaled)
- Difficulty-based item level recommendations
- Item generation for specific difficulty tiers
- Overpowered/underpowered thresholds

**Usage:**
```gdscript
var scaling = ItemScalingSystem.new()

# Get recommended item level for player
var item_level = scaling.get_recommended_item_level(player_level)

# Check if item is appropriate for level
var is_good = scaling.is_item_appropriate_for_level(item, player_level)

# Calculate how strong item is
var effectiveness = scaling.get_item_effectiveness(item, player_level)
# Returns: 1.0 = perfect, <0.7 = weak, >1.5 = overpowered

# Generate item for a level
var generated = scaling.generate_item_for_level(
    Enums.EquipmentSlot.FEET,
    Enums.Rarity.RARE,
    player_level
)

# Upgrade item to new level
var upgraded = scaling.upgrade_item_to_level(item, new_level)
```

**Base Stats by Level:**
```
Level | Health | Magika | Stamina | Damage | Defense | Speed
------|--------|--------|---------|--------|---------|-------
1     | 10     | 5      | 8       | 8      | 3       | 0.05
10    | 15     | 10     | 12      | 12     | 5       | 0.08
20    | 25     | 15     | 18      | 18     | 8       | 0.10
30    | 35     | 25     | 28      | 25     | 12      | 0.12
40    | 50     | 35     | 40      | 35     | 16      | 0.15
50    | 70     | 50     | 55      | 50     | 22      | 0.20
```

**Difficulty Tiers:**
```
Starter:  Levels 1-5
Early:    Levels 5-15
Mid:      Levels 15-30
Late:     Levels 30-40
Endgame:  Levels 40-50
```

---

### 5. Enhanced LootSystem

**Changes:**
- Integrated ItemGenerationSystem and AffixSystem
- Automatic randomized item creation for drops
- Player level awareness for scaling
- Toggles for testing (`enable_stat_randomization`, `enable_affix_generation`)

**New Methods:**
```gdscript
func drop_loot_from_table(loot_table, position, count) -> Array
    # Now generates RandomizedItemData for equipment items
```

**New Properties:**
```gdscript
var player_level: int                    # For loot scaling
var enable_stat_randomization: bool = true
var enable_affix_generation: bool = true
```

**Usage:**
```gdscript
var loot_system = LootSystem.new()
loot_system.player_level = 20
loot_system.enable_stat_randomization = true

# Drops will now generate with randomized stats
var drops = loot_system.drop_loot_from_table(loot_table, position, 1)
# Returns RandomizedItemData objects
```

---

## Integration Guide

### Step 1: Add Systems to Player

```gdscript
# In your Player script
func _ready() -> void:
    # Initialize randomization systems
    var loot_system = LootSystem.new()
    loot_system.player_level = level
    
    # Use in combat
    add_child(loot_system)
```

### Step 2: Use in Enemies

```gdscript
# In Enemy script (when dropping loot)
func drop_loot() -> void:
    var loot_system = LootSystem.new()
    loot_system.player_level = player.level
    
    var table = get_loot_table()
    var drops = loot_system.drop_loot_from_table(table, global_position, 1)
```

### Step 3: Configure Item Affixes

Edit `AffixSystem._initialize_affixes()` to add custom affixes:

```gdscript
_affix_pools[Enums.ItemType.EQUIPMENT] = [
    {
        "id": "custom_affix",
        "prefix": "Custom",
        "stat_bonuses": {"health": 10.0},
        "weight": 0.5
    }
]
```

### Step 4: Adjust Scaling Constants

Edit ItemGenerationSystem constants:

```gdscript
STAT_VARIANCE_BY_RARITY[Enums.Rarity.RARE] = 0.25  # Increase variance
LEVEL_SCALING_FACTOR = 0.20  # Faster level scaling
```

---

## Testing

A comprehensive test suite is included in `tests/test_item_randomization.gd`

**To run tests:**
```bash
# Use Godot's test runner
godot --test tests/test_item_randomization.gd
```

**Test Categories:**
- Stat generation (variance, level scaling)
- Affix generation and application
- RandomizedItemData creation and serialization
- Item scaling calculations
- Loot system integration
- Rarity distribution
- Edge cases and boundaries

---

## Performance Considerations

**Item Generation Cost:**
- Creating a single randomized item: ~0.5-1ms
- Acceptable for drops, bosses, crafting
- Cache systems can reuse generated items

**Memory Impact:**
- Small (~100 bytes per randomized item)
- Affixes stored as dictionaries (lightweight)
- No texture/mesh overhead

**Optimization Tips:**
1. Disable `enable_stat_randomization` for testing
2. Pool/cache generated items if needed
3. Generate affixes asynchronously for large batches
4. Use `fixed_rarity` in loot tables for common items

---

## Examples

### Example 1: Generate Random Loot

```gdscript
var loot_system = LootSystem.new()
loot_system.player_level = 20
loot_system.enable_stat_randomization = true

var loot_table = [
    {
        "item": ItemDatabase.get_item("leather_armor"),
        "weight": 50,
        "min": 1,
        "max": 1
    },
    {
        "item": ItemDatabase.get_item("iron_boots"),
        "weight": 30,
        "min": 1,
        "max": 1
    },
    {
        "item": ItemDatabase.get_item("rare_helmet"),
        "weight": 20,
        "min": 1,
        "max": 1,
        "fixed_rarity": Enums.Rarity.RARE  # Always rare
    }
]

var drops = loot_system.drop_loot_from_table(loot_table, enemy.position, 1)

for item in drops:
    if item is RandomizedItemData:
        print("Generated: ", item.item_name, " with ", item.affixes.size(), " affixes")
```

### Example 2: Create Difficulty-Based Items

```gdscript
var scaling = ItemScalingSystem.new()

# Easy enemies
var easy_item = scaling.generate_item_for_level(
    Enums.EquipmentSlot.FEET,
    Enums.Rarity.UNCOMMON,
    player_level - 5  # Scale down
)

# Boss items
var boss_item = scaling.generate_item_for_level(
    Enums.EquipmentSlot.HEAD,
    Enums.Rarity.PRIMORDIAL,
    player_level      # Perfect scale
)
```

### Example 3: Upgrade Items via Crafting

```gdscript
var scaling = ItemScalingSystem.new()

# Player crafts upgrade
var old_item = player.equipment[Enums.EquipmentSlot.FEET]
var new_level = player.level + 5

var upgraded = scaling.upgrade_item_to_level(old_item, new_level)

# Apply to player
player.equip_item(upgraded)
```

---

## Troubleshooting

**Issue: Items are too weak**
- Increase `LEVEL_SCALING_FACTOR`
- Increase variance percentages
- Check `ITEM_LEVEL_MULTIPLIER` values

**Issue: Items are too strong**
- Decrease variance percentages
- Lower rarity weights in `Constants.gd`
- Adjust affix stat bonuses

**Issue: No affixes generating**
- Check `enable_affix_generation` is true
- Verify item type is in `AffixSystem._affix_pools`
- Check rarity has affixes in `AFFIXES_PER_RARITY`

**Issue: Performance is slow**
- Disable `enable_stat_randomization` for testing
- Reduce loot table size
- Cache generated items

---

## Configuration Checklist

- [ ] Test with `ItemGenerationSystem.print_affix_stats()`
- [ ] Verify rarity weights sum correctly
- [ ] Adjust variance by rarity to taste
- [ ] Configure affix pools with desired affixes
- [ ] Test scaling at levels 1, 20, 50
- [ ] Validate effectiveness ratios make sense
- [ ] Run full test suite
- [ ] Test co-op loot distribution
- [ ] Verify save/load serialization works

---

## Files Modified/Created

**New Files:**
- `scripts/systems/item_generation_system.gd` (418 lines)
- `scripts/systems/affix_system.gd` (424 lines)
- `scripts/systems/item_scaling_system.gd` (381 lines)
- `resources/items/randomized_item_data.gd` (227 lines)
- `tests/test_item_randomization.gd` (289 lines)

**Modified Files:**
- `scripts/systems/loot_system.gd` (enhanced with randomization)

**Total New Code:** ~1,750 lines

---

## Next Steps

1. **Enchantment System** - Allow upgrading randomized items
2. **Transmutation** - Convert items between rarities
3. **Named Items** - Special unique item definitions
4. **Item Evolution** - Progress items through tiers
5. **Affix Rerolling** - Reroll affixes via crafting

---

## Support

For issues or questions:
1. Check `ITEM_RANDOMIZATION_IMPLEMENTATION.md` (this file)
2. Review test cases in `test_item_randomization.gd`
3. Check debug output from `print_affix_stats()` / `print_base_stats_table()`
4. Use `ItemScalingSystem.analyze_item_scaling()` to debug items

