# NPC System Analysis - Document Index

This directory contains comprehensive analysis of the Magewar NPC system.

## Document Overview

### 1. **NPC_SYSTEM_ANALYSIS.md** (RECOMMENDED FIRST READ)
   - Complete technical documentation
   - All classes and their interfaces
   - Signal definitions
   - Full method signatures
   - Code examples for each system
   - **Use this for:** Deep understanding, implementation reference

### 2. **NPC_QUICK_REFERENCE.md** (QUICK LOOKUP)
   - API quick reference
   - Common patterns and code snippets
   - Signal connections
   - Debugging tips and troubleshooting
   - Common issues and solutions
   - **Use this for:** Quick lookups during development

### 3. **ANALYSIS_SUMMARY.txt** (OVERVIEW)
   - High-level system overview
   - Key findings summary
   - Interaction flow diagrams
   - Scene setup examples
   - Enum and constant reference
   - File locations and line counts
   - **Use this for:** Understanding architecture, integration points

---

## Quick Navigation

### Finding Information

**"How do I create an NPC?"**
→ See NPC_QUICK_REFERENCE.md - "Creating an NPC in Code"

**"How do shops work?"**
→ See NPC_SYSTEM_ANALYSIS.md - Section 4 & 5

**"What signals can I connect to?"**
→ See NPC_QUICK_REFERENCE.md - "Signal Connections"

**"How do skills integrate?"**
→ See NPC_SYSTEM_ANALYSIS.md - Section 6 & 7

**"What's the interaction flow?"**
→ See ANALYSIS_SUMMARY.txt - "INTERACTION FLOW"

**"How do I debug something?"**
→ See NPC_QUICK_REFERENCE.md - "Debugging Tips"

**"What are the file locations?"**
→ See NPC_QUICK_REFERENCE.md - "File Locations"

---

## System Architecture at a Glance

```
Player (FPS Controller)
    ↓ [Presses E]
Interactable (Area3D - Base Class)
    ↓ [Proximity Detection]
NPC (Dialogue & Interactions)
    ├── Dialogue System
    ├── Quest Integration (→ QuestManager)
    ├── Shop Integration (→ ShopManager)
    └── Skill Integration (→ SkillManager)

ShopManager (Global Autoload)
├── ShopData Resources
├── Stock Generation
├── Buy/Sell/Buyback
└── Shop UI

SkillManager (Global Autoload)
├── SkillData Resources
├── Passive Skills (→ StatsComponent)
├── Active Abilities
└── Spell Augments

NamePlate (3D Text Display)
└── [Positioned Above NPC]
```

---

## Key Classes Summary Table

| Class | Type | Purpose | Location |
|-------|------|---------|----------|
| NPC | Component | Main NPC with dialogue | scripts/components/npc.gd |
| Interactable | Component | Base interaction system | scripts/components/interactable.gd |
| NamePlate | Component | 3D name display | scripts/components/name_plate.gd |
| ShopManager | Autoload | Global shop system | autoload/shop_manager.gd |
| ShopData | Resource | Shop definition | resources/shops/shop_data.gd |
| SkillManager | Autoload | Global skill system | autoload/skill_manager.gd |
| SkillData | Resource | Skill definition | resources/skills/skill_data.gd |

---

## Common Implementation Patterns

### Simple Dialogue NPC
```gdscript
npc_name = "Elder"
dialogue_lines = ["Greetings.", "How can I help?"]
```

### Quest Giver
```gdscript
npc_name = "Quest Giver"
dialogue_lines = ["I need your help!"]
give_quest_id = "quest_001"
complete_quest_id = "quest_001"
```

### Shopkeeper
```gdscript
npc_name = "Merchant"
dialogue_lines = ["Welcome!"]
open_shop_on_dialogue_end = true
shop_id = "general_store"
```

### One-Time NPC
```gdscript
one_time_only = true
dialogue_lines = ["Thank you!"]
dialogue_on_complete = "Goodbye..."
```

---

## Critical Integration Points

1. **SaveManager** - Stores gold, skills, quest progress
2. **QuestManager** - NPC dialogue triggers quests
3. **GameManager** - Notifies of map load for shop stock refresh
4. **Player** - Must have `set_input_enabled()` method
5. **HUD** - Must exist at `Game/HUD/PlayerHUD` for prompts

---

## Method Call Chains

### Interaction Chain
```
Player presses [E]
  → Interactable._input()
  → Interactable._try_interact()
  → NPC._perform_interaction()
  → NPC._start_dialogue()
  → NPC._show_dialogue_box()
  → NPC._show_current_line()
```

### Dialogue Advancement
```
Player presses [E] or clicks Continue
  → NPC._advance_dialogue()
  → NPC._show_current_line()
  [Repeat until done]
  → NPC._end_dialogue()
  → NPC._trigger_post_dialogue_actions()
```

### Shop Opening
```
NPC dialogue ends with open_shop_on_dialogue_end = true
  → NPC._trigger_post_dialogue_actions()
  → ShopManager.open_shop(shop_id)
  → ShopManager._show_shop_ui()
  → Shop UI displays current shop stock
```

### Skill Unlock
```
Player has skill points and requirements met
  → SkillManager.unlock_skill(skill_id)
  → SaveManager.use_skill_point()
  → If PASSIVE: skill.apply_passive_to_stats()
  → SkillManager.skill_unlocked signal emits
```

---

## Enums You Need to Know

```gdscript
Enums.SkillType
  PASSIVE      # Always on stat bonus
  ACTIVE       # Ability with cooldown
  SPELL_AUGMENT # Modifies spells

Enums.SkillCategory
  OFFENSE    # Damage skills
  DEFENSE    # Defense skills
  UTILITY    # Utility skills
  ELEMENTAL  # Element-specific

Enums.Rarity
  BASIC, UNCOMMON, RARE, MYTHIC, PRIMORDIAL, UNIQUE

Enums.Element
  FIRE, WATER, EARTH, AIR, LIGHT, DARK
```

---

## File Reference Quick Lookup

**Need to see:** → **Look in:**

NPC core functionality → scripts/components/npc.gd
Interaction system → scripts/components/interactable.gd
Name display → scripts/components/name_plate.gd
Shop management → autoload/shop_manager.gd
Shop definition → resources/shops/shop_data.gd
Skill tree system → autoload/skill_manager.gd
Skill definition → resources/skills/skill_data.gd
Game constants → scripts/data/constants.gd
Game enums → scripts/data/enums.gd
Scene setup example → scenes/world/starting_town/town_square.gd
NPC scene examples → scenes/npcs/crazy_joe.tscn, bob.tscn

---

## Reading Recommendations by Role

### Game Designer
1. ANALYSIS_SUMMARY.txt (overview)
2. NPC_QUICK_REFERENCE.md (patterns)
3. NPC_SYSTEM_ANALYSIS.md (Section 11 - workflow)

### Programmer
1. NPC_SYSTEM_ANALYSIS.md (full reference)
2. NPC_QUICK_REFERENCE.md (API reference)
3. Source code files (implementation details)

### New to Project
1. Start with ANALYSIS_SUMMARY.txt
2. Read NPC_QUICK_REFERENCE.md
3. Check specific sections of NPC_SYSTEM_ANALYSIS.md as needed

---

## Troubleshooting Checklist

- [ ] NPC created and added to scene
- [ ] NPC has npc_id set
- [ ] dialogue_lines is not empty
- [ ] NPC has collision shape for interaction
- [ ] Player in range (check players_in_range)
- [ ] [E] key works for interact
- [ ] Dialogue box appears
- [ ] Dialogue advances
- [ ] Post-dialogue actions execute correctly
- [ ] Shop/quest integration works

---

## Version & Last Updated

Analysis Date: December 2025
Files Analyzed: 12 source files
Total Lines: 1,854 lines of code

---

## Related Documentation

- PHASE1_ARCHITECTURE_OVERVIEW.md - Project architecture
- ITEM_SYSTEM_INDEX.md - Item and shop resources
- QUICK_START.md - Project setup guide

