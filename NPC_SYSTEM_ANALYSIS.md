# NPC SYSTEM ANALYSIS - MAGEWAR CODEBASE

## 1. NPC STRUCTURE & ARCHITECTURE

### NPC Base Class (`scripts/components/npc.gd`)
The NPC class extends `Interactable` and provides dialogue, quest, and shop interactions.

**Key Properties:**
- `npc_name: String` - Display name (e.g., "Crazy Joe")
- `npc_title: String` - Optional title (e.g., "Eccentric Hermit")
- `npc_id: String` - Unique identifier for quest tracking
- `dialogue_lines: Array[String]` - Lines of dialogue shown sequentially
- `dialogue_on_complete: String` - Dialogue shown after one-time interaction
- `open_shop_on_dialogue_end: bool` - Auto-open shop after dialogue
- `shop_id: String` - ID of shop to open (must be registered with ShopManager)
- `give_quest_id: String` - Quest to start on dialogue end
- `complete_quest_id: String` - Quest to complete on dialogue end

**Key Signals:**
- `dialogue_started()` - Emitted when dialogue begins
- `dialogue_ended()` - Emitted when dialogue completes

**Key Methods:**
- `_perform_interaction(player)` - Overrides Interactable
  - Starts dialogue sequence
- `_start_dialogue(player)` - Initiates dialogue
  - Disables player input via `player.set_input_enabled(false)`
  - Shows dialogue box
- `_show_current_line()` - Displays next dialogue line
- `_advance_dialogue()` - Moves to next line (called by button or [E] key)
- `_end_dialogue()` - Closes dialogue and triggers post-dialogue actions
- `_trigger_post_dialogue_actions()` - Handles quest/shop/NPC tracking

**Post-Dialogue Actions:**
```gdscript
func _trigger_post_dialogue_actions() -> void:
    # 1. Report to QuestManager that we talked to this NPC
    QuestManager.report_npc_talked(npc_id)
    
    # 2. Give quest via QuestManager
    if give_quest_id:
        QuestManager.start_quest(give_quest_id)
    
    # 3. Complete quest via QuestManager
    if complete_quest_id:
        var quest = QuestManager.get_active_quest(complete_quest_id)
        if quest and quest.is_ready_to_turn_in():
            QuestManager.complete_quest(complete_quest_id)
    
    # 4. Open shop
    if open_shop_on_dialogue_end:
        ShopManager.open_shop(shop_id)
```

---

## 2. INTERACTABLE COMPONENT (`scripts/components/interactable.gd`)

The base class for all interactive objects. NPCs inherit from this.

**Key Properties:**
- `interaction_prompt: String` - Text shown to player (e.g., "[E] Talk to NPC Name")
- `interaction_range: float` - Radius of interaction area (default 2.5)
- `can_interact: bool` - Whether interaction is enabled
- `one_time_only: bool` - If true, can only interact once
- `players_in_range: Array` - List of players currently in range
- `has_been_used: bool` - Track if one-time interaction was used

**Key Signals:**
- `interaction_started(player)` - When interaction happens
- `interaction_ended(player)` - When interaction completes
- `player_entered_range(player)` - When player enters interaction radius
- `player_exited_range(player)` - When player leaves interaction radius

**Key Methods:**
- `_try_interact()` - Called when [E] is pressed
  - Gets closest local player
  - Calls `_perform_interaction(player)` on that player
- `_perform_interaction(player)` - Override in subclasses
  - Base implementation emits `interaction_started` signal
  - Marks as used if `one_time_only`
- `_on_body_entered/exited()` - Range detection via Area3D
  - Shows/hides interaction prompt via HUD
- `set_interactable(value)` - Enable/disable interaction
- `_show_interact_prompt(player)` - Displays prompt in HUD
  - Calls `hud.show_interact_prompt(interaction_prompt)`
  - Looks for HUD at `Game/HUD/PlayerHUD`

**Setup in _ready():**
```gdscript
func _ready() -> void:
    # Collision setup for proximity detection
    collision_layer = Constants.LAYER_TRIGGERS
    collision_mask = Constants.LAYER_PLAYERS
    
    # Create collision shape if missing
    if get_node_or_null("CollisionShape3D") == null:
        var collision = CollisionShape3D.new()
        var shape = SphereShape3D.new()
        shape.radius = interaction_range
        collision.shape = shape
        add_child(collision)
    
    # Connect signals
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
```

---

## 3. NAMEPLATE COMPONENT (`scripts/components/name_plate.gd`)

Displays 3D text above NPCs using Billboard mode.

**Key Properties:**
- `display_name: String` - Text to display
- `height_offset: float` - Y position above entity (default 3.0)
- `font_size: int` - Size of text (default 32)
- `text_color: Color` - Text color (default white)
- `outline_color: Color` - Outline color (default black)
- `outline_width: float` - Outline thickness (default 2.0)

**Key Methods:**
- `set_name_plate_text(text)` - Update display text
- `set_name_plate_color(color)` - Change text color

**Implementation:**
```gdscript
func _ready() -> void:
    label_3d = Label3D.new()
    label_3d.text = display_name
    label_3d.font_size = font_size
    label_3d.modulate = text_color
    label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Always faces camera
    label_3d.no_depth_test = false
    label_3d.outline_size = outline_width
    
    add_child(label_3d)
    label_3d.position.y = height_offset
```

**Usage Example:**
```gdscript
# In NPC creation script:
var nameplate = NamePlate.new()
nameplate.display_name = npc.npc_name
npc.add_child(nameplate)
```

---

## 4. SHOPMANAGER (`autoload/shop_manager.gd`)

Global autoload that manages all shops and transactions.

**Key Properties:**
- `_shops: Dictionary` - Registered shops (shop_id -> ShopData)
- `_current_shop: ShopData` - Currently open shop
- `_shop_ui: Control` - Shop UI reference

**Key Signals:**
- `shop_opened(shop)` - When shop opens
- `shop_closed()` - When shop closes
- `item_purchased(item, quantity, cost)` - When player buys
- `item_sold(item, quantity, gold)` - When player sells
- `stock_refreshed(shop_id)` - When stock rotates

**Core Methods:**

```gdscript
# Registration
func register_shop(shop: ShopData) -> void:
    _shops[shop.shop_id] = shop
    if shop.current_stock.is_empty():
        shop.generate_stock()

func unregister_shop(shop_id: String) -> void:
    _shops.erase(shop_id)

# Querying
func get_shop(shop_id: String) -> ShopData:
    return _shops.get(shop_id)

func get_all_shops() -> Array[ShopData]:
    var result: Array[ShopData] = []
    for shop in _shops.values():
        result.append(shop)
    return result

# Stock Management
func refresh_all_stocks() -> void:  # Called on map load
    for shop_id in _shops:
        var shop = _shops[shop_id]
        if shop.refresh_on_load:
            shop.generate_stock()
            stock_refreshed.emit(shop_id)

func refresh_shop_stock(shop_id: String) -> void:
    var shop = _shops.get(shop_id)
    if shop:
        shop.generate_stock()
        stock_refreshed.emit(shop_id)

# Shop Interaction
func open_shop(shop_id: String) -> bool:
    var shop = _shops.get(shop_id)
    if shop == null:
        push_error("Shop not found: %s" % shop_id)
        return false
    
    _current_shop = shop
    _show_shop_ui()
    shop_opened.emit(shop)
    return true

func close_shop() -> void:
    _current_shop = null
    _hide_shop_ui()
    shop_closed.emit()

func get_current_shop() -> ShopData:
    return _current_shop

func is_shop_open() -> bool:
    return _current_shop != null

# Transactions (operate on current shop)
func buy_item(index: int, quantity: int = 1) -> bool:
    if _current_shop == null:
        return false
    
    var result = _current_shop.buy_item(index, quantity)
    
    if result.success:
        item_purchased.emit(result.item, result.quantity, result.total_cost)
        return true
    
    return false

func sell_item(item: ItemData, quantity: int = 1) -> bool:
    if _current_shop == null:
        return false
    
    var result = _current_shop.sell_item(item, quantity)
    
    if result.success:
        item_sold.emit(item, quantity, result.gold_earned)
        return true
    
    return false

func buyback_item(index: int, quantity: int = 1) -> bool:
    if _current_shop == null:
        return false
    
    var result = _current_shop.buyback_item(index, quantity)
    
    if result.success:
        item_purchased.emit(result.item, result.quantity, result.total_cost)
        return true
    
    return false
```

---

## 5. SHOPDATA RESOURCE (`resources/shops/shop_data.gd`)

Resource class that defines a single shop's inventory and pricing.

**Key Properties:**

```gdscript
# Info
shop_id: String              # Unique identifier
shop_name: String            # Display name
shop_description: String     # Description
shop_keeper_name: String     # NPC name running shop

# Stock Configuration
item_pool: Array[ItemData]   # Items shop can sell
stock_size: int              # Number of items shown (default 12)
refresh_on_load: bool        # Rotate stock on map load

# Rarity Weights (higher = more likely)
basic_weight: float          # default 100.0
uncommon_weight: float       # default 50.0
rare_weight: float           # default 20.0
mythic_weight: float         # default 5.0
primordial_weight: float     # default 1.0
unique_weight: float         # default 0.0

# Pricing
buy_price_multiplier: float  # Markup on buying (default 1.0)
sell_price_multiplier: float # Markup on selling (default 0.5)

# Categories
allowed_item_types: Array[Enums.ItemType]  # Filter items
specialty_element: Enums.Element           # Bonus element
```

**Runtime State:**
```gdscript
current_stock: Array[Dictionary]  # [{item, price, quantity}]
buyback_items: Array[Dictionary]  # Items player sold
```

**Key Methods:**

```gdscript
func generate_stock() -> void:
    # Generate random stock from item_pool weighted by rarity
    # Filters by item type and respects weights

func get_stock() -> Array[Dictionary]:
    return current_stock

func get_buyback() -> Array[Dictionary]:
    return buyback_items

func get_stock_item(index: int) -> Dictionary:
    if index >= 0 and index < current_stock.size():
        return current_stock[index]
    return {}

# Transactions return {success: bool, item: ItemData, total_cost/gold_earned: int, quantity: int}
func buy_item(index: int, quantity: int = 1) -> Dictionary:
    # Check affordability, deduct gold, update stock

func sell_item(item: ItemData, quantity: int = 1) -> Dictionary:
    # Add gold to player, add to buyback

func buyback_item(index: int, quantity: int = 1) -> Dictionary:
    # Buy back previously sold item

func get_sell_price(item: ItemData) -> int:
    return int(item.get_value() * sell_price_multiplier)

func clear_buyback() -> void:
    buyback_items.clear()
```

---

## 6. SKILLMANAGER (`autoload/skill_manager.gd`)

Global skill tree and ability management system.

**Key Properties:**
- `_skill_database: Dictionary` - All available skills (skill_id -> SkillData)
- `_unlocked_skills: Dictionary` - Currently unlocked skills
- `_active_ability: SkillData` - Currently equipped active ability
- `_active_ability_cooldown: float` - Cooldown timer
- `_active_ability_ready: bool` - Can use ability
- `_player_stats: Node` - Reference to player's stats component

**Key Signals:**
- `skill_unlocked(skill)` - When skill is learned
- `skill_points_changed(new_amount)` - When skill points change
- `active_ability_changed(skill)` - When active ability swapped
- `active_ability_used(skill)` - When ability is used
- `active_ability_ready(skill)` - When cooldown finishes

**Database Management:**

```gdscript
func _load_skill_database() -> void:
    # Loads all .tres files from res://resources/skills/definitions/

func register_skill(skill: SkillData) -> void:
    _skill_database[skill.skill_id] = skill

func get_skill(skill_id: String) -> SkillData:
    return _skill_database.get(skill_id)

func get_all_skills() -> Array[SkillData]:
    var result: Array[SkillData] = []
    for skill in _skill_database.values():
        result.append(skill)
    return result

func get_skills_by_category(category: Enums.SkillCategory) -> Array[SkillData]:
    # Returns skills filtered by OFFENSE, DEFENSE, UTILITY, ELEMENTAL

func get_skills_by_type(skill_type: Enums.SkillType) -> Array[SkillData]:
    # Returns skills filtered by PASSIVE, ACTIVE, SPELL_AUGMENT
```

**Skill Unlocking:**

```gdscript
func can_unlock_skill(skill_id: String) -> bool:
    # Check: not already unlocked, level requirement, prerequisites, skill points

func unlock_skill(skill_id: String) -> bool:
    # Spend skill points
    # Add to unlocked
    # Apply passive effects if player_stats set
    # Emit signals

func is_skill_unlocked(skill_id: String) -> bool:
    return skill_id in _unlocked_skills

func get_unlocked_skills() -> Array[SkillData]:
    var result: Array[SkillData] = []
    for skill in _unlocked_skills.values():
        result.append(skill)
    return result
```

**Passive Skills:**

```gdscript
func set_player_stats(stats_component: Node) -> void:
    # Call when player is ready
    _player_stats = stats_component
    _apply_all_passives()  # Apply all unlocked passive skills

func _apply_all_passives() -> void:
    # Iterate unlocked PASSIVE skills
    # Call skill.apply_passive_to_stats(_player_stats)

func _remove_all_passives() -> void:
    # Remove all passive modifiers
```

**Active Abilities:**

```gdscript
func set_active_ability(skill_id: String) -> bool:
    # Validates skill is ACTIVE type and unlocked
    # Sets as active ability
    # Emits active_ability_changed

func get_active_ability() -> SkillData:
    return _active_ability

func can_use_active_ability() -> bool:
    # Check: ability exists, cooldown ready, enough magika/stamina

func use_active_ability(caster: Node) -> bool:
    # Consume resources (magika/stamina)
    # Apply effect
    # Start cooldown
    # Emit active_ability_used

func get_active_ability_cooldown() -> float:
    return _active_ability_cooldown

func get_active_ability_cooldown_percent() -> float:
    # Returns 0.0 to 1.0 for UI progress bars
```

**Spell Augments:**

```gdscript
func apply_augments_to_spell(spell: SpellData) -> void:
    # Iterate SPELL_AUGMENT skills
    # Apply multipliers to spell

func get_augments_for_spell(spell: SpellData) -> Array[SkillData]:
    # Return augments that match this spell
```

**Save/Load:**

```gdscript
func initialize_from_save() -> void:
    # Load unlocked skills from SaveManager

func get_save_data() -> Dictionary:
    return {
        "unlocked_skills": _unlocked_skills.keys(),
        "active_ability": _active_ability.skill_id if _active_ability else ""
    }

func load_save_data(data: Dictionary) -> void:
    # Restore from save data
```

---

## 7. SKILLDATA RESOURCE (`resources/skills/skill_data.gd`)

Resource defining a single skill in the skill tree.

**Key Properties:**

```gdscript
# Info
skill_id: String             # Unique identifier
skill_name: String           # Display name
description: String          # Long description
icon: Texture2D              # Icon for UI
skill_type: Enums.SkillType  # PASSIVE, ACTIVE, SPELL_AUGMENT
category: Enums.SkillCategory # OFFENSE, DEFENSE, UTILITY, ELEMENTAL

# Requirements
required_level: int          # Min player level
prerequisite_skills: Array[String]  # Must unlock these first
skill_points_cost: int       # Usually 1

# For PASSIVE skills
stat_modifiers: Dictionary   # StatType -> float value
is_percentage: bool          # If true, values are percentages (0.1 = 10%)

# For ACTIVE skills
ability_effect: SpellEffect  # Effect to apply when used
cooldown: float              # Seconds (default 30.0)
magika_cost: float
stamina_cost: float
duration: float              # 0 = instant
activation_animation: String # Animation to play

# For SPELL_AUGMENT skills
augment_element: Enums.Element  # Element to affect (NONE = all)
augment_delivery: Enums.SpellDelivery  # Delivery type to affect
augment_any_delivery: bool   # If true, ignores delivery filter
damage_multiplier: float
cost_multiplier: float
cooldown_multiplier: float
range_multiplier: float
aoe_multiplier: float
projectile_count_bonus: int
pierce_bonus: int
chain_bonus: int

# Visual
tree_position: Vector2       # Position in skill tree UI
connects_to: Array[String]   # Visual connections to other skills
```

**Key Methods:**

```gdscript
func can_unlock(player_level: int, unlocked_skills: Array) -> bool:
    # Check level and prerequisites

func get_stat_description() -> String:
    # Returns formatted string of stat bonuses

func get_tooltip() -> String:
    # Full tooltip with description, stats, requirements

func apply_passive_to_stats(stats_component: Node) -> void:
    # Apply this PASSIVE skill's modifiers
    # Calls stats_component.add_modifier(stat_type, "skill_" + skill_id, value, is_percentage)

func remove_passive_from_stats(stats_component: Node) -> void:
    # Remove this skill's modifiers

func apply_augment_to_spell(spell: SpellData) -> void:
    # Apply SPELL_AUGMENT multipliers to spell

func matches_spell(spell: SpellData) -> bool:
    # Check if this augment would affect the spell
```

---

## 8. TOWNQUARE / NPC SETUP (`scenes/world/starting_town/town_square.gd`)

Example of how NPCs are spawned and registered in a scene.

**Key Methods:**

```gdscript
func _ready() -> void:
    _spawn_npcs()
    _setup_portals()
    _setup_entrances()
    
    # Register with FastTravelManager
    FastTravelManager.register_spawn_point("starting_town", get_player_spawn_position())

func _spawn_npcs() -> void:
    if spawn_crazy_joe:
        _spawn_npc("crazy_joe", "CrazyJoeSpawn")
    
    if spawn_bob:
        _spawn_npc("bob", "BobSpawn")

func _spawn_npc(npc_id: String, spawn_node_name: String) -> void:
    var spawn_point = npc_spawns.get_node_or_null(spawn_node_name)
    if spawn_point == null:
        push_warning("NPC spawn point not found: " + spawn_node_name)
        return
    
    # Load NPC scene
    var npc_path = "res://scenes/npcs/%s.tscn" % npc_id
    if not ResourceLoader.exists(npc_path):
        # Fallback: create generic NPC
        var npc = _create_generic_npc(npc_id)
        if npc:
            npc.global_position = spawn_point.global_position
            add_child(npc)
            _npcs[npc_id] = npc
            npc_spawned.emit(npc)
        return
    
    var npc_scene = load(npc_path)
    if npc_scene:
        var npc = npc_scene.instantiate()
        npc.global_position = spawn_point.global_position
        add_child(npc)
        _npcs[npc_id] = npc
        npc_spawned.emit(npc)

func get_npc(npc_id: String) -> Node:
    return _npcs.get(npc_id)
```

---

## 9. ENUMS REFERENCE

**Important Enums for NPCs:**

```gdscript
enum SkillType:
    PASSIVE        # Always active stat boost
    ACTIVE         # Usable ability with cooldown
    SPELL_AUGMENT  # Modifies spells

enum SkillCategory:
    OFFENSE        # Damage skills
    DEFENSE        # Survivability
    UTILITY        # Movement, resources
    ELEMENTAL      # Element-specific

enum Element:
    NONE           # For optional fields
    FIRE, WATER, EARTH, AIR
    LIGHT, DARK

enum ItemType:
    STAFF_PART, WAND_PART, GEM
    EQUIPMENT, CONSUMABLE, GRIMOIRE, MISC

enum Rarity:
    BASIC, UNCOMMON, RARE
    MYTHIC, PRIMORDIAL, UNIQUE

enum StatusEffect:
    BURNING, FROZEN, CHILLED, SHOCKED
    POISONED, CURSED, BLINDED, SILENCED
    WEAKENED, VULNERABLE, HASTE
    FORTIFIED, EMPOWERED, REGENERATING
    SHIELDED, INVISIBLE
```

---

## 10. SCENE STRUCTURE EXAMPLES

### NPC Scene Template (crazy_joe.tscn):
```
Node: CrazyJoe (Area3D, NPC script)
├── CollisionShape3D (Capsule collision, body)
├── MeshInstance3D (Visual representation)
└── InteractionArea (Collision shape, interaction sphere)

Properties set in scene:
- npc_name: "Crazy Joe"
- npc_title: "Eccentric Hermit"
- dialogue_lines: [...]
- give_quest_id: "tutorial_landfill"
- npc_id: "crazy_joe"
- interaction_prompt: "[E] Talk to Crazy Joe"
```

### Minimal NPC Creation (code):
```gdscript
var npc = CharacterBody3D.new()
npc.set_script(load("res://scripts/components/npc.gd"))
npc.name = "MyNPC"
npc.npc_name = "My NPC"
npc.npc_id = "my_npc"
npc.dialogue_lines = ["Hello!", "What's up?"]

# Add collision
var collision = CollisionShape3D.new()
var shape = CapsuleShape3D.new()
shape.radius = 0.4
shape.height = 1.8
collision.shape = shape
collision.position = Vector3(0, 0.9, 0)
npc.add_child(collision)

# Add visual
var mesh_instance = MeshInstance3D.new()
var capsule_mesh = CapsuleMesh.new()
mesh_instance.mesh = capsule_mesh
mesh_instance.position = Vector3(0, 0.9, 0)
npc.add_child(mesh_instance)

add_child(npc)
```

---

## 11. WORKFLOW: CREATING AN NPC WITH A SHOP

### Step 1: Create Shop Data Resource
```gdscript
var shop = ShopData.new()
shop.shop_id = "my_shop"
shop.shop_name = "Magic Emporium"
shop.shop_keeper_name = "Merchant Gerald"
shop.item_pool = [item1, item2, item3, ...]  # Array[ItemData]
shop.stock_size = 12
shop.refresh_on_load = true
shop.buy_price_multiplier = 1.0
shop.sell_price_multiplier = 0.5
shop.generate_stock()

# Register with ShopManager (in _ready or during scene setup)
ShopManager.register_shop(shop)
```

### Step 2: Create NPC Scene
```
Node: MyShopkeeper (Area3D, NPC script)
├── CollisionShape3D
├── MeshInstance3D
└── InteractionArea

Properties:
- npc_name: "Merchant Gerald"
- npc_id: "merchant_gerald"
- dialogue_lines: ["Welcome to my shop!", "What can I help you with?"]
- open_shop_on_dialogue_end: true
- shop_id: "my_shop"
```

### Step 3: Spawn in Scene
```gdscript
func _ready() -> void:
    # Register shop first
    var shop = ShopData.new()
    # ... configure shop ...
    ShopManager.register_shop(shop)
    
    # Then spawn NPC
    var npc_scene = load("res://scenes/npcs/my_shopkeeper.tscn")
    var npc = npc_scene.instantiate()
    npc.global_position = spawn_position
    add_child(npc)
```

### Result:
1. Player presses [E] near NPC
2. Dialogue appears with npc_name as speaker
3. Player presses [E] or clicks "Continue" to advance
4. After final dialogue line, dialogue ends
5. NPC.dialogue_ended signal emits
6. Post-dialogue actions trigger:
   - If `open_shop_on_dialogue_end` is true, ShopManager.open_shop(shop_id) is called
   - Shop UI opens, player can buy/sell

---

## 12. KEY CONSTANTS

From `Constants` class:
```gdscript
WALK_SPEED: 5.0
SPRINT_SPEED: 8.0
JUMP_VELOCITY: 6.0
SKILL_POINTS_PER_LEVEL: 2
ACTIVE_ABILITY_COOLDOWN: 30.0

# Collision layers
LAYER_TRIGGERS: 64
LAYER_PLAYERS: 2
LAYER_WORLD: (various)
```

From `Enums` class:
- All enumerations listed in Section 9

---

## 13. SAVE MANAGER INTEGRATION

**For NPC Tracking:**
```gdscript
# In NPC._trigger_post_dialogue_actions():
QuestManager.report_npc_talked(npc_id)  # Records conversation
```

**For Skills:**
```gdscript
# SkillManager loads/saves via SaveManager
SaveManager.player_data.unlocked_skills: Array[String]
SaveManager.player_data.skill_points: int
SaveManager.get_skill_points(): int
SaveManager.use_skill_point(): bool
SaveManager.get_active_ability(): String
SaveManager.set_active_ability(skill_id: String)
```

**For Shops:**
```gdscript
# SaveManager used for gold transactions
SaveManager.has_gold(amount: int): bool
SaveManager.add_gold(amount: int)
SaveManager.remove_gold(amount: int)
```

