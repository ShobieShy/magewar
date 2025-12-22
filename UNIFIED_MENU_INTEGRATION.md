# Unified Menu UI Integration

## Overview

The pause menu, inventory system, and skill tree have been integrated into a single unified menu accessible via keyboard shortcuts. Users can easily switch between different panels without closing and reopening the menu.

## Files Modified/Created

### New Files:
- **`scenes/ui/menus/unified_menu_ui.gd`** - Main unified menu controller (1100+ lines)

### Modified Files:
- **`scenes/main/game.gd`** - Updated to instantiate and manage the unified menu
- **`scenes/player/player.gd`** - Added public `inventory` property for unified menu access
- **`project.godot`** - Added `skill_tree` input binding (K key)

## Features

### 1. Single Entry Point (Esc Key)
- Press **Esc** to toggle the unified menu open/closed
- Menu opens in the Pause tab by default
- Game pauses while menu is open
- Mouse becomes visible when menu is open

### 2. Three Integrated Tabs

#### Tab 1: Pause Menu (Tab Index 0)
- **Resume Game** - Closes menu and resumes gameplay
- **Join Player** - Placeholder for multiplayer joining
- **Settings** - Opens settings menu while keeping pause state
- **Quit to Menu** - Returns to main menu

#### Tab 2: Inventory (Tab Index 1)
- **Access via**: Esc → Tab, or I key, or Tab key when menu is open
- **Left Panel**: Equipment slots (Head, Primary Weapon, Body, Secondary Weapon, Belt, Grimoire, Feet, Potion)
- **Right Panel**: Inventory grid (8 columns × configurable rows)
- **Features**:
  - Gold display in top-right corner
  - Player level and XP progress in left panel
  - Item tooltips on hover
  - Context menu (right-click) for Use/Equip/Unequip/Drop
  - Drag-and-drop item management
  - Full item slot validation to prevent duplication

#### Tab 3: Skill Tree (Tab Index 2)
- **Access via**: Esc → K key, or K key when menu is open
- **Left Panel**: Skill category tabs (Offense, Defense, Utility, Elemental)
- **Right Panel**: Skill details and actions
- **Features**:
  - Skill points display in header
  - Interactive skill nodes showing state (locked, unlockable, unlocked)
  - Detailed skill information (name, type, category, description, effects)
  - **Unlock Skill** button with prerequisite checking
  - **Set as Active Ability** button for active skills
  - Real-time updates when skills are unlocked

## Input Bindings

| Action | Key | Function |
|--------|-----|----------|
| `pause` | Esc | Toggle unified menu open/closed |
| `inventory` | Tab / I | Switch to Inventory tab (when menu is open) |
| `skill_tree` | K | Switch to Skill Tree tab (when menu is open) |

## How to Use

### Opening the Menu
1. Press **Esc** to open the unified menu
2. Game pauses automatically
3. Mouse cursor becomes visible

### Navigating Between Tabs
**From Pause Tab:**
- Press **I** or **Tab** to go to Inventory
- Press **K** to go to Skill Tree

**From Inventory Tab:**
- Press **I** or **Tab** again to return to Pause
- Press **K** to go to Skill Tree

**From Skill Tree Tab:**
- Press **K** again to return to Pause
- Press **I** or **Tab** to go to Inventory

### Closing the Menu
- Press **Esc** from any tab to close and resume gameplay
- Click **Resume Game** from the Pause tab

## Technical Architecture

### UnifiedMenuUI Class

**Extends**: CanvasLayer
**Layer**: 128 (top layer)

#### Key Properties:
- `_is_open: bool` - Menu visibility state
- `_is_paused: bool` - Game pause state
- `_current_tab: MenuTab` - Active tab (PAUSE=0, INVENTORY=1, SKILLS=2)
- `_inventory_system: Node` - Reference to player's inventory

#### Key Methods:
- `open()` - Opens menu and pauses game
- `close()` - Closes menu and resumes game
- `set_inventory_system(inventory: Node)` - Set inventory to display
- `_switch_tab(tab: MenuTab)` - Switch to specific tab

#### Signals Emitted:
- `menu_opened` - When menu is opened
- `menu_closed` - When menu is closed
- `tab_changed(tab_name: String)` - When tab switches
- `settings_requested` - When settings button is pressed
- `quit_to_menu_requested` - When quit button is pressed
- `join_requested` - When join button is pressed

### Integration with Game

**File**: `scenes/main/game.gd`

The unified menu is instantiated in `_setup_unified_menu()`:

```gdscript
func _setup_unified_menu() -> void:
    unified_menu = UNIFIED_MENU_SCENE.new()
    add_child(unified_menu)
    
    # Pass inventory system reference
    var player = _get_local_player()
    if player and player.inventory:
        unified_menu.set_inventory_system(player.inventory)
    
    # Connect signals
    unified_menu.settings_requested.connect(_on_unified_menu_settings)
    unified_menu.quit_to_menu_requested.connect(_on_unified_menu_quit)
    unified_menu.join_requested.connect(_on_unified_menu_join)
```

### Data Synchronization

The unified menu listens to several manager signals for real-time updates:

**SaveManager**:
- `gold_changed` - Updates gold display in inventory
- `player_data.level` - Shows current player level

**SkillManager**:
- `skill_unlocked` - Refreshes skill node states
- `skill_points_changed` - Updates skill points display

## Interaction Details

### Inventory System
- Full drag-and-drop support for items
- Equipment slot validation
- Context menus for item actions
- Item tooltip system
- Automatic display refresh on any change

### Skill Tree System
- Click skill nodes to view details
- Prerequisites are checked before unlocking
- Skill points cost is displayed
- Active abilities can be set from here
- Visual feedback for locked/unlockable/unlocked skills

## Visual Design

### Color Scheme
- **Background**: Dark semi-transparent overlay (50% opacity)
- **Panels**: Dark with subtle borders (RGB: 0.12, 0.12, 0.15)
- **Text**: Light gray (default) to white (headers)
- **Gold**: Bright yellow (RGB: 1.0, 0.85, 0.0)
- **Skill Points**: Light blue (RGB: 0.8, 0.8, 1.0)

### Layout
- **Pause Tab**: Centered column of buttons
- **Inventory Tab**: Two-column layout (Equipment left, Inventory right)
- **Skill Tree Tab**: Two-column layout (Tree left, Details right)

## Performance Considerations

1. **Lazy Loading**: Skill tree is only populated when the tab is viewed
2. **Signal Optimization**: Only updates relevant displays (inventory gold only updates when tab is active)
3. **Memory Management**: Proper signal disconnection in `_exit_tree()` to prevent memory leaks
4. **Item Validation**: Comprehensive checks prevent duplication bugs

## Migration from Old System

### Old Behavior
- Pause menu: Esc key
- Inventory: I/Tab key (separate instance)
- Skill tree: K key (separate instance)
- Three separate menus that had to be closed to access each other

### New Behavior
- All three accessible from single Esc key
- Switch between them without closing menu
- Shared game pause state
- Unified mouse mode management

## Future Enhancements

Possible improvements for future iterations:

1. **Settings Menu Integration** - Move settings to a fourth tab
2. **Character Stats Tab** - Add character stats/attributes display
3. **Quest Log Integration** - Add active quests to the menu
4. **Minimap** - Add minimap panel to the menu
5. **Keybind Customization** - Allow users to customize tab hotkeys
6. **Menu Resizing** - Make menu panels resizable
7. **Animation Transitions** - Add smooth tab-switching animations
8. **Keyboard Navigation** - Full keyboard-only navigation support

## Debugging

### Common Issues

**Menu won't open**
- Check that `unified_menu` is not null in game.gd
- Verify Esc key is properly bound in project.godot

**Inventory not showing**
- Ensure `inventory` property getter works on player
- Check that `set_inventory_system()` is called with valid system

**Skills not visible**
- Verify SkillManager has `get_all_skills()` method
- Check that skills have valid `tree_position` property

**Performance Issues**
- Monitor signal connections for memory leaks
- Check if skill tree is being repopulated unnecessarily

## Testing Checklist

- [x] Menu opens/closes with Esc
- [x] Tab switching works (I/Tab/K keys)
- [x] Game pauses when menu opens
- [x] Game resumes when menu closes
- [x] Inventory items display correctly
- [x] Equipment slots work with drag-and-drop
- [x] Context menus work
- [x] Skill tree shows all categories
- [x] Skill details update on selection
- [x] Unlock button works with prerequisites
- [x] Active ability button works
- [x] Gold and level display updates
- [x] Skill points display updates
- [x] All buttons connect to proper handlers
- [x] Menu closes after settings/quit
- [x] Mouse visibility toggles correctly
