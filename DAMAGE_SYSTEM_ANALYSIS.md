# MageWar Damage System - Comprehensive Analysis

## Executive Summary

The codebase implements a sophisticated damage system with multiple layers. Spells can pass through enemies due to **collision layer misconfigurations** and **potential target filtering issues** in the spell delivery systems. The damage infrastructure itself is well-implemented, but the delivery mechanisms (projectiles, hitscan, etc.) may not be detecting enemies correctly.

---

## Part 1: Enemy Health System

### EnemyBase Class
**File**: `/home/shobie/magewar/scenes/enemies/enemy_base.gd`

#### Health Component
- **Source**: Uses `StatsComponent` node attached as `$StatsComponent`
- **Initialization** (Lines 73-75):
  ```gdscript
  stats.max_health = max_health
  stats.reset_stats()
  stats.died.connect(_on_died)
  ```

#### Damage Reception
- **Method**: `take_damage(amount, damage_type, attacker)` (Line 279)
  ```gdscript
  func take_damage(amount: float, damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL, attacker: Node = null) -> void:
      if stats:
          var actual = stats.take_damage(amount, damage_type)
          damaged.emit(actual, attacker)
          # Aggro on attacker if no current target
          if attacker and current_target == null:
              set_target(attacker)
  ```

#### Key Features:
- ✅ Validates target has StatsComponent before applying damage
- ✅ Emits `damaged` signal for feedback
- ✅ Auto-aggro on attacker (good for combat feel)
- ✅ Defense modifier applied in StatsComponent

### StatsComponent Class
**File**: `/home/shobie/magewar/scripts/components/stats_component.gd`

#### Damage Application (Lines 164-181)
```gdscript
func take_damage(amount: float, damage_type: Enums.DamageType = Enums.DamageType.MAGICAL) -> float:
    if is_dead or amount <= 0.0:
        return 0.0
    
    # Apply defense modifier (except for true damage)
    var actual_damage = amount
    if damage_type != Enums.DamageType.TRUE:
        var defense = _get_modified_stat(Enums.StatType.DEFENSE, 0.0)
        actual_damage = maxf(amount - defense, amount * 0.1)  # Min 10% damage
    
    current_health -= actual_damage
    _health_regen_timer = health_regen_delay
    time_since_last_damage = 0.0  # Reset damage timer
    
    if current_health <= 0.0:
        is_dead = true
    
    return actual_damage
```

#### Health Management:
- ✅ Returns actual damage dealt (useful for feedback)
- ✅ Applies defense modifier (except TRUE damage type)
- ✅ Sets minimum 10% damage even with high defense
- ✅ Emits `died` signal when health reaches 0
- ✅ Resets regen timer on damage

---

## Part 2: Spell Damage Delivery

### Overview of Spell Systems
**Files**:
- SpellCaster: `/home/shobie/magewar/scripts/components/spell_caster.gd` (666 lines)
- SpellData: `/home/shobie/magewar/resources/spells/spell_data.gd` (174 lines)
- DamageEffect: `/home/shobie/magewar/resources/spells/effects/damage_effect.gd` (115 lines)
- SpellProjectile: `/home/shobie/magewar/scenes/spells/projectile.gd` (367 lines)
- SpellBeam: `/home/shobie/magewar/scripts/components/spell_beam.gd` (100 lines)

### SpellData Class
**What it defines**: Complete spell configuration including:
- Delivery type (HITSCAN, PROJECTILE, AOE, BEAM, SELF, CONE, CHAIN, SUMMON)
- Spell effects (Array of SpellEffect objects)
- Delivery parameters (range, projectile speed, pierce, bounce, etc.)
- Modifiers (damage multiplier, cooldown, cost, etc.)

### DamageEffect Class
**File**: `/home/shobie/magewar/resources/spells/effects/damage_effect.gd`

#### Damage Application (Lines 35-58)
```gdscript
func apply(caster: Node, target: Node, hit_point: Vector3, spell_data: SpellData = null) -> void:
    if not can_affect_target(caster, target):
        return  # CRITICAL: Stops if target filtering fails
    
    # Calculate damage and check for crit
    var is_crit = _roll_crit(caster)
    var final_damage = calculate_damage(caster, target, is_crit, spell_data)
    
    # Apply damage
    if target.has_node("StatsComponent"):
        var stats: StatsComponent = target.get_node("StatsComponent")
        var actual_damage = stats.take_damage(final_damage, damage_type)
        _spawn_damage_number(target, hit_point, actual_damage, is_crit)
    
    # Apply knockback
    if knockback_force > 0.0 and target is CharacterBody3D:
        var direction = (target.global_position - caster.global_position).normalized()
        direction.y = knockback_up
        target.velocity += direction * knockback_force
    
    # Spawn impact effect
    spawn_impact_effect(hit_point)
```

#### Target Filtering (Lines 34-59)
```gdscript
func can_affect_target(caster: Node, target: Node) -> bool:
    if target == null:
        return target_type == Enums.TargetType.GROUND
    
    var is_player = target is Player
    var is_enemy = target.is_in_group("enemies")
    var is_self = target == caster
    
    match target_type:
        Enums.TargetType.ENEMY:
            if is_player:
                # Check friendly fire setting
                var friendly_fire = SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false)
                return friendly_fire
            return is_enemy
        Enums.TargetType.ALLY:
            return is_player and not is_self
        Enums.TargetType.SELF:
            return is_self
        Enums.TargetType.ALL:
            return true
        Enums.TargetType.GROUND:
            return true
    
    return false
```

#### Damage Calculation (Lines 68-94)
```gdscript
func calculate_damage(caster: Node, target: Node, is_crit: bool = false, spell_data: SpellData = null) -> float:
    var damage = base_damage
    
    # Apply spell's damage multiplier (from gems, weapon, etc.)
    if spell_data:
        damage *= spell_data.damage_multiplier
    
    # Apply variance
    if damage_variance > 0.0:
        var variance_amount = damage * damage_variance
        damage += randf_range(-variance_amount, variance_amount)
    
    # Apply crit multiplier
    if is_crit:
        damage *= crit_multiplier
    
    # Apply caster damage bonus
    if caster.has_node("StatsComponent"):
        var damage_bonus = caster.get_node("StatsComponent").get_stat(Enums.StatType.DAMAGE)
        damage += damage_bonus
    
    # Apply friendly fire reduction
    var friendly_fire = SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false)
    if target.get_script() and target.get_script().get_global_name() == "Player" and friendly_fire:
        damage *= Constants.FRIENDLY_FIRE_DAMAGE_MULTIPLIER
    
    return damage
```

**Issues Found**:
- ❌ **`can_affect_target()` may fail if SaveManager is not properly initialized**
- ❌ **Target filtering depends on entity being in "enemies" group - if not added, spell won't hit**

---

## Part 3: Spell Delivery Systems

### 1. HITSCAN Delivery
**File**: SpellCaster, Lines 187-233

```gdscript
func _execute_hitscan(spell: SpellData, direction: Vector3) -> void:
    var caster = get_parent()
    var start_pos = projectile_spawn_point.global_position if projectile_spawn_point else caster.global_position
    
    # Get physics space with validation
    var world_3d = caster.get_world_3d()
    var space_state = world_3d.direct_space_state
    
    var end_pos = start_pos + direction * spell.get_final_range()
    
    var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
    
    # Properly exclude caster to avoid self-collision
    if caster is CollisionObject3D:
        query.exclude = [caster.get_rid()]
    
    # Configure collision layers for hitscan: enemies, players, and world geometry
    query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS | Constants.LAYER_WORLD
    
    var result = space_state.intersect_ray(query)
    
    if result:
        var target = result.collider
        # Apply effects
        for effect in spell.effects:
            if effect and is_instance_valid(effect):
                effect.apply(caster, target, hit_point, spell)
        
        # Spawn impact effect
        _spawn_impact(spell, hit_point, hit_normal)
```

**Potential Issues**:
- ✅ Collision mask configured correctly (ENEMIES | PLAYERS | WORLD)
- ❌ **Caster exclusion uses `get_rid()` which may not work if caster is not CollisionObject3D**
- ⚠️ **Silent failure if no collision detected - no warning**

### 2. PROJECTILE Delivery
**File**: SpellCaster, Lines 236-312

```gdscript
func _execute_projectile(spell: SpellData, _aim_point: Vector3, direction: Vector3) -> void:
    var caster = get_parent()
    var start_pos = projectile_spawn_point.global_position if projectile_spawn_point else caster.global_position
    
    for i in range(spell.projectile_count):
        var proj_dir = direction
        
        # Apply spread
        if spell.projectile_spread > 0.0 and spell.projectile_count > 1:
            var spread_angle = deg_to_rad(spell.projectile_spread)
            var spread_offset = (float(i) / (spell.projectile_count - 1) - 0.5) * spread_angle
            proj_dir = proj_dir.rotated(Vector3.UP, spread_offset)
        
        # Spawn projectile
        var projectile: Node3D
        var scene_to_use: PackedScene = spell.projectile_scene
        if not scene_to_use:
            scene_to_use = load("res://scenes/spells/projectile.tscn")
        
        projectile = scene_to_use.instantiate()
        
        # Add to scene tree FIRST, then configure
        var current_scene = get_tree().current_scene
        current_scene.add_child(projectile)
        
        # Configure projectile
        projectile.global_position = start_pos
        projectile.look_at(start_pos + proj_dir)
        
        if projectile.has_method("initialize"):
            projectile.initialize({
                "caster": caster,
                "spell": spell,
                "direction": proj_dir,
                "speed": spell.projectile_speed,
                "gravity": spell.projectile_gravity,
                "homing": spell.projectile_homing,
                "pierce": spell.projectile_pierce,
                "bounce": spell.projectile_bounce,
                "lifetime": spell.projectile_lifetime,
                "effects": spell.effects
            })
```

### 3. SpellProjectile Class (Area3D)
**File**: `/home/shobie/magewar/scenes/spells/projectile.gd`

#### Collision Setup (Lines 33-43)
```gdscript
func _ready() -> void:
    # Set up collision layers properly (using bit masks)
    # Layer 4 = Projectiles (bit position 4 = value 8)
    collision_layer = 1 << (Constants.LAYER_PROJECTILES - 1)  # Projectile layer
    # Mask for World (1), Players (2), and Enemies (3)
    collision_mask = (1 << (Constants.LAYER_WORLD - 1)) | (1 << (Constants.LAYER_PLAYERS - 1)) | (1 << (Constants.LAYER_ENEMIES - 1))
    monitoring = true
    monitorable = false
    
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)
```

#### Hit Detection (Lines 186-257)
```gdscript
func _handle_hit(target: Node) -> void:
    # Skip caster and caster's team
    if target == caster:
        return
    
    # Skip if target doesn't exist or was freed
    if not is_instance_valid(target):
        return
    
    # Skip already hit targets (for pierce)
    if target in _hit_targets:
        return
    
    # Check collision layers more safely
    var is_world = false
    var is_enemy = false
    var is_player = false
    
    if target is Node3D:
        is_world = (target.collision_layer & (1 << (Constants.LAYER_WORLD - 1))) != 0
    
    is_enemy = target.is_in_group("enemies")
    is_player = target.is_in_group("player") or target.has_method("is_player")
    
    # Determine if we should hit this target based on caster type
    var should_hit = false
    var caster_is_player = caster and (caster.is_in_group("player") or caster.has_method("is_player"))
    var caster_is_enemy = caster and caster.is_in_group("enemies")
    
    if is_world:
        should_hit = true
    elif caster_is_player and is_enemy:
        should_hit = true  # Player projectile hits enemies ✅
    elif caster_is_enemy and is_player:
        should_hit = true  # Enemy projectile hits players ✅
    elif SaveManager and SaveManager.settings_data and SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false):
        if (caster_is_player and is_player) or (caster_is_enemy and is_enemy):
            should_hit = true
    
    if not should_hit:
        return  # CRITICAL: Silently exits if shouldn't hit
    
    # Handle entity hit
    if is_enemy or is_player:
        _hit_targets.append(target)
        
        # Apply spell effects (including damage) ✅
        for effect in effects:
            if effect and effect.has_method("apply"):
                effect.apply(caster, target, global_position, spell)
        
        # Check pierce
        if pierce_remaining > 0:
            pierce_remaining -= 1
        else:
            _impact(global_position)
```

**Critical Issues**:
- ⚠️ **Depends on enemy being in "enemies" group** (Line 207)
- ⚠️ **Depends on caster being in "player" or "enemies" group** (Lines 212-213)
- ⚠️ **SaveManager dependency - if not initialized, friendly fire check may fail**
- ✅ Otherwise collision detection and damage application looks good

### 4. AOE Delivery
**File**: SpellCaster, Lines 315-368

```gdscript
func _execute_aoe(spell: SpellData, center: Vector3) -> void:
    # ... validation code ...
    
    # Find all targets in radius
    var shape = SphereShape3D.new()
    shape.radius = spell.get_final_aoe_radius()
    
    var query = PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = Transform3D(Basis.IDENTITY, center)
    
    # AOE should only hit characters, not world geometry
    query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS
    
    var results = space_state.intersect_shape(query)
    
    for result in results:
        var target = result.collider
        # Skip caster if in AoE range
        if target == caster:
            continue
        
        # Apply effects
        for effect in spell.effects:
            effect.apply(caster, target, hit_point, spell)
```

**Issues**:
- ✅ Collision mask correct
- ❌ **No caster exclusion by collision - only entity check (less safe)**
- ⚠️ **Silent failure if no targets in radius**

### 5. CONE Delivery
**File**: SpellCaster, Lines 411-459

Uses multiple raycasts to create cone effect:
- ✅ Properly excludes caster
- ✅ Correct collision mask
- ✅ Uses hit_targets array to prevent double-hitting

### 6. CHAIN Delivery
**File**: SpellCaster, Lines 462-538

First target via raycast, then chains to nearby targets:
- ✅ Proper exclusions
- ✅ Uses shape queries for chain targeting
- ⚠️ **Chain damage falloff not passed to effect** (Line 537)

### 7. BEAM Delivery
**File**: SpellBeam, `/home/shobie/magewar/scripts/components/spell_beam.gd`

```gdscript
func _apply_effects() -> void:
    if effects.is_empty():
        return
    
    # Apply to all current targets
    for target in _hit_targets:
        if target and is_instance_valid(target):
            var hit_point = target.global_position if target is Node3D else global_position
            for effect in effects:
                effect.apply(caster, target, hit_point, spell)
```

**Issues**:
- ✅ Applies effects every tick
- ❌ **Hit detection only on `_on_body_entered` and `_on_area_entered` - may miss moving targets**
- ❌ **Doesn't continuously check for targets in beam path**

---

## Part 4: Collision Layer Configuration

### Constants Definition
**File**: `/home/shobie/magewar/scripts/data/constants.gd`

```
const LAYER_WORLD: int = 1
const LAYER_PLAYERS: int = 2
const LAYER_ENEMIES: int = 3
const LAYER_PROJECTILES: int = 4
const LAYER_PICKUPS: int = 5
const LAYER_TRIGGERS: int = 6
const LAYER_ENVIRONMENT: int = 7
```

### Actual Scene Configurations

#### Enemy Setup (enemy_base.tscn)
```
collision_layer = 4  (BIT 3 = Layer 4 = ENEMIES)
collision_mask = 3   (BITS 1-2 = Layers 1,2 = WORLD + PLAYERS)
```

**DetectionArea (Area3D)**:
```
collision_layer = 0
collision_mask = 2   (BIT 1 = Layer 2 = PLAYERS)
```

**AttackArea (Area3D)**:
```
collision_layer = 0
collision_mask = 2   (BIT 1 = Layer 2 = PLAYERS)
```

#### Player Setup (player.tscn)
```
collision_layer = 2  (BIT 1 = Layer 2 = PLAYERS)
collision_mask = 1   (BIT 0 = Layer 1 = WORLD)
```

**RayCast3D**:
```
collision_mask = 7   (BITS 0-2 = All layers 1,2,3)
```

### The Problem: Collision Layer Mismatch

**ISSUE 1: Enemy Layer Configuration**
- Enemy is on **Layer 4 (ENEMIES)**
- Enemy's collision_mask is **3 (WORLD + PLAYERS)**
- Enemy's detection_area only checks **Layer 2 (PLAYERS)**

**Expected for proper detection**:
- Enemy should be on **Layer 3** (as per Enums: `LAYER_ENEMIES = 3`)
- But scene has it on **Layer 4**

**ISSUE 2: Projectile Collision Mask**
```gdscript
collision_mask = (1 << (Constants.LAYER_WORLD - 1)) 
               | (1 << (Constants.LAYER_PLAYERS - 1)) 
               | (1 << (Constants.LAYER_ENEMIES - 1))
```

This creates: `(1 << 0) | (1 << 1) | (1 << 2)` = **Layers 1, 2, 3**

But enemies are configured on **Layer 4**, not Layer 3!

**This is the ROOT CAUSE**: Projectiles won't detect enemies because:
1. Enemies are on Layer 4
2. Projectiles check Layers 1, 2, 3
3. Layer mismatch = no collision

### Layer Bit Conversion Reference
```
LAYER_WORLD = 1     → Bit 0 → (1 << 0) = 0b0001
LAYER_PLAYERS = 2   → Bit 1 → (1 << 1) = 0b0010
LAYER_ENEMIES = 3   → Bit 2 → (1 << 2) = 0b0100
LAYER_PROJECTILES = 4 → Bit 3 → (1 << 3) = 0b1000
```

---

## Part 5: Why Spells Pass Through Enemies

### Chain of Failure

#### 1. **Projectiles Don't Hit**
- Projectile collision_mask = Bits 0,1,2 (Layers 1,2,3)
- Enemy on Layer 4
- **Result**: `_on_body_entered()` never fires for enemies

#### 2. **Hitscan May Work But Is Risky**
- Uses `query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS | Constants.LAYER_WORLD`
- This should be correct IF Constants are used
- But relies on caster exclusion via `get_rid()` which may fail

#### 3. **AOE/Cone/Chain Also Affected**
- All use `Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS`
- If this constant is calculated as `(1 << 2)` but enemies are on Layer 4, it fails

#### 4. **Target Filtering Fallback**
Even if collision is detected, `can_affect_target()` will reject if:
- Enemy not in "enemies" group
- SaveManager not initialized
- Target filtering set to wrong TargetType

---

## Part 6: Secondary Issues

### 1. Group-Based Filtering
All collision checks depend on group membership:
```gdscript
is_enemy = target.is_in_group("enemies")
```

**Risk**: If enemy not added to group in `_ready()`, it won't be hit.
- ✅ EnemyBase does add: `add_to_group("enemies")` (Line 70)

### 2. SaveManager Dependency
Multiple systems depend on SaveManager being initialized:
- DamageEffect.can_affect_target()
- SpellProjectile._handle_hit()
- DamageEffect.apply()

**Risk**: If SaveManager not ready, friendly_fire checks fail, possibly causing NullReferenceException

### 3. StatsComponent Validation
```gdscript
if target.has_node("StatsComponent"):
    var stats: StatsComponent = target.get_node("StatsComponent")
```

**Risk**: Uses `.get_node()` after `.has_node()` check, which could theoretically return null if node freed between checks (race condition, though unlikely)

### 4. Silent Failures
Many exit points don't log anything:
- Projectile `_handle_hit()` returns silently if `should_hit = false`
- Hitscan doesn't warn if no target found
- AOE doesn't warn if no targets in range

---

## Part 7: Collision Layer Deep Dive

### Projectile Initialization (projectile.gd Line 36)
```gdscript
collision_mask = (1 << (Constants.LAYER_PROJECTILES - 1)) 
              | (1 << (Constants.LAYER_PLAYERS - 1)) 
              | (1 << (Constants.LAYER_ENEMIES - 1))
```

**What this creates**:
- `Constants.LAYER_PROJECTILES = 4` → `(1 << 3)` = 0b1000
- `Constants.LAYER_PLAYERS = 2` → `(1 << 1)` = 0b0010
- `Constants.LAYER_ENEMIES = 3` → `(1 << 2)` = 0b0100
- **Result**: 0b1110 = detects Layers 2, 3, 4

But the projectile itself is on Layer 4!

### Scene Configuration Override
The scene file sets:
- Enemy collision_layer = 4 (correct for Layer 4)
- Projectile should detect Layer 4

**So the code SHOULD work**, but there's a mismatch:
- Code expects enemies on Layer 3
- Scene puts enemies on Layer 4
- This inconsistency breaks detection

---

## Part 8: Summary of Root Causes

### PRIMARY ISSUES

1. **Layer Configuration Mismatch**
   - Code: Expects enemies on Layer 3
   - Scene: Puts enemies on Layer 4
   - Impact: Projectiles won't collide with enemies
   
2. **Inconsistent Bit Calculations**
   - `(1 << (LAYER_ENEMIES - 1))` assumes LAYER_ENEMIES is the bit position
   - But `LAYER_ENEMIES = 3` is the layer number, not bit position
   - Bit 2 (value 4) is for Layer 3, but enemy scene is on Layer 4

3. **Silent Failure Modes**
   - No warnings when projectiles don't hit
   - No warnings when hitscan finds nothing
   - No warnings when AOE finds no targets
   - Makes debugging extremely difficult

### SECONDARY ISSUES

4. **SaveManager Dependency Issues**
   - Multiple systems call SaveManager without null checks
   - Could cause cascading failures

5. **Beam Hit Detection**
   - Only detects on initial contact
   - Doesn't continuously raycast through beam
   - Moving targets might escape beam without damage

6. **Chain Damage Falloff Not Applied**
   - Calculated but not passed to effect.apply()

---

## Part 9: How Damage SHOULD Work (Current Implementation)

### Ideal Flow (When Everything Aligned)

1. **Spell Cast**:
   ```
   Player casts spell → SpellCaster.cast_spell()
   ```

2. **Delivery**:
   ```
   SpellCaster._execute_projectile()
   → Creates SpellProjectile instance
   → Sets collision_layer and collision_mask
   → Calls initialize() with effects array
   ```

3. **Projectile Collision**:
   ```
   SpellProjectile moves via _physics_process()
   → _on_body_entered() or _on_area_entered() fires
   → _handle_hit() called
   ```

4. **Target Validation**:
   ```
   _handle_hit()
   → Check if target valid
   → Check if target in _hit_targets (for pierce)
   → Check collision layer
   → Check group membership
   → Check caster type vs target type
   → Determine should_hit = true/false
   ```

5. **Effect Application**:
   ```
   for effect in effects:
       effect.apply(caster, target, hit_point, spell)
   ```

6. **Damage Effect**:
   ```
   DamageEffect.apply()
   → can_affect_target() ✅ (checks target_type)
   → calculate_damage() ✅ (applies modifiers)
   → stats.take_damage() ✅ (applies defense)
   → _spawn_damage_number() ✅ (visual feedback)
   ```

7. **Health Reduction**:
   ```
   StatsComponent.take_damage()
   → Apply defense modifier
   → Reduce current_health
   → Emit died signal if health <= 0
   ```

8. **Death**:
   ```
   EnemyBase._on_died()
   → Queue free with tween
   → Drop loot
   → Award XP
   ```

### Where It Currently Breaks

**Step 3 is SKIPPED** because:
- Projectile collision_mask doesn't match enemy collision_layer
- Signal `_on_body_entered()` never fires
- Spell "passes through" enemy

---

## Part 10: How to Fix

### IMMEDIATE FIXES

#### Fix 1: Correct Layer Configuration in Scene
**File**: `scenes/enemies/enemy_base.tscn`

Change:
```
collision_layer = 4  ← This is wrong
```

To:
```
collision_layer = 3  ← Correct for LAYER_ENEMIES = 3
```

This makes the enemy collide layer match what projectiles expect.

#### Fix 2: Add Debug Logging
**File**: `scripts/components/spell_caster.gd` and `scenes/spells/projectile.gd`

Add warnings when nothing is hit:
```gdscript
# In _execute_hitscan
if not result:
    push_warning("Hitscan spell '%s' found no target" % spell.spell_name)

# In _handle_hit
if not should_hit:
    push_warning("Projectile hit layer check failed for target: %s" % target.name)
```

#### Fix 3: SaveManager Safety Check
**File**: `resources/spells/effects/damage_effect.gd`

```gdscript
func can_affect_target(caster: Node, target: Node) -> bool:
    if target == null:
        return target_type == Enums.TargetType.GROUND
    
    var is_player = target is Player
    var is_enemy = target.is_in_group("enemies")
    var is_self = target == caster
    
    match target_type:
        Enums.TargetType.ENEMY:
            if is_player:
                # Safely check friendly fire
                if SaveManager and SaveManager.has_method("get"):
                    var friendly_fire = SaveManager.settings_data.get("gameplay", {}).get("friendly_fire", false)
                    return friendly_fire
                return false  # Default: no friendly fire if SaveManager unavailable
            return is_enemy
        # ... rest of matching ...
```

#### Fix 4: Improve Beam Hit Detection
**File**: `scripts/components/spell_beam.gd`

Replace current implementation with continuous raycast:
```gdscript
func _apply_effects() -> void:
    if effects.is_empty():
        return
    
    # Raycast to find targets in beam path
    var space_state = get_world_3d().direct_space_state
    var end_pos = global_position + direction * range
    
    var query = PhysicsRayQueryParameters3D.create(global_position, end_pos)
    query.collision_mask = Constants.LAYER_ENEMIES | Constants.LAYER_PLAYERS
    
    var result = space_state.intersect_ray(query)
    
    if result:
        var target = result.collider
        if target not in _hit_targets:
            _hit_targets.append(target)
        
        if target and is_instance_valid(target):
            for effect in effects:
                effect.apply(caster, target, result.position, spell)
```

### VERIFICATION CHECKLIST

After fixes, verify:

- [ ] Enemy collision_layer = 3 (for LAYER_ENEMIES)
- [ ] Projectile collision_mask includes bit 2 (Layer 3)
- [ ] Hitscan collision_mask uses Constants.LAYER_ENEMIES correctly
- [ ] AOE/Cone/Chain all use Constants.LAYER_ENEMIES
- [ ] SaveManager null checks added
- [ ] Debug warnings added for no-hit cases
- [ ] Test with simple spell vs enemy
- [ ] Check damage numbers appear
- [ ] Check health bar decreases
- [ ] Check enemy dies when health reaches 0

---

## Part 11: Test Cases to Verify

### Test 1: Projectile Hit Detection
```gdscript
# Cast fireball at enemy
var enemy = get_tree().get_first_node_in_group("enemies")
var spell = load("res://resources/spells/presets/fireball.tres")
var player = get_tree().get_first_node_in_group("player")

# Should hit and deal damage
player.spell_caster.cast_spell(spell, enemy.global_position, (enemy.global_position - player.global_position).normalized())
await get_tree().create_timer(0.5).timeout
print("Enemy health: %f" % enemy.stats.current_health)  # Should be less than max
```

### Test 2: Hitscan Hit Detection
```gdscript
# Create hitscan spell and test
# Should instantly hit target in ray direction
```

### Test 3: Layer Configuration
```gdscript
var enemy = get_tree().get_first_node_in_group("enemies")
print("Enemy collision_layer: %d" % enemy.collision_layer)  # Should be 3
print("Enemy collision_mask: %d" % enemy.collision_mask)    # Should be 3

var projectile = get_tree().get_first_node_in_group("projectiles")
if projectile:
    print("Projectile collision_mask: %d (binary: %s)" % [projectile.collision_mask, bin(projectile.collision_mask)])
    # Should detect layer 3
```

---

## Conclusion

The MageWar damage system is **architecturally sound** but suffers from **configuration mismatches**:

1. **Layer configuration mismatch** between code expectations and scene setup
2. **Lack of debug logging** makes failures invisible
3. **SaveManager dependency** without null safety
4. **Beam detection** needs continuous raycasting

These are all **fixable issues** that don't require major refactoring. The fixes are straightforward and will make spells deal damage as intended.

