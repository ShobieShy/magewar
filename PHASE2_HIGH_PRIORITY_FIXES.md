# PHASE 2: HIGH PRIORITY FIXES (URGENT)
**Estimated Time:** 1 day  
**Priority:** 🟠 HIGH - Core functionality broken, but blocking less systems than Phase 1  
**Status:** ⏳ Blocked until Phase 1 completes

---

## Overview
These fixes address broken core functionality that impacts developer experience and critical game systems. They should be completed immediately after Phase 1.

---

## Task 1: Document All 18 Autoload Systems

**File:** `project.godot:19-38` and `README.md`

### Problem
6 of 18 autoload systems are declared in `project.godot` but completely undocumented in README:

**Undocumented Autoloads:**
1. DungeonPortalSystem
2. EnemySpawnSystem
3. DungeonTemplateSystem
4. SpellNetworkManager
5. SaveNetworkManager
6. CraftingRecipeManager

**Impact:**
- Developers can't find these systems in documentation
- No API reference for critical systems
- Makes debugging and feature additions difficult
- Onboarding confusion

### Files to Document

```
File: /home/shobie/magewar/scripts/systems/dungeon_portal_system.gd
  Purpose: Manage dungeon portal entry/exit
  Key Methods: enter_dungeon(), exit_dungeon()
  Signals: [To be determined]

File: /home/shobie/magewar/scripts/systems/enemy_spawn_system.gd
  Purpose: Spawn enemies in dungeons
  Key Methods: [To be determined]
  Signals: [To be determined]

File: /home/shobie/magewar/scripts/systems/dungeon_template_system.gd
  Purpose: Generate dungeon room layouts
  Key Methods: [To be determined]
  Signals: [To be determined]

File: /home/shobie/magewar/scripts/systems/spell_network_manager.gd
  Purpose: Synchronize spell casting across network
  Key Methods: [To be determined]
  Signals: [To be determined]

File: /home/shobie/magewar/scripts/systems/save_network_manager.gd
  Purpose: Synchronize save data in multiplayer
  Key Methods: [To be determined]
  Signals: [To be determined]

File: /home/shobie/magewar/scripts/systems/crafting_recipe_manager.gd
  Purpose: Manage crafting recipe database
  Key Methods: [To be determined]
  Signals: [To be determined]
```

### Solution

1. **Investigate each undocumented autoload:**
   - Read the script file
   - Identify purpose (class comment or `_ready()` method)
   - Document key methods
   - Document signals
   - Document usage example

2. **Add to README.md:**
   - Extend the "Autoload Managers" table (lines 95-113)
   - Add 6 new rows for undocumented systems
   - Include Purpose and Key Methods columns

3. **Example format:**
```markdown
| **DungeonPortalSystem** | Portal entry/exit management | `enter_dungeon()`, `exit_dungeon()` |
| **EnemySpawnSystem** | Spawn enemies in dungeons | `spawn_enemies()`, `clear_spawned()` |
| **DungeonTemplateSystem** | Generate room layouts | `generate_room()`, `get_template()` |
| **SpellNetworkManager** | Sync spell casting | `send_spell_cast()`, `receive_spell_cast()` |
| **SaveNetworkManager** | Sync save data | `sync_save()`, `validate_save()` |
| **CraftingRecipeManager** | Recipe database | `get_recipe()`, `validate_recipe()` |
```

### Acceptance Criteria
- [ ] All 18 autoloads documented in README
- [ ] Each has Purpose and Key Methods listed
- [ ] Usage examples provided for all 6 previously undocumented systems
- [ ] Documentation accurate (tested by reading actual code)

### Test Plan
```gdscript
# In debug console:
print(DungeonPortalSystem)      # Should print instance
print(EnemySpawnSystem)         # Should print instance
print(DungeonTemplateSystem)    # Should print instance
print(SpellNetworkManager)      # Should print instance
print(SaveNetworkManager)       # Should print instance
print(CraftingRecipeManager)    # Should print instance
```

---

## Task 2: Add Missing Player Convenience Methods

**File:** `scenes/player/player.gd`

### Problem
README documents these convenience methods on Player, but they don't exist:

| Method | Expected Use | Current Location |
|---|---|---|
| `get_stat(stat_name: String) -> float` | Get player stats | `stats: StatsComponent` (scattered) |
| `equip_item(item: ItemData, slot: EquipmentSlot)` | Equip items | `_inventory_system: InventorySystem` |
| `grant_xp(amount: int)` | Award weapon XP | `WeaponLevelingSystem` (autoload) |
| `take_damage(amount: float)` | Apply damage | `stats: StatsComponent` |

### Impact
- Code using documented API crashes with "method not found"
- Inconsistent API design (methods scattered across objects)
- Developers follow README and get errors

### Solution

**Option A (Recommended):** Add convenience methods to Player

Add these methods to `player.gd`:

```gdscript
## Get a player stat by name
func get_stat(stat_name: String) -> float:
    if stats:
        return stats.get_stat(stat_name)
    return 0.0

## Equip item to slot
func equip_item(item: ItemData, slot: EquipmentSlot) -> bool:
    if _inventory_system:
        return _inventory_system.equip_item(item, slot)
    return false

## Grant XP to current primary weapon
func grant_xp(amount: int) -> void:
    if WeaponLevelingSystem:
        var weapon = get_primary_weapon()
        if weapon:
            WeaponLevelingSystem.grant_xp_to_weapon(weapon, amount)

## Apply damage to player
func take_damage(amount: float) -> void:
    if stats:
        stats.take_damage(amount)

## Helper to get primary weapon
func get_primary_weapon() -> Node:
    # Implementation depends on your weapon system
    # e.g., return equipment.get_equipment(EquipmentSlot.PRIMARY_WEAPON)
    pass
```

**Option B:** Update README to reflect actual API
- Change code examples to use scattered methods
- Document each component separately
- Less clean but requires less code changes

### Acceptance Criteria
- [ ] `Player.get_stat()` method exists and works
- [ ] `Player.equip_item()` method exists and works
- [ ] `Player.grant_xp()` method exists and works
- [ ] `Player.take_damage()` method exists and works
- [ ] All methods properly delegate to underlying systems
- [ ] README code examples match implementation

### Test Plan
```gdscript
# In debug console or test script:
var player = get_tree().get_first_node_in_group("player")

# Should work:
var health = player.get_stat("health")
player.take_damage(10)
var new_health = player.get_stat("health")
assert(new_health == health - 10)

# Should work:
var item = ItemDatabase.get_item("fire_staff")
player.equip_item(item, EquipmentSlot.PRIMARY_WEAPON)

# Should work:
player.grant_xp(50)
```

---

## Task 3: Verify SaveManager Method Consistency

**File:** `autoload/save_manager.gd`

### Problem
SaveManager actual methods don't match documentation/code calls:

**What SaveManager Actually Has:**
```gdscript
✅ func save_all() -> void
✅ func save_player_data() -> void
✅ func save_world_data() -> void
✅ func load_player_data() -> void
✅ func load_world_data() -> void
```

**What Documentation/Code May Call:**
```gdscript
❌ SaveManager.save_game()    # Doesn't exist
❌ SaveManager.load_game()    # Doesn't exist
```

### Impact
- Callers using documented API crash: "method not found"
- Multiplayer save sync broken
- Save system inconsistent

### Solution

**Step 1:** Search codebase for SaveManager method calls
```bash
# Find all SaveManager calls
grep -r "SaveManager\." /home/shobie/magewar --include="*.gd" | grep -v "^\s*#"
```

**Step 2:** Decide on naming convention
- **Option A:** Rename SaveManager methods to `save_game()` / `load_game()`
- **Option B:** Update all callers to use `save_all()` / `load_player_data()`

**Step 3:** Apply consistently
- Update SaveManager.gd with final method names
- Update all callers
- Update documentation

### Acceptance Criteria
- [ ] SaveManager has consistent method naming
- [ ] All callers use correct method names
- [ ] No "method not found" errors when calling SaveManager
- [ ] Save/load works in single player
- [ ] Save sync works in multiplayer
- [ ] Documentation matches implementation

### Test Plan
```gdscript
# In debug console:
SaveManager.save_game()      # Should work (whichever choice)
SaveManager.load_game()      # Should work (whichever choice)

# Verify it actually saves/loads:
var player = get_tree().get_first_node_in_group("player")
var initial_level = player.level
SaveManager.save_game()
player.level = 99
SaveManager.load_game()
assert(player.level == initial_level)  # Should be restored
```

---

## Completion Checklist

- [ ] Task 1: All 18 autoloads documented in README
  - [ ] DungeonPortalSystem documented
  - [ ] EnemySpawnSystem documented
  - [ ] DungeonTemplateSystem documented
  - [ ] SpellNetworkManager documented
  - [ ] SaveNetworkManager documented
  - [ ] CraftingRecipeManager documented

- [ ] Task 2: Player convenience methods added/verified
  - [ ] `get_stat()` works
  - [ ] `equip_item()` works
  - [ ] `grant_xp()` works
  - [ ] `take_damage()` works

- [ ] Task 3: SaveManager consistency verified
  - [ ] All methods consistently named
  - [ ] All callers use correct method names
  - [ ] Save/load works in single and multiplayer

---

## Verification Steps

After completing all tasks:

1. **Documentation Check**
   - [ ] Open README.md
   - [ ] Verify all 18 autoloads in table (lines 95-113)
   - [ ] Verify 6 new entries added with purpose and methods

2. **Player Methods Check**
   - [ ] Open `player.gd`
   - [ ] Verify `get_stat()` method exists
   - [ ] Verify `equip_item()` method exists
   - [ ] Verify `grant_xp()` method exists
   - [ ] Verify `take_damage()` method exists

3. **SaveManager Check**
   - [ ] Open `save_manager.gd`
   - [ ] List all public methods
   - [ ] Verify naming consistency
   - [ ] Search codebase for method calls
   - [ ] Verify all calls match actual methods

4. **Integration Test**
   - [ ] Run game
   - [ ] Equip item using `Player.equip_item()`
   - [ ] Check stats using `Player.get_stat()`
   - [ ] Damage player using `Player.take_damage()`
   - [ ] Save game
   - [ ] Load game
   - [ ] Verify save/load worked

---

**Previous Phase:** [PHASE1_CRITICAL_FIXES.md](PHASE1_CRITICAL_FIXES.md)  
**Next Phase:** [PHASE3_MEDIUM_PRIORITY_FIXES.md](PHASE3_MEDIUM_PRIORITY_FIXES.md)
