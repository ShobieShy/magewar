# MageWar Item/Equipment System - Complete Documentation Index

**Last Updated:** December 21, 2025

---

## Documentation Files Created

### 1. ITEM_EQUIPMENT_ARCHITECTURE.md
**Comprehensive technical reference (507 lines)**

Contains:
- Executive summary of the system
- Complete rarity system breakdown (6 tiers with weights)
- Item class hierarchy and inheritance
- Specialized item classes (Equipment, Gems, Potions, Staff Parts)
- Stats system and modifier patterns
- Existing randomization patterns
- Inventory and equipment management
- Database systems (ItemDatabase, GemDatabase)
- Stat application flow
- File structure and directory organization
- Recommended extension points for randomization
- Design patterns observed

**Use this for:** Understanding the complete architecture and how systems interact

---

### 2. ITEM_SYSTEM_QUICK_REFERENCE.md
**Code examples and quick lookups (420 lines)**

Contains:
- Key file locations with line numbers
- Creating items programmatically (Equipment, Gems, Potions)
- Working with rarity (colors, names, rolling)
- Stat modifier examples
- Equipment equipping/unequipping code
- Loot system usage patterns
- Stat types and equipment slots
- Constants reference
- Common coding patterns
- Item creation paths
- Key formulas and calculations
- Import statements

**Use this for:** Copy-paste code examples and quick reference lookups

---

### 3. EXPLORATION_SUMMARY.md
**High-level findings and analysis (419 lines)**

Contains:
- What was explored
- Key findings (strengths and limitations)
- Architecture overview diagram
- File statistics table
- Rarity system details with drop rates
- Stat system details with calculation flows
- Equipment system breakdown
- Inventory details
- Loot system details
- Database loading information
- Code examples from actual implementation
- Crafting system discovery (bonus)
- Recommendations for future work
- Testing opportunities

**Use this for:** Understanding current state, limitations, and expansion points

---

## Quick Navigation

### Finding Information By Topic

#### Rarity System
- **Architecture:** ITEM_EQUIPMENT_ARCHITECTURE.md § 1
- **Quick Ref:** ITEM_SYSTEM_QUICK_REFERENCE.md § 9
- **Details:** EXPLORATION_SUMMARY.md - Rarity System Details section

#### Item Classes
- **Hierarchy:** ITEM_EQUIPMENT_ARCHITECTURE.md § 2-3
- **Base Class:** ITEM_EQUIPMENT_ARCHITECTURE.md § 2
- **Subclasses:** ITEM_EQUIPMENT_ARCHITECTURE.md § 3

#### Stats System
- **Overview:** ITEM_EQUIPMENT_ARCHITECTURE.md § 4
- **Modifiers:** ITEM_SYSTEM_QUICK_REFERENCE.md § 4
- **Details:** EXPLORATION_SUMMARY.md - Stat System Details section

#### Creating Items
- **Code Examples:** ITEM_SYSTEM_QUICK_REFERENCE.md § 2
- **File Structure:** ITEM_EQUIPMENT_ARCHITECTURE.md § 9
- **Classes:** ITEM_EQUIPMENT_ARCHITECTURE.md § 2-3

#### Equipment Management
- **Inventory System:** ITEM_EQUIPMENT_ARCHITECTURE.md § 6
- **Equipping:** ITEM_SYSTEM_QUICK_REFERENCE.md § 5
- **Details:** EXPLORATION_SUMMARY.md - Equipment System Details

#### Loot System
- **Overview:** ITEM_EQUIPMENT_ARCHITECTURE.md § 5
- **Code:** ITEM_SYSTEM_QUICK_REFERENCE.md § 6
- **Details:** EXPLORATION_SUMMARY.md - Loot System Details

#### Databases
- **Overview:** ITEM_EQUIPMENT_ARCHITECTURE.md § 7
- **Details:** EXPLORATION_SUMMARY.md - Database Loading

---

## Key File Locations in Project

### Definition Files
- `/home/shobie/magewar/scripts/data/enums.gd` - All enums (Rarity, ItemType, StatType, etc.)
- `/home/shobie/magewar/scripts/data/constants.gd` - All constants (weights, multipliers, colors)

### Item Classes
- `/home/shobie/magewar/resources/items/item_data.gd` - Base class (71 lines)
- `/home/shobie/magewar/resources/items/equipment_data.gd` - Equipment (126 lines)
- `/home/shobie/magewar/resources/items/staff_part_data.gd` - Staff parts (127 lines)
- `/home/shobie/magewar/resources/spells/gem_data.gd` - Gems (132 lines)
- `/home/shobie/magewar/resources/items/potion_data.gd` - Potions (236 lines)
- `/home/shobie/magewar/resources/equipment/grimoire_data.gd` - Grimoires (241 lines)

### Core Systems
- `/home/shobie/magewar/scripts/components/stats_component.gd` - Stats management (330 lines)
- `/home/shobie/magewar/scripts/systems/inventory_system.gd` - Inventory (517 lines)
- `/home/shobie/magewar/scripts/systems/loot_system.gd` - Loot drops (147 lines)
- `/home/shobie/magewar/scripts/systems/coop_loot_system.gd` - Co-op loot (255 lines)
- `/home/shobie/magewar/scripts/systems/loot_pickup.gd` - Pickup mechanics (125 lines)

### Databases
- `/home/shobie/magewar/autoload/item_database.gd` - Item registry (131 lines)
- `/home/shobie/magewar/autoload/gem_database.gd` - Gem registry (129 lines)

### Resources
- `/home/shobie/magewar/resources/items/equipment/` - Equipment .tres files
- `/home/shobie/magewar/resources/items/gems/` - Gem .tres files
- `/home/shobie/magewar/resources/items/parts/` - Weapon parts
  - `heads/`, `exteriors/`, `handles/`, `interiors/`, `charms/`
- `/home/shobie/magewar/resources/items/potions/` - Potion .tres files
- `/home/shobie/magewar/resources/items/grimoires/` - Grimoire .tres files

---

## At-a-Glance Summary

### System Architecture
```
ItemData (base class with 6 subclasses)
    ↓
Stats Component (modifier-based stat system)
    ↓
Inventory System (40 slots + equipment)
    ↓
Loot System (weighted random drops)
    ↓
Databases (auto-loading from .tres files)
```

### Rarity Tiers (6 total)
1. BASIC (white, 1.0x)
2. UNCOMMON (green, 1.15x)
3. RARE (blue, 1.35x)
4. MYTHIC (purple, 1.6x)
5. PRIMORDIAL (orange, 2.0x)
6. UNIQUE (gold, 2.5x)

### Stat Types (12 total)
- Health, Magika, Stamina
- Health/Magika/Stamina Regen
- Move Speed, Cast Speed
- Damage, Defense
- Critical Chance, Critical Damage

### Equipment Slots (8 total)
- HEAD, BODY, BELT, FEET (armor)
- PRIMARY_WEAPON, SECONDARY_WEAPON (weapons)
- GRIMOIRE, POTION (special)

---

## Implementation Checklist

### Currently Implemented
- [x] Rarity system with 6 tiers
- [x] Stat modifier system
- [x] Equipment slots and management
- [x] Loot system with weighted drops
- [x] Database auto-loading
- [x] Inventory with stacking
- [x] Co-op loot sharing

### Ready to Implement
- [ ] Procedural stat generation
- [ ] Affix/suffix system
- [ ] Level-based scaling
- [ ] Named unique items
- [ ] Item evolution/transmutation

---

## Reading Path by Role

### If You're a **Designer**
1. Start: EXPLORATION_SUMMARY.md (overview)
2. Then: ITEM_EQUIPMENT_ARCHITECTURE.md § 1 (rarity system)
3. Then: ITEM_SYSTEM_QUICK_REFERENCE.md § 9 (constants)

### If You're a **Programmer**
1. Start: ITEM_EQUIPMENT_ARCHITECTURE.md (complete overview)
2. Then: ITEM_SYSTEM_QUICK_REFERENCE.md (code examples)
3. Then: EXPLORATION_SUMMARY.md § Recommendations

### If You're **Adding Features**
1. Start: ITEM_EQUIPMENT_ARCHITECTURE.md § 10 (extension points)
2. Then: EXPLORATION_SUMMARY.md § Recommendations
3. Then: ITEM_SYSTEM_QUICK_REFERENCE.md (implementation patterns)

### If You're **Debugging**
1. Start: EXPLORATION_SUMMARY.md § Code Examples
2. Then: ITEM_SYSTEM_QUICK_REFERENCE.md § Common Patterns
3. Then: Specific section in ITEM_EQUIPMENT_ARCHITECTURE.md

---

## Key Statistics

| Aspect | Value |
|--------|-------|
| **Rarity Tiers** | 6 (BASIC to UNIQUE) |
| **Item Classes** | 6 (ItemData + 5 subclasses) |
| **Stat Types** | 12 |
| **Equipment Slots** | 8 |
| **Inventory Slots** | 40 (default) |
| **Lines of Code** | ~3,400+ (item/stat systems) |
| **Documentation** | 1,346 lines (3 files) |

---

## Formulas Reference

### Stat Calculation
```
final_value = (base_value + additive_bonuses) * (1 + percentage_bonuses)
```

### Item Value
```
gold_value = base_value * RARITY_STAT_MULTIPLIERS[rarity]
```

### Damage After Defense
```
actual_damage = max(base_damage - defense, base_damage * 0.1)
```

### Rarity Drop Weights
```
BASIC: 100 (62.5%)
UNCOMMON: 50 (31.25%)
RARE: 20 (12.5%)
MYTHIC: 5 (3.125%)
PRIMORDIAL: 1 (0.625%)
UNIQUE: 0 (0%)
```

---

## Quick Commands

### Find Item Class Definition
```bash
find /home/shobie/magewar/resources/items -name "*.gd" -type f
```

### Find Equipment Files
```bash
ls /home/shobie/magewar/resources/items/equipment/
```

### Find System Files
```bash
ls /home/shobie/magewar/scripts/systems/ | grep -E "(inventory|loot|crafting)"
```

---

## Related Systems

### Crafting System
- **Status:** Discovered (not fully analyzed)
- **Files:** crafting_manager.gd, crafting_recipe.gd, crafting_logic.gd
- **Integration Point:** Could use item generation for crafted items

### Spell System
- **Status:** Partially analyzed (GemData integration)
- **Integration:** Gems modify spells when slotted in staffs

### Save System
- **Status:** Supported (InventorySystem.get_save_data())
- **Integration:** Items persist across sessions

---

## Getting Help

### Looking for...

**Rarity Information?**
- ITEM_EQUIPMENT_ARCHITECTURE.md § 1 for complete breakdown
- ITEM_SYSTEM_QUICK_REFERENCE.md § 9 for constants
- EXPLORATION_SUMMARY.md for drop rates

**Code Example?**
- ITEM_SYSTEM_QUICK_REFERENCE.md § 2-6 for most scenarios
- EXPLORATION_SUMMARY.md § Code Examples for specific patterns

**System Architecture?**
- ITEM_EQUIPMENT_ARCHITECTURE.md for complete structure
- EXPLORATION_SUMMARY.md § Architecture Overview for diagram

**Implementation Strategy?**
- ITEM_EQUIPMENT_ARCHITECTURE.md § 10 for extension points
- EXPLORATION_SUMMARY.md § Recommendations for roadmap

**File Location?**
- ITEM_SYSTEM_QUICK_REFERENCE.md § 1 for quick lookup
- ITEM_EQUIPMENT_ARCHITECTURE.md § 9 for directory structure

---

## Version History

| Date | Document | Changes |
|------|----------|---------|
| 2025-12-21 | All 3 docs | Initial exploration and documentation |

---

## Notes

All documentation is based on actual code inspection of the MageWar Godot 4.x project. Line numbers and file paths are accurate as of the exploration date.

The system uses best practices including:
- Composition over inheritance
- Resource-based design
- Centralized configuration
- Type safety with enums
- Modifier pattern for stats

All files are ready for:
- Implementation of randomization systems
- Extension with new item types
- Integration with other game systems
- Testing and validation

