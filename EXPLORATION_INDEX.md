# MageWar Exploration Index

This directory contains comprehensive documentation of the MageWar project structure and mechanics.

## Documentation Files

### 1. **PROJECT_EXPLORATION.md** (701 lines)
   **Complete Technical Analysis**
   - Main playable map/scene structure
   - All interactable object systems (5 types)
   - Player mechanics (inventory, crafting, combat, movement, stats)
   - NPC and dialogue systems
   - Enemy loot drop mechanics (with formulas)
   - Network and PvP infrastructure
   - Suggestions for new features (tiered by priority)
   - File reference index
   - Architecture strengths and areas for improvement

   **Best For**: Understanding the complete system architecture

### 2. **QUICK_REFERENCE.md** (280 lines)
   **Developer Quick Lookup Guide**
   - Quick facts and scene hierarchy
   - Key components and how to extend them
   - Inventory, loot, and combat constants
   - Networking connection flow
   - Important files to read first
   - Common operations and code snippets
   - Debugging commands
   - Performance notes
   - Known issues and gotchas

   **Best For**: Quick lookups during development

---

## Quick Navigation

### Understanding Game Structure
1. Start with QUICK_REFERENCE.md "Scene Hierarchy"
2. Read PROJECT_EXPLORATION.md "Main Playable Map/Scene Structure"
3. Reference `/scenes/main/game.gd` for player spawning logic

### Adding New Features
1. Read PROJECT_EXPLORATION.md "Suggestions for New Interactive Elements"
2. Check QUICK_REFERENCE.md "Adding New Features" for patterns
3. Study existing implementations (LootChest, Portal, AssemblyStation)

### Networking & Multiplayer
1. Read PROJECT_EXPLORATION.md "Networking & PvP Systems"
2. Reference `/autoload/network_manager.gd` (connection)
3. Reference `/autoload/game_manager.gd` (player registry)
4. Study `/scenes/main/game.gd` (player spawning)

### Loot & Combat
1. Read QUICK_REFERENCE.md "Loot System" & "Combat Constants"
2. Read PROJECT_EXPLORATION.md "Enemy Loot Drop System"
3. Reference `/scripts/systems/loot_system.gd`
4. Reference `/scenes/enemies/enemy_base.gd` (drop implementation)

### Crafting & Inventory
1. Read PROJECT_EXPLORATION.md "Player Mechanics" sections B & C
2. Reference `/scripts/systems/inventory_system.gd`
3. Reference `/scenes/world/assembly_station.gd`
4. Study `/scripts/systems/crafting_manager.gd`

---

## Key Files by Category

### Core Systems (Read First)
- `/autoload/game_manager.gd` - Game state and player registry
- `/autoload/network_manager.gd` - Network connections and multiplayer
- `/scenes/main/game.gd` - Main gameplay controller and player spawning
- `/scripts/components/interactable.gd` - Base class for all interactions
- `/scripts/data/constants.gd` - All game constants and balancing values
- `/scripts/data/enums.gd` - All game enumerations

### Player & Character
- `/scenes/player/player.gd` - Player character controller
- `/scripts/systems/inventory_system.gd` - Item management
- `/scripts/systems/crafting_manager.gd` - Weapon assembly
- `/scripts/components/stats_component.gd` - Health/mana/stamina

### Enemies & Combat
- `/scenes/enemies/enemy_base.gd` - Enemy AI and loot drops
- `/scripts/systems/loot_system.gd` - Loot drop handling
- `/scripts/systems/coop_loot_system.gd` - Multiplayer loot sharing
- `/resources/spells/effects/damage_effect.gd` - Damage calculation

### Interactable Objects
- `/scenes/objects/loot_chest.gd` - Chest with random loot spawning
- `/scenes/world/storage_chest.gd` - Persistent player storage (100 slots)
- `/scenes/world/assembly_station.gd` - Weapon crafting workbench
- `/scenes/world/portal.gd` - Fast travel portals
- `/scenes/objects/dungeon_portal.gd` - Dungeon entrance/exit portals

### World & NPCs
- `/scenes/world/starting_town/town_square.gd` - Hub area with NPCs
- `/scenes/world/starting_town/home_tree.gd` - Player home/base
- `/scripts/components/npc.gd` - NPC base class
- `/autoload/fast_travel_manager.gd` - Portal management

### UI & Menus
- `/scenes/ui/menus/inventory_ui.gd` - Inventory menu
- `/scenes/ui/menus/storage_ui.gd` - Storage chest UI
- `/scenes/ui/menus/assembly_ui.gd` - Crafting UI
- `/scenes/ui/menus/fast_travel_menu.gd` - Portal menu
- `/scenes/ui/hud/player_hud.gd` - In-game HUD

---

## Implementation Examples

### Create Custom Interactable
See PROJECT_EXPLORATION.md "Suggestions for New Interactive Elements" → "Implementation Patterns to Follow"

### Add Enemy Loot
1. Set `loot_table` array on enemy with items and weights
2. Implement in enemy_base.gd `_drop_loot()` (already done)
3. Configure drop count by enemy type

### Implement Network Feature
1. Use NetworkManager signals (player_connected, player_disconnected)
2. Add RPC methods with authority checks
3. Register with GameManager player registry
4. Use is_multiplayer_authority() for validation

### Create Crafting Station
1. Extend Node3D or use existing AssemblyStation class
2. Add Interactable component
3. Create custom UI script (reference assembly_ui.gd)
4. Connect to crafting manager
5. Save results via SaveManager

---

## Exploration Summary

### Completed Systems
- Arena gameplay with 6 player capacity
- Town hub with NPCs and portals
- Inventory and equipment system (40 items)
- Crafting/assembly system (weapon parts)
- Loot drops with multiplayer support
- Fast travel portals
- Storage chest (100 items)
- Leveling and stats system
- Combat with elements and critical hits
- Network support (Steam P2P + ENet)
- Friendly fire toggle (optional)

### Partial Systems
- PvP (damage system works, but targeting is PvE-focused)
- Dialogue (system exists, minimal dialogue content)
- NPC interactions (base class ready, few NPCs)
- Dungeon system (portals exist, limited dungeons)

### Missing Systems
- PvP matchmaking/lobbies
- Ranking/rating system
- Team system
- Spectator mode
- Replays/match recording
- Anti-cheat validation
- Client-side prediction
- Advanced quest system
- Guild system
- Trading/marketplace
- Pet/companion system
- Housing system

---

## Statistics

- **Total Scenes**: 30+ (enemies, weapons, UI, world)
- **Total Scripts**: 70+ (systems, components, UI)
- **Interactable Types**: 5 (chest, storage, assembly, portals)
- **NPC Types**: 2 (CrazyJoe, Bob) + generic
- **Enemy Types**: 8+ variants (Skeleton, Goblin, Troll, Wraith, Slime, Golem, etc.)
- **Item Rarities**: 6 (Basic, Uncommon, Rare, Mythic, Primordial, Unique)
- **Element Types**: 6 (Fire, Water, Earth, Air, Light, Dark)
- **Damage Types**: 3 (Physical, Magical, Elemental)
- **Equipment Slots**: 8
- **Max Players**: 6
- **Inventory Size**: 40 items
- **Storage Size**: 100 items
- **Material Types**: 50

---

## Navigation Tips

### For Quick Implementation
1. Check QUICK_REFERENCE.md "Adding New Features"
2. Find similar system in codebase
3. Copy and modify the implementation
4. Reference signal names and method patterns

### For Understanding Architecture
1. Start with `/autoload/` (global systems)
2. Move to `/scripts/systems/` (core mechanics)
3. Study `/scripts/components/` (reusable pieces)
4. Review `/scenes/` structure (how pieces fit together)

### For Debugging Issues
1. Use QUICK_REFERENCE.md "Debugging" section
2. Check print statements in key systems
3. Monitor NetworkManager connection state
4. Verify player registry in GameManager

---

## Document Versions

| File | Version | Lines | Last Updated |
|------|---------|-------|--------------|
| PROJECT_EXPLORATION.md | 1.0 | 701 | Dec 21, 2025 |
| QUICK_REFERENCE.md | 1.0 | 280 | Dec 21, 2025 |
| EXPLORATION_INDEX.md | 1.0 | (this file) | Dec 21, 2025 |

---

## Next Steps for Development

1. **Expand World Content**
   - Add vendor NPCs and shops
   - Create quest board with multiple quests
   - Design additional dungeons and portals

2. **Enhance PvP**
   - Implement dedicated PvP arena
   - Add team/duel systems
   - Create ranking/leaderboard

3. **Content Growth**
   - Add more enemy types and bosses
   - Expand loot tables with unique items
   - Create challenging quest chains
   - Add skill/ability progression

4. **Polish & Performance**
   - Optimize networking for larger player base
   - Add anti-cheat validation
   - Implement client-side prediction
   - Add particle effects and visual feedback

---

**Project**: MageWar (Godot 4.x)
**Exploration Date**: December 21, 2025
**Status**: Core systems documented and analyzed
**Depth Level**: Comprehensive technical analysis

For questions or updates, refer to the inline comments in source code.
