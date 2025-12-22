# MageWar Project Exploration Summary

## 1. MAIN PLAYABLE MAP/SCENE STRUCTURE

### Primary Game Scene: `scenes/main/game.tscn`
- **Type**: Node3D root with scripting via `game.gd`
- **Purpose**: Main gameplay hub and player arena
- **Components**:
  - TestArena: 50x50 CSG floor with walls and obstacles
  - SpawnPoints: 6 configurable spawn points for players
  - Players node: Container for instantiated player characters
  - Enemies node: Pre-placed test enemies (Skeleton, Goblin, Troll, Wraith, FilthSlime)
  - Objects node: Interactable loot chest
  - HUD/CanvasLayer: Player heads-up display

### World Hub Structure: `scenes/world/starting_town/`
The game features a multi-scene world structure:

1. **TownSquare** (town_square.tscn)
   - Central hub area
   - NPC spawning (CrazyJoe, Bob)
   - Portal to Landfill
   - Entrances to Mage Association and Home Tree (interior locations)
   - Handles fast travel registration

2. **HomeTree** (home_tree.tscn) - Player Home/Base
   - StorageChest: Persistent inventory storage (100 slots)
   - AssemblyStation: Weapon crafting workbench
   - Bed: Rest point for save/health restore
   - Exit area to return to TownSquare

3. **MageAssociation** (mage_association.tscn)
   - Interior building, details not fully explored
   - Shop/NPC interaction location

### Entry Point Flow
- `main.tscn` → loads main menu
- Main menu → GameManager loads game.tscn OR world scenes
- Supports both arena gameplay and world exploration modes

---

## 2. EXISTING INTERACTABLE OBJECTS & SYSTEMS

### Interactable Base Class (`scripts/components/interactable.gd`)
- **Extends**: Area3D
- **Features**:
  - Proximity detection (configurable range, default 2.5 units)
  - Interaction prompt display "[E] Interact"
  - Player tracking (players_in_range array)
  - One-time-only option
  - Closest player targeting
  - Signals: interaction_started, interaction_ended, player_entered_range, player_exited_range

### Specific Interactable Objects

#### 1. **LootChest** (`scenes/objects/loot_chest.gd`)
- Extends Node3D with Interactable component
- **Functionality**:
  - Spawns 1-10 randomized loot parts when interacted
  - Uses RandomPartGenerator for item creation
  - Spawns items with physics (velocity/bounce effect)
  - Visual feedback: changes color when looted (grayed out)
  - Updates interaction prompt to "Empty Chest" after looting
  - Integration with LootSystem for world drop management

#### 2. **StorageChest** (`scenes/world/storage_chest.gd`)
- Extends Interactable
- **Functionality**:
  - Persistent cross-session storage (100 item capacity)
  - Opens StorageUI for inventory management
  - Auto-save integration after deposits/withdrawals
  - Signals: storage_opened, storage_closed, item_deposited, item_withdrawn
  - Located in HomeTree

#### 3. **AssemblyStation** (`scenes/world/assembly_station.gd`)
- Extends Interactable
- **Functionality**:
  - Weapon/staff assembly for crafting
  - Opens AssemblyUI for part selection and combination
  - Signals: station_opened, station_closed, item_crafted
  - Located in HomeTree

#### 4. **Portal (Fast Travel)** (`scenes/world/portal.gd`)
- Extends Interactable
- **Functionality**:
  - Fast travel between discovered locations
  - State: active/inactive with visual feedback
  - Auto-registers with FastTravelManager
  - Requires boss defeat option for gating
  - Visual effects: color change, particle emission, light glow
  - Pulse animation on activation
  - Signals: portal_activated, portal_deactivated, travel_initiated
  - Located in town_square and acts as hub

#### 5. **DungeonPortal** (`scenes/objects/dungeon_portal.gd`)
- Extends Area3D (collision-based)
- **Functionality**:
  - Dungeon entrance/exit portals
  - Types: ENTRANCE, EXIT, TELEPORT
  - Requirement checking: level, quest, item requirements
  - Item consumption option
  - Discovery tracking
  - Auto-enter vs. interaction-required
  - Visual: rotating torus mesh, emissive material, particle ring
  - Signals: player_entered, player_exited, activated, deactivated
  - 3D label interaction prompt

### Interaction System Summary
- **Total Interactable Types**: 5 main systems
- **Proximity-based Detection**: All use Area3D collision
- **UI Integration**: StorageChest and AssemblyStation open dedicated menus
- **Extensibility**: Base Interactable class allows easy new object creation
- **Networking**: Portal system uses RPC for multiplayer synchronization

---

## 3. PLAYER MECHANICS IMPLEMENTED

### A. INVENTORY & EQUIPMENT SYSTEM

#### InventorySystem (`scripts/systems/inventory_system.gd`)
- **Capacity**: 40 items per inventory
- **Features**:
  - Stackable item support with max_stack limits
  - Equipment slots (helmet, chest, legs, hands, feet, etc.)
  - Material storage (crafting materials, separate 50-type capacity)
  - Transaction counter for preventing duplication in drag-drop
  - Signals: inventory_changed, item_added, item_removed, item_used, equipment_changed
  
**Equipment Slots**:
- Head, Chest, Legs, Hands, Feet
- Main Hand Weapon, Off-hand
- Accessories

#### Item Rarity System
Six rarity tiers with stat multipliers:
- BASIC (1.0x) - White
- UNCOMMON (1.15x) - Green
- RARE (1.35x) - Blue
- MYTHIC (1.6x) - Purple
- PRIMORDIAL (2.0x) - Orange
- UNIQUE (2.5x) - Gold (quest/special items only)

### B. CRAFTING SYSTEM

#### Components:
1. **CraftingManager** - Main orchestrator
2. **CraftingLogic** - Recipe validation and result generation
3. **CraftingRecipeManager** - Recipe storage and lookup
4. **RandomPartGenerator** - Generates random weapon parts
5. **AffinitySystem** - Manages affix application to items
6. **WeaponLevelingSystem** - Weapon progression/refinement

#### Crafting Features:
- **Weapon Assembly**: Combine staff/wand heads, shafts, grips to create weapons
- **Material Crafting**: Transform materials into new items
- **Gem Insertion**: Socket gems into weapon slots for stat bonuses
- **Refinement**: Level up weapons to increase stats
- **Achievement Tracking**: CraftingAchievementManager monitors crafting progress

#### Recipe System:
- Recipes store required parts/materials
- Success chance with potential critical crafts
- Result scaling based on player level
- Material requirements tracked and consumed

### C. COMBAT MECHANICS

#### Player Combat (`scenes/player/player.gd`)
- **Weapons**: Staff (primary), Wand (secondary)
- **Casting System**: SpellCaster component
- **Damage Types**: PHYSICAL, MAGICAL, ELEMENTAL, FIRE, WATER, EARTH, AIR, LIGHT, DARK
- **Spell Effects**: Damage, healing, crowd control
- **Global Cooldown**: 0.25 seconds between casts
- **Critical Hits**: 5% base chance, 1.5x damage multiplier

#### Weapon Systems
1. **Staff** (scenes/weapons/staff.gd)
   - Primary weapon, standard attack
   - Gem slots: 1-3 depending on quality
   
2. **Wand** (scenes/weapons/wand.gd)
   - Offhand weapon
   - Gem slot: 1
   - Secondary casting options

3. **Gem System** (GemDatabase)
   - 5 gem types with different stat bonuses
   - Insertion into weapon slots
   - Stat scaling based on rarity

#### Element Advantage System
- Rock-paper-scissors balance: Fire > Air > Earth > Water > Fire
- Light vs Dark (balanced, no advantage)
- 25% damage bonus when strong against
- 25% reduction when weak against
- Applied in DamageEffect calculations

#### Combat Constants (from Constants.gd)
- Cast time: Instant (0.0s base)
- Projectile speed: 30 units/sec
- Hitscan range: 100 units
- Friendly fire: 50% damage reduction when enabled (optional)
- Charged attack: 200% damage, 250% cost, 150% cooldown

### D. MOVEMENT & LOCOMOTION

#### Player Movement (`scenes/player/player.gd`)
- **Walk Speed**: 5 units/sec
- **Sprint Speed**: 8 units/sec (costs 10 stamina/sec)
- **Crouch Speed**: 2.5 units/sec
- **Jump Velocity**: 6 units/sec (costs 15 stamina per jump)
- **Acceleration**: 10.0
- **Air Control**: 0.3

#### Stamina System
- Default: 100 points
- Regen: 15 points/sec
- Regen delay after use: 1 second
- Sprint cost: 10/sec, Jump cost: 15/jump

#### Camera Controls
- Mouse sensitivity: 0.002 (adjustable)
- Controller sensitivity: 3.0
- Look up max: 89°
- Look down min: -89°
- First-person view with pivot system

### E. STATS & CHARACTER PROGRESSION

#### StatsComponent (implied system)
- **Primary Stats**:
  - Health (default: 100, affected by equipment)
  - Magika (default: 100, for spell casting)
  - Stamina (default: 100, for movement/sprint/jump)
  - Damage bonus
  - Critical chance
  - Defense/resistances

- **Regeneration**:
  - Health: 1 point/sec
  - Magika: 5 points/sec
  - Stamina: 15 points/sec (with 1sec delay)

#### Leveling System
- **Max Level**: 50
- **Skill Points Per Level**: 2
- **Active Ability Cooldown**: 30 seconds (base)
- **Skill Tree**: Skill nodes with progression unlocks

#### Experience/Gold
- Earned from defeating enemies
- Multipliers: Elite (1.5x), MiniBoss (2.5x), Boss (5x), DemonLord (10x)
- Auto-saved by SaveManager

---

## 4. NPCs & INTERACTIVE ELEMENTS

### NPC System

#### NPC Base (`scripts/components/npc.gd`)
- Extends CharacterBody3D
- Properties: npc_id, npc_name, dialogue_id
- Collision: CapsuleShape3D
- Visual: CapsuleMesh placeholder

#### Existing NPCs
1. **CrazyJoe** - Town Square NPC
   - Dialogue ID: "crazy_joe_intro"
   - Located at CrazyJoeSpawn in TownSquare
   
2. **Bob** - Mystery NPC
   - Name: "???" (hidden identity)
   - Dialogue ID: "bob_intro"
   - Located at BobSpawn in TownSquare

#### Dialogue System
- **DialogueBox** (scenes/ui/dialogue_box.gd)
- **DialogueData** (resources/dialogue/dialogue_data.gd)
- Supports quest-related dialogue branches
- Text boxes with NPC interaction

#### Interactive Building Entrances
- **MageAssociationEntrance** - Area3D transition trigger
- **HomeTreeEntrance** - Area3D transition trigger
- Automatic scene transitions on player contact (local player only)

### NPC Spawning System
- Dynamic NPC creation via TownSquare script
- Generic NPC fallback if scene not found
- Capsule mesh for visual representation
- Name plate component for identification

---

## 5. ENEMY LOOT DROP SYSTEM

### Enemy Base Class (`scenes/enemies/enemy_base.gd`)

#### Loot Mechanics
1. **Loot Table System**:
   - Array of items with weights
   - Format: `{item: ItemData, weight: float, min: int, max: int}`
   - Weighted random selection
   
2. **Loot Drop Counts** (by enemy type):
   - BASIC: 1 item
   - ELITE: 2 items
   - MINIBOSS: 3 items
   - BOSS: 5 items
   - DEMON_LORD: 8 items

3. **Gold Drop System**:
   - Base formula: `gold = base_gold * level`
   - Base gold: 5 (configurable per enemy)
   - Multipliers:
     - Elite: 3x
     - MiniBoss: 6x (3x * 2)
     - Boss: 10x
     - DemonLord: 20x (10x * 2)
   - Variance: ±20% random

4. **Experience Awards**:
   - Base formula: `xp = experience_value * level`
   - Bonuses by enemy type:
     - Elite: 1.5x
     - MiniBoss: 2.5x
     - Boss: 5.0x
     - DemonLord: 10.0x

#### Loot System (`scripts/systems/loot_system.gd`)
- **Pickup Scene**: loot_pickup.tscn (world visible pickups)
- **Physics**: Items spawn with velocity for bounce effect
- **Co-op Integration**: CoopLootSystem for shared drops
- **Auto-Despawn**: 5 minute timeout per item
- **Signals**: loot_dropped, loot_picked_up

#### Loot Distribution (Co-op)
- **Strategies**: 
  - FREE_FOR_ALL: Anyone picks up
  - ROUND_ROBIN: Take turns
  - MASTER_LOOTER: One player decides
  - GREED_BASED: Need rolls
  - CLASS_BASED: By class
  - VOTE: Party votes
  
- **Shared Containers**: Visual loot boxes players interact with
- **Pickup Queues**: Per-player assignment tracking
- **RPC Integration**: Synchronized across network

#### Material Drop System
- Enemies drop crafting materials (separate from item loot)
- Drop chances by enemy rarity
- Material types and quantities configured
- Used for weapon crafting

#### Quest Integration
- Enemy kills reported to QuestManager via `report_kill(enemy_type, enemy_id)`
- Tracked for quest completion
- Enemy IDs enable specific kill tracking

---

## 6. NETWORKING & PvP SYSTEMS

### NetworkManager (`autoload/network_manager.gd`)

#### Network Modes
1. **STEAM P2P** (primary):
   - Steam App ID: 480 (Spacewar test app)
   - Peer-to-peer direct connections
   - Lobby system integration
   - Session request handling
   
2. **ENet** (fallback):
   - Godot's native networking
   - TCP/UDP alternative
   - Default port: 7777
   
3. **OFFLINE** (single-player):
   - No networking

#### Connection Management
- Host/client model
- Peer ID assignment (auto-generated for clients)
- Player connection/disconnection signals
- Server authority checks
- Maximum 6 players (Constants.MAX_PLAYERS)

#### Player Synchronization
- Player spawning on host (`game.gd` - _spawn_local_player, _spawn_remote_player)
- Position/rotation synchronization
- AI state synchronization
- Health/damage synchronization

#### RPC System Usage
- `_rpc_respawn_player()`: Server respawn authority
- `_rpc_request_respawn()`: Client requests respawn
- Reliable delivery for critical events
- Authority-based RPC calls (host only)

#### Signals/Events
- connection_state_changed
- player_connected
- player_disconnected
- server_started
- server_stopped
- game_start_requested

### GameManager (`autoload/game_manager.gd`)

#### Player Registry
- `players: Dictionary` - peer_id -> PlayerInfo mapping
- `is_host: bool` - authority flag
- `local_player_id: int` - client's own peer ID

#### Friendly Fire System
- **Feature**: Optional friendly fire toggle (disabled by default)
- **Damage Reduction**: 50% multiplier when enabled
- **Settings**: Stored in SaveManager.settings_data
- **Implementation**: DamageEffect checks `friendly_fire` flag
- **Target Detection**: Target script type checked (Player vs Enemy)

#### Game State Management
- States: NONE, MAIN_MENU, LOADING, PLAYING, PAUSED, LOBBY, DUNGEON
- State transitions with signal emission
- Pause system with multiplayer awareness

### CURRENT PvP LIMITATIONS & OBSERVATIONS

1. **No Direct PvP Targeting System**:
   - DamageEffect's `target_type = Enums.TargetType.ENEMY` (hardcoded)
   - Damage system doesn't distinguish between enemy and player by default
   - Friendly fire is optional but not enforced in targeting

2. **Friendly Fire Implementation**:
   - Only 50% damage reduction (line 92 in damage_effect.gd)
   - Script type checked: `target.get_script().get_global_name() == "Player"`
   - Requires explicit flag in settings to enable
   - Not a full PvP system, more of a "can damage" option

3. **Authority & Anti-Cheat**:
   - Host has server authority for critical functions
   - Respawn only allowed by host
   - RPC calls require authority matching
   - No client-side damage validation (trusted client)

4. **Network Flow**:
   - All players spawned by Game.gd through NetworkManager signals
   - Position updates likely through CharacterBody3D physics sync
   - No explicit damage packet/RPC shown (likely client-predicted with server validation)

5. **Player Damage System**:
   - Player.gd contains take_damage method (line 514)
   - StatsComponent handles actual health reduction
   - No special PvP damage falloff or range checks visible
   - Projectiles can hit both enemies and players (if targeting allows)

### Network Architecture Summary

```
NetworkManager (connection handling)
    ↓
GameManager (player registry + state)
    ↓
Game.tscn (player spawning)
    ↓
Player instances (with multiplayer authority)
    ↓
SpellCaster/Projectiles (damage application)
    ↓
StatsComponent (health reduction)
```

### Network Limitations
- **No explicit PvP matchmaking**: Could add dedicated PvP lobbies
- **No ranking/rating system**: Could track player stats
- **No team system**: Could add team-based mechanics
- **No spectator mode**: Could add observer functionality
- **No replays**: Could log match data
- **Client prediction**: Not explicitly implemented (could cause desyncs)

---

## SUMMARY OF EXISTING INTERACTIVE SYSTEMS

### Interactable Count by Location
- **Game Arena**: 1 (LootChest)
- **Town Square**: 1 (Landfill Portal)
- **Home Tree**: 2 (StorageChest, AssemblyStation)
- **World Portals**: Multiple fast travel points

### Total Systems by Category
- **Interactable Objects**: 5 types
- **NPC Systems**: 2 implemented + generic fallback
- **Loot Systems**: 3 (Basic, CoopLoot, MaterialDrop)
- **Crafting Stations**: 1 (Assembly)
- **Storage Systems**: 1 (Home Tree storage)
- **Portal Systems**: 2 types (FastTravel, Dungeon)

---

## SUGGESTIONS FOR NEW INTERACTIVE ELEMENTS

### Priority Tier 1 - Natural Extensions
1. **Vendor/Shop NPC** (High Value)
   - Location: Mage Association or Town Square
   - Sells potions, scrolls, gear
   - Uses ShopManager already in codebase
   - Dialog-based shop UI

2. **Weapon/Armor Stands** (Medium Value)
   - Interactive display units
   - Show stat previews
   - Can equip for testing
   - Location: Town Square or shops

3. **Skill Trainer NPC** (Medium Value)
   - Opens Skill Tree UI
   - Learns new spells/abilities
   - Requires gold/materials
   - Linked to SkillManager

4. **Potion Brewing Station** (Medium Value)
   - Combines ingredients into potions
   - PotionSystem already exists
   - Location: Home Tree or shop
   - Result: Consumable items

### Priority Tier 2 - PvP Infrastructure
1. **PvP Arena Entrance Portal** (High Value)
   - Separate arena instance
   - Team/free-for-all mode selector
   - Spectator area
   - Leaderboard display

2. **Duel Challenge NPC** (Medium Value)
   - Initiates player vs player matches
   - Betting system (optional)
   - Ranked/casual options
   - Match rewards

3. **Guild/Party Banner** (Medium Value)
   - Team formation
   - Guild halls
   - Group loot sharing UI
   - Joined players can interact

4. **Training Dummy** (Low Value)
   - Practice DPS testing
   - Damage meter
   - No drops
   - Instant respawn

### Priority Tier 3 - Content Expansion
1. **Quest Board/Notice Givers** (Medium Value)
   - Multiple quest NPCs
   - Quest filtering by level/type
   - Reward previews
   - Location: Town Square

2. **Alchemy Workbench** (Medium Value)
   - Different from potion brewing
   - Create buffs/debuffs
   - Temporary stat enhancements
   - Consumable results

3. **Enchanting Station** (Medium Value)
   - Permanent item upgrades
   - Add special effects
   - Cost scaling with item quality
   - Location: Mage Association

4. **Item Transmog/Appearance Chest** (Low Value)
   - Cosmetic appearance changes
   - Keep original stats
   - Cosmetic shop items
   - Character customization

### Implementation Patterns to Follow

**Pattern 1 - Chest/Object Interactable**:
```
Extends Node3D
├── Add Interactable component
├── _perform_interaction() override
├── UI instantiation/opening
└── SaveManager integration for persistence
```

**Pattern 2 - NPC Interactable**:
```
Extends CharacterBody3D (or NPC base class)
├── Name plate component
├── Dialogue trigger
├── Shop/menu opening via UI system
└── Optional dialogue branching
```

**Pattern 3 - Portal/Teleport**:
```
Extends Area3D
├── Collision detection
├── Activation conditions check
├── GameManager.load_scene() call
└── Spawn point registration
```

### Best Locations for New Elements

**Town Square** (Central Hub):
- Vendor/Shop NPCs
- Skill Trainers
- Quest Givers
- PvP Arena Entrance
- Leaderboards

**Home Tree** (Personal Space):
- Potion Brewing
- Alchemy Workbench
- Enchanting Station
- Appearance/Transmog chest
- Personal storage (already exists)

**Mage Association** (Magic Guild):
- Spell Shop
- Enchanting Station
- Advanced Crafting
- Lore/Grimoire system
- Mystical merchants

**New Locations** (Expansion):
- PvP Arena instance
- Guild Halls
- Dungeon Lobby
- Trading Post
- Tavern/Social Hub

---

## CURRENT CODE QUALITY & ARCHITECTURE

### Strengths
- Clean separation of concerns (components pattern)
- Consistent signal-based communication
- Extensible interactable base class
- Comprehensive loot system with co-op support
- RPC authority validation
- SaveManager centralized persistence

### Areas for Improvement
- PvP targeting system incomplete
- No client-side damage prediction
- Limited matchmaking/lobby system
- No spectator/observer mode
- Minimal anti-cheat validation
- Test systems seem arena-focused (game.tscn)

---

## FILE REFERENCE INDEX

**Core Systems**:
- `/autoload/game_manager.gd` - Game state and player registry
- `/autoload/network_manager.gd` - Network connections
- `/autoload/save_manager.gd` - Persistence layer
- `/scripts/systems/loot_system.gd` - Item drops
- `/scripts/systems/inventory_system.gd` - Item management
- `/scripts/systems/crafting_manager.gd` - Weapon assembly

**Scenes**:
- `/scenes/main/game.gd` - Main gameplay controller
- `/scenes/player/player.gd` - Player character
- `/scenes/enemies/enemy_base.gd` - Enemy template
- `/scenes/objects/loot_chest.gd` - Loot interaction
- `/scenes/world/storage_chest.gd` - Item storage
- `/scenes/world/assembly_station.gd` - Crafting station
- `/scenes/world/portal.gd` - Fast travel
- `/scenes/objects/dungeon_portal.gd` - Dungeon entrance

**UI/Interaction**:
- `/scripts/components/interactable.gd` - Interaction base class
- `/scripts/components/npc.gd` - NPC template
- `/scenes/ui/menus/inventory_ui.gd` - Inventory UI
- `/scenes/ui/menus/storage_ui.gd` - Storage UI
- `/scenes/ui/menus/assembly_ui.gd` - Crafting UI
- `/scenes/ui/menus/fast_travel_menu.gd` - Portal menu

**Data**:
- `/scripts/data/constants.gd` - Game constants
- `/scripts/data/enums.gd` - Enumerations
- `/resources/items/` - Item database files
- `/resources/spells/` - Spell definitions

---

**Document Created**: December 21, 2025
**Project**: MageWar - Godot 4.x
**Status**: Core systems implemented, PvP system partial
