# Phase 1 Architecture Overview

**Visual guide to how all the systems interconnect**

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     PLAYER CHARACTER                         │
├─────────────────────────────────────────────────────────────┤
│  - grant_weapon_xp(amount)                                   │
│  - inventory (InventorySystem)                               │
│  - current_weapon (Staff/Wand)                               │
│  - gold                                                      │
└──────────────┬──────────────────┬───────────────────────────┘
               │                  │
               ▼                  ▼
    ┌──────────────────┐  ┌────────────────────────┐
    │ current_weapon   │  │  InventorySystem       │
    │ (Staff/Wand)     │  ├────────────────────────┤
    ├──────────────────┤  │ inventory[]            │ ◄──── ItemData[]
    │ • base_spell     │  │ equipment{}            │
    │ • parts[]        │  │ materials{} ◄──────────┼───┐  (NEW)
    │ • gems[]         │  │ • add_material()       │   │
    ├──────────────────┤  │ • remove_material()    │   │
    │ • leveling_      │  │ • has_materials()      │   │
    │   system ────────┼──┼──────────────────────┐ │   │
    │ • refinement_    │  │ • consume_materials()  │ │   │
    │   system ────────┼──┼───────────┐           │ │   │
    └──────────────────┘  └────────────┼───────────┼─┘   │
               │                       │           │     │
               │                       ▼           ▼     ▼
               │          ┌──────────────────────────────────┐
               │          │  CraftingMaterial Resources      │
               │          ├──────────────────────────────────┤
               │          │ ore_fragment.tres                │
               │          │ fire_essence_2.tres              │
               │          │ shard_chunk.tres                 │
               │          │ ... (48 total materials)         │
               │          └──────────────────────────────────┘
               │
               ▼
    ┌──────────────────────────────────────┐
    │   SPELL CASTING SYSTEM               │
    ├──────────────────────────────────────┤
    │  SpellCaster (player.spell_caster)   │
    │  • cast_spell()                      │
    │  • _process_cooldowns()              │
    │  • signal: spell_cast_completed ────┼──┐
    │  • _grant_weapon_xp_from_spell() ◄──┼──┤ XP GRANT
    │    (NEW)                            │  │
    └──────────────┬───────────────────────┘  │
                   │                          │
                   ▼                          │
        ┌──────────────────┐                 │
        │  SpellData       │                 │
        │  • spell_name    │                 │
        │  • mana_cost     │                 │
        │  • element       │                 │
        │  • effects       │                 │
        └──────────────────┘                 │
                   │                         │
                   ▼                         │
        ┌──────────────────┐                │
        │ Element Matching │                 │
        │ (Fire vs Air)    │                 │
        └──────────────────┘                │
                                            │
                                            ▼
                        ┌───────────────────────────────┐
                        │ WeaponLevelingSystem (NEW)    │
                        ├───────────────────────────────┤
                        │ Properties:                   │
                        │ • weapon_level: int           │
                        │ • weapon_experience: float    │
                        │ • total_experience: float     │
                        │ • max_player_level: int       │
                        │ • experience_table: Array     │
                        │                               │
                        │ Methods:                      │
                        │ • add_experience(amount)      │
                        │ • get_xp_for_next_level()     │
                        │ • get_level_progress()        │
                        │ • get_stat_bonus(name)        │
                        │ • get_damage_bonus() ◄────┐   │
                        │                          │   │
                        │ Signals:                 │   │
                        │ • level_changed()        │   │
                        │ • experience_gained()    │   │
                        │ • level_up()             │   │
                        └───────────────────────────────┘
                                               │
                        ┌──────────────────────┴──────┐
                        │                             │
                        ▼                             ▼
            ┌───────────────────────────┐  ┌────────────────────────┐
            │   Stat Calculation        │  │ RefinementSystem (NEW) │
            │   get_total_damage()      │  ├────────────────────────┤
            │                           │  │ Properties:            │
            │ damage = (base +          │  │ • refinement_level     │
            │           level_bonus) ×  │  │ • success_rates{}      │
            │           refinement_mult │  │ • downgrade_risk{}     │
            │                           │  │ • refinement_costs{}   │
            └───────────────────────────┘  │                        │
                        ▲                  │ Methods:               │
                        │                  │ • attempt_refinement() │
                        │                  │ • get_success_chance() │
                        │                  │ • get_next_cost()      │
                        │                  │ • get_damage_mult() ──┐│
                        │                  │                        ││
                        │                  │ Signals:               ││
                        │                  │ • refinement_changed() ││
                        │                  │ • refinement_succeed() ││
                        │                  │ • refinement_failed()  ││
                        │                  └────────────────────────┘│
                        │                             ▲              │
                        │                             │              │
                        └─────────────────────────────┘              │
                                                                     │
                            Damage Formula:                          │
                        final_damage = (base_dmg +                  │
                                        level_bonus) ×           ◄──┘
                                        refinement_multiplier
```

---

## Data Flow: From Spell Cast to XP Gain

```
SPELL CAST FLOW:
═════════════════════════════════════════════════════════════════

1. Player casts spell
   └─ Input: Player presses spell button
   └─ Action: Player.spell_caster.cast_spell(spell)

2. SpellCaster validates and casts
   ├─ Check: can_cast_spell()?
   ├─ Action: Consume mana
   ├─ Action: Execute delivery (projectile, beam, etc.)
   └─ Signal: spell_cast_completed.emit(spell)

3. XP GRANT (NEW SYSTEM)
   ├─ Listener: spell_cast_completed → _grant_weapon_xp_from_spell()
   ├─ Calculate: xp = 5 + (spell.mana_cost / 10)
   ├─ Call: caster.grant_weapon_xp(xp)
   └─ Signal: weapon XP granted

4. Player distributes XP
   ├─ Method: grant_weapon_xp(amount)
   ├─ Get: current_weapon
   ├─ Call: current_weapon.gain_experience(amount)
   └─ Pass: amount to weapon

5. Weapon receives XP
   ├─ Method: gain_experience(amount)
   ├─ Get: leveling_system
   ├─ Call: leveling_system.add_experience(amount)
   └─ Pass: amount to leveling system

6. WeaponLevelingSystem processes
   ├─ Add: weapon_experience += amount
   ├─ Add: total_experience += amount
   ├─ Signal: experience_gained.emit(amount)
   ├─ Check: weapon_experience >= next_level_xp?
   │         └─ YES: Call _level_up()
   │            ├─ weapon_level += 1
   │            ├─ weapon_experience -= xp_needed
   │            ├─ Signal: level_changed.emit(new_level)
   │            └─ Signal: level_up.emit(new_level)
   │         └─ NO: Continue
   └─ Done: Weapon XP applied

7. Stats recalculated
   ├─ Source: weapon.leveling_system.get_damage_bonus()
   ├─ Source: weapon.refinement_system.get_damage_multiplier()
   ├─ Formula: final_damage = (base + level_bonus) × refinement_mult
   └─ Apply: Player stats updated automatically

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXAMPLE: Fire Spell Cast
═══════════════════════════════════════════════════════════════

1. Player casts: fire_spell (mana_cost: 50)
2. Spell complete → _grant_weapon_xp_from_spell(fire_spell)
3. XP calculated: 5 + (50/10) = 10 XP
4. Player.grant_weapon_xp(10)
5. Weapon.gain_experience(10)
6. leveling_system.add_experience(10)
7. weapon_experience += 10 (now 245/1000 for level 2)
8. No level up yet (need 1000 total)
9. Weapon damage unchanged (not yet level 2)

After 100 casts:
   weapon_experience = 1000
   → Call _level_up()
   → weapon_level = 2
   → weapon_experience = 0 (for next level)
   → damage bonus increases: +2 per level = +2 damage at level 2
```

---

## Material Drop Flow

```
ENEMY DEATH FLOW (Future Integration):
═════════════════════════════════════════════════════════════════

1. Enemy takes fatal damage
   └─ Signal: health <= 0

2. Enemy death handler triggered
   ├─ Action: Play death animation
   ├─ Action: Drop loot
   ├─ Action: Grant XP
   └─ Signal: enemy_died.emit(enemy)

3. MATERIAL DROPS (NEW SYSTEM)
   ├─ Create: material_system = MaterialDropSystem.new()
   ├─ Call: materials = material_system.generate_enemy_drops(
   │           rarity: Enums.Rarity.RARE,
   │           level: 5
   │         )
   └─ Return: Array[CraftingMaterial]
       └─ Example: [ore_chunk.tres, fire_essence_2.tres]

4. For each material drop:
   ├─ Convert: item = create_material_item_data(material, qty)
   ├─ Spawn: loot_system.drop_loot(item, position)
   └─ Visual: Loot pickup appears in world

5. Player picks up loot
   ├─ Trigger: Pickup detection (area3d overlap)
   ├─ Call: player.inventory.add_material(material_id, qty)
   │   └─ materials["ore_chunk"] += 1
   └─ Signal: inventory_changed.emit()

6. WEAPON XP FROM KILL
   ├─ Calculate: xp = 15 × (1 + rarity × 0.5)
   │   └─ Rare enemy: 15 × 1.5 = 22.5 XP
   ├─ Call: player.grant_weapon_xp(22.5)
   └─ Flow: (see above Spell Cast → Stats recalculated)

7. All complete
   ├─ Materials in inventory
   ├─ Weapon XP gained
   ├─ Weapon level increased (if threshold crossed)
   └─ Player can use materials for refinement

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXAMPLE: Defeating Rare Goblin Brute
═══════════════════════════════════════════════════════════════

1. Goblin takes final damage
2. Death handler:
   ├─ material_system.generate_enemy_drops(RARE, 3)
   │  └─ 60% ore → ore_chunk ✓
   │  └─ 30% essence → fire_essence_2 ✓
   │  └─ 10% shard → NO
   │  └─ Return: [ore_chunk, fire_essence_2]
   │
   ├─ Spawn pickups
   │  ├─ loot_system.drop_loot(ore_chunk_item, position)
   │  └─ loot_system.drop_loot(fire_essence_item, position)
   │
   └─ Grant XP: 15 × 1.5 = 22.5 XP → player.grant_weapon_xp(22.5)

3. Player moves over pickups
   ├─ Pickup 1: ore_chunk
   │  └─ player.inventory.add_material("ore_chunk", 1)
   │     └─ materials["ore_chunk"] = 1
   │
   └─ Pickup 2: fire_essence_2
      └─ player.inventory.add_material("fire_essence_2", 1)
         └─ materials["fire_essence_2"] = 1

4. Player has materials for refinement!
   ├─ Can refine to +3: costs 200 gold + 1× ore_chunk
   ├─ Check: player.gold >= 200? ✓
   ├─ Check: inventory.has_materials({"ore_chunk": 1})? ✓
   └─ Ready to refine

5. Player refines weapon
   ├─ Consume: gold -= 200
   ├─ Consume: inventory.consume_materials({"ore_chunk": 1})
   ├─ Attempt: refinement_system.attempt_refinement()
   │  └─ Roll: randf() vs success_chance (85%)
   │  └─ Result: SUCCESS ✓
   │  └─ refinement_level = 3
   │
   └─ New stats applied:
      └─ damage_mult = 1 + (3 × 0.03) = 1.09 (9% boost)
```

---

## Refinement Success/Failure Branches

```
REFINEMENT ATTEMPT FLOW:
═════════════════════════════════════════════════════════════════

Player has: +2 refinement, wants +3

1. Get cost:
   ├─ gold_cost: 200
   ├─ materials: {"ore_piece": 1}
   └─ success_rate: 85%

2. Player spends materials (before attempt):
   ├─ player.gold -= 200
   ├─ player.inventory.consume_materials({"ore_piece": 1})
   └─ Point of no return

3. Refinement attempt:
   ├─ roll = randf() [0.0-1.0]
   ├─ success_chance = 0.85
   │
   └─ IF roll < 0.85:  ══════════════════════════════════════
      │ SUCCESS!
      ├─ refinement_level = 3
      ├─ refinement_exp = 0
      ├─ Signal: refinement_succeeded.emit(3)
      ├─ Signal: refinement_changed.emit(3)
      └─ damage_mult = 1 + (3 × 0.03) = 1.09
   │
   └─ ELSE (roll >= 0.85):  ════════════════════════════════════
      │ FAILURE
      │
      ├─ downgrade_risk = downgrade_risk[2] = 0%
      │  (Tier +2 has no downgrade risk)
      │
      ├─ IF randf() < 0% (NO):
      │  └─ refinement_level stays 2
      │  └─ weapon_experience stays same
      │  └─ Weapon unaffected (just lost materials/gold)
      │
      └─ Signal: refinement_failed.emit(2, false)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTERNATIVE: Attempting +9 refinement (HIGH RISK)
═════════════════════════════════════════════════════════════════

Player has: +8 refinement, wants +9

1. Get cost:
   ├─ gold_cost: 2000
   ├─ materials: {"ore_crystal": 4}
   └─ success_rate: 55%

2. Player spends materials:
   ├─ player.gold -= 2000
   ├─ player.inventory.consume_materials({"ore_crystal": 4})
   └─ Point of no return

3. Refinement attempt:
   ├─ roll = 0.72 (unlucky)
   ├─ success_chance = 0.55
   │
   └─ roll >= success_chance: FAILURE
      │
      ├─ downgrade_risk = downgrade_risk[8] = 40%
      ├─ downgrade_roll = randf() = 0.25
      │
      └─ IF 0.25 < 40% (YES - DOWNGRADE!):
         │
         ├─ refinement_level = 8 (dropped from 9)
         ├─ Materials already consumed (lost!)
         ├─ Gold already spent (lost!)
         │
         └─ Signal: refinement_failed.emit(8, true)
            └─ UI shows: "Refinement failed and downgraded!"

4. Player is now at +8 (where they started)
   ├─ Lost: 2000 gold + 4× ore_crystal
   ├─ Gained: Nothing
   └─ Lesson: High tiers are risky!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECOVERY INSURANCE (Phase 1.8 Feature):
═════════════════════════════════════════════════════════════════

Player enables "Material Recovery" before attempting +9:

1. Calculate recovery cost:
   ├─ materials_count = 4 (ore_crystal)
   ├─ recovery_cost = 4 × 50 = 200 gold
   └─ Display: "200 gold to protect materials"

2. Player pays 200 gold for insurance

3. Refinement attempt fails with downgrade:
   ├─ Materials would be lost
   ├─ BUT: Insurance kicks in
   ├─ Weapon still downgrades to +8
   ├─ But materials are returned to inventory!
   │  └─ {"ore_crystal": 4} returned
   │
   └─ Total loss: 2000 gold + 200 gold insurance
      (Instead of 2000 + 4× ore_crystal)
```

---

## System Interaction Map

```
┌─────────────────────────────────────────────────────────────┐
│                    PLAYER SYSTEMS                           │
├─────────────────────────────────────────────────────────────┤
│  • StatsComponent (health, mana, stamina)                    │
│  • InventorySystem (items, equipment, MATERIALS)            │
│  • SkillManager (passive/active abilities)                  │
│  • QuestManager (progression tracking)                      │
│  • SaveManager (persistence)                                │
└──┬──────────────────────────────────────────────────────────┘
   │
   ├──► weapon.leveling_system (XP, levels)
   ├──► weapon.refinement_system (tiers, costs)
   ├──► inventory.materials (material tracking)
   ├──► spell_caster.spell_cast_completed (XP trigger)
   └──► equipment.primary_weapon (equipped weapon reference)


                   MATERIAL FLOW
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
   ENEMIES                         INVENTORY
   • Generate drops        ──►    • Track materials
   • Material Type RNG           • Persist in save
   • Quantity rolled             • Consume for crafting


                   WEAPON PROGRESSION
                        │
        ┌───────────────┴────────────────┐
        │                                │
        ▼                                ▼
   SPELL CASTING                   ENEMY KILLS
   • XP: 5 + (mana/10)       • XP: 15 × (1+rarity×0.5)
   • Automatic grant          • Future integration
   • Per-spell calc           • Based on difficulty


                   STAT CALCULATION
                        │
        ┌───────────────┴─────────────────┐
        │                                 │
        ▼                                 ▼
   WEAPON LEVEL            WEAPON REFINEMENT
   • +2 damage/level       • ×(1 + level × 0.03)
   • Fire rate %           • Success rate scaling
   • Accuracy %            • Downgrade risk
   • Mana efficiency       • Material costs

        └───────────────┬─────────────────┘
                        ▼
                 FINAL DAMAGE
           (base + level) × refinement
```

---

## Save/Load Data Model

```
SAVE FILE STRUCTURE:
═══════════════════════════════════════════════════════════════

player.gd saves:
{
  "position": Vector3,
  "rotation": Vector3,
  "stats": {
    "health": 100,
    "mana": 50,
    "level": 5,
    "gold": 1500
  },
  "inventory": {
    "inventory": [...],
    "equipment": {...},
    "materials": {                    ◄── NEW
      "ore_fragment": 5,
      "ore_chunk": 2,
      "fire_essence_2": 1,
      "shard_piece": 3
    }
  }
}

weapon.save_data() includes:
{
  "weapon_level": 5,                 ◄── NEW
  "weapon_experience": 234.5,        ◄── NEW
  "weapon_total_experience": 5234.5, ◄── NEW
  "refinement_level": 3,             ◄── NEW
  "spell_core": {...},
  "parts": [...],
  "gems": [...]
}

LOAD FLOW:
1. SaveManager.load_game()
2. InventorySystem.load_save_data()
   ├─ Load inventory items
   ├─ Load equipment
   ├─ Load materials ◄── NEW
   └─ Restore materials dict
3. Weapon.load_save_data()
   ├─ Restore spell core
   ├─ Restore parts
   ├─ Restore level ◄── NEW
   ├─ Restore experience ◄── NEW
   ├─ Restore refinement ◄── NEW
   └─ Recalculate stats
```

---

## Error Handling & Edge Cases

```
SAFE PATTERNS:
═══════════════════════════════════════════════════════════════

1. MATERIAL CONSUMPTION (Atomic)
   ✓ Check: has_materials(requirements)?
   ✓ If NO: Reject transaction, return early
   ✓ If YES: consume_materials(requirements)
   ✓ No rollback needed (atomic operation)

2. WEAPON LEVEL OVERFLOW
   ✓ weapon_level = clamp(new_level, 1, max_player_level)
   ✓ Never exceeds player level
   ✓ When player levels up, weapon can auto-level

3. REFINEMENT DOWNGRADE
   ✓ Check: downgrade_risk[current_tier]
   ✓ On failure: Force down if risk triggers
   ✓ Prevent: refinement_level < 0 (use max())

4. NULL SAFETY
   ✓ if leveling_system: before calling methods
   ✓ if weapon: before granting XP
   ✓ Graceful degradation if systems missing


KNOWN LIMITATIONS (Phase 1.0):
═══════════════════════════════════════════════════════════════

1. No enemy kill XP yet (needs enemy death hook)
2. No refinement UI yet (phase1-8)
3. No CraftingManager integration yet (phase1-9)
4. Material drops not integrated (needs EnemySpawnSystem update)
5. No transmutation system yet (Phase 3)
6. No gem evolution yet (Phase 2)
7. No weapon-specific mechanics yet (Phase 4)
```

---

## Performance Checklist

```
OPTIMIZATION TARGETS:
═══════════════════════════════════════════════════════════════

✓ Material lookup:     O(1) dict access
✓ Level check:         O(1) comparison
✓ XP add:              O(1) math
✓ Refinement cost:     O(1) dict lookup
✓ Stat calculation:    O(1) math
✓ Overall per cast:    <2ms overhead

AVOID:
✗ Don't iterate through experience_table every frame
✗ Don't create new WeaponLevelingSystem per level
✗ Don't recalculate all stats every frame (cache)
✗ Don't grant XP multiple times per spell

RECOMMENDED:
✓ Cache stat calculations
✓ Grant XP once per spell completion
✓ Use signals instead of polling
✓ Batch material operations
```

---

Generated: December 20, 2025
Phase 1 Architecture - Final Overview
