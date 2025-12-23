# Loot Drop System Analysis - Magewar

## CURRENT STATE: PARTIALLY IMPLEMENTED BUT NOT FUNCTIONAL

The loot drop system has the infrastructure in place but there is a **critical mismatch** between how loot tables are defined and how they are processed.

---

## 1. HOW ENEMIES CURRENTLY HANDLE LOOT DROPS

### Files Involved:
- **`/home/shobie/magewar/scenes/enemies/enemy_base.gd`** - Base enemy class with loot drop logic
- **`/home/shobie/magewar/scenes/enemies/skeleton.gd`** - Specific enemy implementation
- **`/home/shobie/magewar/scenes/enemies/goblin.gd`** - Specific enemy implementation
- **Various enemy data files** in `/home/shobie/magewar/resources/enemies/`

### Loot Drop Flow:
1. **Enemy Death** (line 301-320 in `enemy_base.gd`):
   - When `_on_died()` is called, it triggers `_drop_loot()` and `_drop_gold()`
   
2. **Drop Loot Method** (line 323-346):
   ```gdscript
   func _drop_loot() -> void:
       if loot_table.size() == 0:
           return
       
       var loot_system = get_tree().current_scene.get_node_or_null("LootSystem")
       if loot_system == null:
           loot_system = LootSystem.new()
           add_child(loot_system)
       
       # Calculate drop count based on enemy type
       var drop_count = 1
       match enemy_type:
           Enums.EnemyType.ELITE: drop_count = 2
           Enums.EnemyType.MINIBOSS: drop_count = 3
           Enums.EnemyType.BOSS: drop_count = 5
           Enums.EnemyType.DEMON_LORD: drop_count = 8
       
       loot_system.drop_loot_from_table(loot_table, global_position, drop_count)
   ```

3. **Drop Gold Method** (line 349-369):
   - Calculates gold based on enemy level and type multipliers
   - Calls `SaveManager.add_gold(gold_amount)`

### Current Implementation Status:
✓ Infrastructure exists
✓ Death detection works
✓ Gold dropping implemented
✗ **ITEM DROPPING IS BROKEN** (see issue below)

---

## 2. THE LOOT SYSTEM STRUCTURE

### Primary System File:
**`/home/shobie/magewar/scripts/systems/loot_system.gd`** (182 lines)

### Main Methods:

**`drop_loot(item: ItemData, position: Vector3, velocity: Vector3)`**
- Creates a LootPickup scene/node in the world
- Sets item data and initial velocity
- Emits `loot_dropped` signal
- Integrates with co-op loot sharing if in multiplayer mode

**`drop_loot_from_table(loot_table: Array, position: Vector3, count: int)`**
- Takes loot table array and drops `count` random items
- Expected loot table format: `[{"item": ItemData, "weight": float, "min": int, "max": int}]`
- Weighted random selection of items
- Applies rarity rolling and stat randomization
- Spreads items around position with physics-based velocity

### Supporting Systems:

**`/home/shobie/magewar/scripts/systems/loot_pickup.gd`** (125 lines)
- Represents a physical loot pickup in the world
- Auto-despawns after `Constants.LOOT_DESPAWN_TIME`
- Visual representation with bob animation
- Pickup delay to prevent instant collection
- Color changes based on rarity

**`/home/shobie/magewar/scripts/systems/coop_loot_system.gd`** (255 lines)
- Handles loot distribution in multiplayer
- Supports multiple distribution types (FREE_FOR_ALL, ROUND_ROBIN, MASTER_LOOTER, etc.)
- Shared loot containers for party members

**`/home/shobie/magewar/scripts/systems/material_drop_system.gd`** (172 lines)
- Generates material drops based on enemy rarity
- Different drop chances per rarity tier
- Material type distribution (ORE 60%, ESSENCE 30%, SHARD 10%)

### Item Rarity System:
- Uses `Constants.RARITY_WEIGHTS` dictionary
- Rarities: BASIC, UNCOMMON, RARE, MYTHIC, PRIMORDIAL, UNIQUE
- Equipment items can be randomized with `RandomizedItemData.create_from_base()`
- Affixes generated via `AffixSystem`

---

## 3. WHERE ENEMIES ARE CONFIGURED

### Enemy Data Files:
Located in `/home/shobie/magewar/resources/enemies/`:

**Examples:**
- `skeleton_enemy_data.gd` (class_name: `SkeletonEnemyData`)
- `goblin_enemy_data.gd` (class_name: `GoblinEnemyData`)
- `slime_enemy_data.gd` (class_name: `SlimeEnemyData`)
- `troll_enemy_data.gd` (class_name: `TrollEnemyData`)
- `wraith_enemy_data.gd` (class_name: `WraithEnemyData`)

### Loot Configuration Properties:
```gdscript
@export var gold_drop_min: int = 20
@export var gold_drop_max: int = 40
@export var item_drops: Array[String] = ["bone_fragments", "rusty_sword"]
@export var drop_chance: float = 0.5
```

### Loot Table Generation:
Each enemy data file has `get_loot_table() -> Array` that returns:
```gdscript
[
    {
        "item": "gold",           # String ID, not ItemData!
        "weight": 25,
        "min": gold_drop_min,
        "max": gold_drop_max
    },
    {
        "item": "bone_fragments", # String ID, not ItemData!
        "weight": 15,
        "min": 1,
        "max": 1
    }
]
```

---

## 🔴 CRITICAL ISSUE: TYPE MISMATCH

### The Problem:
**LootSystem.drop_loot_from_table() expects ItemData objects, but enemy data files provide STRING IDs**

Looking at `loot_system.gd` line 103:
```gdscript
var item: ItemData = entry.item.duplicate_item()
```

This calls `.duplicate_item()` on whatever is in `entry.item`, expecting it to be `ItemData`.

But in `goblin_enemy_data.gd` line 180:
```gdscript
loot_table.append({
    "item": item_id,  # This is a STRING like "rusty_sword"
    "weight": 20,
    "min": 1,
    "max": 1
})
```

### Result:
When enemies die, loot dropping silently fails because:
1. `entry.item` is a string like `"bone_fragments"`
2. `.duplicate_item()` is called on a string
3. String doesn't have that method → Runtime error or null return
4. Loot is never created

### Attempted Item Lookups:
Enemies reference items that don't exist in the game:
- `bone_fragments` - NOT IN DATABASE
- `rusty_sword` - NOT IN DATABASE
- `rusty_dagger` - NOT IN DATABASE
- `basic_potion` - NOT IN DATABASE
- `slime_glob` - NOT IN DATABASE
- `healing_potion` - NOT IN DATABASE
- `troll_hide_armor` - NOT IN DATABASE
- `shadow_essence` - NOT IN DATABASE
- `wraith_cloak` - NOT IN DATABASE
- `chief_horn` - NOT IN DATABASE
- `boss_key_fragment` - NOT IN DATABASE

Actual items that DO exist:
- Equipment: `apprentice_belt.tres`, `apprentice_robes.tres`, `swift_shoes.tres`, etc.

---

## 4. DROPPERS AND MANAGERS

### LootSystem (Primary):
- **File**: `/home/shobie/magewar/scripts/systems/loot_system.gd`
- **Instantiation**: Created on-demand in scene root or added as child
- **Methods**:
  - `drop_loot()` - Single item drop
  - `drop_loot_from_table()` - Multiple weighted drops
  - `_roll_rarity()` - RNG for item rarity

### LootPickup (Physical Representation):
- **File**: `/home/shobie/magewar/scripts/systems/loot_pickup.gd`
- **Spawning**: Instantiated from `res://scenes/world/loot_pickup.tscn`
- **Pickup Mechanics**:
  - Area3D collision detection
  - Auto-despawn timer
  - Player inventory integration
  - Prevents instant pickup with `_pickup_delay`

### LootChest (Alternative Loot Source):
- **File**: `/home/shobie/magewar/scenes/objects/loot_chest.gd`
- **Mechanics**: Interactable chest that generates random parts
- **Uses**: RandomPartGenerator to create parts
- **Spawn**: Uses LootSystem to drop generated parts

### Player Inventory Integration:
- Loot is added via `player.get_node("InventorySystem").add_item()`
- If inventory full, pickup remains on ground
- Connected to pickup signal system

---

## 5. SUMMARY TABLE

| Component | Location | Status | Issue |
|-----------|----------|--------|-------|
| Enemy Death Detection | `enemy_base.gd` line 301 | ✓ Works | None |
| Gold Dropping | `enemy_base.gd` line 349 | ✓ Works | None |
| Loot Table Generation | `*_enemy_data.gd` | ✓ Exists | **Uses string IDs instead of ItemData** |
| LootSystem | `loot_system.gd` | ✓ Exists | **Expects ItemData, receives strings** |
| LootPickup | `loot_pickup.gd` | ✓ Works | None (when initialized properly) |
| Item Database | `item_database.gd` | ✓ Works | Item registry is empty/incomplete |
| CoopLootSystem | `coop_loot_system.gd` | ✓ Exists | Not fully integrated |

---

## WHAT NEEDS TO BE FIXED

### Priority 1 - CRITICAL:
1. **Fix the type mismatch** in `drop_loot_from_table()`:
   - Check if `entry.item` is a string
   - If so, load the ItemData from ItemDatabase
   - If not, use it directly as ItemData

2. **Create missing items**:
   - Create `.tres` resource files for all referenced items
   - OR update enemy data files to reference actual items

3. **Populate ItemDatabase**:
   - Ensure all items are loaded and accessible by ID

### Priority 2 - IMPORTANT:
1. Verify LootPickup scene exists at `res://scenes/world/loot_pickup.tscn`
2. Test the pickup → inventory flow
3. Verify Constants (LOOT_DESPAWN_TIME, LOOT_PICKUP_RANGE, etc.)

### Priority 3 - ENHANCEMENT:
1. Integration with material drop system for enemies
2. Co-op loot distribution UI
3. Loot message notifications
4. Achievement tracking for rare drops

---

## TEST SCENARIO

When a skeleton dies in-game currently:
1. Death is detected ✓
2. Gold is added ✓
3. `_drop_loot()` is called ✓
4. LootSystem is found/created ✓
5. `drop_loot_from_table()` is called with string IDs ✓
6. Tries to call `.duplicate_item()` on string "bone_fragments" ✗
7. ERROR - loot is never created ✗

