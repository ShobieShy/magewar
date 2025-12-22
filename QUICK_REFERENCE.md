# MageWar Quick Reference Guide

## QUICK FACTS
- **Engine**: Godot 4.x
- **Max Players**: 6 simultaneous
- **Network**: Steam P2P (primary) + ENet (fallback)
- **Current Focus**: PvE with optional PvP infrastructure
- **Main Scene**: `/scenes/main/game.tscn` (arena) or `/scenes/world/` (hub world)

---

## SCENE HIERARCHY

### Game.tscn (Arena)
```
Game (Node3D)
├── TestArena (50x50 area with obstacles)
├── SpawnPoints (6 markers)
├── Players (container for 1-6 player instances)
├── Enemies (pre-placed test enemies)
├── Objects (LootChest)
└── HUD (UI Canvas)
```

### Starting Town Hub
```
TownSquare
├── PlayerSpawn
├── NPCSpawns (CrazyJoe, Bob)
├── Portals (PortalLandfill)
├── MageAssociationEntrance
└── HomeTreeEntrance

HomeTree
├── PlayerSpawn
├── StorageChest (100 slots)
├── AssemblyStation (crafting)
├── Bed (save point)
└── ExitArea
```

---

## KEY COMPONENTS

### Interactable Base Class
**File**: `/scripts/components/interactable.gd`
```gdscript
extends Area3D
@export var interaction_prompt: String = "[E] Interact"
@export var interaction_range: float = 2.5
@export var can_interact: bool = true
@export var one_time_only: bool = false

signal interaction_started(player: Node)
signal interaction_ended(player: Node)
```

### How to Create New Interactable
1. Extend Node3D or Area3D
2. Add Interactable component as child
3. Connect to `interaction_started` signal
4. Implement custom interaction logic
5. Use closest_player from `_get_closest_player()`

---

## INVENTORY SYSTEM
- **Capacity**: 40 items
- **Equipment Slots**: 8 (head, chest, legs, hands, feet, main, off, accessory)
- **Materials**: Separate 50-type limit
- **Signals**: inventory_changed, item_added, item_removed, equipment_changed

---

## LOOT SYSTEM

### Enemy Loot Drops
```
BASIC Enemy:    1 item    + gold
ELITE Enemy:    2 items   + gold * 3
MINIBOSS:       3 items   + gold * 6
BOSS:           5 items   + gold * 10
DEMON_LORD:     8 items   + gold * 20
```

### Gold Formula
```
gold = (base_gold * enemy_level * type_multiplier) * rand(0.8, 1.2)
base_gold = 5 (configurable per enemy)
```

### Experience Formula
```
xp = experience_value * enemy_level * type_bonus
Bonuses: Basic 1x, Elite 1.5x, MiniBoss 2.5x, Boss 5x, DemonLord 10x
```

### Loot Distribution (Multiplayer)
- **FREE_FOR_ALL**: Anyone can grab (default)
- **ROUND_ROBIN**: Take turns
- **MASTER_LOOTER**: One player decides
- **GREED_BASED**: Need rolling
- **CLASS_BASED**: By character class
- **VOTE**: Party votes

---

## COMBAT CONSTANTS

### Damage & Weapons
- Base Projectile Speed: 30 units/sec
- Hitscan Range: 100 units
- Global Cooldown: 0.25 seconds
- Crit Chance: 5% base + stats
- Crit Multiplier: 1.5x
- Friendly Fire: 50% reduction (optional)

### Element Advantage
- Fire > Air > Earth > Water > (Fire)
- Light vs Dark (balanced)
- Advantage: +25% damage
- Disadvantage: -25% damage

### Charged Attacks
- Damage: 200% normal
- Cost: 250% magika
- Cooldown: 150% longer

---

## PLAYER STATS

### Primary Resources
```
Health:  100 (+ equipment bonuses)
Magika:  100 (for spellcasting)
Stamina: 100 (for movement/sprint/jump)
```

### Movement
```
Walk:    5 units/sec
Sprint:  8 units/sec (10 stamina/sec cost)
Crouch:  2.5 units/sec
Jump:    6 units velocity (15 stamina cost)
```

### Regen (per second)
```
Health:  1/sec
Magika:  5/sec
Stamina: 15/sec (after 1 second delay)
```

---

## NETWORKING

### Connection Flow
1. NetworkManager.host_game() or join_game()
2. Steam lobby creation/joining (or ENet fallback)
3. GameManager receives player_connected signal
4. Game.tscn spawns player instances
5. All players synchronized with RPC calls

### RPC Examples
```gdscript
# Server respawn (authority-locked)
@rpc("authority", "call_remote", "reliable")
func _rpc_respawn_player(peer_id: int, position: Vector3) -> void

# Client respawn request
@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_respawn(peer_id: int) -> void
```

### Player Registry
```gdscript
GameManager.players[peer_id] = PlayerInfo
GameManager.is_host = true/false
GameManager.local_player_id = peer_id
```

---

## IMPORTANT FILES

### Must Read
- `/autoload/game_manager.gd` - Game state and player tracking
- `/autoload/network_manager.gd` - Connection handling
- `/scripts/components/interactable.gd` - Base for all interactions
- `/scenes/main/game.gd` - Player spawning logic

### Reference
- `/scripts/data/constants.gd` - All game constants
- `/scripts/data/enums.gd` - All enumerations
- `/scripts/systems/loot_system.gd` - Item drops
- `/scripts/systems/inventory_system.gd` - Item management
- `/scripts/systems/coop_loot_system.gd` - Multiplayer loot

### UI
- `/scenes/ui/menus/inventory_ui.gd` - Inventory menu
- `/scenes/ui/menus/storage_ui.gd` - Storage chest UI
- `/scenes/ui/menus/assembly_ui.gd` - Crafting UI
- `/scenes/ui/menus/fast_travel_menu.gd` - Portal menu

---

## ADDING NEW FEATURES

### Add a Shop NPC
1. Create script extending CharacterBody3D
2. Add NamePlate component
3. Add collision shape
4. Implement dialogue system
5. Hook into ShopManager for inventory
6. Place in TownSquare

### Add a Crafting Station
1. Extend Node3D
2. Add Interactable component
3. Create custom UI script
4. Connect crafting logic
5. Add visual mesh + collision
6. Hook SaveManager for persistence

### Add a Portal
1. Extend Area3D (or use Portal class)
2. Set portal_id for FastTravelManager
3. Configure requirements (level, quest, item)
4. Add visual mesh and effects
5. Register with FastTravelManager
6. Set active/inactive based on conditions

### Add a Custom Interactable
```gdscript
extends Node3D

@onready var interactable = $Interactable

func _ready():
    interactable.interaction_started.connect(_on_interact)

func _on_interact(player: Node):
    # Custom logic here
    print("Player interacted with me!")
    SaveManager.save_data()
```

---

## CONSTANTS & ENUMS

### Enums Location
- `/scripts/data/enums.gd`

### Common Enums
```gdscript
Enums.GameState      # MAIN_MENU, LOADING, PLAYING, PAUSED, etc
Enums.NetworkMode    # OFFLINE, STEAM, ENET
Enums.AIState        # IDLE, PATROL, CHASE, ATTACK, FLEE
Enums.DamageType     # PHYSICAL, MAGICAL, ELEMENTAL
Enums.Element        # FIRE, WATER, EARTH, AIR, LIGHT, DARK
Enums.Rarity         # BASIC, UNCOMMON, RARE, MYTHIC, PRIMORDIAL, UNIQUE
Enums.EquipmentSlot  # HEAD, CHEST, LEGS, HANDS, FEET, MAIN_HAND, OFF_HAND, ACCESSORY
Enums.EnemyType      # BASIC, ELITE, MINIBOSS, BOSS, DEMON_LORD
```

---

## COMMON OPERATIONS

### Get Local Player
```gdscript
var player = GameManager.get_player_info(NetworkManager.local_peer_id).player_node
```

### Add Item to Inventory
```gdscript
player._inventory_system.add_item(item_data)
```

### Open Menu
```gdscript
inventory_ui.open(player._inventory_system)
```

### Spawn Loot
```gdscript
var loot_system = LootSystem.new()
loot_system.drop_loot(item, position, velocity)
```

### Save Game
```gdscript
SaveManager.save_player_data()
SaveManager.save_world_data()
```

### Load Scene
```gdscript
GameManager.load_scene("res://path/to/scene.tscn")
```

---

## DEBUGGING

### Check Network Status
```gdscript
print(NetworkManager.network_mode)           # STEAM, ENET, OFFLINE
print(NetworkManager.is_server)              # bool
print(GameManager.is_host)                   # bool
print(GameManager.players)                   # Dictionary of all players
```

### Check Player State
```gdscript
var player = GameManager.get_player_info(peer_id).player_node
print(player.stats.current_health)
print(player._inventory_system.inventory)
print(player.is_local_player)
```

### Check Loot
```gdscript
var loot_pickups = get_tree().get_nodes_in_group("loot_pickups")
```

---

## PERFORMANCE NOTES

### Object Pooling
- Projectiles use ProjectilePool (GameManager.projectile_pool)
- Get/return projectiles instead of instantiating

### LOD & Culling
- Physics layers help culling (6 layers defined)
- Use collision shapes wisely to avoid overhead

### Network Optimization
- RPC calls marked "reliable" only when necessary
- Use "call_local" to skip network on single-player
- Sync only essential data (position, state, health)

---

## GOTCHAS & KNOWN ISSUES

1. **PvP System Incomplete**
   - Friendly fire is optional, not enforced
   - No PvP-specific matchmaking
   - Damage targeting assumes enemies only

2. **Single Host Authority**
   - Only host can respawn players
   - Could cause lag if host is slow
   - Consider server architecture for large scale

3. **No Anti-Cheat**
   - Client-predicted damage
   - Could be exploited in competitive

4. **Storage Limited**
   - 100 item storage chest
   - 40 item inventory
   - 50 material types max

---

**Last Updated**: December 21, 2025
**Quick Reference v1.0**
