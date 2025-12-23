# Loot System Quick Reference

## File Locations

| Purpose | File Path |
|---------|-----------|
| Enemy base class | `/scenes/enemies/enemy_base.gd` (lines 323-346) |
| Loot system core | `/scripts/systems/loot_system.gd` |
| Loot pickup | `/scripts/systems/loot_pickup.gd` |
| Skeleton enemy | `/resources/enemies/skeleton_enemy_data.gd` |
| Goblin enemy | `/resources/enemies/goblin_enemy_data.gd` |
| Slime enemy | `/resources/enemies/slime_enemy_data.gd` |
| Troll enemy | `/resources/enemies/troll_enemy_data.gd` |
| Wraith enemy | `/resources/enemies/wraith_enemy_data.gd` |
| Item database | `/autoload/item_database.gd` |
| Material drops | `/scripts/systems/material_drop_system.gd` |
| Co-op loot | `/scripts/systems/coop_loot_system.gd` |

## Key Functions

### Enemy Death Flow
```
EnemyBase._on_died() 
  → _drop_loot()           [line 309]
  → _drop_gold()           [line 310]
  → _award_experience()    [line 313]
```

### Loot Drop Functions
```
LootSystem.drop_loot(item, position, velocity)
  ↓
LootSystem.drop_loot_from_table(table, position, count)
  ↓
LootPickup.initialize(item, quantity, velocity)
  ↓
Player.InventorySystem.add_item(item)
```

## Critical Issue Summary

**PROBLEM**: Type mismatch in `loot_system.gd` line 103
```gdscript
var item: ItemData = entry.item.duplicate_item()  // entry.item is STRING, not ItemData!
```

**IMPACT**: 
- All enemy loot drops fail silently
- No items appear when enemies die
- Only gold drops work (handled separately)

**ENEMIES AFFECTED**:
- Skeleton (references: bone_fragments, rusty_sword, commander_helmet)
- Goblin (references: basic_potion, rusty_dagger, chief_horn)
- Slime (references: slime_glob, elemental_essence)
- Troll (references: healing_potion, troll_hide_armor, elder_rune)
- Wraith (references: shadow_essence, wraith_cloak, soul_fragment)

## What's Implemented vs Missing

| Feature | Status | Notes |
|---------|--------|-------|
| Enemy death detection | ✓ | Working |
| Gold drops | ✓ | Working |
| Item table structure | ✓ | Created, but uses strings |
| Loot system | ✓ | Works if fed ItemData |
| Loot pickup visuals | ✓ | Mesh, bob animation, rarity colors |
| Inventory integration | ✓ | Ready to receive items |
| **Item loading from IDs** | ✗ | **MISSING - ROOT CAUSE** |
| **Actual item files** | ✗ | **MISSING - Most items don't exist** |
| Co-op loot sharing | ✓ | Implemented but not integrated |
| Material drops | ✓ | System exists, not linked to enemies |

## Constants to Check

In `Constants.gd`:
- `GOLD_DROP_BASE` - Base gold per level
- `GOLD_DROP_ELITE_MULT` - Elite multiplier
- `GOLD_DROP_BOSS_MULT` - Boss multiplier  
- `RARITY_WEIGHTS` - Drop rate by rarity
- `LOOT_DESPAWN_TIME` - How long loot stays
- `LOOT_PICKUP_RANGE` - Collection radius
- `LAYER_PICKUPS` - Collision layer

## Two-Part Fix Required

### Part A: Fix Type Mismatch
In `loot_system.gd` line 86-139, update `drop_loot_from_table()`:
```gdscript
for entry in loot_table:
    # Handle both ItemData objects and string IDs
    var item: ItemData
    if entry.item is String:
        item = ItemDatabase.get_item(entry.item)
        if item == null:
            push_warning("Item not found: %s" % entry.item)
            continue
    else:
        item = entry.item
    
    item = item.duplicate_item()  # Now safe
    # ... rest of logic
```

### Part B: Create Missing Items or Update References
Option 1: Create .tres files for all referenced items
Option 2: Update enemy data to use existing equipment items

## Testing Checklist

- [ ] Verify LootPickup scene exists: `res://scenes/world/loot_pickup.tscn`
- [ ] Check ItemDatabase loads correctly
- [ ] Spawn a skeleton and kill it
- [ ] Verify gold appears
- [ ] Verify items appear (after fix)
- [ ] Verify items can be picked up
- [ ] Verify rarity colors work
- [ ] Test with different enemy types (BASIC, ELITE, BOSS)

