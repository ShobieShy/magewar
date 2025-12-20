# Magewar - A Co-op Looter Fantasy RPG

> A Godot 4.5-based collaborative multiplayer fantasy RPG inspired by Konosuba and Borderlands, featuring deep crafting systems, procedural dungeons, and dynamic spell mechanics.

## Overview

Magewar is a co-op looter fantasy RPG built with **Godot 4.5** that combines the humor and absurdity of Konosuba with the loot-driven gameplay of Borderlands. Players are summoned as weak misfits to a fractured realm and must grow stronger by defeating monsters, crafting powerful weapons, and uncovering the mystery behind the Dungeon Fracture.

### Key Features

- **Co-op Multiplayer:** Up to 6 players via Steam P2P networking
- **Deep Crafting System:** Assemble custom staffs and wands from interchangeable parts
- **Loot-Driven:** 6-tier rarity system (Basic → Unique) with randomized stats
- **Procedural Dungeons:** 5 dynamically populated dungeons with varied enemy spawns
- **13-Element Magic System:** Comprehensive spell framework with 14+ preset spells
- **Quest Framework:** 10+ objective types with branching paths
- **Skill Progression:** Customizable skill trees with 4+ active systems
- **Cross-Platform:** Windows, Linux, macOS via Godot + Steam SDK
- **Network-Optimized:** Dual backend support (Steam P2P + ENet)

## Project Structure

```
magewar/
├── autoload/                    # Global singleton managers (12 systems)
├── scenes/                      # Visual scenes and scene-specific scripts
│   ├── main/                   # Entry points (main.tscn, game.tscn)
│   ├── player/                 # Player character controller
│   ├── enemies/                # 8 base types + 15 variants
│   ├── dungeons/               # 5 procedural dungeons
│   ├── ui/                     # 15+ UI screens and components
│   ├── spells/                 # Projectile, beam, effect systems
│   ├── weapons/                # Staff, wand implementations
│   └── world/                  # World objects, portals, storage
├── scripts/                     # Core game systems
│   ├── systems/                # 35+ game systems (crafting, combat, etc.)
│   ├── components/             # Reusable components (stats, spells, interactables)
│   └── data/                   # Constants and enumerations
├── resources/                   # Game data (non-code assets)
│   ├── items/                  # Equipment, gems, potions, parts
│   ├── spells/                 # Spell definitions and effects
│   ├── skills/                 # Skill definitions
│   ├── quests/                 # Quest and objective data
│   ├── enemies/                # Enemy data templates
│   ├── dungeons/               # Dungeon configurations
│   ├── dialogue/               # Dialogue data
│   └── equipment/              # Equipment definitions
├── addons/                      # Third-party integrations
│   └── godotsteam/             # Steam SDK (multi-platform)
├── project.godot               # Godot engine configuration
└── documentation/              # Developer guides (17+ markdown files)
```

## Getting Started

### Prerequisites

- **Godot 4.4+** (tested with 4.5)
- **Steam Account** (for multiplayer testing)
- **GDScript** knowledge for scripting
- **Git** for version control

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/magewar.git
   cd magewar
   ```

2. **Open in Godot Editor**
   - Launch Godot 4.5
   - Select "Import" and navigate to the `magewar` folder
   - Open `project.godot`
   - Wait for import to complete (~30 seconds)

3. **Configure Steam Integration** (Optional for local testing)
   - Set your Steam App ID in `project.godot` or via `SteamManager.gd`
   - For local testing, the game falls back to ENet
   - Delete `addons/godotsteam` if you don't need Steam (optional)

4. **Run the Game**
   - Press `F5` to run with current scene
   - Or select `Scene → Play` (main scene: `res://scenes/main/main.tscn`)

### Quick Start Guide

**First Time?** Read the [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for a 5-minute overview of key systems.

**Developers?** Start with [PROJECT_ANALYSIS.md](PROJECT_ANALYSIS.md) for a deep dive into architecture.

## Core Systems

### 1. Autoload Managers (Global Singletons)

These 12 managers are always available globally. They handle core game state:

| Manager | Purpose | Key Methods |
|---------|---------|-------------|
| **GameManager** | Scene transitions, game flow | `change_scene()`, `emit_event()` |
| **NetworkManager** | Multiplayer orchestration | `is_multiplayer()`, `get_peer_count()` |
| **SteamManager** | Steam P2P networking | `send_p2p_message()`, `initialize_steam()` |
| **SaveManager** | Persistence and loading | `save_game()`, `load_game()` |
| **QuestManager** | Quest tracking | `accept_quest()`, `progress_objective()`, `complete_quest()` |
| **SkillManager** | Skill progression | `learn_skill()`, `get_skill()` |
| **ItemDatabase** | Item lookups | `get_item()`, `validate_equipment()` |
| **GemDatabase** | Gem properties | `get_gem()`, `apply_gem_bonus()` |
| **ShopManager** | NPC shops | `buy_item()`, `sell_item()` |
| **SpellManager** | Spell registry | `register_spell()`, `get_spell()` |
| **CutsceneManager** | Dialogue and cutscenes | `play_dialogue()`, `queue_cutscene()` |
| **FastTravelManager** | Portal network | `add_location()`, `teleport_to()` |

**Access anywhere in code:**
```gdscript
# Example: Accept a quest
QuestManager.accept_quest("dungeon_1_clear")

# Check if multiplayer
if NetworkManager.is_multiplayer():
    SteamManager.send_p2p_message(peer_id, data)

# Save game
SaveManager.save_game()
```

### 2. Crafting System

Craft custom staffs and wands from modular parts. Located in `scripts/systems/crafting_*.gd` (7 files).

**Weapon Composition:**
- **Staffs:** Head (1-3 gem slots) + Exterior + Interior + Handle + Optional Charm
- **Wands:** Head (1 gem slot) + Exterior + Interior + Optional Handle

**Key Files:**
- `crafting_manager.gd` - Orchestration and UI integration
- `crafting_logic.gd` - Core recipe validation and crafting
- `crafting_recipe_manager.gd` - Recipe database
- `crafting_achievement_manager.gd` - Milestone tracking

**Example Usage:**
```gdscript
# In Assembly UI
var recipe = CraftingManager.create_recipe([head_part, exterior, interior, handle])
if recipe.is_valid():
    var crafted_staff = recipe.craft()
    inventory.add_item(crafted_staff)
```

### 3. Inventory & Equipment

Manage items, equipment slots, and transactions in `scripts/systems/inventory_system.gd`.

**Equipment Slots (8 total):**
1. Head (Hat)
2. Body (Clothes)
3. Belt
4. Feet (Shoes)
5. Primary Weapon (Staff/Wand)
6. Secondary Weapon (Wand/Staff)
7. Grimoire (Spell book)
8. Potion (Quick-use slot)

**Features:**
- 40-slot inventory
- 100-slot home storage
- Transaction validation (prevents duplication in multiplayer)
- Real-time stat calculation

```gdscript
# Equip an item
inventory.equip_item(item, EquipmentSlot.HEAD)

# Get current stats with equipment bonuses
var total_damage = player.get_stat("damage")  # Includes gear
```

### 4. Spell System

13-element magic system with 14+ preset spells and a modular effect framework.

**Core Components:**
- `spell_data.gd` - Spell definition (name, cost, cooldown, effects)
- `spell_effect.gd` - Base effect class
- 6 effect types: Damage, Heal, Movement, Shield, Status, Summon
- 13 elements: Fire, Ice, Lightning, Earth, Wind, Water, Light, Dark, Shadow, Holy, Arcane, Poison, None

**Preset Spells:**
- Arcane Bolt, Arcane Missile
- Fireball, Fireball Enhanced
- Ice Shard, Ice Shard Piercing
- Lightning Strike, Lightning Chain
- Earth Shield, Earth Spike
- Healing Light, Healing Wave
- Shield Barrier, Wind Dash

**Casting a Spell:**
```gdscript
# In SpellCaster component
var spell = SpellManager.get_spell("fireball")
if can_cast_spell(spell):
    cast_spell(spell, target_position)
    # Network: Automatically synced via SpellNetworkManager
```

### 5. Enemy & Loot System

8 base enemy types with 15+ variants. Enemies drop loot based on rarity tiers.

**Base Enemy Types:**
- **Goblins:** Scout (ranged), Brute (melee), Shaman (caster)
- **Skeletons:** Archer, Berserker, Commander
- **Trolls:** Basic, Hill, Cave, Frost, Ancient
- **Wraiths:** Basic, Frost, Ancient
- **Special:** Filth Slime, The Filth (boss), Trash Golem

**Rarity System (6 tiers):**
| Rarity | Drop Chance | Stat Multiplier | Color |
|--------|-------------|-----------------|-------|
| Basic | 50% | 1.0x | White |
| Uncommon | 25% | 1.2x | Green |
| Rare | 15% | 1.5x | Blue |
| Mythic | 7% | 1.8x | Purple |
| Primordial | 2% | 2.2x | Orange |
| Unique | <1% | 2.5x | Gold |

**Key Files:**
- `enemy_spawn_system.gd` - Spawning orchestration
- `enemy_template_system.gd` - Variant generation
- `dungeon_template_system.gd` - Dungeon room composition
- `loot_system.gd` - Loot generation by rarity
- `coop_loot_system.gd` - Multiplayer loot handling

### 6. Quest Framework

10+ objective types with flexible quest tracking.

**Quest States:**
- Locked, Available, Active, Completed, Failed

**Objective Types:**
Kill, Collect, Talk, Explore, Defeat Boss, Survive, Escort, Interact, Custom Event

**Key Files:**
- `quest_manager.gd` - Central quest registry
- `quest_data.gd` - Quest definition structure
- `quest_objective.gd` - Objective definition
- `quest_trigger.gd` - World event triggers

```gdscript
# Accept and progress a quest
QuestManager.accept_quest("dungeon_1_clear")
QuestManager.progress_objective("dungeon_1_clear", "defeat_boss", 1)

# Listen for quest completion
if QuestManager.quest_completed.connect(on_quest_done):
    pass
```

### 7. Skill System

Passive and active skills with progression tracking.

**Skill Types:**
- **Passive:** Permanent stat buffs (e.g., +10% damage)
- **Active:** Usable abilities (e.g., Arcane Burst ability)
- **Spell Augment:** Modifiers for spells

**Default Skills:**
- Arcane Burst - Spell augmentation
- Critical Strikes - +20% crit damage
- Regeneration - 5 HP/s passive regen
- Swift Feet - +15% movement speed

**Progression:**
- Start at level 1 with 0 skill points
- Earn 2 skill points per level (max level 50 = 98 total points)
- Server-validated purchases

### 8. Multiplayer Architecture

Supports up to 6 simultaneous players with network optimization.

**Networking Stack:**
```
Steam P2P (Primary) → ENet (Fallback for local testing)
         ↓
NetworkManager (Abstraction layer)
         ↓
SpellNetworkManager (Spell sync)
SaveNetworkManager (Save sync)
```

**Key Configuration:**
- Max players: 6
- Network tick rate: 60 Hz
- Steam App ID: Configurable in `SteamManager.gd`
- Fallback transport: ENet (no Steam required for testing)

**Key Files:**
- `network_manager.gd` - Network abstraction
- `steam_manager.gd` - Steam P2P implementation
- `spell_network_manager.gd` - Spell state sync
- `save_network_manager.gd` - Save validation and sync

### 9. Save System

Persistent save game with validation.

**Save Data Includes:**
- Player stats, position, level
- Inventory and equipment
- Quest progress
- Unlocked skills
- Discovered fast travel locations
- Play time

**Key Files:**
- `save_manager.gd` - Save/load orchestration
- `save_validator.gd` - Integrity checking
- `save_network_manager.gd` - Multiplayer save syncing

```gdscript
# Save current game state
SaveManager.save_game()

# Load previous save
SaveManager.load_game()

# In multiplayer: Data synced automatically
```

## Game Data (Resources)

### Items
Located in `resources/items/` - All items are `.tres` resource files:

**Equipment:** 10 armor/accessory templates (Apprentice to Legendary tiers)
**Gems:** 5 types (Amethyst, Ruby, Sapphire, Topaz, Emerald)
**Grimoires:** 3 spell books (Apprentice, Elemental, Forbidden)
**Weapon Parts:** 13 interchangeable parts
  - Heads: Cracked Crystal, Polished Focus, Primordial Core
  - Exteriors: Rough Wood, Carved Oak, Runewood
  - Handles: Leather Wrap, Silk Binding, Master's Grip
  - Interiors: Iron/Silver/Mithril Conduits
  - Charms: Ember, Frost, Vampiric
**Potions:** 7 consumables (Health, Mana, Stamina, Elixirs)
**Misc:** Joe's Trash (tutorial quest item)

### Spells
Located in `resources/spells/`:

**Presets:** 14 `.tres` files with ready-to-use configurations
**Effects:** 6 effect types implemented in GDScript
**Gem Data:** `gem_data.gd` - Gem bonus calculations

### Skills
Located in `resources/skills/definitions/`:

- `arcane_burst.tres` - Offensive augmentation
- `critical_strikes.tres` - Crit chance increase
- `regeneration.tres` - Health regen buff
- `swift_feet.tres` - Movement speed buff

### Quests
Located in `resources/quests/`:

**Structure:**
- Quest definitions (name, description, NPC giver)
- Objectives (type, target count, rewards)
- Progression tracking

### Enemies
Located in `resources/enemies/`:

5 enemy data files:
- `goblin_enemy_data.gd`
- `skeleton_enemy_data.gd`
- `slime_enemy_data.gd`
- `troll_enemy_data.gd`
- `wraith_enemy_data.gd`

Each defines stats, abilities, and drop tables.

## Game Constants & Enumerations

### Enumerations (`scripts/data/enums.gd` - 285 lines)

Global enums for game state, items, damage types, elements, and more:

```gdscript
enum GameState { MENU, LOADING, PLAYING, PAUSED, CUTSCENE }
enum NetworkMode { OFFLINE, LOCAL_MULTIPLAYER, STEAM_P2P }
enum ItemRarity { BASIC, UNCOMMON, RARE, MYTHIC, PRIMORDIAL, UNIQUE }
enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING, ARCANE, LIGHT, DARK }
enum Element { FIRE, ICE, LIGHTNING, EARTH, WIND, WATER, LIGHT, DARK, SHADOW, HOLY, ARCANE, POISON, NONE }
enum ObjectiveType { KILL, COLLECT, TALK, EXPLORE, DEFEAT_BOSS, SURVIVE, ESCORT, INTERACT, CUSTOM_EVENT }
enum EquipmentSlot { HEAD, BODY, BELT, FEET, PRIMARY_WEAPON, SECONDARY_WEAPON, GRIMOIRE, POTION }
enum SkillType { PASSIVE, ACTIVE, SPELL_AUGMENT }
enum QuestState { LOCKED, AVAILABLE, ACTIVE, COMPLETED, FAILED }
# ... and 20+ more
```

### Constants (`scripts/data/constants.gd` - 171 lines)

Game tuning constants:

```gdscript
const STEAM_APP_ID = 123456  # Your Steam App ID
const MAX_PLAYERS = 6
const NETWORK_TICK_RATE = 60
const PLAYER_MAX_HEALTH = 100
const PLAYER_MAX_MANA = 50
const PLAYER_MAX_STAMINA = 100
const PLAYER_BASE_SPEED = 5.0
const INVENTORY_SIZE = 40
const STORAGE_SIZE = 100
const POTION_QUICK_USE_KEY = KEY_Q
const ITEM_RARITY_WEIGHTS = { ... }  # Probability curve
# ... and 40+ more
```

## World Organization

### Starting Town (Tutorial Area)
- **Home Tree:** Player base, storage, Bob's lab
- **Town Square:** Quest hub, NPCs, shops
- **Mage Association:** Story exposition, Crazy Joe's expulsion point
- **Landfill:** Tutorial dungeon, Filth Slime boss, loot tutorial

### Procedural Dungeons (5 Total)
Each dungeon has:
- Multiple room templates
- Randomized enemy spawns
- Boss encounters at the end
- Unique loot tables

**Dungeon Scenes:**
- `scenes/dungeons/dungeon_1.tscn` through `dungeon_5.tscn`

### Locations Network
Fast travel system connects all major hubs via `FastTravelManager`.

## Story & Lore

### The Cataclysm (10 Years Before Game Start)
The Dungeon Fracture shattered barriers between the underground and surface world, releasing monsters everywhere. Kingdoms banded together to erect protective barriers around major cities.

### Current Setting
The Summoned are weak individuals pulled from another world by Crazy Joe, an unhinged 300-year-old mage. Given a home in an old tree, they must grow stronger to investigate the truth behind the Fracture.

### Key NPCs
- **Crazy Joe** - Mad mage, expulsion catalyst
- **Bob** - Recluse arcanist, true tree owner, mysterious mentor
- **The Summoned** - Player characters, initially pitied, destined for greatness

**Full story in:** [Magewar Storyline.md](Magewar%20Storyline.md)

## Development Workflow

### Adding a New Item

1. **Create a `.tres` resource file** in `resources/items/`
   - Inherit from `ItemData` or `EquipmentData`
   - Set name, description, rarity, stats
   
2. **Register in ItemDatabase**
   - Add entry in `autoload/item_database.gd`
   
3. **Add to shop or loot table**
   - Update shop data or enemy loot drops
   
4. **Test in crafting/inventory UI**
   - Verify rendering and stat calculations

### Adding a New Spell

1. **Create spell definition** in `resources/spells/presets/`
   - Name, manacost, cooldown, effects array
   
2. **Define effects** in `scripts/systems/spell_effects/`
   - Inherit from `SpellEffect`
   - Implement `apply()` method
   
3. **Register in SpellManager**
   - Add entry in `autoload/spell_manager.gd`
   
4. **Test casting**
   - Add to a Grimoire
   - Equip and cast in game

### Adding a New Quest

1. **Create quest definition** in `resources/quests/definitions/`
   - Set up objectives array
   - Define NPC giver and rewards
   
2. **Create ObjectiveTriggers** in world
   - Use `quest_trigger.gd` component
   - Connect to world events
   
3. **Register in QuestManager**
   - Add entry to quest registry
   
4. **Test progression**
   - Use console or debug UI to progress quest

### Adding a New Enemy Type

1. **Create enemy data** in `resources/enemies/`
   - Inherit from base enemy data class
   - Set stats, abilities, drop table
   
2. **Create scene variants** in `scenes/enemies/`
   - Use enemy base scene as template
   - Assign data resource
   
3. **Register in EnemySpawnSystem**
   - Add to spawn pool for dungeons
   
4. **Test in dungeon**
   - Verify spawn rates and loot drops

### Network Development

For multiplayer features:
1. Use `NetworkManager.is_multiplayer()` to gate code paths
2. Call `SteamManager.send_p2p_message()` for P2P communication
3. Server validates all critical operations (saves, quest progress)
4. Automatic sync: Spells via `SpellNetworkManager`, Saves via `SaveNetworkManager`

## Testing

### Local Testing (No Steam)
Game automatically falls back to ENet when Steam is unavailable:
```gdscript
# In SteamManager.gd
if not initialize_steam():
    switch_to_enet_backend()  # Fallback
```

### Test Scenes
- `test/crafting_test.tscn` - Crafting system tests
- Console commands for quick progression:
  ```gdscript
  # Debug console input
  QuestManager.complete_quest("tutorial_landfill")
  SkillManager.learn_skill("critical_strikes")
  ItemDatabase.get_item("fireball_spell")
  ```

### Debugging
1. Enable Godot debugger (`F6` or `Debug → Debugger`)
2. Add breakpoints in `.gd` scripts
3. Use `print()` or `push_error()` for logs
4. Check `Output → Debug` console for messages

## Performance Optimization

### Implemented Optimizations

1. **Object Pooling:** Projectiles reused instead of instantiated
   - File: `scripts/systems/projectile_pool.gd`

2. **Network Optimization:**
   - Tick rate: 60 Hz (not per-frame)
   - Only sync relevant state changes
   - Compression for large messages

3. **Rendering:**
   - Forward Plus renderer (modern, efficient)
   - MSAA 2x anti-aliasing
   - Physics-optimized collision layers

4. **Inventory Transactions:**
   - Validates before executing
   - Prevents server-side desync

### Profiling
- Use Godot Profiler (`Debug → Profiler`)
- Monitor: FPS, draw calls, memory usage
- Target: 60 FPS on target hardware

## Build & Deployment

### Exporting for Production

1. **Configure Export Preset**
   - `Project → Export`
   - Add Windows, Linux, macOS presets
   - Set Steam App ID in each preset

2. **Build Steps**
   ```
   # Windows
   godot --export "Windows Desktop" builds/magewar.exe
   
   # Linux
   godot --export "Linux/X.11" builds/magewar
   
   # macOS
   godot --export "Mac OSX" builds/magewar.zip
   ```

3. **Steam Integration**
   - Ensure Steam App ID is set correctly
   - Test P2P with `steam_network_test.gd`
   - Verify achievements/leaderboards (if implemented)

4. **Distribution**
   - Upload to Steam or itch.io
   - Include `CHANGELOG.md` and `LICENSE`
   - Set minimum requirements (Godot runtime)

## Code Style & Conventions

### GDScript Style Guide

**File Structure:**
```gdscript
# 1. Class comment
## Brief description of class
## Extended documentation with parameters and usage

# 2. Extends
extends Node3D

# 3. Inner classes (if any)
class InnerHelper:
    pass

# 4. Signals
signal status_changed(new_status: String)

# 5. Enums and constants
enum State { IDLE, MOVING, ATTACKING }
const SPEED = 5.0

# 6. Variables (public, then private)
var health: float = 100.0
var _target: Node3D

# 7. Lifecycle methods (_ready, _process, _physics_process)
func _ready() -> void:
    pass

# 8. Signal handlers (on_*)
func on_enemy_died(enemy: Enemy) -> void:
    pass

# 9. Public methods
func take_damage(amount: float) -> void:
    pass

# 10. Private methods (_*)
func _calculate_total_damage() -> float:
    return 0.0
```

**Naming:**
- `snake_case` for functions and variables
- `PascalCase` for classes and types
- `UPPER_SNAKE_CASE` for constants
- Prefix private methods with `_`
- Use descriptive names (avoid single-letter vars)

**Type Hints:**
```gdscript
# ✅ Good
func take_damage(amount: float) -> void:
    health -= amount

func get_equipped_items() -> Array[ItemData]:
    return equipped_items

# ❌ Bad
func take_damage(amount):
    health -= amount
```

## Contributing

1. **Fork & Branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Follow Code Style**
   - Use GDScript conventions above
   - Run formatter if available
   - Keep commit messages clear

3. **Test Thoroughly**
   - Test solo and multiplayer
   - Verify no console errors
   - Check save data integrity

4. **Create Pull Request**
   - Reference issue number
   - Describe changes and motivation
   - Include screenshots for visual changes

5. **Code Review**
   - Address feedback
   - Keep commits organized
   - Squash if requested

## Troubleshooting

### Common Issues

**Q: Game won't start in Godot**
- A: Check `project.godot` is in the root directory
- Ensure you're using Godot 4.4 or higher
- Delete `.godot/` folder and re-import

**Q: Steam integration not working**
- A: Verify Steam App ID in `SteamManager.gd`
- Ensure Steam is running locally
- Game falls back to ENet if Steam fails
- Check `addons/godotsteam/` platform-specific binaries

**Q: Multiplayer connection issues**
- A: Confirm `NetworkManager.is_multiplayer()` = true
- Verify peer count with `NetworkManager.get_peer_count()`
- Check network tick rate in `constants.gd`
- Use ENet locally (no Steam required)

**Q: Crafting system crashes**
- A: Ensure parts are valid types (use `ItemDatabase.validate_equipment()`)
- Check recipe definition in `crafting_recipe_manager.gd`
- Verify gem slots match head part

**Q: Saves won't load**
- A: Run `SaveValidator` to check integrity
- Delete corrupted save file, start fresh
- Check file permissions in save directory

**Q: Enemy spawns are too high/low**
- A: Adjust `ITEM_RARITY_WEIGHTS` in `constants.gd`
- Tune `EnemySpawnSystem` spawn rates
- Check dungeon template composition

## Documentation Index

| Document | Purpose |
|----------|---------|
| [Magewar Bible.md](Magewar%20Bible.md) | Game vision, mechanics, systems overview |
| [Magewar Storyline.md](Magewar%20Storyline.md) | Narrative, world lore, character backgrounds |
| [PROJECT_ANALYSIS.md](PROJECT_ANALYSIS.md) | **MAIN DOC** - 11 sections, architecture deep-dive |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | 5-minute developer quickstart |
| [CRAFTING_SYSTEM_README.md](CRAFTING_SYSTEM_README.md) | Crafting system API reference |
| [ASSEMBLY_UI_IMPLEMENTATION.md](ASSEMBLY_UI_IMPLEMENTATION.md) | Crafting UI system details |
| [EQUIPMENT_IMPLEMENTATION.md](EQUIPMENT_IMPLEMENTATION.md) | Equipment system specifics |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | Feature status tracking |
| [DIAGNOSTIC_REPORT.md](DIAGNOSTIC_REPORT.md) | Pre-fix code issues (resolved) |
| [FIXES_APPLIED.md](FIXES_APPLIED.md) | Post-fix verification |
| [NEXT_PHASE_PLAN.md](NEXT_PHASE_PLAN.md) | Roadmap for future development |

## Statistics

| Metric | Value |
|--------|-------|
| **Total Files** | 300+ |
| **GDScript Files** | 121 |
| **Lines of Code** | ~33,000 |
| **Scenes** | 58 (.tscn files) |
| **Resources** | 84 (.tres files) |
| **Autoload Managers** | 12 |
| **Game Systems** | 35+ |
| **Components** | 6 |
| **Enemy Types** | 8 base + 15 variants |
| **Spells** | 14+ presets |
| **Skills** | 4+ implemented |
| **UI Screens** | 15+ |
| **Dungeons** | 5 procedural |
| **Documentation** | 2,500+ lines |

## License

[See LICENSE file]

## Community & Support

- **Bug Reports:** GitHub Issues
- **Discussions:** GitHub Discussions
- **Discord:** [Link if available]
- **Email:** [Contact if available]

---

**Status:** ✅ Production Ready  
**Last Updated:** December 19, 2025  
**Maintainer(s):** [Project maintainers]

For questions or contributions, please open an issue or pull request on GitHub!
