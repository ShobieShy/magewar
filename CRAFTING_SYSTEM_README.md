# Complete Crafting Logic System

## Overview

This is a comprehensive crafting system for the co-op looter FPS game that handles weapon creation from parts and gems, recipe discovery, rarity calculation, and achievement tracking.

## System Architecture

### Core Components

1. **WeaponConfiguration** (`weapon_configuration.gd`)
   - Data structure for weapon assembly
   - Manages parts, gems, stats, and calculations
   - Handles validation and configuration logic

2. **CraftingRecipe** (`crafting_recipe.gd`)
   - Recipe data structure for discovered combinations
   - Matching logic for configurations
   - Discovery chance calculations

3. **CraftingAchievement** (`crafting_achievement.gd`)
   - Achievement tracking system
   - Progress calculation and unlocking logic
   - Reward distribution

4. **CraftingLogic** (`crafting_logic.gd`)
   - Main crafting controller
   - Handles crafting process, timing, and success calculations
   - Integrates with inventory and skill systems

### Manager Classes

1. **CraftingRecipeManager** (`crafting_recipe_manager.gd`)
   - Recipe database and discovery system
   - Recipe matching and validation
   - Discovery progress tracking

2. **CraftingAchievementManager** (`crafting_achievement_manager.gd`)
   - Achievement database and progress tracking
   - Event processing and unlocking
   - Statistics and completion tracking

3. **CraftingManager** (`crafting_manager.gd`)
   - Global access point for all crafting functionality
   - Unified interface for crafting operations
   - Event aggregation and forwarding

### Integration Layer

1. **CraftingIntegration** (`crafting_integration.gd`)
   - Bridge between Assembly UI and Crafting Logic
   - Handles UI communication and data extraction
   - Provides status updates and feedback

## Key Features

### 1. Weapon Creation
- Supports both staff and wand creation
- Modular part system (head, exterior, interior, handle, charm)
- Gem socketing with elemental effects
- Dynamic stat calculation based on parts and gems
- Rarity-based stat multipliers

### 2. Recipe System
- Automatic recipe discovery through crafting
- Recipe matching with configuration validation
- Discovery chance based on player level and skill
- Recipe unlocking and tracking
- Different difficulty tiers for recipes

### 3. Achievement System
- Comprehensive achievement tracking
- Multiple achievement categories:
  - Quantity (craft X weapons)
  - Type (craft X staffs/wands)
  - Quality (craft rare/mythic weapons)
  - Materials (use specific parts/gems)
  - Discovery (discover X recipes)
- Progress tracking and rewards
- Rarity-based achievement tiers

### 4. Rarity Calculation
- Dynamic rarity based on part and gem rarities
- Rarity affects success chance, craft time, and cost
- Visual feedback through color coding
- Rarity multipliers for stats and value

### 5. Craft Time and Success
- Variable craft times based on complexity
- Player skill and level affect success rates
- Difficulty modifiers
- Visual progress feedback

## Integration Points

### Assembly UI Integration
The crafting system is designed to work seamlessly with the existing Assembly UI:

```gdscript
# In AssemblyUI.gd, connect to crafting system
var crafting_integration = CraftingIntegration.new()
crafting_integration.initialize(self)

# Handle crafting requests
func _on_craft_pressed() -> void:
    crafting_integration._on_assembly_item_crafted("staff")
```

### Inventory System Integration
- Validates material availability
- Consumes parts and gems during crafting
- Adds crafted weapons to inventory

### Save System Integration
- Saves discovered recipes
- Stores achievement progress
- Persists crafting statistics

### Skill System Integration
- Crafting skill affects success rates
- Skill provides time and cost bonuses
- Experience rewards for successful crafting

## Usage Examples

### Basic Crafting
```gdscript
# Create configuration
var config = WeaponConfiguration.new()
config.weapon_type = "staff"

# Add parts
var head = get_staff_head_part()
config.add_part(head)

# Add gems
var gem = get_fire_gem()
config.add_gem(gem)

# Start crafting
CraftingManager.craft_weapon(config, player_level)
```

### Recipe Discovery
```gdscript
# Find matching recipes
var recipes = CraftingManager.find_matching_recipes(config, player_level)

# Check if any recipes can be crafted
for recipe in recipes:
    if CraftingManager.validate_configuration(config).is_empty():
        print("Can craft: %s" % recipe.recipe_name)
```

### Achievement Progress
```gdscript
# Get achievement statistics
var stats = CraftingManager.get_achievement_stats()
print("Completion: %.1f%%" % stats.completion_rate)

# Get near completion achievements
var near = CraftingManager.get_near_completion_achievements(0.8)
for achievement in near:
    print("Almost there: %s (%.1f%%)" % [achievement.achievement_name, achievement.get_progress_percentage()])
```

## Configuration

### Crafting Settings
- `enable_crafting`: Enable/disable crafting system
- `base_crafting_time`: Base time for crafting operations
- `max_crafting_time`: Maximum crafting time cap
- `DIFFICULTY_MULTIPLIERS`: Success rate modifiers by difficulty

### Rarity Multipliers
Located in `constants.gd`:
- `RARITY_STAT_MULTIPLIERS`: Affect weapon stats
- `RARITY_COLORS`: Visual color coding
- `RARITY_WEIGHTS`: Drop chance weights

## Testing

### Test Suite
Run the comprehensive test suite:
```gdscript
var test = CraftingSystemTest.new()
add_child(test)
```

### Demo Script
Run the interactive demo:
```gdscript
var demo = CraftingDemo.new()
add_child(demo)
```

## File Structure
```
scripts/systems/
├── weapon_configuration.gd      # Configuration data class
├── crafting_recipe.gd          # Recipe data class
├── crafting_achievement.gd     # Achievement data class
├── crafting_logic.gd           # Main crafting system
├── crafting_recipe_manager.gd   # Recipe management
├── crafting_achievement_manager.gd # Achievement management
├── crafting_manager.gd          # Global crafting access
├── crafting_integration.gd       # UI integration layer
├── save_manager_extension.gd    # Save system extensions
├── crafting_system_test.gd      # Test suite
└── crafting_demo.gd             # Interactive demo
```

## Data Flow

1. **Configuration**: Player selects parts/gems in Assembly UI
2. **Validation**: System validates configuration completeness
3. **Calculation**: Stats, rarity, time, and cost are calculated
4. **Crafting**: Crafting process starts with timer and success chance
5. **Discovery**: Check for recipe discoveries
6. **Achievements**: Update achievement progress
7. **Creation**: Create and add weapon to inventory
8. **Rewards**: Distribute experience and gold rewards

## Error Handling

The system includes comprehensive error handling for:
- Invalid configurations
- Missing materials
- Insufficient gold
- Inventory full conditions
- System unavailability
- Network issues (for co-op)

## Performance Considerations

- Efficient recipe matching algorithms
- Minimal memory allocations during crafting
- Lazy loading of achievement and recipe data
- Optimized stat calculations
- Background saving for large datasets

## Extensibility

The system is designed to be easily extended:
- New weapon types through enum extensions
- New part types through StaffPart enum
- New achievement categories
- Additional crafting modifiers
- Custom recipe conditions
- Plugin-like expansion system

## Co-op Integration

The crafting system supports co-op play through:
- Shared recipe discoveries
- Group achievement progress
- Material sharing systems
- Crafting station cooperation
- Network-synchronized crafting state

## Security

- Server-side validation in multiplayer
- Anti-exploit protection
- Secure data transmission
- Input sanitization
- Resource consumption limits