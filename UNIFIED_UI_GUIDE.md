# Unified UI System - Complete Guide

## Overview

The Unified Menu UI consolidates all in-game menus and systems into a single, tabbed interface accessible via the **Escape** key. This provides a cohesive, easy-to-navigate experience for players.

## Access & Navigation

### Opening the Unified Menu
- **Press Escape** or **Tab** to toggle the unified menu open/closed
- Menu pauses the game when opened
- Mouse mode switches to visible for menu interaction

### Tab Navigation

The unified menu contains 11 integrated tabs accessible via keyboard shortcuts:

| Tab | Keyboard Shortcut | Description |
|-----|------------------|-------------|
| **Pause** | Esc | Resume, Join, Settings, Quit options |
| **Inventory** | Tab / I | Equipment slots + inventory grid |
| **Skills** | K | Skill tree with categories + details |
| **Stats** | - | Character stat allocation |
| **Settings** | S | Audio, Video, Gameplay options |
| **Shop** | H | Merchant shop interface |
| **Crafting** | C | Item crafting system |
| **Refinement** | R | Item enhancement/upgrade |
| **Storage** | D | Storage/chest management |
| **Quests** | Q | Quest log and tracking |
| **Fast Travel** | M | Map and fast travel locations |

### Examples
```
Press Escape → Opens unified menu (pauses game)
Press Tab/I → Switch to Inventory tab
Press K → Switch to Skills tab
Press S → Switch to Settings tab
Press Escape again → Close menu (resumes game)
```

## Tab Details

### 1. Pause Tab
**Keyboard:** Default tab when opening menu

Features:
- Resume Game button - continues gameplay
- Join Player button - multiplayer functionality
- Settings button - access settings panel
- Quit to Menu button - return to main menu

### 2. Inventory Tab
**Keyboard:** Tab or I

Features:
- **Equipment Slots (Left):** 8 equipment slots (Head, Weapons, Body, Belt, Grimoire, Feet, Potion)
- **Inventory Grid (Right):** 8x8 grid for items (96 item slots)
- **Gold Display:** Shows current gold amount
- **Level Progress:** Displays player level and experience percentage
- **Drag & Drop:** Rearrange items, equip/unequip by dragging
- **Right-Click Menu:** Quick actions (Use, Equip, Drop, etc.)
- **Item Tooltip:** Hover over items to see details

### 3. Skills Tab
**Keyboard:** K

Features:
- **Skill Categories (Left):** Offense, Defense, Utility, Elemental
- **Skill List:** Browse all skills in each category
- **Skill Details (Right):** 
  - Skill name and type
  - Description and effects
  - Unlock requirements
  - Button to unlock or set as active ability
- **Skill Points Display:** Shows available skill points

### 4. Stats Tab
**Keyboard:** No dedicated shortcut (access via clicking or Tab navigation)

Features:
- Character statistics display
- Stat point allocation for level progression
- Base stats and bonuses from equipment

### 5. Settings Tab
**Keyboard:** S

Features:

**Audio:**
- Master Volume slider (0-100)
- Music Volume slider (0-100)
- SFX Volume slider (0-100)

**Gameplay:**
- Mouse Sensitivity slider (0.1-2.0)
- Show Damage Numbers toggle
- Friendly Fire toggle

Settings are automatically saved.

### 6. Shop Tab
**Keyboard:** H

Features:
- Populate dynamically when interacting with shopkeepers
- Buy tab - browse merchant inventory
- Sell tab - sell items to merchant
- Buyback tab - repurchase previously sold items
- Item details and pricing

### 7. Crafting Tab
**Keyboard:** C

**Status:** Placeholder - ready for Assembly system integration

### 8. Refinement Tab
**Keyboard:** R

**Status:** Placeholder - ready for item enhancement system integration

### 9. Storage Tab
**Keyboard:** D

**Status:** Placeholder - ready for storage/chest system integration

### 10. Quests Tab
**Keyboard:** Q

**Status:** Placeholder - ready for quest log integration

### 11. Fast Travel Tab
**Keyboard:** M

**Status:** Placeholder - ready for map/fast travel system integration

## Input Handling

### In-Menu Input
When the unified menu is open:
- **Escape** - Close menu and resume game
- **Tab / I** - Switch to Inventory
- **K** - Switch to Skills
- **S** - Switch to Settings
- **H** - Switch to Shop
- **C** - Switch to Crafting
- **R** - Switch to Refinement
- **D** - Switch to Storage
- **Q** - Switch to Quests
- **M** - Switch to Fast Travel
- **Right-Click** - Context menus in Inventory
- **Double-Click** - Quick actions in Inventory

### Escape Behavior
- Menu closed = Escape resumes normal gameplay
- Menu open = Escape closes menu

## Technical Architecture

### File Location
- **Main Script:** `scenes/ui/menus/unified_menu_ui.gd` (1350+ lines)
- **Scene Reference:** Created dynamically by `game.gd` at game startup

### Components
- **CanvasLayer:** Layer 128 (ensures menu appears on top)
- **TabContainer:** Central navigation between tabs
- **PanelContainers:** Styled panels for each tab
- **ColorRect:** Semi-transparent background dimmer

### Styling
- **Background:** Dark theme (RGB 0.12, 0.12, 0.15 with 95% opacity)
- **Borders:** Dark gray (RGB 0.3, 0.3, 0.35)
- **Rounded Corners:** 8px radius
- **Text Colors:** White for primary, Gold for currency, Light blue for special text

### Signal Integration
The unified menu connects to these manager signals:
- `SaveManager.gold_changed` - Updates gold display
- `SkillManager.skill_unlocked` - Refreshes skill tree
- `SkillManager.skill_points_changed` - Updates point display

## Integration with Game Systems

### Inventory System
- Directly accesses `player.inventory` for item data
- Supports drag-drop, context menus, and quick actions
- Equipment slots sync with player equipped items

### Shop System
- ShopManager dynamically populates Shop tab
- Triggers when player interacts with shopkeeper NPC
- Uses same ItemSlot components as inventory

### Skill System
- SkillManager provides skill data and unlock requirements
- Displays all 4 skill categories with filterable view
- Supports skill unlocking and active ability selection

### Save System
- Gold and item data automatically synced with SaveManager
- Settings changes auto-saved

## Customization & Extension

### Adding a New Tab

1. **Add to MenuTab enum:**
```gdscript
enum MenuTab {
    PAUSE = 0,
    ...
    MY_NEW_TAB = 11
}
```

2. **Add property:**
```gdscript
var _my_new_panel: Control
```

3. **Create tab function:**
```gdscript
func _create_my_new_tab() -> void:
    _my_new_panel = PanelContainer.new()
    _my_new_panel.name = "MyNewTab"
    _apply_panel_style(_my_new_panel)
    _tab_container.add_child(_my_new_panel)
    # ... populate with content
```

4. **Call in _create_ui():**
```gdscript
_create_my_new_tab()
```

5. **Update _switch_tab() and _on_tab_changed():**
```gdscript
MenuTab.MY_NEW_TAB:
    pass  # Or add refresh logic
```

6. **Add keyboard shortcut in _input():**
```gdscript
elif event is InputEventKey and event.pressed:
    match event.keycode:
        KEY_X:  # Your shortcut
            _switch_tab(MenuTab.MY_NEW_TAB)
```

## Performance Considerations

### Memory Usage
- All 11 tabs instantiated at game startup
- Total memory: ~500KB-1MB for all UI elements
- Acceptable trade-off for instant tab switching

### Frame Rate
- No visible performance impact when menu is open
- Game pauses when menu is active (no simultaneous processing)
- Tab switching is instantaneous

### Optimization Tips
- Complex tabs (like Shop) are populated dynamically
- Simple tabs are static panels to minimize overhead
- Tooltips are created on-demand, not cached

## Troubleshooting

### Menu won't open
- Check that Escape/Tab input actions are bound in project.godot
- Verify game is not in a dialog or cutscene state
- Ensure Input.mouse_mode isn't locked

### Tabs don't switch
- Check keyboard input isn't being consumed elsewhere
- Verify UnifiedMenuUI script is loaded (check _ready() calls)
- Confirm menu is open (check _is_open flag)

### Items don't appear in Inventory
- Verify player has inventory system initialized
- Check SaveManager has gold data
- Ensure items have proper ItemData class type

### Settings don't persist
- Verify SaveManager.gold_changed signal is connected
- Check settings are being saved to SaveManager

## Future Enhancements

1. **Full Settings Panel Integration**
   - Extract complete SettingsMenu into unified settings tab
   - Add video/graphics options

2. **Crafting System**
   - Integrate assembly_ui.gd
   - Add recipe browsing and crafting interface

3. **Refinement System**
   - Integrate refinement_ui.gd
   - Add item upgrade interface

4. **Quest Log**
   - Integrate quest_log.gd
   - Add quest tracking and objectives

5. **Fast Travel**
   - Integrate fast_travel_menu.gd
   - Add interactive map

6. **Storage System**
   - Integrate storage_ui.gd
   - Add multi-container management

7. **UI Polish**
   - Add tab scroll arrows if tabs exceed screen width
   - Implement tab favorites/pinning
   - Add search functionality across tabs

## Related Files

- `autoload/game_manager.gd` - Game state management
- `autoload/save_manager.gd` - Persistent data storage
- `autoload/skill_manager.gd` - Skill system
- `autoload/shop_manager.gd` - Shop system
- `scenes/main/game.gd` - Unified menu instantiation
- `scripts/systems/inventory_system.gd` - Item management

## Summary

The Unified UI System provides a professional, cohesive interface for all in-game menus. With 11 integrated tabs, consistent styling, and intuitive keyboard shortcuts, players can access all game systems from a single menu panel. The modular design allows for easy expansion and customization.
