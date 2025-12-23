# Magewar - A Co-op Looter Fantasy RPG

> A Godot 4.5-based collaborative multiplayer fantasy RPG inspired by Konosuba and Borderlands, featuring modular weapon crafting, rock-paper-scissors elemental combat, and dynamic spell mechanics.

## Overview

Magewar is a co-op looter fantasy RPG built with **Godot 4.5** where players are summoned as weak misfits to a fractured realm and must grow stronger by defeating monsters, crafting powerful weapons, and uncovering the mystery behind the Dungeon Fracture.

### Key Features

- **Co-op Multiplayer:** Up to 6 players via Steam P2P networking
- **Deep Crafting System:** Customize staffs/wands with rarity-based spell cores + modular parts
- **6-Element Magic System:** Fire, Water, Earth, Air, Light, Dark with rock-paper-scissors balance
- **Loot-Driven:** 6-tier rarity system (Basic → Unique) with randomized stats
- **Procedural Dungeons:** 5 dynamically populated dungeons with up to 100 floors and varied enemy spawns
- **Specialized Elements:** Light heals allies, Dark corrupts enemies into summons
- **Quest Framework:** 10+ objective types with branching paths
- **Skill Progression:** Customizable skill trees with 4+ active systems
- **Cross-Platform:** Windows, Linux, macOS via Godot + Steam SDK
- **Network-Optimized:** Dual backend support (Steam P2P + ENet)

## Project Structure

```
magewar/
├── autoload/                    # Global singleton managers (18 systems)
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
├── README.md                    # This file (main entry point)
└── EXTRA.md                     # Complete system reference & documentation
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

## Core Systems Overview

This README provides a quick overview of key systems. For detailed documentation, see **[EXTRA.md](EXTRA.md)**.

### 1. Autoload Managers (Global Singletons)

18 managers handle core game state and are available globally:

| Manager | Purpose |
|---------|---------|
| **GameManager** | Scene transitions, game flow |
| **SaveManager** | Persistence and loading |
| **QuestManager** | Quest tracking and progression |
| **SkillManager** | Skill learning and progression |
| **ItemDatabase** | Item and equipment lookups |
| **SpellManager** | Spell registry and casting |
| **NetworkManager** | Multiplayer orchestration |
| **SteamManager** | Steam P2P networking backend |
| *+ 10 more* | See EXTRA.md § 3.2 for complete list |

**Quick Example:**
```gdscript
# Accept a quest
QuestManager.accept_quest("dungeon_1_clear")

# Check if multiplayer
if NetworkManager.is_multiplayer():
    SteamManager.send_p2p_message(peer_id, data)

# Save game
SaveManager.save_game()
```

### 2. Crafting System

Craft custom staffs and wands by combining a **rarity-based spell core** with **modular performance parts**.

**Core Concept:**
- **Spell Core** (Base): Determines element + rarity (Basic → Unique with 1.0x-2.5x multiplier)
- **Modifier Parts**: Exterior, Interior, Handle, Head, Charm that enhance the spell core
- **Assembly UI**: Visually combine components to create weapons

**Example:**
```gdscript
var fire_core = get_rare_fire_core()  # Rarity + element
var exterior = get_oak_exterior()
var interior = get_silver_interior()
var handle = get_leather_handle()

var config = WeaponConfiguration.new()
config.spell_core = fire_core
config.add_part(exterior)
config.add_part(interior)
config.add_part(handle)

var crafted_staff = CraftingManager.craft_weapon(config)
```

**For complete crafting reference:** See EXTRA.md § 1.4

### 3. 6-Element Magic System

Rock-paper-scissors balanced spell system with 6 core elements:

| Element | Strong Against | Weak Against | Special Effect |
|---------|---|---|---|
| Fire 🔥 | Air | Water | AOE damage over time |
| Water 💧 | Fire | Earth | Slowing/freeze effects |
| Earth 🪨 | Water | Air | Knockback and stun |
| Air 💨 | Earth | Fire | High critical damage |
| Light ✨ | Dark | None | Heals allies + summon |
| Dark 🌑 | Light | None | Corrupts enemies → summons |

**Light & Dark Unique Mechanics:**
- **Light:** Healing spell + summons Radiant Guardian (1 allied creature, 30s duration)
- **Dark:** Corruption curse + converts enemies into Corrupted Servants (50% reduced HP, 30s duration)

**For complete system:** See EXTRA.md § 1.2

### 4. Inventory & Equipment

Manage items with 8 equipment slots and a 40-slot inventory:

**Equipment Slots:**
1. Head (Hat) | 2. Body (Clothes) | 3. Belt | 4. Feet (Shoes) |
5. Primary Weapon (Staff/Wand) | 6. Secondary Weapon (Wand/Staff) |
7. Grimoire (Spell book) | 8. Potion (Quick-use slot)

**Features:**
- 40-slot inventory + 100-slot home storage
- Transaction validation (prevents duplication in multiplayer)
- Real-time stat calculation with equipment bonuses

### 5. Loot System

Enemies drop loot based on **6-tier rarity system**:

| Rarity | Drop Chance | Stat Multiplier |
|--------|-------------|-----------------|
| Basic | 50% | 1.0x |
| Uncommon | 25% | 1.2x |
| Rare | 15% | 1.5x |
| Mythic | 7% | 1.8x |
| Primordial | 2% | 2.2x |
| Unique | <1% | 2.5x |

**For detailed loot mechanics:** See EXTRA.md § 1.1

### 6. Enemy & Dungeon System

**8 Base Enemy Types:**
- Goblins (Scout, Brute, Shaman)
- Skeletons (Archer, Berserker, Commander)
- Trolls (variants by tier)
- Wraiths (variants by tier)
- + Special bosses (Filth Slime, Trash Golem)

**5 Procedural Dungeons:**
- Dynamically generated rooms
- Enemy spawns by rarity level
- Boss encounters at end
- Unique loot tables per dungeon

### 7. Quest Framework

10+ objective types with flexible quest tracking:

**Objective Types:** Kill Enemy, Kill Specific, Collect Item, Talk to NPC, Discover Area, Defeat Boss, Survive Time, Escort NPC, Interact Object, Custom

```gdscript
# Accept and progress a quest
QuestManager.accept_quest("dungeon_1_clear")
QuestManager.progress_objective("dungeon_1_clear", "defeat_boss", 1)

# Listen for quest completion
QuestManager.quest_completed.connect(on_quest_done)
```

### 8. Skill System

Passive and active skills with progression tracking:

**Default Skills:**
- Arcane Burst - Spell augmentation
- Critical Strikes - +20% crit damage
- Regeneration - 5 HP/s passive regen
- Swift Feet - +15% movement speed

**Progression:** Earn 2 skill points per level (max level 50 = 98 total points)

### 9. Weapon Leveling & Refinement (Phase 1 ✅ Complete)

**Weapon Leveling:** 1-50 levels with exponential XP scaling
- Spells grant XP when cast
- +2% damage per level
- Capped at player level

**Refinement System:** +0 to +10 tiers
- Success rates: 100% at +0, declining to 50% at +10
- +3% damage per refinement level
- Material costs scale exponentially
- Risk of downgrade on failure

**48 Materials:** Ore, Essence, Shard (6 rarities each)

**For complete Phase 1 details:** See EXTRA.md § 2.1

### 10. Multiplayer Architecture

Supports up to 6 simultaneous players with network optimization:

**Networking Stack:**
```
Steam P2P (Primary) → ENet (Fallback for local testing)
         ↓
NetworkManager (Abstraction layer)
         ↓
SpellNetworkManager (Spell sync)
SaveNetworkManager (Save sync)
```

**Configuration:**
- Max players: 6
- Network tick rate: 60 Hz
- Fallback transport: ENet (no Steam required for testing)

## Development Workflow

### Adding a New Spell Core

1. Create spell core resource in `resources/spells/cores/`
   - Set element (FIRE, WATER, EARTH, AIR, LIGHT, DARK)
   - Set rarity (BASIC → UNIQUE)
   - Define base damage, mana cost, cooldown

2. Register in SpellManager (`autoload/spell_manager.gd`)

3. Configure special effects (Light = healing + summon, Dark = corruption + summon)

4. Add to loot tables (boss/dungeon drops)

5. Test in Assembly UI (equip and cast to verify)

### Adding a New Item

1. Create `.tres` resource file in `resources/items/`
   - Inherit from ItemData, EquipmentData, or PotionData
   - Set name, description, rarity, stats

2. Register in ItemDatabase

3. Add to shop or loot table

4. Test in crafting/inventory UI

### Adding a New Quest

1. Create quest definition in `resources/quests/definitions/`
   - Set up objectives array
   - Define NPC giver and rewards

2. Create ObjectiveTriggers in world using `quest_trigger.gd` component

3. Register in QuestManager

4. Test progression with console or debug UI

### Adding a New Enemy Type

1. Create enemy data in `resources/enemies/`
   - Set stats, abilities, drop table

2. Create scene variants in `scenes/enemies/`

3. Register in EnemySpawnSystem

4. Test in dungeon

## Testing & Debugging

### Local Testing (No Steam Required)

Game automatically falls back to ENet when Steam is unavailable:

```gdscript
# In SteamManager.gd
if not initialize_steam():
    switch_to_enet_backend()  # Fallback
```

### Test Scenes
- `test/crafting_test.tscn` - Crafting system tests
- `tests/test_*.gd` - Unit tests for various systems

### Debugging
1. Enable Godot debugger (`F6` or `Debug → Debugger`)
2. Add breakpoints in `.gd` scripts
3. Use `print()` or `push_error()` for logs
4. Check `Output → Debug` console for messages

## Build & Deployment

### Exporting for Production

1. **Configure Export Preset**
   - `Project → Export`
   - Add Windows, Linux, macOS presets
   - Set Steam App ID in each preset

2. **Build Steps**
   ```bash
   # Windows
   godot --export "Windows Desktop" builds/magewar.exe

   # Linux
   godot --export "Linux/X.11" builds/magewar

   # macOS
   godot --export "Mac OSX" builds/magewar.zip
   ```

3. **Steam Integration**
   - Ensure Steam App ID is set correctly
   - Test P2P with local multiplayer
   - Verify achievements/leaderboards

4. **Distribution**
   - Upload to Steam or itch.io
   - Include `LICENSE` file
   - Document minimum requirements

## Code Style & Conventions

### GDScript File Structure

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

### Naming Conventions

- `snake_case` for functions and variables
- `PascalCase` for classes and types
- `UPPER_SNAKE_CASE` for constants
- Prefix private methods with `_`
- Use descriptive names (avoid single-letter vars)

### Type Hints

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

## Troubleshooting

### Q: Game won't start in Godot
**A:** 
- Check `project.godot` is in the root directory
- Ensure you're using Godot 4.4 or higher
- Delete `.godot/` folder and re-import

### Q: Steam integration not working
**A:** 
- Verify Steam App ID in `SteamManager.gd`
- Ensure Steam is running locally
- Game falls back to ENet if Steam fails
- Check `addons/godotsteam/` platform-specific binaries

### Q: Multiplayer connection issues
**A:** 
- Confirm `NetworkManager.is_multiplayer()` = true
- Verify peer count with `NetworkManager.get_peer_count()`
- Check network tick rate in `constants.gd`
- Use ENet locally (no Steam required)

### Q: Spell cores not showing in Assembly UI
**A:** 
- Verify spell core resource exists in `resources/spells/cores/`
- Check if registered in `SpellManager.get_spell_core()`
- Ensure core has valid element (FIRE, WATER, EARTH, AIR, LIGHT, DARK)
- Verify rarity multiplier is set correctly

### Q: Element advantage not calculating correctly
**A:** 
- Check `Element` enum in `enums.gd` has 6 elements only
- Verify `ELEMENT_ADVANTAGE` constant = 1.25
- Confirm matchup logic in `spell_caster.gd` calculates modifier
- Test with console: `SpellManager.get_element_multiplier(FIRE, AIR)` should return 1.25

### Q: Crafting system crashes
**A:** 
- Ensure spell core is selected (not empty)
- Check parts are valid types (use `WeaponConfiguration.validate()`)
- Verify gem slots don't exceed head capacity
- Confirm rarity multipliers exist for core in `RARITY_STAT_MULTIPLIERS`

### Q: Saves won't load
**A:** 
- Run `SaveValidator` to check integrity
- Delete corrupted save file, start fresh
- Check file permissions in save directory

## Statistics

| Metric | Value |
|--------|-------|
| **Total Source Files** | 350+ |
| **GDScript Files** | 126 |
| **Lines of Code** | ~36,000 |
| **Scenes** | 60 (.tscn files) |
| **Resources** | 132+ (.tres files) |
| **Autoload Managers** | 18 |
| **Game Systems** | 38+ |
| **Magic Elements** | 6 |
| **Spell Cores** | 36 (6 elements × 6 rarities) |
| **Modifier Parts** | 30+ |
| **Rarity Tiers** | 6 (Basic → Unique) |
| **Materials** | 48 (Ore, Essence, Shard) |
| **Enemy Types** | 8 base + 15 variants |
| **Skills** | 4+ implemented |
| **UI Screens** | 15+ |
| **Dungeons** | 5 procedural |
| **Documentation** | README + EXTRA |

## Quick Links to Detailed Documentation

For comprehensive system documentation, see **[EXTRA.md](EXTRA.md)**:

- **§ 1.1** - [Loot System](EXTRA.md#11-loot-system)
- **§ 1.2** - [Damage System](EXTRA.md#12-damage-system)
- **§ 1.3** - [NPC System](EXTRA.md#13-npc-system)
- **§ 1.4** - [Item & Equipment System](EXTRA.md#14-item--equipment-system)
- **§ 1.5** - [UI Systems](EXTRA.md#15-ui-systems)
- **§ 2.1** - [Phase 1: Weapon Leveling & Refinement](EXTRA.md#21-phase-1-weapon-leveling--refinement)
- **§ 3.1** - [Project Architecture](EXTRA.md#31-project-architecture-overview)
- **§ 3.2** - [Developer Quick Reference](EXTRA.md#32-developer-quick-reference)
- **§ 4.1** - [Implementation Roadmap](EXTRA.md#41-implementation-roadmap)
- **§ 4.2** - [Active Development Work](EXTRA.md#42-active-development-work)

## Contributing

1. **Fork & Branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Follow Code Style**
   - Use GDScript conventions above
   - Keep commit messages clear

3. **Test Thoroughly**
   - Test solo and multiplayer
   - Verify no console errors
   - Check save data integrity

4. **Create Pull Request**
   - Reference issue number
   - Describe changes and motivation
   - Include screenshots for visual changes

## License

See [LICENSE](LICENSE) file for details.

## Community & Support

- **Bug Reports:** GitHub Issues
- **Discussions:** GitHub Discussions
- **Email:** [Contact if available]

---

**Status:** ✅ Production Ready (Phase 1 Complete)  
**Last Updated:** December 23, 2025  
**Phase:** Weapon Leveling & Refinement (Complete) → Next: Gem Evolution & Fusion  
**Documentation:** See [EXTRA.md](EXTRA.md) for complete system reference

For questions or contributions, please open an issue or pull request on GitHub!
