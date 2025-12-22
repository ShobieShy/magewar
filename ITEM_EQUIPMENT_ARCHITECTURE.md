# MageWar Item/Equipment System - Architecture Analysis

## Executive Summary

The MageWar Godot project has a well-structured, modular item and equipment system with:
- **6-tier rarity system** (Basic → Unique) with stat multipliers
- **Component-based architecture** for different item types
- **Flexible stat system** with additive and percentage modifiers
- **Existing randomization** in loot drops based on weighted probabilities
- **Clear inheritance hierarchy** with base ItemData class and specialized subclasses

---

## 1. RARITY SYSTEM

### Defined in: `scripts/data/enums.gd`

```gdscript
enum Rarity {
    BASIC,         # White - common drops
    UNCOMMON,      # Green - slightly better stats
    RARE,          # Blue - notable improvements
    MYTHIC,        # Purple - powerful items
    PRIMORDIAL,    # Orange - very rare, unique abilities
    UNIQUE         # Gold - one-of-a-kind named items
}
```

### Rarity Weighting & Multipliers (`scripts/data/constants.gd`)

**Drop Weights** (weighted random selection):
- BASIC: 100 (most common)
- UNCOMMON: 50
- RARE: 20
- MYTHIC: 5
- PRIMORDIAL: 1
- UNIQUE: 0 (never random, specific sources only)

**Stat Multipliers** (applied to base stats):
- BASIC: 1.0x
- UNCOMMON: 1.15x
- RARE: 1.35x
- MYTHIC: 1.6x
- PRIMORDIAL: 2.0x
- UNIQUE: 2.5x + unique effects

**UI Colors**:
- BASIC: White
- UNCOMMON: Green
- RARE: Dodger Blue
- MYTHIC: Medium Purple
- PRIMORDIAL: Orange
- UNIQUE: Gold

---

## 2. ITEM CLASS STRUCTURE

### Base Class: `ItemData` (resources/items/item_data.gd)

**Properties:**
- `item_id`: String (unique identifier)
- `item_name`: String (display name)
- `description`: String (tooltip text)
- `icon`: Texture2D
- `item_type`: Enums.ItemType (determines subclass)
- `rarity`: Enums.Rarity
- `stackable`: bool
- `max_stack`: int
- `base_value`: int (gold value)
- `level_required`: int

**Key Methods:**
- `get_display_name()` → String
- `get_rarity_color()` → Color
- `get_value()` → int (applies rarity multiplier to base_value)
- `get_tooltip()` → String (formatted with colors and stats)
- `can_use()` → bool
- `use(user: Node)` → bool
- `duplicate_item()` → ItemData

### Item Type Enum: `Enums.ItemType`

```gdscript
enum ItemType {
    NONE,
    STAFF_PART,    # Weapon parts
    WAND_PART,     # Weapon parts
    GEM,           # Gem inserts
    EQUIPMENT,     # Armor/accessories
    CONSUMABLE,    # Potions, food
    GRIMOIRE,      # Spell books
    MISC           # Other items
}
```

---

## 3. SPECIALIZED ITEM CLASSES

### A. StaffPartData (resources/items/staff_part_data.gd)

**Extends:** ItemData

**Part Types** (Enums.StaffPart):
- HEAD: Gem slots (1-3), element restrictions
- EXTERIOR: Fire rate, projectile speed modifiers
- INTERIOR: Damage multiplier, magika efficiency
- HANDLE: Handling, stability, accuracy
- CHARM: Special effects (SpellEffect)

**Stat Properties:**
- `gem_slots`: int (1-3 for staff, 1 for wand)
- `gem_slot_types`: Array[Enums.Element] (restrictions)
- `fire_rate_modifier`: float
- `projectile_speed_modifier`: float
- `damage_modifier`: float
- `magika_efficiency`: float
- `handling`: float
- `stability`: float
- `accuracy`: float
- `charm_effect`: SpellEffect
- `charm_element`: Enums.Element

**Key Methods:**
- `apply_to_weapon_stats(stats: Dictionary)` → void (modifies weapon stats by part type)

### B. EquipmentData (resources/items/equipment_data.gd)

**Extends:** ItemData

**Slots** (Enums.EquipmentSlot):
- HEAD, BODY, BELT, FEET (armor)
- PRIMARY_WEAPON, SECONDARY_WEAPON (weapons)
- GRIMOIRE (spell book)
- POTION (quick-use)

**Stat Bonuses:**
- `health_bonus`: float
- `magika_bonus`: float
- `stamina_bonus`: float
- `health_regen_bonus`: float
- `magika_regen_bonus`: float
- `stamina_regen_bonus`: float
- `move_speed_bonus`: float
- `damage_bonus`: float
- `defense_bonus`: float
- `crit_chance_bonus`: float
- `crit_damage_bonus`: float

**Special Properties:**
- `special_effects`: Array[SpellEffect]
- `passive_status`: Enums.StatusEffect

**Key Methods:**
- `get_stat_bonuses()` → Dictionary
- `apply_to_stats(stats: StatsComponent)` → void (adds modifiers)
- `remove_from_stats(stats: StatsComponent)` → void (cleans up modifiers)
- `get_stat_description()` → String

### C. GemData (resources/spells/gem_data.gd)

**Extends:** ItemData

**Element System:**
- `element`: Enums.Element
- `converts_element`: bool (changes spell element)

**Spell Modifiers:**
- `damage_multiplier`: float
- `cost_multiplier`: float
- `cooldown_multiplier`: float
- `range_multiplier`: float
- `aoe_multiplier`: float
- `projectile_speed_multiplier`: float
- `projectile_count_bonus`: int

**Projectile Effects:**
- `adds_pierce`: int
- `adds_bounce`: int
- `adds_chain`: int
- `adds_homing`: float
- `reduces_gravity`: float
- `additional_effects`: Array[SpellEffect]

**Key Methods:**
- `apply_to_spell(spell: SpellData)` → void

### D. ConsumableData / PotionData (resources/items/)

**Extends:** ItemData

**Types:** Health, Magika, Stamina potions + buffs

**Key Properties:**
- Instant restoration (health/magika/stamina)
- Percentage-based restoration
- Duration buffs
- Stat multipliers
- Resistances
- Special effects (debuff removal, immunity, revive)

---

## 4. STATS SYSTEM

### StatsComponent (scripts/components/stats_component.gd)

**Core Stats:**
- `current_health`, `max_health`
- `current_magika`, `max_magika`
- `current_stamina`, `max_stamina`

**Regen Rates:**
- `health_regen_rate`: 1.0/sec
- `magika_regen_rate`: 5.0/sec
- `stamina_regen_rate`: 15.0/sec

**Stat Types** (Enums.StatType):
```gdscript
enum StatType {
    HEALTH,
    MAGIKA,
    STAMINA,
    HEALTH_REGEN,
    MAGIKA_REGEN,
    STAMINA_REGEN,
    MOVE_SPEED,
    CAST_SPEED,
    DAMAGE,
    DEFENSE,
    CRITICAL_CHANCE,
    CRITICAL_DAMAGE
}
```

### Modifier System

**Two Types of Modifiers:**
1. **Additive**: Direct value addition (e.g., +20 Defense)
2. **Percentage**: Multiplier (e.g., +15% Damage)

**Implementation:**
```gdscript
func add_modifier(stat_type: Enums.StatType, modifier_id: String, 
                  value: float, is_percentage: bool = false) -> void
    
func remove_modifier(stat_type: Enums.StatType, modifier_id: String) -> void

func _get_modified_stat(stat_type: Enums.StatType, base_value: float) -> float:
    # Adds all additive modifiers
    # Multiplies by all percentage modifiers
    # Result = (base + additive_sum) * (1 + percentage_sum)
```

**Flow:**
1. Equipment is equipped → `apply_to_stats()` creates modifiers
2. Each modifier has unique ID (e.g., "equip_boots_DEFENSE")
3. Stats recalculated when modifiers added/removed
4. Equipment unequipped → `remove_from_stats()` cleans up

---

## 5. EXISTING RANDOMIZATION PATTERNS

### A. Loot Drop System (scripts/systems/loot_system.gd)

**Rarity Rolling:**
```gdscript
func _roll_rarity() -> Enums.Rarity:
    # Uses weighted distribution from Constants.RARITY_WEIGHTS
    # Rolls random number based on total weight
    # Returns matching rarity tier
```

**Loot Table Format:**
```gdscript
var loot_table = [
    {
        "item": ItemData,
        "weight": float,
        "min": int,        # Min stack count
        "max": int,        # Max stack count
        "fixed_rarity": true  # Optional: lock to specific rarity
    }
]

func drop_loot_from_table(loot_table: Array, position: Vector3, count: int = 1) -> Array:
    # Weighted random selection
    # Randomizes stack count
    # Rolls rarity if not fixed
    # Spreads items with random velocity
```

**Drop Modifications:**
- Position offset randomization: ±0.5 units
- Velocity randomization: 3-5 upward, ±2 horizontal

### B. Existing Parameters

**Constants Already Used:**
- RARITY_WEIGHTS: Dictionary
- RARITY_STAT_MULTIPLIERS: Dictionary
- RARITY_COLORS: Dictionary

---

## 6. INVENTORY & EQUIPMENT SYSTEM

### InventorySystem (scripts/systems/inventory_system.gd)

**Storage:**
- `inventory`: Array[ItemData] (40 slots by default)
- `equipment`: Dictionary[EquipmentSlot → ItemData]
- `materials`: Dictionary[material_id → quantity] (for crafting)

**Key Operations:**
- `add_item(item: ItemData)` → int (returns slot or -1)
- `remove_item(slot: int)` → ItemData
- `equip_item(item: ItemData, from_slot: int)` → ItemData (returns unequipped)
- `unequip_slot(slot: Enums.EquipmentSlot)` → ItemData
- `swap_items(slot_a, slot_b)` → int (atomic operation, prevents duplication)

**Stacking Logic:**
- Stackable items group together
- Non-stackable items take individual slots
- Stack count clamped to `max_stack`

---

## 7. DATABASE SYSTEMS

### ItemDatabase (autoload/item_database.gd)

**Purpose:** Central registry for all items

**Registry:**
- `_items`: Dictionary[item_id → ItemData]

**Key Methods:**
- `register_item(item: ItemData)` → void
- `get_item(item_id: String)` → ItemData (returns duplicate)
- `find_by_type(item_type: Enums.ItemType)` → Array[ItemData]
- `find_by_rarity(rarity: Enums.Rarity)` → Array[ItemData]
- `find_by_name(name: String)` → Array[ItemData]

**Auto-Loading:**
- Loads from: `res://resources/items/equipment/`
- Loads from: `res://resources/items/grimoires/`
- Loads from: `res://resources/items/potions/`

### GemDatabase (autoload/gem_database.gd)

**Purpose:** Central registry for all gems

Similar structure to ItemDatabase, loads from `res://resources/items/gems/`

---

## 8. STAT APPLICATION FLOW

### When Equipment is Equipped:

```
1. Player equips item (EquipmentData)
2. EquipmentData.apply_to_stats(stats_component) called
3. For each stat bonus:
   - Creates modifier with ID: "equip_[item_id]_[stat_type]"
   - Adds modifier to StatsComponent
   - stats_component._get_modified_stat() recalculates
4. Equipment icon shows in UI
5. Player gets stat bonuses immediately

When Unequipped:
1. Call EquipmentData.remove_from_stats(stats_component)
2. Removes all modifiers created by that equipment
3. Stats recalculate to baseline
```

---

## 9. FILE STRUCTURE & KEY FILES

### Directory Structure:
```
resources/
├── items/
│   ├── equipment/      # EquipmentData .tres files
│   ├── grimoires/      # GrimoireEquipmentData .tres files
│   ├── gems/           # GemData .tres files
│   ├── potions/        # PotionData .tres files
│   ├── parts/          # StaffPartData .tres files
│   │   ├── heads/
│   │   ├── exteriors/
│   │   ├── handles/
│   │   ├── interiors/
│   │   └── charms/
│   └── [class files]:
│       ├── item_data.gd
│       ├── equipment_data.gd
│       ├── staff_part_data.gd
│       ├── consumable_data.gd
│       ├── potion_data.gd
│       └── grimoire_data.gd

scripts/
├── data/
│   ├── enums.gd        # All enumerations including Rarity, ItemType, StatType
│   └── constants.gd    # All constants including RARITY_WEIGHTS, RARITY_STAT_MULTIPLIERS
├── systems/
│   ├── loot_system.gd
│   ├── inventory_system.gd
│   ├── coop_loot_system.gd
│   ├── crafting_*.gd   # Multiple crafting-related systems
│   └── loot_pickup.gd
└── components/
    └── stats_component.gd

autoload/
├── item_database.gd    # Central item registry
├── gem_database.gd     # Central gem registry
└── [other managers]
```

---

## 10. RECOMMENDED EXTENSION POINTS FOR RANDOMIZATION

### Priority 1: Item Stats Generation
**File:** Create new `scripts/systems/item_generation_system.gd`

**Responsibilities:**
1. Generate random stat ranges based on:
   - Item base stats
   - Rarity tier
   - Item level
   - Equipment slot

2. Apply variance formula:
   ```
   final_stat = base_stat * rarity_multiplier + random_variance
   ```

3. Support per-stat variance percentages

### Priority 2: Affix System
**File:** Create new `resources/items/affix_system.gd`

**Responsibilities:**
1. Define prefixes/suffixes for items
2. Apply multiple affixes per rarity:
   - BASIC: 0 affixes
   - UNCOMMON: 1 affix
   - RARE: 2 affixes
   - MYTHIC: 3 affixes
   - PRIMORDIAL: 4 affixes
   - UNIQUE: Named + special affixes

3. Track affix pools by item type

### Priority 3: Loot Table Enhancement
**File:** Enhance `scripts/systems/loot_system.gd`

**Responsibilities:**
1. Support rarity-weighted stat generation
2. Support leveled loot scaling
3. Support guaranteed/optional affix rolls

### Priority 4: Crafted Item System
**File:** Integrate with existing `scripts/systems/crafting_*.gd`

**Responsibilities:**
1. Generate unique items from crafting recipes
2. Support deterministic + random components
3. Support rarity escalation through crafting

---

## 11. SUMMARY TABLE

| Aspect | Location | Status |
|--------|----------|--------|
| **Rarity Tiers** | Enums, Constants | Fully Defined (6 tiers) |
| **Rarity Weighting** | Constants | Implemented |
| **Stat Multipliers** | Constants | Implemented (1.0x - 2.5x) |
| **Item Classes** | resources/items/*.gd | Comprehensive inheritance |
| **Stat System** | StatsComponent | Modifier-based, flexible |
| **Stat Types** | Enums.StatType | 12 types defined |
| **Loot Drops** | LootSystem | Weighted random implemented |
| **Equipment Application** | InventorySystem | Working with StatsComponent |
| **Item Database** | ItemDatabase | Auto-loading from .tres |
| **Randomization** | LootSystem | Basic (rarity + stack count) |
| **Item Generation** | NONE (ready to implement) | - |
| **Affix System** | NONE (ready to implement) | - |
| **Scaling/Progression** | Partially (level_required) | Limited |

---

## 12. DESIGN PATTERNS OBSERVED

1. **Composition over Inheritance**: Equipment applies stats via modifiers, not direct property changes
2. **Resource-Based**: All items are .tres resources, easy to create variants
3. **Centralized Enums**: All gameplay constants in one place (Enums, Constants)
4. **Auto-Loading**: Databases scan directories for .tres files
5. **Modifier Pattern**: Stats don't change items, modifiers track changes
6. **Type Safety**: Heavy use of typed properties and enums

