# PHASE 1: CRITICAL FIXES (BLOCKING)
**Estimated Time:** 1-2 days  
**Priority:** 🔴 CRITICAL - Game cannot function without these fixes  
**Status:** ⏳ In Progress

---

## Overview
These fixes are blocking and must be completed before the game can be tested. Without them, core systems (combat, crafting, equipment, quests, dungeons) will not function.

---

## Task 1: Fix Element Enum System (9/10 Impact)

**File:** `scripts/data/enums.gd:101-115`

### Problem
- README documents 6-element system: FIRE, WATER, EARTH, **AIR**, LIGHT, DARK
- Code defines 13 elements: FIRE, ICE, LIGHTNING, EARTH, **WIND**, WATER, LIGHT, DARK, SHADOW, HOLY, ARCANE, POISON
- Missing AIR (breaks rock-paper-scissors balance)
- Extra undefined elements (ICE, LIGHTNING, SHADOW, HOLY, ARCANE, POISON)

### Impact Chain
1. Spell system uses elements for damage types → Broken
2. Crafting system uses elements for weapon cores → Broken
3. Element advantage calculations (25% bonus) → Can't work
4. Game balance completely broken
5. Combat damage calculations fail

### Affected Code
- `scripts/components/spell_caster.gd` - Uses elements
- `scripts/systems/crafting_logic.gd` - Validates elements
- `resources/spells/presets/` - 14 spell definitions
- `scenes/ui/menus/assembly_ui.gd` - Crafting UI
- All spell cores in `resources/items/spell_cores/`

### Solution
**Option A (Recommended):** Normalize to README specification
- Remove: ICE, LIGHTNING, SHADOW, HOLY, ARCANE, POISON
- Rename: WIND → AIR
- Keep: FIRE, WATER, EARTH, AIR, LIGHT, DARK

**Option B:** Update README to match code
- Document all 13 elements
- Explain rock-paper-scissors logic for each

### Acceptance Criteria
- [ ] Element enum has exactly 6 elements: FIRE, WATER, EARTH, AIR, LIGHT, DARK
- [ ] All spell caster references use correct element names
- [ ] All spell core resources validate against new enum
- [ ] Crafting system validates spell elements correctly
- [ ] Element advantage logic can be implemented

### Test Plan
```gdscript
# In debug console:
print(Element.FIRE)    # Should work
print(Element.AIR)     # Should work (not WIND)
print(Element.ICE)     # Should NOT exist
```

---

## Task 2: Fix EquipmentSlot Enum Naming (7/10 Impact)

**File:** `scripts/data/enums.gd:67-77`

### Problem
- README documents: `PRIMARY_WEAPON`, `SECONDARY_WEAPON`
- Code defines: `WEAPON_PRIMARY`, `WEAPON_SECONDARY`
- Creates silent failures in equipment assignment

### Impact
1. Equipment assignment uses wrong enum values
2. Save files have incompatible slot data
3. Equipment validation fails
4. Crafted weapons can't be equipped
5. UI binding breaks silently

### Affected Code
- `scenes/player/player.gd:65` - Equipment slot setup
- `scripts/systems/inventory_system.gd` - Equipment operations
- All equipment UI code

### Solution
**Standardize naming convention:** Choose ONE and apply everywhere

**Option A (Recommended):** Use README naming (PRIMARY_WEAPON, SECONDARY_WEAPON)
```gdscript
enum EquipmentSlot {
    HEAD,
    BODY,
    BELT,
    FEET,
    PRIMARY_WEAPON,      # Instead of WEAPON_PRIMARY
    SECONDARY_WEAPON,    # Instead of WEAPON_SECONDARY
    GRIMOIRE,
    POTION
}
```

**Option B:** Use code naming (WEAPON_PRIMARY, WEAPON_SECONDARY)
- Update all README documentation
- Update all UI references

### Acceptance Criteria
- [ ] EquipmentSlot enum has consistent naming
- [ ] PRIMARY_WEAPON or WEAPON_PRIMARY exists (not both)
- [ ] All inventory system references use correct enum name
- [ ] Player equipment setup uses correct enum values
- [ ] Save/load system compatible with new names

### Test Plan
```gdscript
# In debug console:
inventory.equip_item(item, EquipmentSlot.PRIMARY_WEAPON)  # Should work
print(EquipmentSlot.WEAPON_PRIMARY)  # Should NOT exist
```

---

## Task 3: Fix Quest ObjectiveType Enum (9/10 Impact)

**File:** `scripts/data/enums.gd:258-268`

### Problem
All objective types have been renamed with descriptive suffixes, breaking documentation:

| README | Code |
|---|---|
| KILL | KILL_ENEMY |
| COLLECT | COLLECT_ITEM |
| TALK | TALK_TO_NPC |
| EXPLORE | DISCOVER_AREA |
| DEFEAT_BOSS | DEFEAT_BOSS ✓ (only match) |
| SURVIVE | SURVIVE_TIME |
| ESCORT | ESCORT_NPC |
| INTERACT | INTERACT_OBJECT |
| CUSTOM_EVENT | CUSTOM |

### Impact
1. Quest definitions can't load (enum mismatch)
2. Objective tracking completely broken
3. Save files incompatible
4. NPC dialogue can't reference quests
5. Entire progression system fails

### Affected Code
- `autoload/quest_manager.gd` - Quest loading (4 uses of KILL_ENEMY)
- `resources/quests/definitions/` - All quest data files
- `scripts/components/quest_trigger.gd` - World triggers (7 uses of DISCOVER_AREA, 7 uses of CUSTOM)
- `scenes/ui/menus/quest_ui.gd` - Quest UI
- Total: 43 references across codebase

### Solution
**Option A (Recommended):** Use code naming (KILL_ENEMY, COLLECT_ITEM, etc.)
- Update README.md to match code
- Update documentation examples
- No code changes needed

**Option B:** Use README naming (KILL, COLLECT, etc.)
- Rename all enum values
- Update all 43+ code references
- Update all quest definition files

### Acceptance Criteria
- [ ] ObjectiveType enum finalized (9 values)
- [ ] README matches ObjectiveType enum exactly
- [ ] All quest definitions use correct enum values
- [ ] Quest trigger system works with new enum
- [ ] Quest UI displays correctly

### Test Plan
```gdscript
# In debug console:
QuestManager.progress_objective("quest_id", "KILL_ENEMY", 5)  # Should work
QuestManager.progress_objective("quest_id", "KILL", 5)        # Should NOT work
```

---

## Task 4: Fix Missing Dungeon Portal Scenes (10/10 Impact)

**File:** `scripts/systems/dungeon_portal_system.gd:33-40`

### Problem
Three dungeon scene files are referenced but don't exist:

```
❌ Line 36: "crystal_cave": "res://scenes/dungeons/crystal_cave.tscn"
❌ Line 37: "ancient_ruins": "res://scenes/dungeons/ancient_ruins.tscn"
❌ Line 40: overworld_scene = "res://scenes/world/overworld.tscn"
```

Actual existing dungeons:
```
✅ dungeon_1.tscn through dungeon_5.tscn
```

### Impact Cascade
1. Players enter "crystal_cave" → CRASH (FileNotFound)
2. Players enter "ancient_ruins" → CRASH
3. Players exit ANY dungeon → CRASH (overworld missing)
4. **Result:** Players trapped in dungeons with no exit

### Affected Code
```gdscript
# In dungeon_portal_system.gd:33-40
var dungeon_scenes = {
    "crystal_cave": "res://scenes/dungeons/crystal_cave.tscn",      # ❌ MISSING
    "ancient_ruins": "res://scenes/dungeons/ancient_ruins.tscn",    # ❌ MISSING
    # ... other dungeons
}

var overworld_scene = "res://scenes/world/overworld.tscn"  # ❌ MISSING
```

### Solution
**Option A (Recommended):** Remove references, use existing dungeons 1-5
```gdscript
var dungeon_scenes = {
    "dungeon_1": "res://scenes/dungeons/dungeon_1.tscn",
    "dungeon_2": "res://scenes/dungeons/dungeon_2.tscn",
    "dungeon_3": "res://scenes/dungeons/dungeon_3.tscn",
    "dungeon_4": "res://scenes/dungeons/dungeon_4.tscn",
    "dungeon_5": "res://scenes/dungeons/dungeon_5.tscn",
}

# Find correct overworld location (or create one)
var overworld_scene = "res://scenes/world/starting_town/starting_town.tscn"  # Or similar
```

**Option B:** Create missing scene files
- Create `crystal_cave.tscn`
- Create `ancient_ruins.tscn`
- Create `overworld.tscn`
- (Time-intensive, requires design)

### Acceptance Criteria
- [ ] No missing scene references in dungeon_portal_system.gd
- [ ] All dungeon scene paths point to existing .tscn files
- [ ] Overworld/exit scene path is valid
- [ ] Players can enter dungeons without crash
- [ ] Players can exit dungeons without crash
- [ ] Portal system works for all 5 dungeons

### Test Plan
```gdscript
# In debug console:
DungeonPortalSystem.enter_dungeon("dungeon_1")  # Should work
# Wait, then exit portal
# Should NOT crash
```

---

## Completion Checklist

- [ ] Task 1: Element enum fixed (6 elements: FIRE, WATER, EARTH, AIR, LIGHT, DARK)
- [ ] Task 2: EquipmentSlot naming standardized (PRIMARY_WEAPON or WEAPON_PRIMARY)
- [ ] Task 3: ObjectiveType enum matches code implementation
- [ ] Task 4: Dungeon scene references valid (no missing files)
- [ ] All tests pass
- [ ] No compiler errors in affected systems
- [ ] Save system compatible with new enum values

---

## Verification Steps

After completing all tasks:

1. **Open project in Godot 4.5**
   - [ ] No compilation errors in debug console
   - [ ] No missing reference errors

2. **Test Element System**
   - [ ] Can equip Fire/Water/Earth/Air/Light/Dark spell cores
   - [ ] Can craft weapons with all 6 elements
   - [ ] Element advantage calculation works (test in combat)

3. **Test Equipment System**
   - [ ] Can equip items to PRIMARY_WEAPON slot
   - [ ] Can equip items to SECONDARY_WEAPON slot
   - [ ] Equipment bonuses apply correctly
   - [ ] Save/load preserves equipment

4. **Test Quest System**
   - [ ] Can accept quests without error
   - [ ] Can progress objectives
   - [ ] Quest UI shows objectives correctly
   - [ ] Save/load preserves quest state

5. **Test Dungeon System**
   - [ ] Can enter dungeon_1 through dungeon_5
   - [ ] Can exit dungeons without crash
   - [ ] Portal system navigates correctly

---

**Next Phase:** [PHASE2_HIGH_PRIORITY_FIXES.md](PHASE2_HIGH_PRIORITY_FIXES.md)
