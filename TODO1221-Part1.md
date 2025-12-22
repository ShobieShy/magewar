# TODO1221-Part1.md: Shop NPC & Skill Trainer Implementation

**Timeline**: Estimated 2-3 hours
**Status**: Planning phase
**Scope**: Add 2 new interactive NPCs with existing backend systems

---

## PART 1 OBJECTIVES

### Primary Goal
Implement **Vendor/Shop NPC** and **Skill Trainer NPC** in Town Square using existing ShopManager and SkillManager systems.

### Secondary Goal
Create reusable NPC interaction patterns for future development.

---

## TASK BREAKDOWN

### PHASE 1.1: Shop Vendor NPC (2.5 hours estimated)

#### 1.1.1 Create Vendor NPC Script
**File**: `/scenes/world/starting_town/vendor_npc.gd`
**Type**: New script extending CharacterBody3D or NPC base class
**Requirements**:
- Extend NPC component
- Store shop_id reference (e.g., "town_shop")
- Implement interaction trigger
- Create visual mesh and collision

**Key Methods**:
```
_ready() -> void
  - Initialize as NPC
  - Set npc_name = "Merchant"
  - Load name plate component
  - Register collision shape
_on_interact(player: Node) -> void
  - Open shop UI via ShopManager
  - Pass inventory_system to shop
  - Show shop stock
```

**Dependencies**:
- ShopManager (already exists)
- ShopUI (already exists)
- Interactable component
- NamePlate component

---

#### 1.1.2 Create Shop Data Resource
**File**: `/resources/shops/town_shop.tres`
**Type**: ShopData resource (see ShopManager for structure)
**Contents**:
- shop_id: "town_shop"
- shop_name: "Town Market"
- npc_name: "Merchant"
- buy_price_multiplier: 1.5 (mark up)
- sell_price_multiplier: 0.5 (player gets 50% back)
- stock: Mix of potions, scrolls, basic gear
- refresh_on_load: true (stock rotates each session)

**Stock Options**:
- Healing potions (consumable)
- Mana potions
- Stat scrolls
- Basic weapons/armor
- Crafting materials

---

#### 1.1.3 Register Shop in Town Square
**File**: `/scenes/world/starting_town/town_square.gd` (modify)
**Changes**:
- In _ready(), load town_shop.tres
- Register with ShopManager.register_shop()
- Spawn Vendor NPC at designated position
- Connect shop interactions to signals

**Implementation Pattern**:
```gdscript
func _ready() -> void:
    # ... existing code ...
    _setup_shop()

func _setup_shop() -> void:
    # Load shop data
    var shop_data = load("res://resources/shops/town_shop.tres")
    ShopManager.register_shop(shop_data)
    
    # Spawn vendor NPC
    _spawn_vendor_npc()

func _spawn_vendor_npc() -> void:
    var vendor_scene = preload("res://scenes/world/starting_town/vendor_npc.tscn")
    if vendor_scene:
        var vendor = vendor_scene.instantiate()
        vendor.position = Vector3(-5, 0, 0)  # Position in Town Square
        add_child(vendor)
```

---

#### 1.1.4 Create Vendor NPC Scene
**File**: `/scenes/world/starting_town/vendor_npc.tscn`
**Structure**:
```
VendorNPC (CharacterBody3D)
├── CollisionShape3D (CapsuleShape3D - radius 0.4, height 1.8)
├── MeshInstance3D (CapsuleMesh - visual representation)
├── Interactable (Area3D component)
└── NamePlate (Label3D - shows "Merchant")
```

**Mesh Customization**:
- Use CapsuleMesh with different color (e.g., brown) to distinguish from generic NPCs
- Add optional hat/armor visual indication (simple plane or another mesh)

**Interactable Config**:
- interaction_prompt: "[E] Shop with Merchant"
- interaction_range: 2.5
- can_interact: true
- one_time_only: false

---

### PHASE 1.2: Skill Trainer NPC (2.5 hours estimated)

#### 1.2.1 Create Skill Trainer Script
**File**: `/scenes/world/starting_town/skill_trainer_npc.gd`
**Type**: New script extending NPC base class
**Requirements**:
- Extend NPC component
- Interface with SkillManager
- Open SkillTreeUI when interacted
- Track trained skills for player

**Key Methods**:
```
_ready() -> void
  - Initialize as NPC
  - Set npc_name = "Skill Master"
  - Set dialogue_id = "skill_trainer_intro"
_on_interact(player: Node) -> void
  - Open SkillTreeUI
  - Pass player._inventory_system and SaveManager
  - Show available skills
  - Handle skill point costs
```

**Dependencies**:
- SkillManager (already exists)
- SkillTreeUI (already exists)
- SaveManager (for skill points and progression)
- Interactable component
- NamePlate component

---

#### 1.2.2 Create Dialogue Content
**File**: `/resources/dialogue/skill_trainer_intro.tres` (or add to existing dialogue_data.gd)
**Content**:
- Welcome message explaining skill system
- Mention skill point costs
- Explain skill tree mechanics
- Optional: Flavor text about training

**Dialogue Options**:
```
"Welcome, adventurer! I can help you master new skills.
You currently have X skill points.

Available skills in the tree:
- [Health Boost I] - 1 point
- [Damage Boost I] - 1 point
- [Defense Boost I] - 1 point
- [Cast Speed I] - 2 points
..."
```

---

#### 1.2.3 Register Skill Trainer in Town Square
**File**: `/scenes/world/starting_town/town_square.gd` (modify)
**Changes**:
- In _ready() or new _setup_npcs(), spawn Skill Trainer
- Position at different location than Vendor
- Connect interaction signals

**Implementation Pattern**:
```gdscript
func _spawn_skill_trainer_npc() -> void:
    var trainer_scene = preload("res://scenes/world/starting_town/skill_trainer_npc.tscn")
    if trainer_scene:
        var trainer = trainer_scene.instantiate()
        trainer.position = Vector3(5, 0, 0)  # Right side of square
        add_child(trainer)
        _npcs["skill_trainer"] = trainer
```

---

#### 1.2.4 Create Skill Trainer Scene
**File**: `/scenes/world/starting_town/skill_trainer_npc.tscn`
**Structure**:
```
SkillTrainerNPC (CharacterBody3D)
├── CollisionShape3D (CapsuleShape3D)
├── MeshInstance3D (CapsuleMesh - different color, e.g., purple/blue)
├── Interactable (Area3D)
└── NamePlate (Label3D - "Skill Master")
```

**Visual Differentiation**:
- Color: Purple/Blue (different from Vendor's brown)
- Optional: Add glowing effect material to indicate magical nature
- NamePlate text: "Skill Master"

---

### PHASE 1.3: Integration & Testing (1 hour estimated)

#### 1.3.1 Update TownSquare Script
**File**: `/scenes/world/starting_town/town_square.gd`
**Changes**:
- Add _setup_shop() call in _ready()
- Add _spawn_skill_trainer_npc() call in _ready()
- Add skill trainer to _npcs dictionary
- Connect signals (if any)

**Modifications**:
```gdscript
func _ready() -> void:
    _spawn_npcs()
    _setup_portals()
    _setup_entrances()
    _setup_shop()           # NEW
    _spawn_skill_trainer()  # NEW
    
    # Register with FastTravelManager
    FastTravelManager.register_spawn_point("starting_town", get_player_spawn_position())
```

---

#### 1.3.2 Test in Game
**Verification Checklist**:
- [ ] NPCs spawn at correct positions in Town Square
- [ ] Visual meshes render correctly (different colors)
- [ ] Name plates display correct names
- [ ] Interaction prompts appear when player approaches
- [ ] Vendor NPC opens shop UI on interaction
- [ ] Shop shows stock with prices
- [ ] Player can buy/sell items
- [ ] Skill Trainer opens skill tree UI on interaction
- [ ] Skill tree shows available skills
- [ ] Player can spend skill points
- [ ] UI closes properly when pressing Esc or closing button

**Testing Locations**:
- Run scenes/world/starting_town/town_square.tscn
- Approach each NPC from different angles
- Test all UI interactions
- Verify network compatibility (if applicable)

---

#### 1.3.3 Fix Common Issues
**Potential Problems & Solutions**:

1. **NPC not appearing**
   - Check scene path in preload()
   - Verify position coordinates are on visible terrain
   - Check collision layers/masks

2. **Interaction prompt not showing**
   - Verify Interactable component exists
   - Check collision shape size matches interaction_range
   - Verify collision_layer and collision_mask settings

3. **Shop UI not opening**
   - Check ShopManager is registered and available
   - Verify ShopUI scene path is correct
   - Check shop_id matches registered shop

4. **Skill trainer UI not opening**
   - Check SkillTreeUI exists and loads correctly
   - Verify SkillManager has loaded skill definitions
   - Check SaveManager has skill points tracked

---

## DELIVERABLES FOR PART 1

### New Files Created
1. `/scenes/world/starting_town/vendor_npc.gd` - Shop NPC script
2. `/scenes/world/starting_town/vendor_npc.tscn` - Vendor scene
3. `/scenes/world/starting_town/skill_trainer_npc.gd` - Skill trainer script
4. `/scenes/world/starting_town/skill_trainer_npc.tscn` - Trainer scene
5. `/resources/shops/town_shop.tres` - Shop data resource

### Modified Files
1. `/scenes/world/starting_town/town_square.gd` - Register NPCs and shop

### Documentation
- This todo list with implementation details

---

## SUCCESS CRITERIA

✓ Both NPCs visible in Town Square with distinct visuals
✓ Vendor NPC opens shop with functional buy/sell UI
✓ Skill Trainer NPC opens skill tree with point spending
✓ All interactions smooth and responsive
✓ No console errors or warnings
✓ Network compatible (single-player tested, multiplayer ready)

---

## NOTES & CONSIDERATIONS

### Design Decisions
- Using existing Vendor/Trainer instead of generic NPCs for visual differentiation
- Placing at opposite sides of Town Square (X: -5 and +5) for spatial balance
- Reusing existing ShopManager and SkillManager to avoid code duplication
- Using preloaded scenes for performance

### Future Extensions
- Add vendor quest lines
- Implement seasonal stock rotations
- Add trainer NPC progression (unlock higher-level skills)
- Create multiple trainers for different skill trees
- Add merchant haggling/reputation system

### Network Considerations
- Shop transactions are local (no sync needed)
- Skill unlocks saved in SaveManager (auto-synced)
- NPC positions are static (no need for network sync)
- Ready for multiplayer in current design

---

## ESTIMATED TIMELINE

| Phase | Duration | Task |
|-------|----------|------|
| 1.1 | 2.5h | Shop Vendor NPC |
| 1.2 | 2.5h | Skill Trainer NPC |
| 1.3 | 1h | Integration & Testing |
| **Total** | **6h** | **Part 1 Complete** |

---

**Next**: After Part 1 completion, proceed to TODO1221-Part2.md for PvP Arena and Dungeon Lobby implementation.

