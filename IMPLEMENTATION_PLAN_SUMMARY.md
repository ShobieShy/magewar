# MageWar Implementation Plan Summary

**Date**: December 21, 2025
**Status**: Planning Complete - Ready for Implementation
**Total Estimated Duration**: 12 hours across 2 parts

---

## OVERVIEW

This implementation plan breaks down the MageWar project into two focused parts based on the exploration findings:

- **PART 1** (6 hours): Add Shop Vendor NPC and Skill Trainer NPC to Town Square
- **PART 2** (6 hours): Implement PvP Arena with team-based combat and Dungeon Lobby system

---

## PART 1: INTERACTIVE NPC IMPLEMENTATION (6 hours)

### What Gets Built
Two new interactive NPCs in Town Square that leverage existing backend systems:

1. **Shop Vendor NPC**
   - NPC character with shop interaction
   - Buys/sells items using existing ShopManager
   - Dynamic stock rotation
   - Located at position (-5, 0, 0) in Town Square

2. **Skill Trainer NPC**
   - NPC character teaching skills
   - Opens SkillTree UI for progression
   - Manages skill point spending
   - Located at position (5, 0, 0) in Town Square

### New Files (5)
- `/scenes/world/starting_town/vendor_npc.gd`
- `/scenes/world/starting_town/vendor_npc.tscn`
- `/scenes/world/starting_town/skill_trainer_npc.gd`
- `/scenes/world/starting_town/skill_trainer_npc.tscn`
- `/resources/shops/town_shop.tres`

### Modified Files (1)
- `/scenes/world/starting_town/town_square.gd`

### Key Dependencies
- Existing: ShopManager, SkillManager, Interactable, NPC base class
- No new systems required - uses existing infrastructure

### Testing Checklist
```
✓ NPCs spawn at correct positions
✓ Visual meshes distinguish between vendors (color coding)
✓ Interaction prompts appear on approach
✓ Shop UI opens and shows inventory
✓ Players can buy/sell items
✓ Skill tree opens with available skills
✓ Skill points can be spent
✓ UI closes properly with Esc key
```

### Success Criteria
- 2 NPCs visible and interactive in Town Square
- Shop functional with buy/sell mechanics
- Skill trainer functional with point spending
- No console errors
- Network-compatible (single-player tested)

---

## PART 2: PvP & DUNGEON LOBBY SYSTEM (6 hours)

### What Gets Built

1. **PvP Arena Infrastructure**
   - PvP damage system (enables player-to-player damage)
   - Team assignment system
   - Team color indicators
   - Friendly fire prevention for teammates

2. **PvP Arena Portal & Instance**
   - New portal in Town Square (center-bottom)
   - Mode selection menu (Free-for-all, Team DM, Training)
   - Separate 40x40 arena scene
   - Match timer and scoring system
   - Spectator framework foundation

3. **Dungeon Lobby System**
   - Party formation UI
   - Ready status tracking
   - Leader-only controls
   - Auto-spawn in dungeons with party

### New Files (10)
- `/scripts/systems/pvp_match_manager.gd`
- `/scenes/pvp/pvp_arena.tscn`
- `/scenes/pvp/pvp_arena.gd`
- `/scenes/world/starting_town/pvp_portal.gd`
- `/scenes/world/starting_town/pvp_portal.tscn`
- `/scenes/ui/menus/pvp_mode_select.tscn`
- `/scenes/ui/menus/pvp_mode_select.gd`
- `/scripts/systems/dungeon_lobby_manager.gd`
- `/scenes/ui/menus/dungeon_lobby.tscn`
- `/scenes/ui/menus/dungeon_lobby.gd`

### Modified Files (5)
- `/resources/spells/effects/damage_effect.gd`
- `/scenes/player/player.gd`
- `/scenes/world/starting_town/town_square.gd`
- `/scenes/main/game.gd`
- `/autoload/dungeon_portal_system.gd`

### Key Dependencies
- Part 1 completion (optional but recommended for context)
- Existing: Portal system, DamageEffect, Player controller
- New: PvPMatchManager, DungeonLobbyManager

### Testing Checklist
```
PvP Arena:
✓ Portal appears in Town Square
✓ Mode selection menu works
✓ Arena loads with correct team spawns
✓ Team damage prevention works
✓ Match timer counts down
✓ Scoring system tracks kills
✓ Return to Town Square works
✓ Network sync for scores and kills

Dungeon Lobby:
✓ Lobby UI appears on dungeon portal
✓ Players can join lobby
✓ Ready status syncs
✓ Leader can start dungeon
✓ Party spawns together in dungeon
```

### Success Criteria
- PvP arena fully functional with modes
- Team system prevents friendly fire
- Dungeon lobbies enable co-op organization
- Match scoring and tracking works
- Network synchronization for multiplayer
- No console errors
- All interactions smooth and responsive

---

## IMPLEMENTATION ORDER

### Recommended Sequence

**Phase 1A** (Parallel if resources available):
- Both NPC scripts and scenes
- Shop data resource

**Phase 1B** (Dependent on 1A):
- Update Town Square to register NPCs
- Test and debug

**Phase 2A** (After Part 1 or parallel):
- PvP infrastructure changes (DamageEffect, Player)
- PvPMatchManager system

**Phase 2B** (Dependent on 2A):
- PvP portal and arena
- Mode selection UI

**Phase 2C** (Can be parallel with 2B):
- Dungeon lobby system
- Dungeon portal enhancement

**Phase 2D** (Final):
- Full integration and network testing

---

## KEY DESIGN DECISIONS

### Part 1
- **Reuse existing systems** instead of creating new ones
- **Visual differentiation** via mesh colors (brown for merchant, purple for trainer)
- **Opposite sides of Town Square** for clear spatial organization
- **No new backend systems** required

### Part 2
- **Separate PvP arena** prevents griefing in main world
- **Team-based by default** for balanced gameplay
- **Dungeon lobbies** organize co-op without forced teaming
- **Host authority** for match state prevents client cheating
- **Framework extensibility** for future ranked/ladder system

---

## ARCHITECTURE PATTERNS ESTABLISHED

### NPC Pattern
Used for both Vendor and Skill Trainer:
```
NPC (CharacterBody3D)
├── Collision (CapsuleShape3D)
├── Mesh (CapsuleMesh with team color)
├── Interactable component
└── Signals connected to UI systems
```

### Lobby Pattern
Used for both PvP and Dungeons:
```
Lobby Manager (Node)
├── Player tracking (peer_id -> info)
├── Ready status (peer_id -> bool)
├── Start conditions validation
└── Signals for UI synchronization
```

These patterns can be reused for:
- Other NPCs (quest givers, merchants, trainers)
- Other multiplayer activities (raids, world events, GvG)

---

## FUTURE EXTENSIONS (PART 5+)

After Parts 1-4 are complete, add:
- Ranked PvP with ELO/ladder
- Achievement tracking and rewards
- Cosmetic cosmetics for PvP/achievements
- Seasonal content rotation
- Guild/faction systems
- Trading/marketplace
- Advanced quest systems

---

## RISKS & MITIGATION

### Potential Issues
1. **Network desynchronization in PvP**
   - Mitigation: Host authority for scoring, local prediction for movement

2. **Performance with many particles/effects**
   - Mitigation: Disable particles on low-end devices, use object pooling

3. **Team stacking in lobby**
   - Mitigation: Balanced auto-assignment, leader cannot change teams

4. **Shop/skill progression exploits**
   - Mitigation: SaveManager validation, server-side verification (future)

### Testing Strategy
1. Single-player first (both parts)
2. Local multiplayer (split-screen or 2 clients on same PC)
3. Network multiplayer (different machines with Steam or ENet)
4. Load testing (max 6 players per spec)

---

## FILE REFERENCES

### Documentation
- `TODO1221-Part1.md` - Detailed tasks for Part 1 (358 lines)
- `TODO1221-Part2.md` - Detailed tasks for Part 2 (658 lines)
- `PROJECT_EXPLORATION.md` - Complete codebase analysis (701 lines)
- `QUICK_REFERENCE.md` - Developer lookup guide (280 lines)
- `EXPLORATION_INDEX.md` - Navigation and statistics

### Code Dependencies
**Must Read First**:
- `/autoload/game_manager.gd` - Player registry
- `/autoload/network_manager.gd` - Network layer
- `/scripts/components/interactable.gd` - Interaction base
- `/scripts/data/constants.gd` - Game constants

**Reference**:
- `/autoload/shop_manager.gd` - Shop system
- `/autoload/skill_manager.gd` - Skills system
- `/scenes/world/portal.gd` - Portal pattern
- `/scenes/world/assembly_station.gd` - Interactable pattern

---

## EXPECTED OUTCOMES

### After Part 1
- Town Square feels more populated with interactive NPCs
- Players have immediate access to shops and skill training
- Pattern established for future NPC additions
- Total new interactive elements: 2 NPCs

### After Part 2
- PvP gameplay enabled with structured matches
- Team-based damage system prevents accidental griefing
- Co-op dungeon parties more organized
- Foundation for ranked/competitive systems
- Total new interactive elements: PvP Arena + Lobby system

### Overall Project Impact
- **Reusable patterns**: NPC template, Lobby system
- **Multiplayer features**: PvP arena, party system
- **Extensible systems**: Team framework, match manager
- **Community features**: Shop, training, PvP

---

## TIMELINE SUMMARY

| Phase | Duration | Task | Status |
|-------|----------|------|--------|
| 1.1 | 2.5h | Vendor NPC | Planned |
| 1.2 | 2.5h | Skill Trainer | Planned |
| 1.3 | 1h | Integration & Test | Planned |
| **Part 1 Total** | **6h** | **NPCs** | **Planned** |
| 2.1 | 2h | PvP Infrastructure | Planned |
| 2.2 | 1.5h | PvP Arena & Portal | Planned |
| 2.3 | 1.5h | Dungeon Lobbies | Planned |
| 2.4 | 1h | Integration & Test | Planned |
| **Part 2 Total** | **6h** | **PvP & Lobbies** | **Planned** |
| **GRAND TOTAL** | **12h** | **Complete Plan** | **Planned** |

---

## NEXT STEPS

1. **Review this plan** - Confirm Part 1 and Part 2 scope with stakeholders
2. **Read Part 1 in detail** (`TODO1221-Part1.md`)
3. **Begin Part 1 implementation** - Vendor NPC first, then Skill Trainer
4. **Test after each phase** - Don't wait until end
5. **Read Part 2** (`TODO1221-Part2.md`) while Part 1 is in progress
6. **Integrate Part 2** - PvP infrastructure, then arena, then lobbies

---

**Documentation Complete**: Ready for implementation
**Questions?**: See TODO1221-Part*.md for detailed tasks or contact team lead

