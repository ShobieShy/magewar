# Loot System - Complete File Index

## Critical Files (Must Fix)

### 1. Primary Loot Drop Logic
- **`/home/shobie/magewar/scripts/systems/loot_system.gd`** (182 lines)
  - `drop_loot()` - Works
  - `drop_loot_from_table()` - **BROKEN at line 103**
  - `_roll_rarity()` - Works

### 2. Enemy Death Handling
- **`/home/shobie/magewar/scenes/enemies/enemy_base.gd`** (449 lines)
  - `_on_died()` - Line 301 (works, triggers drops)
  - `_drop_loot()` - Line 323 (broken, calls broken loot system)
  - `_drop_gold()` - Line 349 (works)
  - `_award_experience()` - Line 372 (works)

## Enemy Configuration Files

### Enemy Data Files
- **`/home/shobie/magewar/resources/enemies/skeleton_enemy_data.gd`**
  - `get_loot_table()` - Line 132 (returns string IDs)
  
- **`/home/shobie/magewar/resources/enemies/goblin_enemy_data.gd`**
  - `get_loot_table()` - Line 165 (returns string IDs)
  
- **`/home/shobie/magewar/resources/enemies/slime_enemy_data.gd`**
  - `get_loot_table()` - Line 166 (returns string IDs)
  
- **`/home/shobie/magewar/resources/enemies/troll_enemy_data.gd`**
  - `get_loot_table()` - Line 150 (returns string IDs)
  
- **`/home/shobie/magewar/resources/enemies/wraith_enemy_data.gd`**
  - `get_loot_table()` - Line 140 (returns string IDs)

### Enemy Implementation Files
- **`/home/shobie/magewar/scenes/enemies/skeleton.gd`** (309 lines)
  - `_apply_skeleton_config()` - Line 57
  
- **`/home/shobie/magewar/scenes/enemies/goblin.gd`** (304 lines)
  - `_apply_goblin_config()` - Line 52

## Support Systems

### Loot Pickup System
- **`/home/shobie/magewar/scripts/systems/loot_pickup.gd`** (125 lines)
  - `initialize()` - Line 53
  - `_on_body_entered()` - Line 94
  - `_pickup_by_player()` - Line 102
  - `_update_visual()` - Line 72

### Item Database
- **`/home/shobie/magewar/autoload/item_database.gd`** (131 lines)
  - `_load_items()` - Line 55
  - `get_item()` - Line 31

### Co-op Loot System
- **`/home/shobie/magewar/scripts/systems/coop_loot_system.gd`** (255 lines)
  - Full co-op implementation

### Material Drop System
- **`/home/shobie/magewar/scripts/systems/material_drop_system.gd`** (172 lines)
  - `generate_enemy_drops()` - Line 72
  - Not currently integrated with enemy drops

## Resource Directories

### Items That Exist
- **`/home/shobie/magewar/resources/items/equipment/`**
  - apprentice_belt.tres
  - apprentice_hat.tres
  - apprentice_robes.tres
  - apprentice_shoes.tres
  - arcane_robes.tres
  - enchanted_shoes.tres
  - enhanced_robes.tres
  - expert_hat.tres
  - flying_shoes.tres
  - journeyman_hat.tres
  - legendary_belt.tres
  - magical_belt.tres
  - master_hat.tres
  - mystic_robes.tres
  - reinforced_belt.tres
  - swift_shoes.tres

- **`/home/shobie/magewar/resources/items/grimoires/`**
  - (Various grimoire files)

- **`/home/shobie/magewar/resources/items/potions/`**
  - (Various potion files)

- **`/home/shobie/magewar/resources/items/parts/`**
  - Various part resources

- **`/home/shobie/magewar/resources/items/materials/`**
  - Material resources for crafting

### Items That Don't Exist (Referenced by Enemies)
- bone_fragments
- rusty_sword
- rusty_dagger
- basic_potion
- slime_glob
- elemental_essence
- healing_potion
- troll_hide_armor
- shadow_essence
- wraith_cloak
- commander_helmet
- chief_horn
- boss_key_fragment
- elder_rune
- soul_fragment

## Scene Files

### Loot Pickup Scene
- **`/home/shobie/magewar/scenes/world/loot_pickup.tscn`**
  - Status: Unknown (may not exist)
  - Required by: LootSystem line 50-51

### Other Related Scenes
- **`/home/shobie/magewar/scenes/objects/loot_chest.gd`** (111 lines)
  - Uses LootSystem for interactable chests

## Configuration Files

### Constants File
- **`/home/shobie/magewar/scripts/data/constants.gd`**
  - `GOLD_DROP_BASE` - Used by _drop_gold()
  - `GOLD_DROP_ELITE_MULT` - Elite gold multiplier
  - `GOLD_DROP_BOSS_MULT` - Boss gold multiplier
  - `RARITY_WEIGHTS` - Item rarity drop rates
  - `LOOT_DESPAWN_TIME` - How long items stay
  - `LOOT_PICKUP_RANGE` - Collection radius
  - `LAYER_PICKUPS` - Collision layer
  - `LAYER_PLAYERS` - Player collision layer

## Global Autoload Managers
- **`/home/shobie/magewar/autoload/item_database.gd`**
  - Central item registry
  
- **`/home/shobie/magewar/autoload/save_manager.gd`**
  - Handles `add_gold()` calls
  
- **`/home/shobie/magewar/autoload/quest_manager.gd`**
  - Handles `report_kill()` calls

## Generated Documentation Files

All created in root directory:
- **`LOOT_SYSTEM_ANALYSIS.md`** - Detailed analysis
- **`LOOT_SYSTEM_QUICK_REFERENCE.md`** - Quick reference guide
- **`LOOT_DROP_SYSTEM_OVERVIEW.md`** - Comprehensive overview
- **`LOOT_SYSTEM_FILE_INDEX.md`** - This file

---

## Summary of Changes Needed

### File to Fix: `/home/shobie/magewar/scripts/systems/loot_system.gd`
**Location**: Line 86-139 in `drop_loot_from_table()` method

**Current Code (BROKEN)**:
```gdscript
var item: ItemData = entry.item.duplicate_item()
```

**Fixed Code**:
```gdscript
var item: ItemData
if entry.item is String:
    item = ItemDatabase.get_item(entry.item)
    if item == null:
        push_warning("Loot drop: Item not found: %s" % entry.item)
        continue
else:
    item = entry.item

item = item.duplicate_item()
```

### Files to Update: Enemy Data Files
Either update item references OR create missing item files:
- `/home/shobie/magewar/resources/enemies/skeleton_enemy_data.gd` - Line 42
- `/home/shobie/magewar/resources/enemies/goblin_enemy_data.gd` - Line 50
- `/home/shobie/magewar/resources/enemies/slime_enemy_data.gd` - Line 56-57
- `/home/shobie/magewar/resources/enemies/troll_enemy_data.gd` - Line 46-47
- `/home/shobie/magewar/resources/enemies/wraith_enemy_data.gd` - Line 53-54

### Files to Verify: Support Systems
- `/home/shobie/magewar/scenes/world/loot_pickup.tscn` - Scene must exist
- `/home/shobie/magewar/scripts/data/constants.gd` - Constants must be defined
- Player InventorySystem - Must have `add_item()` method

