# MageWar Item/Equipment System - Quick Reference

## Quick Lookups

### 1. Finding Key Files

**Rarity System Definition:**
- `/home/shobie/magewar/scripts/data/enums.gd` → Line 47 (Enums.Rarity)
- `/home/shobie/magewar/scripts/data/constants.gd` → Lines 87-114 (RARITY_WEIGHTS, RARITY_STAT_MULTIPLIERS, RARITY_COLORS)

**Item Classes:**
- `/home/shobie/magewar/resources/items/item_data.gd` → Base class (71 lines)
- `/home/shobie/magewar/resources/items/equipment_data.gd` → Equipment (126 lines)
- `/home/shobie/magewar/resources/items/staff_part_data.gd` → Weapon parts (127 lines)
- `/home/shobie/magewar/resources/spells/gem_data.gd` → Gems (132 lines)
- `/home/shobie/magewar/resources/items/potion_data.gd` → Potions (236 lines)

**Stats System:**
- `/home/shobie/magewar/scripts/components/stats_component.gd` → Core stats (330 lines)

**Loot & Inventory:**
- `/home/shobie/magewar/scripts/systems/loot_system.gd` → Loot drops (147 lines)
- `/home/shobie/magewar/scripts/systems/inventory_system.gd` → Inventory management (517 lines)

**Databases:**
- `/home/shobie/magewar/autoload/item_database.gd` → Item registry (131 lines)
- `/home/shobie/magewar/autoload/gem_database.gd` → Gem registry (129 lines)

---

## 2. Creating Items Programmatically

### Creating Equipment

```gdscript
var boots = EquipmentData.new()
boots.item_id = "boots_leather"
boots.item_name = "Leather Boots"
boots.rarity = Enums.Rarity.UNCOMMON
boots.slot = Enums.EquipmentSlot.FEET
boots.health_bonus = 10.0
boots.move_speed_bonus = 0.15  # +15%
boots.base_value = 100
boots.level_required = 5

# Add to inventory
player.inventory.add_item(boots)
```

### Creating a Gem

```gdscript
var fire_gem = GemData.new()
fire_gem.item_id = "gem_fire_basic"
fire_gem.gem_name = "Fire Shard"
fire_gem.element = Enums.Element.FIRE
fire_gem.converts_element = true
fire_gem.damage_multiplier = 1.2
fire_gem.rarity = Enums.Rarity.BASIC

player.inventory.add_item(fire_gem)
```

### Creating a Potion

```gdscript
var health_potion = PotionData.new()
health_potion.item_id = "potion_health_small"
health_potion.item_name = "Minor Health Potion"
health_potion.instant_health = 50
health_potion.rarity = Enums.Rarity.BASIC
health_potion.stackable = true
health_potion.max_stack = 99
health_potion.level_required = 1

player.inventory.add_item(health_potion)
```

---

## 3. Working with Rarity

### Get Rarity Color
```gdscript
var item = player.inventory.get_item(0)
var color = item.get_rarity_color()
# color == Constants.RARITY_COLORS[item.rarity]
```

### Get Rarity Name
```gdscript
var rarity_name = Enums.rarity_to_string(item.rarity)
# "Rare", "Mythic", etc.
```

### Calculate Rarity-Adjusted Value
```gdscript
var gold_value = item.get_value()
# Automatically applies Constants.RARITY_STAT_MULTIPLIERS
```

### Roll Random Rarity
```gdscript
# Internally used by LootSystem
var rarity = rng._roll_rarity()  # Private method in LootSystem
# Or implement your own:

func roll_rarity() -> Enums.Rarity:
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

---

## 4. Stat Modifiers

### Add Stat Modifier
```gdscript
# When equipment is equipped, internally:
var stats = player.get_node("StatsComponent")

# Additive (absolute value)
stats.add_modifier(Enums.StatType.DEFENSE, "equip_boots_defense", 20.0, false)

# Percentage (relative)
stats.add_modifier(Enums.StatType.MOVE_SPEED, "equip_boots_speed", 0.15, true)
```

### Remove Modifier
```gdscript
stats.remove_modifier(Enums.StatType.DEFENSE, "equip_boots_defense")
stats.remove_modifier(Enums.StatType.MOVE_SPEED, "equip_boots_speed")
```

### Get Modified Stat Value
```gdscript
var defense = stats.get_stat(Enums.StatType.DEFENSE)
# Returns: base_defense + additive_bonuses * (1 + percentage_bonuses)
```

---

## 5. Equipping Items

### Equip Equipment

```gdscript
var inventory = player.get_node("InventorySystem")
var boots = inventory.get_item(0)  # From slot 0

# Equip and get previously equipped item
var old_boots = inventory.equip_item(boots, 0)  # 0 = from_inventory_slot

# Stats automatically applied via EquipmentData.apply_to_stats()
```

### Unequip Equipment

```gdscript
# Get unequipped item from slot
var old_item = inventory.unequip_slot(Enums.EquipmentSlot.FEET)

# Or unequip directly to inventory
if inventory.unequip_to_inventory(Enums.EquipmentSlot.FEET):
    print("Unequipped successfully")
else:
    print("Inventory full!")
```

---

## 6. Loot System

### Drop Loot
```gdscript
var loot_system = LootSystem.new()
var item = ItemDatabase.get_item("health_potion_basic")

# Drop single item
loot_system.drop_loot(item, enemy.global_position)
```

### Drop from Loot Table
```gdscript
var loot_table = [
    {
        "item": ItemDatabase.get_item("health_potion"),
        "weight": 50,
        "min": 1,
        "max": 3
    },
    {
        "item": ItemDatabase.get_item("mana_potion"),
        "weight": 30,
        "min": 1,
        "max": 2
    },
    {
        "item": ItemDatabase.get_item("rare_scroll"),
        "weight": 20,
        "min": 1,
        "max": 1,
        "fixed_rarity": Enums.Rarity.RARE  # Don't roll rarity for this
    }
]

var drops = loot_system.drop_loot_from_table(loot_table, position, count = 2)
# Returns array of dropped items
```

---

## 7. Stat Types Available

```gdscript
# From Enums.StatType:
Enums.StatType.HEALTH              # Current health
Enums.StatType.MAGIKA              # Current magika
Enums.StatType.STAMINA             # Current stamina
Enums.StatType.HEALTH_REGEN        # HP per second
Enums.StatType.MAGIKA_REGEN        # Magika per second
Enums.StatType.STAMINA_REGEN       # Stamina per second
Enums.StatType.MOVE_SPEED          # Movement speed (percentage)
Enums.StatType.CAST_SPEED          # Cast speed (percentage)
Enums.StatType.DAMAGE              # Damage output (absolute)
Enums.StatType.DEFENSE             # Damage reduction (absolute)
Enums.StatType.CRITICAL_CHANCE     # Crit % (0.0-1.0)
Enums.StatType.CRITICAL_DAMAGE     # Crit multiplier
```

---

## 8. Equipment Slots

```gdscript
# Available slots:
Enums.EquipmentSlot.HEAD           # Hat
Enums.EquipmentSlot.BODY           # Armor/clothes
Enums.EquipmentSlot.BELT           # Belt
Enums.EquipmentSlot.FEET           # Boots/shoes
Enums.EquipmentSlot.PRIMARY_WEAPON   # Main weapon
Enums.EquipmentSlot.SECONDARY_WEAPON # Offhand weapon
Enums.EquipmentSlot.GRIMOIRE       # Spell book
Enums.EquipmentSlot.POTION         # Quick potion slot
```

---

## 9. Constants Reference

### Rarity Weights (higher = more common)
```gdscript
Constants.RARITY_WEIGHTS = {
    Enums.Rarity.BASIC: 100,
    Enums.Rarity.UNCOMMON: 50,
    Enums.Rarity.RARE: 20,
    Enums.Rarity.MYTHIC: 5,
    Enums.Rarity.PRIMORDIAL: 1,
    Enums.Rarity.UNIQUE: 0  # Never drops randomly
}
```

### Rarity Stat Multipliers
```gdscript
Constants.RARITY_STAT_MULTIPLIERS = {
    Enums.Rarity.BASIC: 1.0,
    Enums.Rarity.UNCOMMON: 1.15,
    Enums.Rarity.RARE: 1.35,
    Enums.Rarity.MYTHIC: 1.6,
    Enums.Rarity.PRIMORDIAL: 2.0,
    Enums.Rarity.UNIQUE: 2.5
}
```

### Colors
```gdscript
Constants.RARITY_COLORS = {
    Enums.Rarity.BASIC: Color.WHITE,
    Enums.Rarity.UNCOMMON: Color.GREEN,
    Enums.Rarity.RARE: Color.DODGER_BLUE,
    Enums.Rarity.MYTHIC: Color.MEDIUM_PURPLE,
    Enums.Rarity.PRIMORDIAL: Color.ORANGE,
    Enums.Rarity.UNIQUE: Color.GOLD
}
```

---

## 10. Common Patterns

### Check if Player Can Equip Item
```gdscript
func can_equip(item: ItemData, player) -> bool:
    if not item is EquipmentData:
        return false
    
    var stats = player.get_node("StatsComponent")
    if stats.get_stat(Enums.StatType.HEALTH) < 1:  # Dead
        return false
    
    if item.level_required > player.level:
        return false
    
    return true
```

### Find Best Equipment in Inventory
```gdscript
func find_best_armor(inventory: InventorySystem) -> EquipmentData:
    var best: EquipmentData = null
    var best_value = 0
    
    for item in inventory.inventory:
        if item and item is EquipmentData:
            var value = item.get_value()
            if value > best_value:
                best = item
                best_value = value
    
    return best
```

### Create Rarity Scaled Item
```gdscript
func create_scaled_item(base_item: ItemData, rarity: Enums.Rarity) -> ItemData:
    var item = base_item.duplicate_item()
    item.rarity = rarity
    
    # Scale up stat bonuses if EquipmentData
    if item is EquipmentData:
        var multiplier = Constants.RARITY_STAT_MULTIPLIERS[rarity]
        item.health_bonus *= multiplier
        item.defense_bonus *= multiplier
        item.damage_bonus *= multiplier
        # ... etc for other bonuses
    
    return item
```

---

## 11. Item Creation Paths

### Creating .tres Resources (Recommended)
1. Right-click in FileSystem → New Resource
2. Select ItemData (or subclass)
3. Set properties in Inspector
4. Save as `resources/items/[type]/name.tres`
5. Automatically loads on game start via ItemDatabase

### Creating Programmatically
```gdscript
var item = EquipmentData.new()
item.item_id = "custom_item"
# Set properties...
ItemDatabase.register_item(item)  # Add to registry
```

---

## 12. Key Formulas

### Stat Calculation
```
final_stat = (base_stat + additive_modifiers) * (1 + percentage_modifiers)
```

### Item Value
```
gold_value = base_value * RARITY_STAT_MULTIPLIERS[rarity]
```

### Damage After Defense
```
actual_damage = max(base_damage - defense, base_damage * 0.1)
```

---

## 13. Import Statements for New Scripts

```gdscript
# Use these at the top of new scripts working with items:

# Data structures
extends Node
class_name MyItemSystem

# Access item data
var item: ItemData
var equipment: EquipmentData
var gem: GemData
var potion: PotionData

# Access systems
var inventory: InventorySystem
var stats: StatsComponent
var loot_system: LootSystem

# Access databases
var item_db = ItemDatabase
var gem_db = GemDatabase

# Access constants
var rarity = Enums.Rarity
var stat_type = Enums.StatType
var equipment_slot = Enums.EquipmentSlot
```

