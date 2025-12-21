# PHASE 3: MEDIUM PRIORITY FIXES (IMPORTANT)
**Estimated Time:** 1-2 days  
**Priority:** 🟡 MEDIUM - Improves stability and balancing  
**Status:** ⏳ Blocked until Phase 1 & 2 complete

---

## Overview
These fixes improve game stability, balance, and code quality. They're important but less critical than Phases 1-2. Focus on correctness and data integrity.

---

## Task 1: Implement Element Advantage Logic

**File:** `scripts/components/spell_caster.gd`

### Problem
README documents element advantage system with 25% damage bonus, but code doesn't implement the calculation:

**Expected Behavior:**
```
Fire vs Air (strong):    Damage × 1.25 = 25% bonus
Fire vs Water (weak):    Damage × 0.75 = 25% penalty
Fire vs Fire (neutral):  Damage × 1.0  = No bonus
Fire vs Light/Dark:      Damage × 1.0  = No advantage
```

**Current State:**
- No element advantage calculation in `spell_caster.gd`
- Damage calculations wrong
- Game balance broken

### Rock-Paper-Scissors System

**Advantage Matrix:**
```
Fire   > Air      (Fire burns through air)
Air    > Earth    (Wind erodes stone)
Earth  > Water    (Ground absorbs water)
Water  > Fire     (Water extinguishes flames)

Light ↔ Dark      (Balanced opposition, no advantage)
```

### Implementation Location

Add to `spell_caster.gd` in damage calculation:

```gdscript
## Calculate final spell damage with element advantage
func calculate_spell_damage(
    base_damage: float,
    caster_element: int,      # Element enum value
    target_element: int       # Target element type
) -> float:
    var total_damage = base_damage
    
    # Apply element advantage/disadvantage
    var advantage_multiplier = get_element_advantage(caster_element, target_element)
    total_damage *= advantage_multiplier
    
    return total_damage

## Get damage multiplier based on element matchup
func get_element_advantage(attacker_element: int, defender_element: int) -> float:
    # Constants from enums.gd
    var ADVANTAGE = Constants.ELEMENT_ADVANTAGE        # 1.25
    var DISADVANTAGE = Constants.ELEMENT_DISADVANTAGE # 0.75
    
    # Fire > Air
    if attacker_element == Element.FIRE and defender_element == Element.AIR:
        return ADVANTAGE
    
    # Air > Earth
    if attacker_element == Element.AIR and defender_element == Element.EARTH:
        return ADVANTAGE
    
    # Earth > Water
    if attacker_element == Element.EARTH and defender_element == Element.WATER:
        return ADVANTAGE
    
    # Water > Fire
    if attacker_element == Element.WATER and defender_element == Element.FIRE:
        return ADVANTAGE
    
    # Light/Dark: No advantage (balanced)
    if attacker_element == Element.LIGHT or attacker_element == Element.DARK:
        return 1.0
    
    # Check for disadvantage (reverse logic)
    var reverse_advantage = get_element_advantage(defender_element, attacker_element)
    if reverse_advantage > 1.0:
        return DISADVANTAGE
    
    # Neutral matchup
    return 1.0
```

### Integration Points

**1. In `cast_spell()` method:**
```gdscript
func cast_spell(spell: SpellData, target: Node3D) -> void:
    var base_damage = spell.base_damage
    var caster_element = spell.element
    var target_element = get_target_element(target)
    
    var final_damage = calculate_spell_damage(base_damage, caster_element, target_element)
    
    # Apply damage (continue as before)
    apply_spell_damage(target, final_damage)
```

**2. Helper method to detect target element:**
```gdscript
func get_target_element(target: Node3D) -> int:
    # If target has element (e.g., enemy with elemental affinity)
    if target.has_method("get_element"):
        return target.get_element()
    
    # Default: neutral (no advantage)
    return Element.EARTH  # or create NEUTRAL constant
```

### Acceptance Criteria
- [ ] Element advantage calculation implemented
- [ ] Fire > Air tested (1.25x multiplier)
- [ ] Air > Earth tested (1.25x multiplier)
- [ ] Earth > Water tested (1.25x multiplier)
- [ ] Water > Fire tested (1.25x multiplier)
- [ ] Reverse logic gives disadvantage (0.75x)
- [ ] Light/Dark return neutral (1.0x)
- [ ] Constants ELEMENT_ADVANTAGE and ELEMENT_DISADVANTAGE used

### Test Plan

```gdscript
# In debug console:
var spell_caster = player.spell_caster

# Fire vs Air (should get 1.25x)
var fire_damage = spell_caster.calculate_spell_damage(100, Element.FIRE, Element.AIR)
assert(fire_damage == 125.0)

# Fire vs Water (should get 0.75x)
var weak_damage = spell_caster.calculate_spell_damage(100, Element.FIRE, Element.WATER)
assert(weak_damage == 75.0)

# Light vs Dark (should get 1.0x)
var light_damage = spell_caster.calculate_spell_damage(100, Element.LIGHT, Element.DARK)
assert(light_damage == 100.0)
```

---

## Task 2: Complete/Verify Crafting System

**File:** `scripts/systems/crafting_*.gd`

### Problem
Uncertain if all crafting features are fully implemented. Need comprehensive audit.

**Files to Check:**
- `crafting_manager.gd` - Orchestration
- `crafting_logic.gd` - Core recipe validation
- `weapon_configuration.gd` - Spell core + parts assembly
- `crafting_recipe_manager.gd` - Recipe database

### Verification Checklist

**1. Core Functionality:**
- [ ] Player can select spell core from inventory
- [ ] Player can add modifier parts (Exterior, Interior, Handle, Head, Charm)
- [ ] Player can add gems to gem slots
- [ ] Weapon configuration validates correctly
- [ ] Crafted weapon stats calculate correctly

**2. Stat Calculations:**
- [ ] Base damage = Spell core damage × rarity multiplier
- [ ] Interior parts apply damage bonus
- [ ] Exterior parts apply fire rate bonus
- [ ] Handle parts apply accuracy bonus
- [ ] Head parts apply gem slot count
- [ ] Charm parts apply element bonuses
- [ ] Gems apply secondary effects

**3. Rarity System:**
- [ ] BASIC: 1.0x multiplier
- [ ] UNCOMMON: 1.2x multiplier
- [ ] RARE: 1.5x multiplier
- [ ] MYTHIC: 1.8x multiplier
- [ ] PRIMORDIAL: 2.2x multiplier
- [ ] UNIQUE: 2.5x multiplier

**4. Recipe Discovery:**
- [ ] New weapon combinations unlock achievements
- [ ] Recipe book tracks discovered patterns
- [ ] UI shows new recipes as "?" before discovery

**5. Validation:**
- [ ] Can't craft without spell core
- [ ] Can't add more gems than head allows
- [ ] Can't equip crafted weapon if wrong type
- [ ] Weapon stats reasonable (not overflow)

### Detailed Audit Steps

**Step 1: Test Basic Crafting**
```gdscript
# In test scene or debug console:
var fire_core = ItemDatabase.get_item("rare_fire_core")
var exterior = ItemDatabase.get_item("oak_exterior")
var interior = ItemDatabase.get_item("silver_interior")
var handle = ItemDatabase.get_item("master_grip")

var config = WeaponConfiguration.new()
config.spell_core = fire_core
config.add_part(exterior)
config.add_part(interior)
config.add_part(handle)

var crafted = CraftingManager.craft_weapon(config)
assert(crafted != null)
assert(crafted.element == Element.FIRE)
assert(crafted.rarity == ItemRarity.RARE)
```

**Step 2: Test Stat Calculation**
```gdscript
var stats = crafted.get_stats()
var expected_damage = 50 * 1.5 * 1.1 * 1.0  # base × rare × interior × exterior
assert(stats.damage >= expected_damage - 1 and stats.damage <= expected_damage + 1)
```

**Step 3: Test Gem System**
```gdscript
var gem = ItemDatabase.get_item("fire_gem")
config.add_gem(gem, 0)  # Add to first slot
var with_gem = CraftingManager.craft_weapon(config)
assert(with_gem.gems.size() == 1)
```

**Step 4: Test Validation**
```gdscript
var bad_config = WeaponConfiguration.new()  # No spell core
var errors = bad_config.validate()
assert(errors.size() > 0)
assert("No spell core" in errors)
```

### Issue Resolution

**If Feature Complete:**
- [ ] Document feature in README (update crafting section)
- [ ] Add usage example to QUICK_REFERENCE.md

**If Features Missing:**
Document what's missing and create follow-up tasks

### Acceptance Criteria
- [ ] Crafting system 100% audited
- [ ] All features working or documented as missing
- [ ] Test script passes all checks
- [ ] README accurately describes crafting

---

## Task 3: Add Missing Type Hints

**File:** `scenes/player/player.gd`

### Problem
Only 81% of methods have type hints (21/26 functions).

**Current Coverage:**
```
Type Hints: 21/26 functions (81%)
Missing: 5 functions without return type annotations
```

### Missing Type Hints

Identify and add return types to all methods:

```gdscript
# ❌ Before
func take_damage(amount: float):
    health -= amount

# ✅ After
func take_damage(amount: float) -> void:
    health -= amount
```

### Solution

**Step 1:** Find all methods in `player.gd` without return type
```bash
grep -n "^[[:space:]]*func " /home/shobie/magewar/scenes/player/player.gd | grep -v " -> "
```

**Step 2:** Add return type to each method
- `-> void` - Returns nothing
- `-> float` - Returns number
- `-> bool` - Returns true/false
- `-> Node` - Returns node reference
- `-> Array` - Returns array
- `-> Dictionary` - Returns dictionary

**Step 3:** Update parameter types if missing
```gdscript
# ❌ Incomplete
func equip_item(item, slot):

# ✅ Complete
func equip_item(item: ItemData, slot: EquipmentSlot) -> bool:
```

### Type Hint Best Practices

**Variable declarations:**
```gdscript
var health: float = 100.0
var inventory: Array[ItemData] = []
var equipped: Dictionary = {}
```

**Function returns:**
```gdscript
func get_health() -> float:
    return health

func get_inventory() -> Array[ItemData]:
    return inventory

func is_alive() -> bool:
    return health > 0
```

**Typed function parameters:**
```gdscript
func take_damage(amount: float) -> void:
    pass

func equip_item(item: ItemData, slot: EquipmentSlot) -> bool:
    return false
```

### Acceptance Criteria
- [ ] All methods in `player.gd` have return type annotation
- [ ] All parameters have type hints
- [ ] All variables have type hints
- [ ] Code compiles without type warnings
- [ ] Type coverage: 100% (26/26 functions)

### Test Plan
```bash
# Compile check
godot --check-gdscript /home/shobie/magewar/scenes/player/player.gd

# Should show 0 type hint warnings
```

---

## Completion Checklist

- [ ] Task 1: Element advantage logic implemented
  - [ ] `calculate_spell_damage()` method created
  - [ ] `get_element_advantage()` method created
  - [ ] Integrated into `cast_spell()`
  - [ ] Fire > Air tested
  - [ ] Air > Earth tested
  - [ ] Earth > Water tested
  - [ ] Water > Fire tested
  - [ ] Disadvantage (reverse) logic works
  - [ ] Light/Dark neutral tested

- [ ] Task 2: Crafting system audited and complete
  - [ ] Basic crafting workflow tested
  - [ ] Stat calculations verified
  - [ ] Rarity multipliers correct
  - [ ] Gem system working
  - [ ] Validation working
  - [ ] Recipe discovery working
  - [ ] No missing features identified

- [ ] Task 3: Type hints 100% complete
  - [ ] All methods have return types
  - [ ] All parameters typed
  - [ ] All variables typed
  - [ ] Zero type warnings

---

## Verification Steps

After completing all tasks:

1. **Element Advantage Check**
   - [ ] Test Fire > Air (1.25x)
   - [ ] Test Air > Earth (1.25x)
   - [ ] Test Earth > Water (1.25x)
   - [ ] Test Water > Fire (1.25x)
   - [ ] Test disadvantage (0.75x)
   - [ ] Test neutral (1.0x)

2. **Crafting System Check**
   - [ ] Create test weapon with crafting UI
   - [ ] Verify stat calculations match formula
   - [ ] Check gem system works
   - [ ] Verify validation catches errors

3. **Type Hints Check**
   - [ ] Open `player.gd`
   - [ ] Verify every `func` has `-> ReturnType`
   - [ ] Run godot type check (0 warnings)
   - [ ] Verify IDE autocomplete works

---

**Previous Phase:** [PHASE2_HIGH_PRIORITY_FIXES.md](PHASE2_HIGH_PRIORITY_FIXES.md)  
**Next Phase:** [PHASE4_LOW_PRIORITY_CLEANUP.md](PHASE4_LOW_PRIORITY_CLEANUP.md)
