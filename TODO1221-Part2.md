# TODO1221-Part2.md: PvP Arena & Dungeon Lobby Implementation

**Timeline**: Estimated 4-5 hours
**Status**: Planning phase (Part 1 prerequisite)
**Scope**: Add PvP matchmaking infrastructure and Dungeon Lobby system

---

## PART 2 OBJECTIVES

### Primary Goals
1. Implement **PvP Arena Portal** in Town Square with team/mode selection
2. Create **PvP Arena Instance** as separate scene for player battles
3. Create **Dungeon Lobby** for organizing co-op dungeon runs
4. Establish framework for future PvP features (ranking, leaderboards, etc.)

### Secondary Goals
1. Extend DamageEffect to support PvP targeting
2. Create team-based damage validation
3. Implement basic anti-grief mechanics (team damage reduction)
4. Build reusable lobby system for other multiplayer content

---

## TASK BREAKDOWN

### PHASE 2.1: PvP Infrastructure (2 hours estimated)

#### 2.1.1 Extend DamageEffect for PvP
**File**: `/resources/spells/effects/damage_effect.gd` (modify)
**Changes**:
- Add `allow_pvp_damage: bool = false` export variable
- Modify `can_affect_target()` to allow Player targets when PvP enabled
- Update `apply()` to respect PvP targeting rules
- Add team damage reduction for allies

**Implementation Details**:
```gdscript
# Add to exports
@export var allow_pvp_damage: bool = false
@export var friendly_fire_enabled: bool = false

# Update can_affect_target()
func can_affect_target(caster: Node, target: Node) -> bool:
    # Check if target is enemy (existing logic)
    if target.is_in_group("enemies"):
        return true
    
    # Check if target is player (new PvP logic)
    if target is Player:
        if not allow_pvp_damage:
            return false
        
        # Check friendly fire setting
        if not friendly_fire_enabled:
            # Check if on same team
            if _are_on_same_team(caster, target):
                return false
        
        return true
    
    return false

func _are_on_same_team(player1: Node, player2: Node) -> bool:
    if player1.has_meta("team_id") and player2.has_meta("team_id"):
        return player1.get_meta("team_id") == player2.get_meta("team_id")
    return false
```

**Dependencies**:
- Player script modifications (meta tagging for team)
- SpellCaster or projectile system to support allow_pvp_damage

---

#### 2.1.2 Add Team System to Player
**File**: `/scenes/player/player.gd` (modify)
**Changes**:
- Add team_id property
- Add team color/indicator
- Add damage multiplier for friendly fire
- Add team chat/messages (optional)

**Properties to Add**:
```gdscript
# Team management
var team_id: int = -1  # -1 = no team, 0 = red, 1 = blue, etc.
var team_color: Color = Color.WHITE

func set_team(team: int) -> void:
    team_id = team
    set_meta("team_id", team)
    
    # Set color based on team
    match team:
        0: team_color = Color.RED
        1: team_color = Color.BLUE
        _: team_color = Color.WHITE

func get_team() -> int:
    return team_id
```

---

#### 2.1.3 Create PvP Match Manager
**File**: `/scripts/systems/pvp_match_manager.gd`
**Type**: New system for PvP match lifecycle
**Scope**: Manages match state, team assignment, scoring

**Key Components**:
```gdscript
class_name PvPMatchManager
extends Node

enum MatchState { LOBBY, COUNTDOWN, ACTIVE, FINISHED }
enum MatchType { FREE_FOR_ALL, TEAM_DEATHMATCH, CAPTURE_FLAG }

# Current match state
var match_state: MatchState = MatchState.LOBBY
var match_type: MatchType = MatchType.FREE_FOR_ALL
var match_duration: float = 600.0  # 10 minutes
var match_time_remaining: float = 0.0

# Player tracking
var players_in_match: Dictionary = {}  # peer_id -> {team, kills, deaths, score}
var team_scores: Dictionary = {0: 0, 1: 0}

# Signals
signal match_started()
signal match_ended(winner: int)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal player_died(peer_id: int, killer_id: int)
signal team_score_changed(team: int, new_score: int)
```

**Key Methods**:
- `start_match()` - Begin match countdown
- `end_match()` - Finish and calculate winner
- `assign_teams()` - Distribute players to teams
- `record_kill(killer_id, killed_id)` - Track kills
- `get_match_results()` - Return final scores

---

#### 2.1.4 Create PvP Arena Scene
**File**: `/scenes/pvp/pvp_arena.tscn` (new scene)
**File**: `/scenes/pvp/pvp_arena.gd` (new script)
**Purpose**: Separate map instance for PvP matches

**Scene Structure**:
```
PvPArena (Node3D)
├── Environment (lighting, skybox)
├── Arena (CSG geometry - symmetric 40x40 arena)
├── SpawnPoints
│   ├── Team0_Spawn1-4 (red team spawns)
│   └── Team1_Spawn1-4 (blue team spawns)
├── Objects (power-ups, obstacles)
├── HUD (match timer, scores)
└── AudioStreamPlayer (arena ambience)
```

**Arena Design**:
- Symmetric layout (40x40 units)
- Central contested area
- Team-specific flanking routes
- Multiple spawn options per team
- Obstacle placement for tactical play

**Script Responsibilities** (`pvp_arena.gd`):
- Initialize match
- Spawn players at correct team spawn points
- Display match UI (timer, scores)
- Handle match completion
- Return to Town Square on completion

---

### PHASE 2.2: PvP Arena Portal (1.5 hours estimated)

#### 2.2.1 Create PvP Portal Script
**File**: `/scenes/world/starting_town/pvp_portal.gd`
**Type**: New script extending Portal class
**Purpose**: Entry point for PvP, shows mode/team selection

**Key Methods**:
```gdscript
extends Portal

func _perform_interaction(player: Node) -> void:
    if not is_active:
        return
    
    # Open PvP mode selection UI
    _open_pvp_selection_menu(player)

func _open_pvp_selection_menu(player: Node) -> void:
    # Create or show PvP mode selection UI
    var pvp_menu = load("res://scenes/ui/menus/pvp_mode_select.tscn")
    if pvp_menu:
        var menu = pvp_menu.instantiate()
        get_tree().root.add_child(menu)
        
        # Connect signals for mode selection
        menu.mode_selected.connect(_on_pvp_mode_selected)
        menu.cancelled.connect(_on_pvp_cancelled)

func _on_pvp_mode_selected(match_type: int) -> void:
    # Load PvP arena with selected mode
    GameManager.load_scene("res://scenes/pvp/pvp_arena.tscn")
    # Pass match_type to arena via GameManager

func _on_pvp_cancelled() -> void:
    # User closed menu, do nothing
    pass
```

**Dependencies**:
- Portal base class (extends existing)
- PvP mode selection UI
- PvPMatchManager

---

#### 2.2.2 Create PvP Mode Selection UI
**File**: `/scenes/ui/menus/pvp_mode_select.tscn`
**File**: `/scenes/ui/menus/pvp_mode_select.gd`
**Purpose**: Menu for selecting PvP match type

**Options**:
1. **Free-For-All** (4-6 players, every player for themselves)
2. **Team Deathmatch** (2 teams, 3 players each)
3. **Training Dummy** (single player vs AI practice)

**UI Layout**:
```
PvP Mode Selection
├── Title: "Choose Battle Mode"
├── Option 1: Free-For-All
│   ├── Description: "4-6 players, last one standing wins"
│   └── [Select] Button
├── Option 2: Team Deathmatch
│   ├── Description: "2 teams compete for most kills"
│   └── [Select] Button
├── Option 3: Training
│   ├── Description: "Practice against dummies"
│   └── [Select] Button
└── [Cancel] Button
```

**Script Implementation**:
```gdscript
extends Control

signal mode_selected(match_type: int)
signal cancelled()

enum MatchType { FREE_FOR_ALL = 0, TEAM_DEATHMATCH = 1, TRAINING = 2 }

func _on_ffa_selected() -> void:
    mode_selected.emit(MatchType.FREE_FOR_ALL)
    queue_free()

func _on_team_selected() -> void:
    mode_selected.emit(MatchType.TEAM_DEATHMATCH)
    queue_free()

func _on_training_selected() -> void:
    mode_selected.emit(MatchType.TRAINING)
    queue_free()

func _on_cancel() -> void:
    cancelled.emit()
    queue_free()
```

---

#### 2.2.3 Create PvP Portal Scene
**File**: `/scenes/world/starting_town/pvp_portal.tscn`
**Structure**:
```
PvPPortal (Area3D - extends Portal)
├── CollisionShape3D (SphereShape3D)
├── MeshInstance3D (custom PvP portal mesh - red/blue swirling)
├── GPUParticles3D (battle energy effect)
├── OmniLight3D (red/blue glow)
├── Label3D (InteractionPrompt: "[E] Enter Arena")
└── AnimationPlayer (pulsing animation)
```

**Visual Customization**:
- Colors: Alternating red and blue
- Particles: Combat-themed (sparks, energy)
- Sound: Battle horn/gong on approach
- Animation: Faster rotation than dungeon portals

---

#### 2.2.4 Register PvP Portal in Town Square
**File**: `/scenes/world/starting_town/town_square.gd` (modify)
**Changes**:
- Spawn PvP portal at designated location
- Connect match state signals if needed

**Implementation**:
```gdscript
func _setup_pvp_portal() -> void:
    var pvp_portal_scene = preload("res://scenes/world/starting_town/pvp_portal.tscn")
    if pvp_portal_scene:
        var pvp_portal = pvp_portal_scene.instantiate()
        pvp_portal.position = Vector3(0, 0.5, -15)  # Center-bottom of square
        pvp_portal.portal_id = "pvp_arena"
        pvp_portal.is_active = true
        add_child(pvp_portal)
```

---

### PHASE 2.3: Dungeon Lobby System (1.5 hours estimated)

#### 2.3.1 Create Dungeon Lobby Manager
**File**: `/scripts/systems/dungeon_lobby_manager.gd`
**Type**: New system for organizing dungeon parties

**Key Functionality**:
```gdscript
class_name DungeonLobbyManager
extends Node

# Lobby state
var party_members: Dictionary = {}  # peer_id -> PlayerInfo
var lobby_type: String = ""  # dungeon_1, dungeon_2, etc.
var lobby_leader: int = -1
var min_players: int = 2
var max_players: int = 4

# Signals
signal player_joined_lobby(peer_id: int)
signal player_left_lobby(peer_id: int)
signal lobby_ready()  # All players ready
signal lobby_disbanded()

# Ready status
var ready_players: Dictionary = {}  # peer_id -> bool

func create_lobby(dungeon_id: String, leader_id: int) -> void:
    lobby_type = dungeon_id
    lobby_leader = leader_id
    party_members[leader_id] = GameManager.get_player_info(leader_id)
    player_joined_lobby.emit(leader_id)

func add_player(peer_id: int) -> bool:
    if party_members.size() >= max_players:
        return false
    
    if peer_id not in party_members:
        party_members[peer_id] = GameManager.get_player_info(peer_id)
        ready_players[peer_id] = false
        player_joined_lobby.emit(peer_id)
        return true
    return false

func set_player_ready(peer_id: int, ready: bool) -> void:
    ready_players[peer_id] = ready
    
    # Check if all players ready
    if _all_players_ready():
        lobby_ready.emit()

func _all_players_ready() -> bool:
    if party_members.size() < min_players:
        return false
    
    for peer_id in party_members:
        if not ready_players.get(peer_id, false):
            return false
    return true

func start_dungeon_run() -> void:
    # Load dungeon scene and spawn party
    GameManager.load_scene("res://scenes/dungeons/%s.tscn" % lobby_type)
```

---

#### 2.3.2 Create Dungeon Lobby UI
**File**: `/scenes/ui/menus/dungeon_lobby.tscn`
**File**: `/scenes/ui/menus/dungeon_lobby.gd`
**Purpose**: UI for organizing party and confirming readiness

**Layout**:
```
Dungeon Lobby: [Dungeon Name]
├── Party Members (list)
│   ├── Player1 (Leader) [Ready ✓]
│   ├── Player2 [Ready ✗]
│   └── [Invite] button
├── Party Info
│   ├── Difficulty: Normal
│   ├── Time Limit: 30 min
│   └── Rewards: 500 gold + loot
├── Action Buttons
│   ├── [I'm Ready] toggle
│   ├── [Start Dungeon] (if leader)
│   └── [Leave] button
└── Chat (optional)
```

**Script Features**:
- Display party members with portraits
- Toggle ready status
- Leader-only start button
- Auto-update when players join/leave
- Show dungeon info (difficulty, rewards)

---

#### 2.3.3 Create Dungeon Portal Enhancement
**File**: `/scenes/objects/dungeon_portal.gd` (modify)
**Changes**:
- When interacted, open lobby creation
- If party exists, show lobby UI
- Prevent solo entry (require party if not tutorial dungeon)

**New Methods**:
```gdscript
func _use_portal(player: Node) -> void:
    if not can_use_portal(player):
        return
    
    # Create or join dungeon lobby
    _open_dungeon_lobby(player)

func _open_dungeon_lobby(player: Node) -> void:
    var lobby_ui = load("res://scenes/ui/menus/dungeon_lobby.tscn").instantiate()
    if lobby_ui:
        get_tree().root.add_child(lobby_ui)
        lobby_ui.initialize(dungeon_id, player)
```

---

#### 2.3.4 Register Dungeon Lobbies
**File**: `/autoload/dungeon_portal_system.gd` (modify)
**Changes**:
- Track active lobbies
- Handle party creation for dungeons
- Manage party synchronization

**New Functionality**:
```gdscript
var active_lobbies: Dictionary = {}  # dungeon_id -> DungeonLobbyManager

func create_lobby_for_dungeon(dungeon_id: String, leader_id: int) -> DungeonLobbyManager:
    var lobby = DungeonLobbyManager.new()
    lobby.create_lobby(dungeon_id, leader_id)
    active_lobbies[dungeon_id] = lobby
    return lobby

func get_lobby(dungeon_id: String) -> DungeonLobbyManager:
    return active_lobbies.get(dungeon_id)
```

---

### PHASE 2.4: Integration & Testing (1 hour estimated)

#### 2.4.1 Update Town Square
**File**: `/scenes/world/starting_town/town_square.gd` (modify)
**Changes**:
- Add `_setup_pvp_portal()` call in _ready()
- Verify all portals spawn correctly

```gdscript
func _ready() -> void:
    _spawn_npcs()
    _setup_portals()
    _setup_entrances()
    _setup_shop()
    _spawn_skill_trainer()
    _setup_pvp_portal()  # NEW
    
    FastTravelManager.register_spawn_point("starting_town", get_player_spawn_position())
```

---

#### 2.4.2 Update Game Scene
**File**: `/scenes/main/game.gd` (modify)
**Changes**:
- Ensure PvP damage is enabled in test arena
- Set team IDs for test purposes (2 teams of 3 players)

**Optional Test Code**:
```gdscript
func _spawn_local_player() -> void:
    var spawn_pos = _get_next_spawn_position()
    var player = PLAYER_SCENE.instantiate()
    player.name = "Player_" + str(NetworkManager.local_peer_id)
    player.position = spawn_pos
    player.set_multiplayer_authority(NetworkManager.local_peer_id)
    player.is_local_player = true
    
    # For testing: assign teams based on spawn index
    if _spawn_index % 2 == 0:
        player.set_team(0)  # Red
    else:
        player.set_team(1)  # Blue
    
    players_node.add_child(player)
```

---

#### 2.4.3 Testing Checklist
**PvP Arena**:
- [ ] PvP portal appears in Town Square
- [ ] Portal shows correct interaction prompt
- [ ] Mode selection menu opens on interaction
- [ ] Mode selection displays all 3 options
- [ ] Selecting mode loads PvP arena
- [ ] Arena spawns players at team spawn points
- [ ] Player damage only works on enemies (not teamates in TDM)
- [ ] Match timer counts down
- [ ] Score updates on kills
- [ ] Match completion shows results
- [ ] Return to Town Square works

**Dungeon Lobby**:
- [ ] Dungeon portals show lobby option
- [ ] Lobby UI opens with correct dungeon info
- [ ] Players can join party
- [ ] Leader-only start button works
- [ ] Ready status syncs across clients
- [ ] Dungeon starts when all ready
- [ ] Party members spawn together in dungeon

---

#### 2.4.4 Network Testing
**Multiplayer Validation**:
- [ ] PvP works with 2+ players
- [ ] Teams are assigned consistently
- [ ] Damage synchronizes across network
- [ ] Kills tracked on all clients
- [ ] Scores broadcast to all players
- [ ] Lobby creation syncs across network
- [ ] Party members see each other in dungeon

---

## DELIVERABLES FOR PART 2

### New Files Created
1. `/scripts/systems/pvp_match_manager.gd` - PvP match lifecycle
2. `/scenes/pvp/pvp_arena.tscn` - PvP arena map
3. `/scenes/pvp/pvp_arena.gd` - Arena controller
4. `/scenes/world/starting_town/pvp_portal.gd` - PvP portal script
5. `/scenes/world/starting_town/pvp_portal.tscn` - Portal scene
6. `/scenes/ui/menus/pvp_mode_select.tscn` - Mode selection UI
7. `/scenes/ui/menus/pvp_mode_select.gd` - Mode selection script
8. `/scripts/systems/dungeon_lobby_manager.gd` - Lobby system
9. `/scenes/ui/menus/dungeon_lobby.tscn` - Lobby UI
10. `/scenes/ui/menus/dungeon_lobby.gd` - Lobby script

### Modified Files
1. `/resources/spells/effects/damage_effect.gd` - PvP targeting support
2. `/scenes/player/player.gd` - Team system
3. `/scenes/world/starting_town/town_square.gd` - Register PvP portal
4. `/scenes/main/game.gd` - Optional team assignment for testing
5. `/autoload/dungeon_portal_system.gd` - Lobby tracking

---

## SUCCESS CRITERIA

✓ PvP arena accessible and functional with mode selection
✓ Team assignment working correctly in arena
✓ Friendly fire disabled for teammates (enabled for enemies)
✓ Match timer and scoring system operational
✓ Dungeon lobby system allows party formation
✓ Party members spawn together in dungeons
✓ Network synchronization for PvP and lobbies
✓ No console errors or warnings
✓ All interactions smooth and responsive

---

## NOTES & CONSIDERATIONS

### Design Decisions
- Separate PvP arena from main game to avoid griefing
- Team-based by default (2v2 or 3v3) for balance
- Free-for-all option for competitive players
- Dungeon lobbies prevent solo griefing in group content
- Auto-team assignment to prevent team stacking

### Future Extensions
- Ranked ladder system
- ELO rating and matchmaking
- Seasonal rewards
- PvP cosmetics and titles
- Team-based objective modes (Capture the Flag, Payload)
- 1v1 duel system
- Spectator mode for matches
- Match replays and highlights

### Known Limitations
- No built-in anti-cheat (client-side prediction)
- No rejoin system if player disconnects
- No party persistence between sessions
- Free-for-all mode possible griefing (low priority)

### Networking Considerations
- Team metadata synced via player registry
- Match state handled by host authority
- Kill/score updates reliable RPC calls
- Lobby creation coordinated via GameManager
- Ready status local to player (verified on start)

---

## ESTIMATED TIMELINE

| Phase | Duration | Task |
|-------|----------|------|
| 2.1 | 2h | PvP Infrastructure |
| 2.2 | 1.5h | PvP Arena Portal |
| 2.3 | 1.5h | Dungeon Lobby System |
| 2.4 | 1h | Integration & Testing |
| **Total** | **6h** | **Part 2 Complete** |

---

## OVERALL PROJECT STATUS

**After Part 1 + Part 2**:
- 2 new NPCs (Vendor, Skill Trainer)
- PvP arena with matchmaking
- Dungeon party system
- Enhanced damage system for PvP
- Team-based gameplay foundation

**Ready for**:
- Player testing and feedback
- Balance adjustments
- Content expansion (new dungeons, quests, cosmetics)

---

**Next Steps**:
Part 5 (Rewards/Achievements) comes after Parts 1-4 are complete.

See EXPLORATION_INDEX.md for additional feature suggestions and implementation patterns.

