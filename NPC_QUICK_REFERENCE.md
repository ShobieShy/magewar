# NPC SYSTEM - QUICK REFERENCE GUIDE

## Most Important Classes

1. **NPC** (`scripts/components/npc.gd`) - Main NPC class
2. **Interactable** (`scripts/components/interactable.gd`) - Base interaction class
3. **NamePlate** (`scripts/components/name_plate.gd`) - 3D name display
4. **ShopManager** (`autoload/shop_manager.gd`) - Global shop system
5. **ShopData** (`resources/shops/shop_data.gd`) - Shop definition
6. **SkillManager** (`autoload/skill_manager.gd`) - Skill tree system
7. **SkillData** (`resources/skills/skill_data.gd`) - Skill definition

---

## Quick API Reference

### Creating an NPC in Code

```gdscript
var npc = Node.new()
npc.set_script(load("res://scripts/components/npc.gd"))
npc.npc_name = "MyNPC"
npc.npc_id = "my_npc"
npc.dialogue_lines = ["Hello!", "How are you?"]
add_child(npc)
```

### Creating a Shop-Keeping NPC

```gdscript
# Create shop
var shop = ShopData.new()
shop.shop_id = "my_shop"
shop.shop_name = "My Shop"
shop.shop_keeper_name = "Shopkeeper Name"
shop.item_pool = [item1, item2, ...]  # ItemData resources
shop.generate_stock()
ShopManager.register_shop(shop)

# Create NPC
var npc = Node.new()
npc.set_script(load("res://scripts/components/npc.gd"))
npc.npc_name = "Shopkeeper Name"
npc.npc_id = "shopkeeper"
npc.dialogue_lines = ["Welcome!"]
npc.open_shop_on_dialogue_end = true
npc.shop_id = "my_shop"
add_child(npc)
```

### Accessing NPCs from a Scene

```gdscript
# If you spawn them in _ready()
var npc = get_node("MyNPC")
npc.npc_name = "Updated Name"

# Or from town_square pattern
var npc = town_square.get_npc("npc_id")
```

### Interacting with Shops

```gdscript
# Open a shop
ShopManager.open_shop("shop_id")

# Get current shop
var shop = ShopManager.get_current_shop()

# Buy item
ShopManager.buy_item(index, quantity)

# Sell item
ShopManager.sell_item(item_data, quantity)

# Close shop
ShopManager.close_shop()

# Check if open
if ShopManager.is_shop_open():
    print("Shop is open")
```

### Skill System API

```gdscript
# Unlock a skill
if SkillManager.can_unlock_skill("skill_id"):
    SkillManager.unlock_skill("skill_id")

# Get active ability
var ability = SkillManager.get_active_ability()

# Set active ability
SkillManager.set_active_ability("skill_id")

# Use active ability
if SkillManager.can_use_active_ability():
    SkillManager.use_active_ability(player)

# Get skill info
var skill = SkillManager.get_skill("skill_id")
print(skill.get_tooltip())
```

---

## Common Patterns

### Pattern 1: Simple Dialogue NPC
```gdscript
npc_name = "Elder"
npc_id = "elder"
dialogue_lines = ["Greetings, young one.", "How may I help?"]
dialogue_on_complete = "Come back if you need anything."
```

### Pattern 2: Quest Giver
```gdscript
npc_name = "Quest Giver"
npc_id = "quest_giver"
dialogue_lines = ["I have a task for you.", "Will you help?"]
give_quest_id = "quest_001"
complete_quest_id = "quest_001"  # for turn-in
```

### Pattern 3: Shopkeeper
```gdscript
npc_name = "Merchant"
npc_id = "merchant"
dialogue_lines = ["Welcome to my shop!"]
open_shop_on_dialogue_end = true
shop_id = "general_store"
```

### Pattern 4: One-Time NPC
```gdscript
npc_name = "Lost Traveler"
one_time_only = true
dialogue_lines = ["Thank you for helping me!"]
dialogue_on_complete = "I'm long gone now..."
```

---

## File Locations

```
/scripts/components/
├── npc.gd
├── interactable.gd
├── name_plate.gd
├── ...

/autoload/
├── shop_manager.gd
├── skill_manager.gd
├── quest_manager.gd
├── ...

/resources/
├── shops/shop_data.gd
├── skills/skill_data.gd
└── skills/definitions/*.tres

/scenes/
├── npcs/
│   ├── crazy_joe.tscn
│   └── bob.tscn
└── world/starting_town/town_square.gd
```

---

## Signal Connections

### NPC Signals
```gdscript
npc.dialogue_started.connect(_on_dialogue_started)
npc.dialogue_ended.connect(_on_dialogue_ended)
npc.interaction_started.connect(_on_interaction_started)
npc.player_entered_range.connect(_on_player_entered)
npc.player_exited_range.connect(_on_player_exited)
```

### ShopManager Signals
```gdscript
ShopManager.shop_opened.connect(_on_shop_opened)
ShopManager.shop_closed.connect(_on_shop_closed)
ShopManager.item_purchased.connect(_on_item_purchased)
ShopManager.item_sold.connect(_on_item_sold)
ShopManager.stock_refreshed.connect(_on_stock_refreshed)
```

### SkillManager Signals
```gdscript
SkillManager.skill_unlocked.connect(_on_skill_unlocked)
SkillManager.skill_points_changed.connect(_on_skill_points_changed)
SkillManager.active_ability_changed.connect(_on_ability_changed)
SkillManager.active_ability_used.connect(_on_ability_used)
SkillManager.active_ability_ready.connect(_on_ability_ready)
```

---

## Key Methods to Know

### NPC Methods
- `_perform_interaction(player)` - Override this for custom interaction
- `_start_dialogue(player)` - Begin dialogue sequence
- `_end_dialogue()` - End dialogue and trigger actions
- `_trigger_post_dialogue_actions()` - Runs quests, shop, NPC tracking

### Interactable Methods
- `set_interactable(value: bool)` - Enable/disable interaction
- `_try_interact()` - Called when [E] pressed
- `_show_interact_prompt(player)` - Shows "[E] Talk to..." text
- `_hide_interact_prompt(player)` - Hides prompt

### NamePlate Methods
- `set_name_plate_text(text: String)` - Change display name
- `set_name_plate_color(color: Color)` - Change text color

### ShopManager Methods
- `register_shop(shop: ShopData)` - Register a shop
- `open_shop(shop_id: String) -> bool` - Open shop UI
- `close_shop()` - Close shop
- `buy_item(index: int, quantity: int) -> bool`
- `sell_item(item: ItemData, quantity: int) -> bool`

### SkillManager Methods
- `unlock_skill(skill_id: String) -> bool`
- `set_active_ability(skill_id: String) -> bool`
- `use_active_ability(caster: Node) -> bool`
- `apply_augments_to_spell(spell: SpellData)`

---

## Debugging Tips

### Check if NPC is set up correctly
```gdscript
var npc = get_node("NPC")
print("NPC Name: ", npc.npc_name)
print("Dialogue Lines: ", npc.dialogue_lines)
print("In Range Players: ", npc.players_in_range.size())
print("Can Interact: ", npc.can_interact)
```

### Check shop status
```gdscript
var shop = ShopManager.get_shop("shop_id")
if shop:
    print("Stock: ", shop.get_stock().size())
    print("Buyback: ", shop.get_buyback().size())
```

### Check skill status
```gdscript
print("Unlocked: ", SkillManager.is_skill_unlocked("skill_id"))
print("Can Unlock: ", SkillManager.can_unlock_skill("skill_id"))
print("Active Ability: ", SkillManager.get_active_ability())
print("Cooldown: ", SkillManager.get_active_ability_cooldown_percent())
```

---

## Common Issues & Solutions

**Issue**: Dialogue doesn't show
- Check `dialogue_lines` is not empty
- Verify player is in range (check `players_in_range`)
- Ensure NPC has collision setup for interaction

**Issue**: Shop doesn't open
- Verify shop is registered: `ShopManager.get_shop(shop_id) != null`
- Check `open_shop_on_dialogue_end = true`
- Verify `shop_id` matches registered shop

**Issue**: Interaction prompt doesn't show
- Check HUD exists at `Game/HUD/PlayerHUD`
- Verify `interaction_prompt` is set
- Ensure `can_interact = true`

**Issue**: Skills don't unlock
- Check skill points available: `SaveManager.get_skill_points()`
- Verify level requirement met: `skill.required_level <= player_level`
- Check prerequisites are unlocked

---

## Performance Notes

- **Shop Stock Generation**: Called once on registration, then on map load if `refresh_on_load = true`
- **Skill Database**: Loaded once in `_ready()` from resource files
- **Dialogue Box**: Created dynamically on first dialogue, reused afterward
- **Nameplate**: Created once per NPC, uses billboard mode for camera-facing

