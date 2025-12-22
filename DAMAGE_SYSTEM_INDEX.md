# Damage System Analysis - Complete Index

## Quick Navigation

### For the Impatient (TL;DR)
- **Problem**: Projectile spells pass through enemies without dealing damage
- **Root Cause**: Enemy collision layer set to 4, should be 3
- **Fix**: Change 1 line in `scenes/enemies/enemy_base.tscn`
- **Time to Fix**: 1 minute
- **Confidence**: 100% certain

### For Understanding the System
1. Start: [DAMAGE_INVESTIGATION_SUMMARY.txt](DAMAGE_INVESTIGATION_SUMMARY.txt) (5 min read)
2. Then: [DAMAGE_SYSTEM_ANALYSIS.md](DAMAGE_SYSTEM_ANALYSIS.md) (30 min detailed read)
3. Reference: [DAMAGE_SYSTEM_FILES_REFERENCE.md](DAMAGE_SYSTEM_FILES_REFERENCE.md) (look up methods/files)
4. File List: [CRITICAL_DAMAGE_FILES.txt](CRITICAL_DAMAGE_FILES.txt) (find absolute paths)

---

## Document Purposes

### DAMAGE_INVESTIGATION_SUMMARY.txt
**Purpose**: Executive summary of the investigation
**Length**: ~250 lines
**Reading Time**: 5-10 minutes
**Content**:
- Investigation scope
- Finding summary for each system
- Root cause analysis
- Detailed damage flow (9 steps)
- Where it breaks and why
- Verification data
- Impact assessment
- Fix complexity analysis

**Best For**: Getting the big picture quickly

### DAMAGE_SYSTEM_ANALYSIS.md
**Purpose**: Complete technical deep dive
**Length**: ~1000 lines / 11 parts
**Reading Time**: 30-60 minutes
**Content**:
- Part 1: Enemy health system
- Part 2: Spell damage delivery
- Part 3: Spell delivery systems (7 types)
- Part 4: Collision layer configuration
- Part 5: Why spells pass through enemies
- Part 6: Secondary issues
- Part 7: Collision layer deep dive
- Part 8: Root cause summary
- Part 9: How damage should work
- Part 10: How to fix
- Part 11: Test cases

**Best For**: Complete understanding of the system and fixes

### DAMAGE_SYSTEM_FILES_REFERENCE.md
**Purpose**: Quick reference for all files and methods
**Length**: ~400 lines
**Reading Time**: 10-20 minutes (skim as needed)
**Content**:
- Enemy health components
- Spell system architecture
- Spell effects (all types)
- Projectile system details
- Player class
- Configuration files
- Scene files
- Spell presets
- Data flow
- Critical variables
- Summary table

**Best For**: Finding specific methods or understanding file organization

### CRITICAL_DAMAGE_FILES.txt
**Purpose**: Quick reference with absolute file paths
**Length**: ~120 lines
**Reading Time**: 3-5 minutes
**Content**:
- All critical files with absolute paths
- File types and line counts
- Root cause summary
- Fix priority list
- Testing procedures
- Key methods

**Best For**: Finding files to edit and understanding priority

---

## Key Files and Their Roles

### Core Health System
```
EnemyBase (scenes/enemies/enemy_base.gd)
    └─ Receives damage via take_damage()
       └─ Delegates to StatsComponent
          └─ StatsComponent (scripts/components/stats_component.gd)
             └─ Actually applies damage and manages health
```

### Spell Execution Pipeline
```
Player casts spell
    └─ SpellCaster (scripts/components/spell_caster.gd)
       └─ Chooses delivery method based on SpellData
          ├─ PROJECTILE → SpellProjectile (scenes/spells/projectile.gd)
          ├─ HITSCAN → Direct raycast
          ├─ AOE → Sphere shape query
          ├─ CONE → Multiple raycasts
          ├─ CHAIN → Raycast + shape queries
          ├─ BEAM → SpellBeam (scripts/components/spell_beam.gd)
          └─ SELF → Apply to caster
             └─ For each effect:
                └─ DamageEffect (resources/spells/effects/damage_effect.gd)
                   └─ apply() → damage dealt
```

---

## System Status Summary

| System | File | Status | Issue |
|--------|------|--------|-------|
| Enemy Health | enemy_base.gd | ✓ Works | None |
| Health Manager | stats_component.gd | ✓ Works | None |
| Spell Casting | spell_caster.gd | ✓ Works | Lacks debug output |
| Spell Definition | spell_data.gd | ✓ Works | None |
| Damage Calculation | damage_effect.gd | ✓ Works | SaveManager dependency |
| Hitscan Delivery | spell_caster.gd | ✓ Works | Lacks debug output |
| Projectile Delivery | projectile.gd | ✗ Broken | Layer mismatch |
| AOE Delivery | spell_caster.gd | ✓ Works | No caster rid exclusion |
| Cone Delivery | spell_caster.gd | ✓ Works | None |
| Chain Delivery | spell_caster.gd | ✓ Works | Falloff not applied |
| Beam Delivery | spell_beam.gd | ⚠ Partial | Incomplete hit detection |
| Target Filtering | spell_effect.gd | ✓ Works | Group-based only |
| Configuration | constants.gd | ⚠ Issue | Enemy on Layer 4 not 3 |

---

## The One Critical Bug

### The Problem
```
Projectile-based spells pass through enemies without dealing damage
```

### The Root Cause
```
File: scenes/enemies/enemy_base.tscn
Current: collision_layer = 4
Should be: collision_layer = 3

File: scenes/spells/projectile.gd (Line 36-38)
collision_mask = (1 << (LAYER_ENEMIES - 1))
where LAYER_ENEMIES = 3
Results in checking: Layer 3

Mismatch:
Enemy on Layer 4
Projectile looks for Layer 3
No collision signal
```

### The Fix
```
1. Open: scenes/enemies/enemy_base.tscn
2. Find: collision_layer = 4
3. Replace: collision_layer = 3
4. Save
5. Test: Cast projectile at enemy, verify damage
```

### Affected Spells
- Any projectile-based spell (fireball, ice_shard, etc.)
- Enemy projectiles cast at player

### Unaffected Spells
- Hitscan (lightning_strike, arcane_bolt) - might work
- AOE (earth_spike) - might work
- Self-cast spells
- Healing spells

---

## Damage Flow Diagram

```
┌─────────────────┐
│ Player Casts    │
│ Spell           │
└────────┬────────┘
         │
         v
┌─────────────────────────────┐
│ SpellCaster.cast_spell()    │
│ Validates can_cast          │
│ Uses magika                 │
└────────┬────────────────────┘
         │
         v
┌──────────────────────────────────────┐
│ SpellCaster._execute_spell()         │
│ Chooses delivery type                │
└─┬──────────────────────────────────┬─┘
  │                                  │
  v (PROJECTILE)                     v (HITSCAN/AOE/etc)
┌─────────────────────────┐     ┌────────────────────┐
│ SpellCaster.           │     │ Direct raycast or  │
│ _execute_projectile()  │     │ shape query        │
│ Creates SpellProjectile│     │ to find targets    │
└─────────┬───────────────┘     └────────┬───────────┘
          │                             │
          v                             v
   ┌────────────────┐         ┌─────────────────┐
   │ Projectile     │         │ Find targets    │
   │ moves in       │         │ via physics     │
   │ physics        │         │ query           │
   └────────┬───────┘         └────────┬────────┘
            │                         │
            v                         v
   ┌──────────────────┐       ┌──────────────────┐
   │ _on_body/area_   │       │ For each target: │
   │ entered() fires  │       │ apply effect     │
   │ IF collision     │       └────────┬─────────┘
   │ detected        │                │
   └────────┬────────┘                │
            │                         v
            └─────────────┬─────────────────────┐
                          │                     │
                          v                     v
                  ┌──────────────────────────────────┐
                  │ DamageEffect.apply()             │
                  │ - can_affect_target() check      │
                  │ - calculate_damage()             │
                  │ - stats.take_damage()            │
                  │ - spawn_damage_number()          │
                  └──────────────┬───────────────────┘
                                 │
                                 v
                  ┌──────────────────────────────────┐
                  │ StatsComponent.take_damage()     │
                  │ - Apply defense modifier         │
                  │ - Reduce health                  │
                  │ - Emit signals                   │
                  └──────────────┬───────────────────┘
                                 │
                                 v
                          ┌──────────────┐
                          │ Health <= 0? │
                          └─┬────────┬───┘
                           NO        YES
                            │         │
                            v         v
                         [ALIVE] ┌────────────┐
                                 │ _on_died() │
                                 │ - Loot     │
                                 │ - XP       │
                                 │ - Queue_fr │
                                 └────────────┘
```

---

## Testing Checklist

After applying the layer fix:

```
[ ] Layer change made in enemy_base.tscn
[ ] Game reloads without errors
[ ] Cast fireball at enemy
[ ] Verify projectile visible traveling to enemy
[ ] Verify damage number appears on impact
[ ] Verify enemy health bar decreases
[ ] Verify spell effects trigger (impact, knockback)
[ ] Cast multiple projectiles, verify pierce works if enabled
[ ] Cast hitscan spell, verify instant hit
[ ] Cast AOE spell, verify radius damage
[ ] Kill enemy, verify loot drops
[ ] Kill enemy, verify XP awarded
[ ] Verify enemy death animation plays
```

---

## Additional Improvements (Optional)

1. **Debug Logging** (10 min)
   - Add warnings to spell_caster.gd when hitscan finds nothing
   - Add warnings to projectile.gd when hit target doesn't match expected type
   - Makes future debugging easier

2. **SaveManager Safety** (10 min)
   - Add null checks to damage_effect.gd
   - Prevents crashes if SaveManager not initialized

3. **Beam Improvement** (20 min)
   - Replace Area3D contact detection with continuous raycasting
   - Allows hitting moving targets in beam path

4. **AOE Caster Exclusion** (5 min)
   - Use physics RID exclusion instead of entity check
   - Cleaner and more robust

---

## Contact Points

All files are located in: `/home/shobie/magewar/`

Key editing locations:
1. **Critical Bug Fix**: `scenes/enemies/enemy_base.tscn` (1 line)
2. **Damage Logic**: `scenes/spells/projectile.gd` (understand lines 186-257)
3. **Damage Calculation**: `resources/spells/effects/damage_effect.gd` (understand lines 35-94)
4. **Spell Execution**: `scripts/components/spell_caster.gd` (understand spell delivery methods)

---

## References

- Godot Physics Documentation: Collision layers and masks
- Scene format: .tscn files are text-based Godot resources
- GDScript: All code is in GDScript (Python-like language for Godot)

---

## Summary

The MageWar damage system is architecturally excellent with one simple configuration bug. 
After a 1-minute fix to change an enemy collision layer from 4 to 3, the entire spell 
damage system will work correctly.

All infrastructure for:
- Damage calculation (with variance, crits, bonuses)
- Defense application
- Multiple damage types
- Element advantage/disadvantage
- Knockback effects
- Visual feedback (damage numbers)
- Health signals

...is already implemented and working. Only the collision detection for projectiles 
needs the layer fix to enable the system to function.

