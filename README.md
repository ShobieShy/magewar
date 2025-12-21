# Magewar - A Co-op Looter Fantasy RPG

> A Godot 4.5-based collaborative multiplayer fantasy RPG inspired by Konosuba and Borderlands, featuring modular weapon crafting, rock-paper-scissors elemental combat, and dynamic spell mechanics.

## Overview

Magewar is a co-op looter fantasy RPG built with **Godot 4.5** where Players are summoned as weak misfits to a fractured realm and must grow stronger by defeating monsters, crafting powerful weapons, and uncovering the mystery behind the Dungeon Fracture.

### Key Features

- **Co-op Multiplayer:** Up to 6 players via Steam P2P networking
- **Deep Crafting System:** Customize staffs/wands with rarity-based spell cores + modular parts
- **6-Element Magic System:** Fire, Water, Earth, Air, Light, Dark with rock-paper-scissors balance
- **Loot-Driven:** 6-tier rarity system (Basic → Unique) with randomized stats
- **Procedural Dungeons:** 5 dynamically populated dungeons with with up to 100 floors and varied enemy spawns
- **Specialized Elements:** Light heals allies, Dark corrupts enemies into summons
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

These 18 managers are always available globally. They handle core game state:

#### Core Game Systems
| Manager | Purpose | Key Methods |
|---------|---------|-------------|
| **GameManager** | Scene transitions, game flow | `change_scene()`, `emit_event()` |
| **SaveManager** | Persistence and loading | `save_all()`, `save_player_data()`, `load_player_data()` |
| **QuestManager** | Quest tracking and progression | `accept_quest()`, `progress_objective()`, `complete_quest()` |
| **SkillManager** | Skill learning and progression | `learn_skill()`, `get_skill()`, `get_skill_points()` |
| **ShopManager** | NPC shop management | `buy_item()`, `sell_item()`, `get_shop()` |
| **CutsceneManager** | Dialogue and cutscene playback | `play_dialogue()`, `queue_cutscene()`, `skip_cutscene()` |
| **FastTravelManager** | Portal network and fast travel | `add_location()`, `teleport_to()`, `get_locations()` |

#### Data & Registry Systems
| Manager | Purpose | Key Methods |
|---------|---------|-------------|
| **ItemDatabase** | Item and equipment lookups | `get_item()`, `validate_equipment()`, `register_item()` |
| **GemDatabase** | Gem properties and bonuses | `get_gem()`, `apply_gem_bonus()`, `get_gem_by_element()` |
| **SpellManager** | Spell registry and casting | `register_spell()`, `get_spell()`, `learn_spell()` |
| **CraftingRecipeManager** | Crafting recipes database | `get_recipe()`, `validate_recipe()`, `discover_recipe()` |

#### Networking Systems  
| Manager | Purpose | Key Methods |
|---------|---------|-------------|
| **NetworkManager** | Multiplayer orchestration | `is_multiplayer()`, `get_peer_count()`, `sync_player_data()` |
| **SteamManager** | Steam P2P networking backend | `send_p2p_message()`, `initialize_steam()`, `get_lobby()` |
| **SpellNetworkManager** | Spell casting synchronization | `sync_spell_cast()`, `broadcast_effect()` |
| **SaveNetworkManager** | Save data validation in multiplayer | `validate_save()`, `sync_saves()`, `prevent_corruption()` |

#### Dungeon & Enemy Systems
| Manager | Purpose | Key Methods |
|---------|---------|-------------|
| **DungeonPortalSystem** | Dungeon entry/exit management | `enter_dungeon()`, `exit_dungeon()`, `discover_portal()` |
| **EnemySpawnSystem** | Enemy spawning and patrols | `spawn_enemies()`, `set_spawn_rate()`, `clear_spawned()` |
| **DungeonTemplateSystem** | Dungeon room layout generation | `generate_room()`, `get_template()`, `create_layout()` |

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

Craft custom staffs and wands by combining a **rarity-based spell core** with **modular performance parts**. Located in `scripts/systems/crafting_*.gd` (7 files).

**Core Concept:**
The base staff/wand **is the spell** (Fire/Water/Earth/Air/Light/Dark) with a rarity tier. Parts are **modifiers** that enhance the spell's delivery and power.

**Weapon Composition:**
- **Base Spell Core** (determines element + starting spell, has rarity: Basic → Unique)
  - Fire, Water, Earth, Air, Light, Dark
  - Each rarity grants stat multipliers (1.0x to 2.5x)
  
- **Modifier Parts** (enhance the spell core):
  - **Head** (Staff only) - Holds 1-3 gem slots for secondary effects
  - **Exterior** - Affects fire rate and projectile speed
  - **Interior** - Boosts base damage and mana efficiency
  - **Handle** - Improves accuracy, stability, and handling
  - **Charm** (Optional) - Extra augmentation (e.g., damage type conversion)

**Example Weapon:**
```
Rare Fire Staff = Rare Fire Spell Core + Oak Exterior + Silver Interior + Leather Handle
= 1.5x fire damage, medium fire rate, good accuracy
```

**Key Files:**
- `crafting_manager.gd` - Orchestration and UI integration
- `crafting_logic.gd` - Core recipe validation and crafting
- `crafting_recipe_manager.gd` - Recipe database
- `crafting_achievement_manager.gd` - Milestone tracking
- `weapon_configuration.gd` - Spell core + parts assembly

**Example Usage:**
```gdscript
# In Assembly UI - Select a spell core and add parts
var fire_core = get_rare_fire_core()  # Rarity + element
var exterior = get_oak_exterior()
var interior = get_silver_interior()
var handle = get_leather_handle()

var config = WeaponConfiguration.new()
config.spell_core = fire_core  # Base spell: Fire (1.5x multiplier)
config.add_part(exterior)
config.add_part(interior)
config.add_part(handle)

var crafted_staff = CraftingManager.craft_weapon(config)
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

**6-Element Magic System** with rock-paper-scissors balance and specialized effects.

**Core Elements (6 Total):**

| Element | Strong Against | Weak Against | Special Effect |
|---------|---|---|---|
| **Fire** 🔥 | Air | Water | AOE damage over time |
| **Water** 💧 | Fire | Earth | Slowing/freeze effects |
| **Earth** 🪨 | Water | Air | Knockback and stun |
| **Air** 💨 | Earth | Fire | High critical damage |
| **Light** ✨ | Dark | None | Heals allies + 1 summon |
| **Dark** 🌑 | Light | None | Corrupts enemies → summons |

**Rock-Paper-Scissors Balance:**
```
Fire beats Air
Air beats Earth  
Earth beats Water
Water beats Fire

Light beats Dark
Dark beats Light (neutral, both strong)
```

**Element-Specific Mechanics:**

1. **Light Element**
   - Primary: Healing (direct HP restore)
   - Secondary: Radiant Summon (1 allied creature)
   - Weakness: Absorbed by Dark magic
   
2. **Dark Element**
   - Primary: Damage + enemy corruption
   - Secondary: Summon corrupted enemies as servants
   - Effect: Twisted enemies fight for player, then expire
   - Weakness: Purged by Light magic

3. **Fire/Water/Earth/Air**
   - Bidirectional weakness system enforces balance
   - Spell cores have innate element
   - Gems can modify element or add secondary effects

**Casting System:**
```gdscript
# Spell core determines element automatically
var rare_fire_staff = get_rare_fire_staff()
# Rare Fire Staff casting = 1.5x base damage, Fire element

if can_cast_spell(rare_fire_staff):
    cast_spell(rare_fire_staff, target_position)
    # Automatically scaled by rarity + element strength
    # Network: Synced via SpellNetworkManager
```

**Key Files:**
- `spell_data.gd` - Spell definition (element, cost, cooldown, effects)
- `spell_effect.gd` - Base effect class
- `spell_caster.gd` - Casting mechanics for entities
- `spell_network_manager.gd` - Network spell synchronization

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
Kill Enemy, Kill Specific, Collect Item, Talk to NPC, Discover Area, Defeat Boss, Survive Time, Escort NPC, Interact Object, Custom

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

### 9. Weapon Leveling System (Phase 1)

Weapons gain experience from spellcasting and increase in power through leveling.

**Features:**
- **Weapon Levels:** 1-50, capped at player level
- **XP Scaling:** Exponential XP requirements (50 XP for level 1 → ~5000 XP for level 50)
- **XP Sources:** Spell casting (by default, enemy kills ready for integration)
- **Level Bonuses:** +2% damage per level (cumulative)
- **Key Files:**
  - `scripts/systems/weapon_leveling_system.gd` - Core leveling logic
  - Integration in `spell_caster.gd`, `staff.gd`, `wand.gd`

**Example Usage:**
```gdscript
# Weapon gains XP when spell cast
var staff = player.primary_weapon
staff.grant_xp(10)  # +10 XP toward next level

# Check weapon level
var current_level = staff.get_level()  # 1-50
var damage_bonus = staff.get_level_bonus()  # 1.0x + (level * 0.02)
```

### 10. Refinement System (Phase 1)

Enhance weapons with rare materials for increased power and special properties.

**Features:**
- **Refinement Tiers:** +0 to +10 (each +3% damage multiplier)
- **Success Rates:** 100% at +0-+4, declining to 50% at +10
- **Downgrade Risk:** Failure can downgrade by 1 tier (+5 onwards)
- **Material Requirements:** Scale exponentially (e.g., +3: 10 materials → +10: 1000+ materials)
- **Cost:** Gold per refinement attempt
- **Key Files:**
  - `scripts/systems/refinement_system.gd` - Refinement logic
  - `scripts/systems/material_drop_system.gd` - Material loot generation
  - `scenes/ui/menus/refinement_ui.gd` - UI integration

**Refinement Progression:**
```
+0 (Base)        → 100% success, no cost
+1 to +4 (Safe)  → 100% success, scaling material cost
+5 to +7 (Risk)  → 80-90% success, downgrade risk
+8 to +10 (High) → 50-70% success, severe downgrade penalty
```

**Example Usage:**
```gdscript
# Attempt refinement
var result = RefinementSystem.attempt_refinement(
    weapon,
    refinement_tier + 1,
    materials_available
)

if result.success:
    print("Weapon refined to +", weapon.refinement_tier)
else:
    print("Refinement failed! Lost materials.")
```

### 11. Material System (Phase 1)

48 unique materials for weapon refinement, drop from enemies.

**Material Types:**
- **Ore** (6 rarities) - Primary refinement material
- **Essence** (36 variants by rarity & element) - Element-specific bonuses
- **Shard** (6 rarities) - Secondary component

**Rarity-Based Drops:**
- Basic enemies → Basic/Uncommon materials
- Rare enemies → Rare/Mythic materials  
- Unique enemies → Primordial/Unique materials

**Key Files:**
- `scripts/systems/material_drop_system.gd` - Intelligent loot generation
- `scripts/systems/crafting_material.gd` - Material data class
- `resources/items/materials/` - 48 material resource files

### 12. Save System

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

**Spell Cores (Base Weapons):** Rarity-locked spell cores with 6 element types
  - Fire Core (Basic, Uncommon, Rare, Mythic, Primordial, Unique)
  - Water Core (6 rarity tiers)
  - Earth Core (6 rarity tiers)
  - Air Core (6 rarity tiers)
  - Light Core (6 rarity tiers) - Healing + summon
  - Dark Core (6 rarity tiers) - Corruption + summon
  - Total: 36 spell core variants with stat multipliers

**Modifier Parts:** Performance enhancements (can have own rarities)
  - Exteriors (6 variants): Wood, Oak, Runewood, etc. - Fire rate/speed
  - Interiors (6 variants): Iron/Silver/Mithril Conduits - Damage/efficiency
  - Handles (6 variants): Leather/Silk/Master's grips - Accuracy/stability
  - Heads (Staff only, 6 variants): Crystal/Focus/Core - Gem slots (1-3)
  - Charms (Optional, 6 variants): Ember/Frost/Vampiric - Secondary effects

**Equipment:** 10 armor/accessory templates (Apprentice to Legendary tiers)

**Grimoires:** 3 spell books (Apprentice, Elemental, Forbidden)

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

Global enums for game state, items, elements, and more:

```gdscript
enum GameState { MENU, LOADING, PLAYING, PAUSED, CUTSCENE }
enum NetworkMode { OFFLINE, LOCAL_MULTIPLAYER, STEAM_P2P }
enum ItemRarity { BASIC, UNCOMMON, RARE, MYTHIC, PRIMORDIAL, UNIQUE }

# 6-Element System (Rock-Paper-Scissors)
enum Element { FIRE, WATER, EARTH, AIR, LIGHT, DARK }

# Element Matchups (Auto-calculated from triangle)
# Fire > Air > Earth > Water > Fire (cycle)
# Light vs Dark (balanced opposition)

enum ObjectiveType { KILL_ENEMY, KILL_SPECIFIC, COLLECT_ITEM, TALK_TO_NPC, DISCOVER_AREA, DEFEAT_BOSS, SURVIVE_TIME, ESCORT_NPC, INTERACT_OBJECT, CUSTOM }
enum EquipmentSlot { HEAD, BODY, BELT, FEET, PRIMARY_WEAPON, SECONDARY_WEAPON, GRIMOIRE, POTION }
enum SkillType { PASSIVE, ACTIVE, SPELL_AUGMENT }
enum QuestState { LOCKED, AVAILABLE, ACTIVE, COMPLETED, FAILED }
enum SpellCore { FIRE, WATER, EARTH, AIR, LIGHT, DARK }
enum PartType { EXTERIOR, INTERIOR, HANDLE, HEAD, CHARM }
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

# Rarity Multipliers (applied to spell cores)
const RARITY_STAT_MULTIPLIERS = {
    ItemRarity.BASIC: 1.0,        # Base power
    ItemRarity.UNCOMMON: 1.2,     # +20%
    ItemRarity.RARE: 1.5,         # +50%
    ItemRarity.MYTHIC: 1.8,       # +80%
    ItemRarity.PRIMORDIAL: 2.2,   # +120%
    ItemRarity.UNIQUE: 2.5        # +150%
}

# Element Advantage System (Damage multiplier)
const ELEMENT_ADVANTAGE = 1.25  # 25% bonus when strong against
const ELEMENT_DISADVANTAGE = 0.75  # 25% reduction when weak against

const ITEM_RARITY_WEIGHTS = { ... }  # Probability curve
# ... and 40+ more
```

### Element Matchup Chart
```
ADVANTAGE MATRIX:
Fire   > Air      (25% boost to Fire when fighting Air)
Air    > Earth    (25% boost to Air when fighting Earth)
Earth  > Water    (25% boost to Earth when fighting Water)
Water  > Fire     (25% boost to Water when fighting Fire)

Light vs Dark     (Balanced - no advantage)

SPECIAL EFFECTS:
Light   = Healing + 1 Summon (allied creature)
Dark    = Corruption + Summon (enemies become servants)
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

## Magic System Deep Dive

### The 6-Element System

Magewar features a balanced **rock-paper-scissors magic system** with 6 core elements:

#### The Damage Cycle

```
        FIRE (🔥)
         /    \
        /      \
      AIR      WATER
       \        /
        \      /
        EARTH
```

**Elemental Advantages:**
- **Fire** > Air (Fire burns through air) = 25% damage boost
- **Air** > Earth (Wind erodes stone) = 25% damage boost
- **Earth** > Water (Ground absorbs water) = 25% damage boost
- **Water** > Fire (Water extinguishes flames) = 25% damage boost

**Reverse Logic** - Disadvantages are automatic:
- Air < Water (Water fills air)
- Earth < Air (Wind scatters earth)
- Water < Earth (Earth blocks water)
- Fire < Water (Fire extinguished by water)

#### Special Opposites

**Light vs Dark** (No advantage/disadvantage - perfectly balanced)
- Light does not gain bonus vs Dark
- Dark does not gain bonus vs Light
- **But:** Each has unique mechanics that make them distinct

#### Element-Specific Mechanics

**1. Fire (🔥 - Offense)**
- Standard damage-dealing element
- Advantage over Air
- AOE and damage-over-time effects
- Burns terrain for tactical advantage

**2. Water (💧 - Control)**
- Advantage over Fire
- Slowing and freezing effects
- Movement speed reduction
- Freezes enemies to reduce actions

**3. Earth (🪨 - Defense)**
- Advantage over Water
- Knockback and stun effects
- Shield and armor bonuses
- Can create walls or obstacles

**4. Air (💨 - Speed)**
- Advantage over Earth
- High critical damage
- Movement speed boost
- Projectile velocity increase

**5. Light (✨ - Support)**
- **Primary:** Healing spell (restores ally HP)
- **Secondary:** Summon **Radiant Guardian** (1 allied creature)
- Opposed by Dark (not at disadvantage, but has interaction)
- Cannot damage enemies (only support role)
- Radiant summons last ~30 seconds

**6. Dark (🌑 - Conversion)**
- **Primary:** Corruption curse (converts enemy loyalty)
- **Secondary:** Enemy becomes **Corrupted Servant** (fights for player)
- Opposed by Light (not at disadvantage, but interacts)
- Cannot heal enemies
- Corrupted servants have 50% reduced HP, fight until death or duration expires (~30 seconds)
- Multiple corruptions stack (can control multiple enemies)

### Spell Core System

**What is a Spell Core?**

A Spell Core is the **base weapon** that defines:
1. **Element Type** (determines spell cast)
2. **Rarity Level** (scales damage 1.0x to 2.5x)
3. **Innate Stats** (base damage, mana cost, cooldown)

**Rarity Scaling:**

| Rarity | Damage Multiplier | Mana Cost | Cooldown Reduction |
|--------|---|---|---|
| Basic | 1.0x | 100% | 0% |
| Uncommon | 1.2x | 90% | 5% |
| Rare | 1.5x | 80% | 10% |
| Mythic | 1.8x | 70% | 15% |
| Primordial | 2.2x | 60% | 20% |
| Unique | 2.5x | 50% | 25% |

**Example:**
```
Basic Fire Staff = 1.0x damage, 50 mana, 5s cooldown
Rare Fire Staff  = 1.5x damage, 40 mana, 4.5s cooldown
Unique Fire Staff = 2.5x damage, 25 mana, 3.75s cooldown
```

### Part System (Modifiers)

Parts are **modifiers** that enhance spell core performance:

**Exterior Parts** (Affects Fire Rate & Projectile Speed)
- Low: 0.8x fire rate, 0.9x projectile speed
- Medium: 1.0x fire rate, 1.0x projectile speed
- High: 1.2x fire rate, 1.1x projectile speed

**Interior Parts** (Affects Damage & Mana Efficiency)
- Low: 0.9x damage, +10% mana cost
- Medium: 1.0x damage, 0% mana change
- High: 1.1x damage, -10% mana cost

**Handle Parts** (Affects Accuracy & Stability)
- Poor: 0.8x accuracy, 0.7x stability
- Standard: 1.0x accuracy, 1.0x stability
- Excellent: 1.2x accuracy, 1.2x stability

**Head Parts** (Staff only - Gem Slots)
- Tier 1: 1 gem slot, +5% elemental damage
- Tier 2: 2 gem slots, +10% elemental damage
- Tier 3: 3 gem slots, +15% elemental damage

**Charm Parts** (Optional - Secondary Effect)
- Ember Charm: +20% fire damage
- Frost Charm: +20% water damage
- Chaos Charm: +20% critical damage

### Damage Calculation Example

```gdscript
# Rare Fire Staff + High-tier parts example:

Base Damage = Spell Core (50)
Rarity Multiplier = 1.5x (Rare)
Element Advantage = 1.25x (Fire vs Air target)
Interior Bonus = 1.1x (high interior)
Charm Bonus = 1.2x (fire charm)
Critical Hit = 2.0x (random)

Final Damage = 50 × 1.5 × 1.25 × 1.1 × 1.2 × 2.0 = 495 damage!
```

### Special Summon Systems

#### Light Summons (Radiant Guardian)
- **Triggered by:** Light element spell core cast
- **Count:** Maximum 1 active summon per player
- **Duration:** 30 seconds or until defeated
- **Stats:** 100% of player's level + 50% of player's damage
- **Behavior:** Attacks nearest enemy, follows player
- **Network:** Spawned on all clients when Light spell cast

#### Dark Summons (Corrupted Servants)
- **Triggered by:** Dark element spell core cast on enemy
- **Count:** Unlimited (but each costs mana/cooldown)
- **Duration:** 30 seconds or until defeated
- **Stats:** 50% of target's original stats
- **Behavior:** Attacks former allies, follows player
- **Network:** Enemy AI switches to player control when corrupted
- **Note:** When corrupted servant expires, enemy returns to dust (doesn't respawn)

---

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

### Adding a New Spell Core (Fire/Water/Earth/Air/Light/Dark)

1. **Create spell core resource** in `resources/spells/cores/`
   - Set element (FIRE, WATER, EARTH, AIR, LIGHT, DARK)
   - Set rarity (BASIC, UNCOMMON, RARE, MYTHIC, PRIMORDIAL, UNIQUE)
   - Define base damage, mana cost, cooldown
   - Element determines spell mechanics automatically
   
2. **Register in SpellManager**
   - Add entry in `autoload/spell_manager.gd`
   - Map element to casting behavior and effects
   
3. **Configure Special Effects (if Light/Dark)**
   - **Light cores:** Link to `summon_radiant_effect.gd`
   - **Dark cores:** Link to `enemy_corruption_effect.gd`
   - Set summon type and duration (30s default)
   
4. **Add to loot tables**
   - Update boss/dungeon drops by rarity
   - Add shop inventory entries
   
5. **Test in Assembly UI**
   - Equip as primary weapon
   - Cast and verify element advantage/disadvantage works
   - For Light: verify healing and summon appear
   - For Dark: cast on enemy and verify corruption

### Adding a New Modifier Part

1. **Create part resource** in `resources/items/parts/`
   - Inherit from `StaffPartData`
   - Choose part type (EXTERIOR, INTERIOR, HANDLE, HEAD, CHARM)
   - Set modifier values:
     - Exterior: fire_rate_multiplier, projectile_speed_multiplier
     - Interior: damage_multiplier, mana_cost_modifier
     - Handle: accuracy_multiplier, stability_multiplier
     - Head: gem_slots, elemental_damage_bonus
     - Charm: element_bonus or damage_type_bonus
   
2. **Register in ItemDatabase**
   - Add to part lookup table in `item_database.gd`
   
3. **Add to crafting loot**
   - Update enemy drop tables by part type
   - Add shop entries for vendors
   
4. **Test in Assembly UI**
   - Select spell core, then add this part
   - Verify stats recalculate correctly
   - Check part bonus applies (e.g., +20% damage for high interior)

### Adding a New Item (Equipment/Potion/Misc)

1. **Create a `.tres` resource file** in `resources/items/`
   - Inherit from `ItemData`, `EquipmentData`, or `PotionData`
   - Set name, description, rarity, stats
   
2. **Register in ItemDatabase**
   - Add entry in `autoload/item_database.gd`
   
3. **Add to shop or loot table**
   - Update shop data or enemy loot drops
   
4. **Test in crafting/inventory UI**
   - Verify rendering and stat calculations

### Adding a New Spell Core (Element Variant)

1. **Create spell core resource** in `resources/spells/cores/`
   - Set element (Fire, Water, Earth, Air, Light, Dark)
   - Set rarity and stat multiplier
   - Define base damage, mana cost, cooldown
   
2. **Configure element effects** in `scripts/systems/spell_effects/`
   - Inherit from `SpellEffect`
   - Implement `apply_element_bonus()` for rock-paper-scissors logic
   
3. **Register in SpellManager**
   - Add entry in `autoload/spell_manager.gd`
   - Map element to casting behavior
   
4. **Special Handlers**
   - **Light cores:** Add healing effect + summon logic
   - **Dark cores:** Add enemy corruption + summon conversion
   
5. **Test in Assembly UI**
   - Equip as weapon and cast to verify element behavior

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

### Crafting Workflow: Complete Example

Here's a complete example of crafting a weapon in the Assembly UI:

```gdscript
# Step 1: Player selects a spell core from inventory
var selected_core = player_inventory.get_item("Rare_Fire_Staff")
# Type: SpellCoreData
# Element: FIRE
# Rarity: RARE (1.5x multiplier)
# Base Damage: 50

# Step 2: Player selects modifier parts
var exterior = player_inventory.get_item("High_Quality_Wood")  # 1.2x fire rate
var interior = player_inventory.get_item("Silver_Conduit")     # 1.1x damage
var handle = player_inventory.get_item("Master_Leather_Grip")  # 1.2x accuracy
var head = player_inventory.get_item("Polished_Focus")         # 2 gem slots
var charm = player_inventory.get_item("Ember_Charm")           # +20% fire damage

# Step 3: Build weapon configuration
var config = WeaponConfiguration.new()
config.spell_core = selected_core
config.add_part(exterior)
config.add_part(interior)
config.add_part(handle)
config.add_part(head)
config.add_part(charm)

# Step 4: Validate configuration
var validation_errors = config.validate()
if validation_errors.is_empty():
    # Step 5: Calculate final stats
    var final_stats = config.calculate_stats()
    # Returns: {
    #   damage: 50 × 1.5 (rare) × 1.1 (interior) × 1.2 (charm) = 99
    #   fire_rate: 1.2x (from exterior)
    #   accuracy: 1.2x (from handle)
    #   mana_cost: 50 × 0.9 (mana efficiency from interior) = 45
    #   cooldown: 5s (base from core)
    # }

    # Step 6: Start crafting
    var crafted_weapon = CraftingManager.craft_weapon(config, player_level)
    
    # Step 7: Add to inventory
    if crafted_weapon:
        inventory.add_item(crafted_weapon)
        # Achievement check: Did we discover a new recipe?
        CraftingManager.check_recipe_discovery(config)
else:
    print("Cannot craft: ", validation_errors)  # e.g., "Too many gems", "Missing head"
```

**Result:**
- Player now has **Rare Fire Staff with Silver Interior**
- Deals ~99 damage per hit with Fire advantage vs Air enemies
- Can cast fire spell automatically (element determined by core)
- Parts provide stat bonuses
- If Light core was used: Would heal allies + summon Radiant Guardian
- If Dark core was used: Would corrupt enemies + turn them into servants

### Network Development

For multiplayer features:
1. Use `NetworkManager.is_multiplayer()` to gate code paths
2. Call `SteamManager.send_p2p_message()` for P2P communication
3. Server validates all critical operations (saves, quest progress)
4. Automatic sync: 
   - Spells via `SpellNetworkManager` (including element advantage calculations)
   - Summons via summon effect network handlers
   - Saves via `SaveNetworkManager`
   - Corrupted enemies converted to player control on all clients

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

**Q: Spell cores not showing in Assembly UI**
- A: Verify spell core resource exists in `resources/spells/cores/`
- Check if registered in `SpellManager.get_spell_core()`
- Ensure core has valid element (FIRE, WATER, EARTH, AIR, LIGHT, DARK)
- Verify rarity multiplier is set correctly

**Q: Element advantage not calculating correctly**
- A: Check `Element` enum in `enums.gd` has 6 elements only
- Verify `ELEMENT_ADVANTAGE` constant = 1.25
- Confirm matchup logic in `spell_caster.gd` calculates modifier
- Test with console: `SpellManager.get_element_multiplier(FIRE, AIR)` should return 1.25

**Q: Light/Dark summons not appearing**
- A: Check `summon_effect.gd` is linked to Light/Dark cores
- Verify summon entity prefab exists in `scenes/summons/`
- Confirm summon duration timer is initialized
- Check network sync in `SpellNetworkManager` for co-op

**Q: Crafting system crashes**
- A: Ensure spell core is selected (not empty)
- Check parts are valid types (use `WeaponConfiguration.validate()`)
- Verify gem slots don't exceed head capacity
- Confirm rarity multipliers exist for core in `RARITY_STAT_MULTIPLIERS`

**Q: Saves won't load**
- A: Run `SaveValidator` to check integrity
- Delete corrupted save file, start fresh
- Check file permissions in save directory

**Q: Part modifiers not affecting spell damage**
- A: Verify parts are registered in `weapon_configuration.gd`
- Check stat calculations in `calculate_final_damage()` include part bonuses
- Confirm part multipliers are loaded from resource files
- Test with console: `weapon.get_total_damage()` should include all modifiers

**Q: Weapon leveling not progressing**
- A: Verify `weapon_leveling_system.gd` is loaded
- Check weapon has valid XP property
- Ensure spells are calling `grant_xp()` after casting
- Confirm weapon level cap matches player level
- Test with console: `weapon.get_experience()` should increase after spells

**Q: Refinement system not working**
- A: Verify refinement UI scene is instantiated in crafting menu
- Check materials exist in inventory with correct type/rarity
- Ensure RefinementSystem has valid materials array
- Confirm weapon has refinement_tier property
- Test: Attempt +0 refinement (should always succeed)

**Q: Materials not dropping from enemies**
- A: Verify `material_drop_system.gd` is called in enemy death handler
- Check enemy rarity matches material drop tables
- Confirm materials are registered in ItemDatabase
- Test by killing different enemy rarities
- Check console for material drop debug logs

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
| [PHASE1_COMPLETION.md](PHASE1_COMPLETION.md) | Phase 1 completion summary (weapon leveling & refinement) |
| [PHASE1_IMPLEMENTATION_SUMMARY.md](PHASE1_IMPLEMENTATION_SUMMARY.md) | Phase 1 implementation details |
| [PHASE1_QUICK_REFERENCE.md](PHASE1_QUICK_REFERENCE.md) | Phase 1 quick reference guide |
| [PHASE1_ARCHITECTURE_OVERVIEW.md](PHASE1_ARCHITECTURE_OVERVIEW.md) | Phase 1 architecture documentation |

## Phase 1: Weapon Leveling & Refinement (✅ COMPLETE)

Phase 1 of the crafting system expansion is **production-ready**. New systems include:

### New Features
- **Weapon Leveling System** (1-50 levels with exponential XP scaling)
- **Refinement System** (+0 to +10 tiers with success rates and material costs)
- **Material System** (48 material variants across 3 types and 6 rarities)
- **Material Drop System** (intelligent loot generation by enemy rarity)
- **Refinement UI** (integrated into crafting interface)

### Key Files Added
- `scripts/systems/weapon_leveling_system.gd` - XP tracking and leveling
- `scripts/systems/refinement_system.gd` - Refinement tier progression
- `scripts/systems/material_drop_system.gd` - Material loot generation
- `scripts/systems/crafting_material.gd` - Material data class
- `scenes/ui/menus/refinement_ui.gd` - Refinement UI panel
- `resources/items/materials/` - 48 material resource files

### Key Balancing
- **Weapon Levels:** 1-50, capped at player level
- **Refinement Tiers:** +0 (safe) to +10 (high risk/reward)
- **Success Rates:** 100% at +0, declining to 50% at +10
- **Damage Scaling:** +3% damage per refinement level
- **Material Requirements:** Scale exponentially from +5 onwards

For full details, see [PHASE1_COMPLETION.md](PHASE1_COMPLETION.md).

---

## Statistics

| Metric | Value |
|--------|-------|
| **Total Files** | 350+ |
| **GDScript Files** | 126 |
| **Lines of Code** | ~36,000 |
| **Scenes** | 60 (.tscn files) |
| **Resources** | 132+ (.tres files) |
| **Autoload Managers** | 18 |
| **Game Systems** | 38+ |
| **Components** | 6 |
| **Magic Elements** | 6 (Fire, Water, Earth, Air, Light, Dark) |
| **Spell Cores** | 36 (6 elements × 6 rarities) |
| **Modifier Parts** | 5 types (Exterior, Interior, Handle, Head, Charm) |
| **Part Variants** | 30+ (6 variants per type) |
| **Rarity Tiers** | 6 (Basic → Unique with 1.0x-2.5x multipliers) |
| **Material Types** | 3 (Ore, Essence, Shard) with 6 rarities each |
| **Material Variants** | 48 total |
| **Enemy Types** | 8 base + 15 variants |
| **Skills** | 4+ implemented |
| **UI Screens** | 15+ |
| **Dungeons** | 5 procedural |
| **Documentation** | 3,500+ lines |

## License

[See LICENSE file]

## Community & Support

- **Bug Reports:** GitHub Issues
- **Discussions:** GitHub Discussions
- **Discord:** [Link if available]
- **Email:** [Contact if available]

---

**Status:** ✅ Production Ready (Phase 1 Complete)  
**Phase 1 Completion:** December 20, 2025  
**Last Updated:** December 20, 2025  
**Project Phase:** Weapon Leveling & Refinement (Complete) → Next: Gem Evolution & Fusion

For questions or contributions, please open an issue or pull request on GitHub!
