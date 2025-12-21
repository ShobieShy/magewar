# PHASE 4: LOW PRIORITY CLEANUP (NICE TO HAVE)
**Estimated Time:** Few hours  
**Priority:** 🟢 LOW - Code cleanliness and organization  
**Status:** ⏳ Blocked until Phases 1-3 complete

---

## Overview
These are cleanup tasks that don't affect gameplay but improve code quality, organization, and maintainability. Complete these last for a polished codebase.

---

## Task 1: Delete Obsolete Files

**Files to Remove:**
1. `/autoload/quest_manager_old.gd` - Old version (superseded)
2. `/scenes/enemies/wraith_shadow_copy.tscn` - Test copy

### Purpose
- Remove duplicate/old code that confuses developers
- Reduce codebase clutter
- Avoid accidental usage of old code

### Impact
- Minimal impact on gameplay
- Cleaner project structure
- Faster searches (fewer results)

### Implementation

**Step 1: Verify Files Are Truly Obsolete**
```bash
# Check if quest_manager_old.gd is referenced anywhere
grep -r "quest_manager_old" /home/shobie/magewar --include="*.gd"
grep -r "quest_manager_old" /home/shobie/magewar --include="*.tscn"

# Expected result: No references (it's safe to delete)
```

**Step 2: Check wraith_shadow_copy.tscn**
```bash
# Check if wraith_shadow_copy is referenced
grep -r "wraith_shadow_copy" /home/shobie/magewar --include="*.gd"
grep -r "wraith_shadow_copy" /home/shobie/magewar --include="*.tscn"

# Expected result: No references
```

**Step 3: Delete Files**
```bash
rm /home/shobie/magewar/autoload/quest_manager_old.gd
rm /home/shobie/magewar/autoload/quest_manager_old.gd.uid  # Delete .uid file too
rm /home/shobie/magewar/scenes/enemies/wraith_shadow_copy.tscn
rm /home/shobie/magewar/scenes/enemies/wraith_shadow_copy.tscn.uid
```

**Step 4: Verify Deletion**
```bash
ls -la /home/shobie/magewar/autoload/quest_manager_old.gd
# Should show: "No such file or directory"

ls -la /home/shobie/magewar/scenes/enemies/wraith_shadow_copy.tscn
# Should show: "No such file or directory"
```

**Step 5: Reload Godot Project**
- Close Godot
- Reopen project
- Verify no errors in console

### Acceptance Criteria
- [ ] `quest_manager_old.gd` deleted
- [ ] `quest_manager_old.gd.uid` deleted
- [ ] `wraith_shadow_copy.tscn` deleted
- [ ] `wraith_shadow_copy.tscn.uid` deleted
- [ ] No references to deleted files remain
- [ ] Project opens without errors

### Test Verification
```bash
# Confirm files are deleted
find /home/shobie/magewar -name "*quest_manager_old*" -o -name "*wraith_shadow_copy*"

# Should return: (nothing)
```

---

## Task 2: Move Test Scripts to Tests Directory

**Files to Relocate:**
1. `/test_equipment.gd`
2. `/test_equipment_slots.gd`
3. `/test_empty.gd`
4. `/scripts/systems/simple_crafting_test.gd`

### Purpose
- Separate test code from production code
- Keep root directory clean
- Make it clear which scripts are for testing only
- Prevent test code from being included in exports

### Impact
- No gameplay impact
- Cleaner project structure
- Better organization

### Implementation

**Step 1: Create Tests Directory (if it doesn't exist)**
```bash
mkdir -p /home/shobie/magewar/tests
```

**Step 2: Move Test Files**
```bash
# Move root-level test files
mv /home/shobie/magewar/test_equipment.gd /home/shobie/magewar/tests/
mv /home/shobie/magewar/test_equipment.gd.uid /home/shobie/magewar/tests/

mv /home/shobie/magewar/test_equipment_slots.gd /home/shobie/magewar/tests/
mv /home/shobie/magewar/test_equipment_slots.gd.uid /home/shobie/magewar/tests/

mv /home/shobie/magewar/test_empty.gd /home/shobie/magewar/tests/
mv /home/shobie/magewar/test_empty.gd.uid /home/shobie/magewar/tests/

# Move systems test file
mv /home/shobie/magewar/scripts/systems/simple_crafting_test.gd /home/shobie/magewar/tests/
mv /home/shobie/magewar/scripts/systems/simple_crafting_test.gd.uid /home/shobie/magewar/tests/
```

**Step 3: Update Any References**
```bash
# Check if test files are referenced anywhere
grep -r "test_equipment" /home/shobie/magewar --include="*.gd"
grep -r "test_equipment_slots" /home/shobie/magewar --include="*.gd"
grep -r "test_empty" /home/shobie/magewar --include="*.gd"
grep -r "simple_crafting_test" /home/shobie/magewar --include="*.gd"

# If any references found, update paths from res://test_*.gd to res://tests/test_*.gd
```

**Step 4: Update .godot Cache**
```bash
# Delete Godot's project cache so it re-indexes
rm -rf /home/shobie/magewar/.godot/

# Reopen project in Godot to regenerate cache
```

### File Structure After Move
```
magewar/
├── autoload/                    # Unchanged
├── scenes/                      # Unchanged
├── scripts/                     # Unchanged
├── resources/                   # Unchanged
├── tests/                       # NEW!
│   ├── test_equipment.gd
│   ├── test_equipment.gd.uid
│   ├── test_equipment_slots.gd
│   ├── test_equipment_slots.gd.uid
│   ├── test_empty.gd
│   ├── test_empty.gd.uid
│   ├── simple_crafting_test.gd
│   └── simple_crafting_test.gd.uid
├── project.godot
└── README.md
```

### Acceptance Criteria
- [ ] All 4 test scripts moved to `/tests/` directory
- [ ] All corresponding `.uid` files moved
- [ ] No references to old paths remain
- [ ] Project opens without errors
- [ ] Test scripts still accessible (res://tests/test_*.gd)

### Test Verification
```bash
# Confirm files moved
ls -la /home/shobie/magewar/tests/

# Should show:
# test_equipment.gd
# test_equipment.gd.uid
# test_equipment_slots.gd
# test_equipment_slots.gd.uid
# test_empty.gd
# test_empty.gd.uid
# simple_crafting_test.gd
# simple_crafting_test.gd.uid

# Confirm old locations empty
ls /home/shobie/magewar/test*.gd
# Should show: "No such file or directory"

ls /home/shobie/magewar/scripts/systems/simple_crafting_test.gd
# Should show: "No such file or directory"
```

---

## Task 3: Add .gitignore Rules for Test/Cache Files

**Files to Ignore:**
- `.godot/` - Godot cache (large, regenerates)
- `*.exe` - Builds
- `*.pck` - Packed resources
- `*.zip` - Archives
- `tests/` - Test scripts (optional)

### Purpose
- Prevent large cache files from being committed
- Keep git repo clean
- Prevent build artifacts in version control

### Implementation

**Step 1: Check Existing .gitignore**
```bash
cat /home/shobie/magewar/.gitignore
```

**Step 2: Add Test/Build Rules**
```bash
# Append to .gitignore
cat >> /home/shobie/magewar/.gitignore << 'EOF'

# Godot Cache (regenerates automatically)
.godot/

# Build Artifacts
*.exe
*.exe.import
*.pck
*.zip
*.so

# Test/Debug Files
tests/*.gd
tests/*.gd.uid

# OS Files
.DS_Store
Thumbs.db
*.swp
*.swo
*~
EOF
```

**Step 3: Verify Changes**
```bash
git status  # Should not show .godot/, tests/, build files
```

### Acceptance Criteria
- [ ] `.gitignore` updated with cache rules
- [ ] `.gitignore` updated with build artifact rules
- [ ] `.gitignore` updated with OS-specific rules
- [ ] `.godot/` no longer committed (if it was)
- [ ] Build artifacts ignored

---

## Completion Checklist

- [ ] Task 1: Obsolete files deleted
  - [ ] `quest_manager_old.gd` deleted
  - [ ] `wraith_shadow_copy.tscn` deleted
  - [ ] All `.uid` files deleted
  - [ ] No references remain
  - [ ] Project opens cleanly

- [ ] Task 2: Test scripts relocated
  - [ ] `/tests/` directory created
  - [ ] All 4 test scripts moved
  - [ ] All `.uid` files moved
  - [ ] No broken references
  - [ ] `.godot/` cache cleared

- [ ] Task 3: .gitignore rules added
  - [ ] Cache rules added
  - [ ] Build artifact rules added
  - [ ] OS-specific rules added
  - [ ] Verified with `git status`

---

## Verification Steps

After completing all tasks:

1. **File Cleanup Check**
   ```bash
   # Verify old files gone
   [ ! -f /home/shobie/magewar/autoload/quest_manager_old.gd ] && echo "✓ quest_manager_old deleted"
   [ ! -f /home/shobie/magewar/scenes/enemies/wraith_shadow_copy.tscn ] && echo "✓ wraith_shadow_copy deleted"
   
   # Verify test files moved
   [ -f /home/shobie/magewar/tests/test_equipment.gd ] && echo "✓ test_equipment moved"
   [ -f /home/shobie/magewar/tests/test_equipment_slots.gd ] && echo "✓ test_equipment_slots moved"
   [ -f /home/shobie/magewar/tests/test_empty.gd ] && echo "✓ test_empty moved"
   [ -f /home/shobie/magewar/tests/simple_crafting_test.gd ] && echo "✓ simple_crafting_test moved"
   ```

2. **Project Verification**
   - [ ] Open Godot
   - [ ] No errors in console
   - [ ] File explorer shows clean structure
   - [ ] `.godot/` folder exists but not in git

3. **Git Status Check**
   ```bash
   cd /home/shobie/magewar
   git status
   
   # Should NOT show:
   # - .godot/ changes
   # - build artifacts
   # - deleted old files (good!)
   
   # Should show:
   # - tests/ folder (if changed)
   ```

---

## Optional: Additional Cleanup

Consider these optional improvements:

### Create README for Tests Directory
```markdown
# /tests - Test Scripts

This directory contains test and debug scripts for development.

## Test Files
- `test_equipment.gd` - Equipment system tests
- `test_equipment_slots.gd` - Equipment slot tests
- `test_empty.gd` - Empty test template
- `simple_crafting_test.gd` - Crafting system tests

These are NOT included in production builds.
```

### Add Test Runner Script
```gdscript
# tests/test_runner.gd
extends Node

func _ready():
    # Auto-run all tests in this directory
    var tests = [
        load("res://tests/test_equipment.gd"),
        load("res://tests/test_equipment_slots.gd"),
    ]
    
    for test in tests:
        test.run()
```

---

**Previous Phase:** [PHASE3_MEDIUM_PRIORITY_FIXES.md](PHASE3_MEDIUM_PRIORITY_FIXES.md)  
**Complete!** All phases finished. See [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md) for next steps.
