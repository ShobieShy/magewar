# MageWar Damage System - Files Reference Guide

This document provides quick reference for all files involved in the damage system.

## Enemy Health & Damage Reception

### EnemyBase Class
- **File**: `/home/shobie/magewar/scenes/enemies/enemy_base.gd`
- **Lines**: 446 total
- **Key Methods**:
  - `take_damage(amount, damage_type, attacker)` (Line 279) - Entry point for enemy damage
  - `_perform_attack()` (Line 264) - Enemy melee attack
  - `_on_died()` (Line 301) - Death handler
- **Key Components**:
  - `$StatsComponent` - Manages health and stats
  - `$DetectionArea` - Detects player nearby
  - `$AttackArea` - Melee attack range
  - `$NavigationAgent3D` - Pathfinding

### StatsComponent
- **File**: `/home/shobie/magewar/scripts/components/stats_component.gd`
- **Lines**: 330 total
- **Key Methods**:
  - `take_damage(amount, damage_type)` (Line 164) - **Core damage application**
  - `heal(amount)` (Line 184) - Healing
  - `take_damage()` actually reduces health after applying defense
- **Key Signals**:
  - `health_changed(current, maximum)`
  - `died()`
  - `respawned()`

## Spell System Architecture

### SpellData (Spell Definition)
- **File**: `/home/shobie/magewar/resources/spells/spell_data.gd`
- **Lines**: 174 total
- **What it defines**:
  - Delivery type (HITSCAN, PROJECTILE, AOE, BEAM, CONE, CHAIN, SELF, SUMMON)
  - Spell effects (Array of SpellEffect instances)
  - Projectile parameters (speed, pierce, bounce, homing, etc.)
  - AoE parameters (radius, falloff)
  - Modifiers (damage_multiplier, cost_multiplier, etc.)
- **Key Methods**:
  - `apply_gem_modifiers(gems)` - Apply gem enhancements

### SpellCaster (Spell Execution)
- **File**: `/home/shobie/magewar/scripts/components/spell_caster.gd`
- **Lines**: 666 total
- **Key Methods** (in order of execution):
  1. `cast_spell(spell, aim_point, aim_direction)` (Line 69) - Spell casting entry
  2. `_execute_spell(spell, aim_point, aim_direction)` (Line 133) - Main execution
  3. `_execute_hitscan(spell, direction)` (Line 187) - **Hitscan delivery**
  4. `_execute_projectile(spell, aim_point, direction)` (Line 236) - **Projectile delivery**
  5. `_execute_aoe(spell, center)` (Line 315) - **AOE delivery**
  6. `_execute_cone(spell, direction)` (Line 411) - **Cone delivery**
  7. `_execute_chain(spell, direction)` (Line 462) - **Chain delivery**
  8. `_execute_beam(spell, direction)` (Line 371) - **Beam delivery**
- **Key Properties**:
  - `projectile_spawn_point` - Where projectiles spawn from
  - `stats_component` - Player/caster stats

## Spell Effects

### SpellEffect (Base Class)
- **File**: `/home/shobie/magewar/resources/spells/spell_effect.gd`
- **Lines**: 71 total
- **Key Methods**:
  - `apply(caster, target, hit_point, spell_data)` (Line 29) - Virtual method for subclasses
  - `can_affect_target(caster, target)` (Line 34) - Target filtering logic
- **Key Properties**:
  - `effect_type` - Type of effect (DAMAGE, HEAL, BUFF, etc.)
  - `target_type` - Who can be affected (ENEMY, ALLY, SELF, ALL, GROUND)
  - `delay` - Delay before effect triggers
  - `duration` - Duration for over-time effects

### DamageEffect (Damage Implementation)
- **File**: `/home/shobie/magewar/resources/spells/effects/damage_effect.gd`
- **Lines**: 115 total
- **Key Methods**:
  - `apply(caster, target, hit_point, spell_data)` (Line 35) - **Applies damage to target**
  - `calculate_damage(caster, target, is_crit, spell_data)` (Line 68) - **Damage calculation**
  - `_roll_crit(caster)` (Line 61) - Crit chance
  - `can_affect_target(caster, target)` (Line 34, inherited from SpellEffect) - **Target filtering**
- **Key Properties**:
  - `base_damage` - Base damage amount
  - `damage_type` - Type of damage (PHYSICAL, MAGICAL, ELEMENTAL, SHADOW, HOLY, TRUE)
  - `element` - Element type (FIRE, WATER, EARTH, AIR, LIGHT, DARK)
  - `damage_variance` - Damage variance (±%)
  - `crit_multiplier` - Critical hit multiplier
  - `knockback_force` - Knockback amount

### Other Effects
- **HealEffect**: `/home/shobie/magewar/resources/spells/effects/heal_effect.gd`
- **ShieldEffect**: `/home/shobie/magewar/resources/spells/effects/shield_effect.gd`
- **StatusEffect**: `/home/shobie/magewar/resources/spells/effects/status_effect.gd`
- **SummonEffect**: `/home/shobie/magewar/resources/spells/effects/summon_effect.gd`
- **MovementEffect**: `/home/shobie/magewar/resources/spells/effects/movement_effect.gd`

## Projectile System

### SpellProjectile (Projectile Class)
- **File**: `/home/shobie/magewar/scenes/spells/projectile.gd`
- **Lines**: 367 total
- **Type**: Area3D
- **Key Methods**:
  - `initialize(config)` (Line 80) - Initialize projectile with spell config
  - `_physics_process(delta)` (Line 46) - Move and check collisions
  - `_on_body_entered(body)` (Line 174) - Body collision callback
  - `_on_area_entered(area)` (Line 178) - Area collision callback
  - `_handle_hit(target)` (Line 186) - **Core hit logic with damage application**
  - `_check_collision_during_movement()` (Line 107) - Shape-based collision check
  - `_bounce(surface)` (Line 260) - Bounce off surface
- **Key Collision Settings** (Lines 35-40):
  - `collision_layer` = Projectile layer
  - `collision_mask` = Enemies + Players + World layers
  - `monitoring = true` - Detect collisions
  - `monitorable = false` - Not detected by others
- **Key Properties**:
  - `caster` - Who cast the spell
  - `spell` - SpellData reference
  - `effects` - Array of SpellEffect to apply on hit
  - `direction` - Projectile direction
  - `speed` - Travel speed
  - `pierce_remaining` - Pierce count
  - `bounce_remaining` - Bounce count
  - `lifetime` - Max lifetime before disappear

### SpellBeam (Beam Spell)
- **File**: `/home/shobie/magewar/scripts/components/spell_beam.gd`
- **Lines**: 100 total
- **Type**: Node3D (continuous beam effect)
- **Key Methods**:
  - `initialize(config)` (Line 59) - Setup beam parameters
  - `_process(delta)` (Line 36) - Update beam direction and apply effects
  - `_apply_effects()` (Line 90) - Apply effects to hit targets each tick
  - `_on_body_entered()` (Line 74) - Add body to hit targets
  - `_on_area_entered()` (Line 83) - Add area to hit targets
- **Issues**:
  - Only detects targets on initial contact
  - Should continuously raycast to detect moving targets

## Player Class

### Player (FPS Character)
- **File**: `/home/shobie/magewar/scenes/player/player.gd`
- **Lines**: 526 total
- **Key Methods**:
  - `take_damage(amount)` (Line 516) - **Delegates to stats.take_damage()**
  - `equip_weapon(weapon)` (Line 325) - Equip weapon
  - `get_current_spell()` (Line 355) - Get weapon's current spell
  - `grant_weapon_xp(amount)` (Line 484) - Grant XP to weapon
- **Key Components**:
  - `$StatsComponent` - Health/mana/stamina
  - `$SpellCaster` - Spell casting system
  - `$CameraPivot/Camera3D/WeaponHolder` - Holds equipped weapon
  - `$CameraPivot/Camera3D/RayCast3D` - For aiming

## Configuration & Constants

### Constants
- **File**: `/home/shobie/magewar/scripts/data/constants.gd`
- **Relevant Constants**:
  ```
  const LAYER_WORLD: int = 1
  const LAYER_PLAYERS: int = 2
  const LAYER_ENEMIES: int = 3
  const LAYER_PROJECTILES: int = 4
  ```
- **Damage Constants**:
  ```
  const CRITICAL_CHANCE_BASE: float = 0.05
  const CRITICAL_DAMAGE_MULTIPLIER: float = 1.5
  const ELEMENT_ADVANTAGE: float = 1.25
  const ELEMENT_DISADVANTAGE: float = 0.75
  const FRIENDLY_FIRE_DAMAGE_MULTIPLIER: float = 0.5
  ```

### Enums
- **File**: `/home/shobie/magewar/scripts/data/enums.gd`
- **Relevant Enums**:
  - `DamageType` - PHYSICAL, MAGICAL, ELEMENTAL, SHADOW, HOLY, TRUE
  - `SpellDelivery` - HITSCAN, PROJECTILE, AOE, BEAM, SELF, SUMMON, CONE, CHAIN
  - `SpellEffectType` - DAMAGE, HEAL, BUFF, DEBUFF, DOT, HOT, KNOCKBACK, etc.
  - `TargetType` - ENEMY, ALLY, SELF, ALL, GROUND
  - `Element` - FIRE, WATER, EARTH, AIR, LIGHT, DARK

## Scene Files

### Enemy Base Scene
- **File**: `/home/shobie/magewar/scenes/enemies/enemy_base.tscn`
- **Key Nodes**:
  - Root: `EnemyBase` (CharacterBody3D)
    - `$CollisionShape3D` - Body collision
    - `$StatsComponent` - Health management
    - `$NavigationAgent3D` - Pathfinding
    - `$DetectionArea` (Area3D) - Detects nearby players
    - `$AttackArea` (Area3D) - Melee attack range
    - `$MeshInstance3D` - Visual mesh
    - `$NamePlate` - Name label
    - `$HealthBar` - Health visualization
- **Collision Settings**:
  - Root collision_layer = **4** ⚠️ (Issue: should be 3)
  - Root collision_mask = 3 (Detects world + players)
  - DetectionArea collision_mask = 2 (Only players)
  - AttackArea collision_mask = 2 (Only players)

### Player Scene
- **File**: `/home/shobie/magewar/scenes/player/player.tscn`
- **Key Nodes**:
  - Root: `Player` (CharacterBody3D)
    - `$CollisionShape3D` - Body collision
    - `$StatsComponent` - Health/mana/stamina
    - `$SpellCaster` - Spell casting
    - `$CameraPivot` - Camera control
      - `$Camera3D` - First-person view
        - `$RayCast3D` - Aiming raycast
        - `$WeaponHolder` - Holds equipped weapon
- **Collision Settings**:
  - Root collision_layer = 2 (Player layer)
  - Root collision_mask = 1 (Only world)
  - RayCast3D collision_mask = 7 (World + players + enemies)

### Projectile Scene
- **File**: `/home/shobie/magewar/scenes/spells/projectile.tscn`
- **Key Nodes**:
  - Root: `SpellProjectile` (Area3D)
    - `$CollisionShape3D` - Projectile collision
    - `$MeshInstance3D` - Visual mesh
    - `$OmniLight3D` - Light effect
- **Collision Setup** (in code at runtime):
  - collision_layer = Projectile layer
  - collision_mask = World + Players + Enemies layers

## Spell Preset Files

All located in `/home/shobie/magewar/resources/spells/presets/`:
- `arcane_bolt.tres` - Hitscan spell
- `fireball.tres` - Projectile with AoE
- `ice_shard.tres` - Projectile
- `lightning_strike.tres` - Hitscan
- `healing_wave.tres` - Self-heal
- `shield_barrier.tres` - Shield
- `wind_dash.tres` - Movement
- `earth_spike.tres` - AOE
- `lightning_chain.tres` - Chain spell

## Important Data Flow

### Damage Application Flow
```
SpellCaster.cast_spell()
→ _execute_projectile() [or _execute_hitscan, _execute_aoe, etc.]
→ Creates SpellProjectile with effects
→ SpellProjectile._handle_hit()
→ effect.apply(caster, target, hit_point, spell)
→ DamageEffect.apply()
  → can_affect_target() [target filtering]
  → calculate_damage() [damage calculation with modifiers]
  → stats.take_damage() [apply defense and reduce health]
    → Emit health_changed signal
    → Emit died signal if health <= 0
→ EnemyBase._on_died() [or Player respawn handler]
```

## Critical Variables to Check

1. **Collision Layer Mismatch** (PRIMARY ISSUE):
   - Enemy `collision_layer` = 4 (scene setting)
   - Code expects `LAYER_ENEMIES = 3`
   - Projectile collision_mask = `(1 << 2)` = detects Layer 3
   - **Result**: Projectiles don't detect enemies!

2. **Group Membership** (SECONDARY):
   - Enemies must be in "enemies" group
   - Players must be in "player" group
   - Checked in: `SpellProjectile._handle_hit()` line 207, 213

3. **SaveManager Dependency**:
   - Used for friendly_fire setting
   - Can cause NullReferenceException if not initialized
   - Checked in: `DamageEffect.can_affect_target()` line 47

4. **StatsComponent Presence**:
   - Must have `$StatsComponent` node
   - Checked with `.has_node()` before `.get_node()`
   - If missing, damage is silently ignored

## Summary Table

| System | File | Purpose | Status |
|--------|------|---------|--------|
| Enemy Health | `enemy_base.gd` | Takes damage, manages health | ✅ Works |
| Health Storage | `stats_component.gd` | Stores/applies health changes | ✅ Works |
| Spell Definition | `spell_data.gd` | Defines spell behavior | ✅ Works |
| Spell Execution | `spell_caster.gd` | Casts spells, chooses delivery | ✅ Works |
| Projectile Delivery | `projectile.gd` | Travels and hits targets | ⚠️ Layer issue |
| Damage Effect | `damage_effect.gd` | Applies damage to target | ✅ Works (if reached) |
| Beam Effect | `spell_beam.gd` | Continuous damage beam | ⚠️ Incomplete detection |
| Config Values | `constants.gd` | Damage values, layer definitions | ⚠️ Layer mismatch |
| Enemy Scene | `enemy_base.tscn` | Enemy configuration | ❌ Wrong layer |
| Player Scene | `player.tscn` | Player configuration | ✅ Correct |
| Projectile Scene | `projectile.tscn` | Projectile configuration | ✅ Correct |

