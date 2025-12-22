# MageWar Implementation Plan Index

**Date**: December 21, 2025  
**Status**: ✓ Planning Complete - Ready for Implementation  
**Total Scope**: 12 hours across 2 parts  
**Mode**: Planning Phase (Read-only, no code changes yet)

---

## DOCUMENTS OVERVIEW

### Executive Summary
**File**: `IMPLEMENTATION_PLAN_SUMMARY.md` (9.7 KB)

Start here for a high-level understanding. Contains:
- Part 1 & 2 overview
- What gets built
- Files to create/modify
- Success criteria
- Timeline summary
- Key design decisions

**Read Time**: 15 minutes

---

### Detailed Implementation Plans

#### Part 1: Interactive NPCs (6 hours)
**File**: `TODO1221-Part1.md` (10 KB, 358 lines)

Covers Shop Vendor and Skill Trainer NPC implementation:
- **Phase 1.1**: Vendor NPC (2.5 hours)
  - Create script, scene, shop data
  - Register in Town Square
  - Testing

- **Phase 1.2**: Skill Trainer NPC (2.5 hours)
  - Create script, scene, dialogue
  - Register in Town Square
  - Testing

- **Phase 1.3**: Integration & Testing (1 hour)
  - Final integration
  - Verification checklist
  - Debugging guide

**Contents**: Code examples, file structure, testing checklist

**Read Time**: 45 minutes (detailed)

---

#### Part 2: PvP & Dungeon Lobbies (6 hours)
**File**: `TODO1221-Part2.md` (19 KB, 658 lines)

Covers PvP arena and dungeon party system:
- **Phase 2.1**: PvP Infrastructure (2 hours)
  - Extend DamageEffect for PvP
  - Add team system to Player
  - Create PvPMatchManager
  - PvP arena scene

- **Phase 2.2**: PvP Arena Portal (1.5 hours)
  - Portal script and scene
  - Mode selection menu
  - Town Square registration

- **Phase 2.3**: Dungeon Lobbies (1.5 hours)
  - DungeonLobbyManager system
  - Lobby UI
  - Party management

- **Phase 2.4**: Integration & Testing (1 hour)
  - Full system integration
  - Comprehensive testing
  - Network validation

**Contents**: Code examples, architecture patterns, testing checklist

**Read Time**: 60 minutes (detailed)

---

### Reference Documents

#### Project Exploration
**File**: `PROJECT_EXPLORATION.md` (22 KB, 701 lines)

Complete technical analysis of MageWar codebase:
- Main scenes and structure
- All interactable objects
- Player mechanics (inventory, crafting, combat)
- NPC systems
- Enemy loot mechanics
- Network & PvP architecture
- Feature suggestions

**Use For**: Understanding existing systems before implementation

---

#### Quick Reference
**File**: `QUICK_REFERENCE.md` (8.7 KB, 280 lines)

Developer lookup guide:
- Scene hierarchies
- Key components and patterns
- Constants and formulas
- Common operations
- Debugging commands
- Known issues

**Use For**: Quick lookups during coding

---

#### Navigation Index
**File**: `EXPLORATION_INDEX.md` (8.4 KB)

How to find specific information:
- File organization by category
- Implementation examples
- Statistics
- Best practices

**Use For**: Finding information efficiently

---

## READING SEQUENCE

### For Approval/Review
1. `IMPLEMENTATION_PLAN_SUMMARY.md` (15 min)
   - Get overview of both parts
   - Understand scope and timeline
   - Review design decisions

### For Implementation Start
1. `IMPLEMENTATION_PLAN_SUMMARY.md` (15 min) - Overview
2. `TODO1221-Part1.md` (45 min) - Detailed Part 1
3. `PROJECT_EXPLORATION.md` - Reference as needed
4. `QUICK_REFERENCE.md` - Reference as needed

### For Debugging/Issues
1. `QUICK_REFERENCE.md` - Known issues section
2. `PROJECT_EXPLORATION.md` - Architecture explanation
3. Code files mentioned in todo lists

### For Future Features (Part 5+)
1. `EXPLORATION_INDEX.md` - Suggestions section
2. `PROJECT_EXPLORATION.md` - Full features analysis
3. Implementation patterns from Parts 1-2

---

## QUICK FACTS

### Part 1 (NPCs)
- **Duration**: 6 hours
- **New Files**: 5
- **Modified Files**: 1
- **Systems Used**: ShopManager, SkillManager (existing)
- **Difficulty**: Low-Medium (uses existing systems)

### Part 2 (PvP & Lobbies)
- **Duration**: 6 hours
- **New Files**: 10
- **Modified Files**: 5
- **Systems Created**: 2 (PvPMatchManager, DungeonLobbyManager)
- **Difficulty**: Medium-High (new systems)

### Combined
- **Total Duration**: 12 hours
- **Total Files**: 15 new + 6 modified
- **Code Quality**: Follows existing patterns
- **Network Ready**: Both parts support multiplayer
- **Reusability**: Patterns for future features

---

## FILES TO CREATE

### Part 1 (5 new files)
```
/scenes/world/starting_town/
├── vendor_npc.gd
├── vendor_npc.tscn
├── skill_trainer_npc.gd
└── skill_trainer_npc.tscn

/resources/shops/
└── town_shop.tres
```

### Part 2 (10 new files)
```
/scripts/systems/
├── pvp_match_manager.gd
└── dungeon_lobby_manager.gd

/scenes/pvp/
├── pvp_arena.gd
└── pvp_arena.tscn

/scenes/world/starting_town/
├── pvp_portal.gd
└── pvp_portal.tscn

/scenes/ui/menus/
├── pvp_mode_select.gd
├── pvp_mode_select.tscn
├── dungeon_lobby.gd
└── dungeon_lobby.tscn
```

### Part 1 & 2 Modified (6 files)
```
/resources/spells/effects/damage_effect.gd
/scenes/player/player.gd
/scenes/world/starting_town/town_square.gd
/scenes/objects/dungeon_portal.gd
/scenes/main/game.gd
/autoload/dungeon_portal_system.gd
```

---

## KEY DECISIONS

### Part 1
- ✓ Use existing ShopManager (no new systems)
- ✓ Use existing SkillManager (no new systems)
- ✓ Visual distinction via mesh colors (brown vs purple)
- ✓ Opposite sides of Town Square (spatial balance)

### Part 2
- ✓ Separate PvP arena (prevents griefing)
- ✓ Team-based by default (better balance)
- ✓ Host authority for match state (anti-cheat)
- ✓ Framework extensible (future ranked system)

---

## ARCHITECTURE PATTERNS

### NPC Pattern (Reusable)
```
CharacterBody3D (NPC)
├── CollisionShape3D (CapsuleShape3D)
├── MeshInstance3D (color-coded)
├── Interactable component
└── Signals to UI systems
```

**Used For**: Both Part 1 NPCs, extensible for more

### Lobby Pattern (Reusable)
```
Manager System (Node)
├── Player tracking
├── Ready status
├── Start validation
└── Signal emission
```

**Used For**: PvP matchmaking and dungeon parties, extensible for raids/events

---

## SUCCESS CRITERIA

### Part 1
- ✓ 2 NPCs spawn in Town Square
- ✓ Shop functional (buy/sell)
- ✓ Skill trainer functional (point spending)
- ✓ No console errors
- ✓ Network compatible

### Part 2
- ✓ PvP arena accessible and functional
- ✓ Team system prevents friendly fire
- ✓ Dungeon lobbies organize parties
- ✓ Match scoring works
- ✓ Network synchronization functional
- ✓ No console errors

---

## TESTING STRATEGY

1. **Part 1 Single-Player**
   - Load town_square.tscn
   - Test NPC interactions
   - Verify shop/skill UI

2. **Part 2 Single-Player**
   - Test PvP arena loading
   - Verify team assignment
   - Test lobby creation

3. **Multiplayer (Optional but Recommended)**
   - Test 2+ clients
   - Verify network sync
   - Check score broadcasting
   - Validate party creation

4. **Load Testing**
   - Max 6 players per spec
   - Test performance limits
   - Identify bottlenecks

---

## RISK MITIGATION

### Potential Issue #1: Network Desync
- **Mitigation**: Host authority for critical state
- **Reference**: Part 2 section 2.1.3

### Potential Issue #2: Shop/Skill Exploits
- **Mitigation**: SaveManager validation
- **Future**: Server-side verification

### Potential Issue #3: Team Stacking
- **Mitigation**: Auto-assignment, no manual team switch
- **Reference**: Part 2 section 2.2.2

### Potential Issue #4: Performance
- **Mitigation**: Particle culling, object pooling
- **Reference**: QUICK_REFERENCE.md performance section

---

## IMPLEMENTATION TIMELINE

| Phase | Duration | Deliverable | Notes |
|-------|----------|-------------|-------|
| 1.1 | 2.5h | Vendor NPC | Shop + data |
| 1.2 | 2.5h | Skill Trainer | UI integration |
| 1.3 | 1h | Testing | Part 1 verification |
| 2.1 | 2h | PvP Infrastructure | Team system |
| 2.2 | 1.5h | PvP Arena | Portal + menu |
| 2.3 | 1.5h | Dungeon Lobbies | Party system |
| 2.4 | 1h | Testing | Part 2 verification |
| **Total** | **12h** | **2 parts** | **Ready for play** |

---

## NEXT ACTIONS

### Before Implementation
1. ✓ Read IMPLEMENTATION_PLAN_SUMMARY.md
2. ✓ Review TODO1221-Part1.md
3. ? Approve plan and timeline
4. ? Clear any blockers

### When Ready to Start
1. Read TODO1221-Part1.md (detailed)
2. Start Phase 1.1 (Vendor NPC)
3. Reference PROJECT_EXPLORATION.md as needed
4. Use QUICK_REFERENCE.md for lookups

### After Part 1
1. Test Part 1 completely
2. Read TODO1221-Part2.md (detailed)
3. Review any Part 1 lessons learned
4. Begin Phase 2.1

### After Both Parts
1. Full testing and debugging
2. Network validation
3. Performance optimization
4. Ready for player testing

---

## DOCUMENTATION VERSIONS

| Document | Size | Lines | Status |
|----------|------|-------|--------|
| IMPLEMENTATION_PLAN_SUMMARY.md | 9.7 KB | ~300 | ✓ Complete |
| TODO1221-Part1.md | 10 KB | 358 | ✓ Complete |
| TODO1221-Part2.md | 19 KB | 658 | ✓ Complete |
| PROJECT_EXPLORATION.md | 22 KB | 701 | ✓ Complete |
| QUICK_REFERENCE.md | 8.7 KB | 280 | ✓ Complete |
| EXPLORATION_INDEX.md | 8.4 KB | ~400 | ✓ Complete |
| PLAN_INDEX.md | (this file) | - | ✓ Complete |

**Total Documentation**: ~78 KB, ~2,700 lines

---

## SUPPORT & QUESTIONS

### For Implementation Questions
→ See detailed task description in TODO1221-Part*.md

### For System Architecture Questions
→ See PROJECT_EXPLORATION.md or QUICK_REFERENCE.md

### For Code Pattern Questions
→ See existing implementations referenced in todo lists

### For Debugging Issues
→ Check QUICK_REFERENCE.md "Debugging" and "Known Issues" sections

---

## APPROVAL CHECKLIST

Before starting implementation, ensure:

- [ ] IMPLEMENTATION_PLAN_SUMMARY.md reviewed
- [ ] Part 1 scope agreed upon (6 hours, 2 NPCs)
- [ ] Part 2 scope agreed upon (6 hours, PvP + Lobbies)
- [ ] Timeline acceptable (12 hours total)
- [ ] Design decisions understood
- [ ] No blocking dependencies
- [ ] Development resources available
- [ ] Testing strategy acceptable

---

**Document Status**: ✓ Planning Complete  
**Implementation Status**: Ready (not yet started)  
**Next Step**: Begin implementation when approved

---

**Questions?** See reference documents or ask team lead.

