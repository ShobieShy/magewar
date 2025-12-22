# MageWar Item/Equipment System - Exploration Summary

**Date:** December 21, 2025  
**Project:** MageWar (Godot 4.x)  
**Scope:** Complete exploration of item/equipment systems

---

## What Was Explored

### 1. Rarity System
- **Location:** `scripts/data/enums.gd` (lines 47-54) + `scripts/data/constants.gd` (lines 87-114)
- **Status:** Fully implemented with 6 tiers
- **Components:**
  - Rarity enum with weights
  - Stat multipliers per rarity (1.0x to 2.5x)
  - UI colors for each rarity
  - Weighted random selection implementation

### 2. Item Class Hierarchy
- **Base Class:** `ItemData` (71 lines)
- **Subclasses:**
  - `EquipmentData` - Wearable items (126 lines)
  - `StaffPartData` - Weapon component pieces (127 lines)
  - `GemData` - Gem inserts (132 lines)
  - `ConsumableData` - Usable items (197 lines)
  - `PotionData` - Potion variants (236 lines)
  - `GrimoireEquipmentData` - Spell books (241 lines)

### 3. Statistics System
- **Location:** `scripts/components/stats_component.gd` (330 lines)
- **Core Stats:** Health, Magika, Stamina (with regeneration)
- **Modifier System:** Additive + Percentage-based
- **Stat Types:** 12 different stat categories
- **Application:** Via modifier pattern with unique IDs

### 4. Inventory & Equipment Management
- **Location:** `scripts/systems/inventory_system.gd` (517 lines)
- **Features:**
  - 40-item inventory with stacking support
  - Equipment slots (8 types)
  - Material inventory for crafting
  - Atomic swap/move operations to prevent duplication

### 5. Loot & Randomization
- **Location:** `scripts/systems/loot_system.gd` (147 lines)
- **Existing Randomization:**
  - Weighted rarity selection
  - Stack count randomization
  - Position/velocity randomization
  - Loot table format with weights
- **Co-op Extension:** `coop_loot_system.gd` with distribution modes

### 6. Databases
- **ItemDatabase:** Auto-loads items from `.tres` files
- **GemDatabase:** Auto-loads gems from `.tres` files
- **Auto-discovery:** Scans resource directories at startup

### 7. Item Resources
- **Structure:** `/resources/items/parts/` organized by type
  - heads/ (gem slots)
  - exteriors/ (fire rate)
  - handles/ (stability)
  - interiors/ (damage)
  - charms/ (special effects)

---

## Key Findings

### Strengths
1. **Well-designed inheritance:** Clear base class with specialized subclasses
2. **Flexible stat system:** Modifier-based allows complex stacking without data bloat
3. **Resource-driven:** All items as .tres files, easy to create variants
4. **Centralized configuration:** All constants in one place (Constants.gd)
5. **Extensible loot system:** Weighted tables support complex distributions
6. **Type safety:** Heavy use of enums and typed properties

### Current Limitations
1. **No item generation system:** Items are static, no procedural randomization
2. **No affix/suffix system:** No way to add special properties to items
3. **Limited stat variation:** Items use base stats only, no variance
4. **No item level scaling:** `level_required` exists but no stat scaling
5. **Basic randomization:** Only rarity and stack count are randomized
6. **No named items:** No unique item naming system

### Expansion Points
1. **Item Generation System:** Create procedural stat generation
2. **Affix Pool:** Define prefix/suffix combinations
3. **Scaling System:** Level-based stat progression
4. **Named Items:** Unique item naming and special effects
5. **Rarity Progression:** Crafting recipes for rarity upgrades

---

## Architecture Overview

```
ItemData (Base)
├── EquipmentData
│   └── GrimoireEquipmentData
├── StaffPartData
├── GemData
├── ConsumableData
│   └── PotionData
└── [Custom subclasses]

StatsComponent
├── Core Stats (Health, Magika, Stamina)
├── Regen Rates
├── Modifier System
│   ├── Additive Modifiers
│   └── Percentage Modifiers
└── Stat Types (12 different)

InventorySystem
├── Inventory (Array[ItemData])
├── Equipment (Dictionary[Slot → Item])
├── Materials (Dictionary[ID → Quantity])
└── Operations (add, remove, equip, swap)

LootSystem
├── Rarity Rolling (weighted)
├── Drop Table Format
└── Loot Pickup (3D world drops)

ItemDatabase / GemDatabase
├── Central Registry
├── Auto-loading from .tres files
└── Search/Query Methods
```

---

## File Statistics

| System | Files | Total Lines | Key Files |
|--------|-------|-------------|-----------|
| **Data/Enums** | 2 | ~361 + ~178 | enums.gd, constants.gd |
| **Items** | 7 | ~1,300 | item_data.gd, equipment_data.gd, etc. |
| **Systems** | 5 | ~2,000+ | inventory_system.gd, loot_system.gd |
| **Components** | 1 | 330 | stats_component.gd |
| **Databases** | 2 | ~260 | item_database.gd, gem_database.gd |
| **Resources** | 25+ | N/A | .tres files for items |

---

## Rarity System Details

### Drop Rates (Weighted)
```
BASIC:      100 (62.5%)
UNCOMMON:   50  (31.25%)
RARE:       20  (12.5%)
MYTHIC:     5   (3.125%)
PRIMORDIAL: 1   (0.625%)
UNIQUE:     0   (0%, manual only)
```

### Stat Multipliers Applied
```
BASIC:      1.0x
UNCOMMON:   1.15x (+15%)
RARE:       1.35x (+35%)
MYTHIC:     1.6x (+60%)
PRIMORDIAL: 2.0x (+100%)
UNIQUE:     2.5x (+150%) + unique effects
```

### Implementation
- Base stats are defined in `.tres` files
- Rarity multiplier applied at runtime in `get_value()`
- Each rarity has associated UI color
- Weights used for weighted random selection

---

## Stat System Details

### Stat Types (12 total)
1. **Resource Stats:** Health, Magika, Stamina
2. **Regen Stats:** Health/Magika/Stamina Regen
3. **Combat Stats:** Damage, Defense, Move Speed, Cast Speed
4. **Special Stats:** Critical Chance, Critical Damage

### Modifier Flow
```
Equipment.apply_to_stats(stats_component)
    ↓
Creates modifiers with ID: "equip_[item_id]_[stat_type]"
    ↓
stats_component.add_modifier(stat_type, modifier_id, value, is_percentage)
    ↓
Stored in _stat_modifiers[stat_type][modifier_id]
    ↓
On equipment unequip:
    ↓
stats_component.remove_modifier(stat_type, modifier_id)
```

### Calculation
```
final_value = (base_value + sum_additive) * (1 + sum_percentage)
```

---

## Equipment System Details

### 8 Equipment Slots
- HEAD, BODY, BELT, FEET (armor)
- PRIMARY_WEAPON, SECONDARY_WEAPON (weapons)
- GRIMOIRE (spell book)
- POTION (quick item)

### 11 Stat Bonuses per Item
- Health, Magika, Stamina bonuses
- Regen bonuses (health/magika/stamina)
- Move Speed, Damage, Defense
- Critical Chance, Critical Damage
- Special Effects array
- Passive Status Effect

---

## Inventory Details

### Storage (40 slots default)
- Can stack stackable items
- One item per slot for non-stackables
- Atomic swap/move operations prevent duplication

### Materials System
- Separate from inventory
- Tracks crafting materials by ID
- Capacity of 50 unique material types

### Operations
- `add_item()` - Add to inventory
- `remove_item()` - Remove from inventory
- `equip_item()` - Equip and apply stats
- `unequip_slot()` - Remove and apply negative stats
- `swap_items()` - Atomic swap with validation

---

## Loot System Details

### Weighted Selection
1. Sum all weights in loot table
2. Roll random number 0 to total_weight
3. Iterate through items, accumulating weights
4. Return item where roll is within weight range

### Loot Table Format
```gdscript
{
    "item": ItemData,           # Item to drop
    "weight": float,            # Drop weight
    "min": int,                 # Min stack count
    "max": int,                 # Max stack count
    "fixed_rarity": bool        # Optional: lock rarity
}
```

### Drop Modifications
- Rarity rolled unless fixed
- Stack count randomized between min/max
- Position offset by ±0.5 units
- Velocity randomized (3-5 up, ±2 horizontal)

---

## Database Loading

### ItemDatabase
- **Paths scanned:**
  - `res://resources/items/equipment/`
  - `res://resources/items/grimoires/`
  - `res://resources/items/potions/`
- **Auto-loads:** All `.tres` files matching ItemData subclasses
- **Registry:** `_items: Dictionary[item_id → ItemData]`

### GemDatabase
- **Path scanned:**
  - `res://resources/items/gems/`
- **Registry:** `_gems: Dictionary[gem_id → GemData]`

### Duplicate on Access
- `get_item()` returns a duplicate
- Prevents modifications from affecting the original
- Supports instance-specific modifications

---

## Code Examples Found

### Rarity Rolling
```gdscript
func _roll_rarity() -> Enums.Rarity:
    var total_weight = 0
    for weight in Constants.RARITY_WEIGHTS.values():
        total_weight += weight
    
    var roll = randi_range(0, total_weight)
    var current = 0
    
    for rarity in Constants.RARITY_WEIGHTS.keys():
        current += Constants.RARITY_WEIGHTS[rarity]
        if roll <= current:
            return rarity
    
    return Enums.Rarity.BASIC
```

### Stat Modifier Calculation
```gdscript
func _get_modified_stat(stat_type: Enums.StatType, base_value: float) -> float:
    var result = base_value
    var percentage_bonus = 1.0
    
    if _stat_modifiers.has(stat_type):
        for modifier_data in _stat_modifiers[stat_type].values():
            if modifier_data.is_percentage:
                percentage_bonus += modifier_data.value
            else:
                result += modifier_data.value
    
    return result * percentage_bonus
```

### Equipment Application
```gdscript
func apply_to_stats(stats: StatsComponent) -> void:
    var bonuses = get_stat_bonuses()
    var equip_id = "equip_" + item_id
    
    for stat_type in bonuses.keys():
        var bonus = bonuses[stat_type]
        if bonus != 0.0:
            stats.add_modifier(stat_type, 
                equip_id + "_" + str(stat_type), 
                bonus, false)
```

---

## Crafting System (Bonus)

### Discovered Files
- `crafting_manager.gd` - Main crafting system
- `crafting_recipe.gd` - Recipe definitions
- `crafting_recipe_manager.gd` - Recipe registry
- `crafting_logic.gd` - Recipe execution
- `crafting_material.gd` - Material tracking
- Multiple achievement and test files

**Note:** Crafting system exists but was not deeply explored in this pass. It could be a useful integration point for item randomization.

---

## Recommendations

### For Immediate Implementation
1. **Item Generation System** - Randomize equipment stats within rarity bands
2. **Affix System** - Add prefix/suffix combinations to items
3. **Scale System** - Level-based stat adjustment

### For Future Enhancement
1. **Named Items** - Support unique item names and special effects
2. **Enchantment System** - Post-drop stat modification
3. **Transmutation** - Convert items via crafting
4. **Progression Tiers** - Rarity escalation paths

---

## Testing Points

### Unit Test Opportunities
- Rarity rolling distribution
- Stat modifier stacking
- Inventory operations (especially atomic swap)
- Equipment equip/unequip cycles
- Loot table weighted selection
- Database loading and access

### Integration Test Opportunities
- Equipment stat application to player
- Loot pickup integration with inventory
- Database auto-loading verification
- Co-op loot distribution

---

## Documentation Created

1. **ITEM_EQUIPMENT_ARCHITECTURE.md** - Comprehensive 12-section analysis
2. **ITEM_SYSTEM_QUICK_REFERENCE.md** - Code snippets and quick lookups
3. **EXPLORATION_SUMMARY.md** - This document

---

## Conclusion

The MageWar item/equipment system has a **solid foundation** with:
- Well-structured class hierarchy
- Flexible modifier-based stat system
- Comprehensive enum/constant definitions
- Existing weighted randomization
- Clean database auto-loading

The system is **ready for extension** with:
- Item generation for randomized stats
- Affix/suffix systems for special properties
- Level-based scaling
- Advanced loot mechanics

All pieces are in place for implementing a robust randomization system. The architecture supports adding complexity without significant refactoring.

