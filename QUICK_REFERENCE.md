# Magewar-AI: Quick Reference Guide

## At a Glance
- **Status:** ✅ Production Ready
- **Completion:** ~35-40% of full vision
- **Codebase:** 100+ GDScript files, ~4,700 lines (scenes), all systems working
- **Last Updated:** December 19, 2025 (all bugs fixed)

---

## What's Fully Implemented (READY TO USE)

### Core Systems
- ✅ Crafting system (weapon assembly, recipes, achievements)
- ✅ Inventory & equipment management
- ✅ Combat & spell system (7 spells, multiple effects)
- ✅ Potion quick-use system (4 types, hotkey-based)
- ✅ Grimoire augmentation system
- ✅ Skill tree (15 passive/active skills)
- ✅ Quest system with objectives
- ✅ Save/load with corruption prevention
- ✅ Multiplayer foundation

### Content
- ✅ Story: Prologue + Chapter 1 complete
- ✅ Locations: Starting town with 3 areas
- ✅ Enemies: 6 types with variants (13 scene files)
- ✅ Items: 15 weapon parts + 5 gems + equipment
- ✅ NPCs: Bob, Joe, shopkeepers, quest givers
- ✅ UI: 13+ menus fully implemented

### Infrastructure
- ✅ 12 autoload manager systems
- ✅ Component-based architecture
- ✅ Object pooling for projectiles
- ✅ Network synchronization
- ✅ Steam API integration

---

## What Needs Work (PRIORITY ORDER)

### CRITICAL (Do First)
1. **Story Content** - Chapters 2-16 (only outlines exist)
2. **Dungeons 2-5** - Design and populate
3. **Boss Encounters** - Demon Lord, Joe, dungeon bosses
4. **Additional Towns** - Town 2, Small Town

### HIGH PRIORITY
5. Enemy AI (patrol routes, advanced behaviors)
6. Equipment slots (Hat, Clothes, Belt, Shoes UI)
7. Character customization
8. More enemy variants

### MEDIUM PRIORITY
9. Advanced features (trading, guilds, leaderboards)
10. Quality of life (minimap, compass, tutorial)
11. Content expansion (more spells, items, variants)

### LOW PRIORITY
12. Visual polish (particles, animations, sound)
13. Optimization passes
14. Endgame content (raids, seasonal events)

---

## File Map (Find Things Quickly)

```
Core Game Logic
├── scenes/main/game.gd          - Game scene controller
├── scenes/player/player.gd      - Character controller
├── scenes/weapons/staff.gd      - Staff system
└── scenes/weapons/wand.gd       - Wand system

Combat & Spells
├── scenes/spells/projectile.gd  - Projectile mechanics
├── scripts/components/spell_caster.gd - Casting system
├── resources/spells/            - Spell definitions
└── scripts/systems/spell_manager.gd

Inventory & Items
├── scripts/systems/inventory_system.gd
├── autoload/item_database.gd
├── autoload/gem_database.gd
├── resources/items/             - All item data
└── scenes/ui/menus/inventory_ui.gd

Crafting
├── scenes/ui/menus/assembly_ui.gd      - Crafting UI
├── scenes/world/assembly_station.gd    - Crafting station
├── scripts/systems/crafting_*.gd       - 12 crafting files
└── resources/items/parts/               - Weapon parts

Enemies
├── scenes/enemies/enemy_base.gd - Base class for all
├── scenes/enemies/*.tscn        - Individual enemy scenes
└── resources/enemies/*.gd       - Enemy data

UI & Menus
├── scenes/ui/menus/             - All menu scenes
├── scenes/ui/hud/               - HUD display
├── scenes/ui/components/        - Reusable UI widgets
└── scenes/ui/dialogue_box.gd    - NPC dialogue

Quests & Story
├── autoload/quest_manager.gd    - Quest system
├── autoload/cutscene_manager.gd - Story cutscenes
├── resources/quests/            - Quest data
└── resources/dialogue/          - Dialogue data

World & Locations
├── scenes/world/                - All locations
├── scenes/world/starting_town/  - Starting area
├── scenes/world/landfill/       - Tutorial dungeon
├── scenes/dungeons/             - Dungeon scenes
└── scenes/objects/              - Portals, pickups, etc
```

---

## Key Managers (Autoload Services)

| Manager | Purpose | Key Methods |
|---------|---------|-------------|
| GameManager | Game state & scene loading | change_state(), load_scene() |
| NetworkManager | Multiplayer sessions | host_game(), join_game() |
| SaveManager | Save/load progress | save_game(), load_game() |
| QuestManager | Quest tracking | add_quest(), complete_quest() |
| SkillManager | Skill tree & abilities | unlock_skill(), use_ability() |
| ItemDatabase | Item definitions | get_item(), get_rarity_color() |
| GemDatabase | Gem definitions | get_gem(), apply_gem_effect() |
| ShopManager | NPC commerce | buy_item(), sell_item() |
| SpellManager | Spell management | register_spell(), learn_spell() |
| FastTravelManager | Teleportation | travel_to(), register_location() |
| CutsceneManager | Story sequences | play_cutscene(), add_dialogue() |
| SteamManager | Steam API | initialize(), get_achievements() |

---

## Development Tips

### Adding a New Quest
1. Create QuestData resource in `/resources/quests/definitions/chapter*/`
2. Add quest objectives
3. Hook into QuestManager.add_quest()
4. Add dialogue triggers in NPC scripts
5. Create cutscenes if needed

### Adding a New Enemy
1. Create EnemyData resource in `/resources/enemies/`
2. Create .tscn file extending EnemyBase
3. Implement special abilities if needed
4. Add to enemy spawner systems
5. Create loot table

### Adding a New Spell
1. Create SpellData resource in `/resources/spells/presets/`
2. Define spell effects (damage, heal, status, etc.)
3. Register with SpellManager
4. Create projectile prefab if ranged
5. Add to spell UI/hotbar system

### Adding New Equipment Slot
1. Create UI in inventory (hat_slot, clothes_slot, etc.)
2. Define data class (HatData, ClothesData)
3. Link stat bonuses in equipment system
4. Add cosmetic variants
5. Create equipment generation in loot system

---

## Performance Notes

### Currently Good
- Object pooling for projectiles
- Efficient inventory management
- Data-driven design reduces memory
- Signal-based systems avoid polling

### Could Be Better
- Enemy spawner optimization
- UI update efficiency
- Save file size
- Network message batching

---

## Testing Checklist

Before deployment, verify:
- [ ] All quests play through without error
- [ ] Crafting succeeds consistently
- [ ] Combat doesn't crash
- [ ] Multiplayer spawns players correctly
- [ ] Save/load preserves player state
- [ ] No memory leaks on extended play (1+ hour)
- [ ] UI responds to all inputs
- [ ] Enemies spawn and behave correctly

---

## Common Code Patterns

### Accessing a Manager
```gdscript
GameManager.change_state(Enums.GameState.PLAYING)
SaveManager.save_game()
QuestManager.add_quest(quest_id)
```

### Creating an Item Drop
```gdscript
var loot = LOOT_SCENE.instantiate()
loot.position = position
loot.item_data = item
add_sibling(loot)
```

### Emitting Damage
```gdscript
stats.take_damage(amount, damage_type, attacker)
```

### Playing a Sound
```gdscript
# Add AudioStreamPlayer3D to scene
$AudioStreamPlayer3D.play()
```

### Making Something Glow
```gdscript
# Add StandardMaterial3D with emission
material.emission_enabled = true
material.emission = color
```

---

## Known Limitations

1. **Limited to 5 Dungeons** - Design supports up to 5, more requires architecture changes
2. **Flat Network** - All players connect to host; consider region servers for 50+ players
3. **Inventory Size Fixed** - 20 slots; would need UI redesign for larger
4. **No True Guilds** - Current party system is ad-hoc only
5. **Limited Boss Mechanics** - Would need animation system for complex patterns

---

## Quick Start for New Developers

1. Read Magewar Bible.md (game design)
2. Read Magewar Storyline.md (narrative)
3. Review PROJECT_ANALYSIS.md (architecture overview)
4. Check which system you'll work on
5. Look at existing examples in `/scenes/` or `/scripts/systems/`
6. Follow the component pattern (inherit from existing base classes)
7. Use signals for event communication
8. Add to manager systems if it's global functionality

---

## Contact/Questions

- **Architecture Questions:** Check PROJECT_ANALYSIS.md
- **System Implementation:** Check CRAFTING_IMPLEMENTATION_SUMMARY.md
- **Known Issues:** Check DIAGNOSTIC_REPORT.md
- **Recent Fixes:** Check FIXES_APPLIED.md

---

**Last Updated:** December 19, 2025  
**Status:** ✅ All systems functional, production-ready for content development

