## Global enumerations for Magewar
## All game-wide enums are defined here for consistency
class_name Enums
extends RefCounted

# =============================================================================
# GAME STATE
# =============================================================================

enum GameState {
	NONE,
	MAIN_MENU,
	LOBBY,
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER
}

# =============================================================================
# NETWORKING
# =============================================================================

enum NetworkMode {
	OFFLINE,       ## Single player / no network
	STEAM,         ## Steam P2P networking
	ENET           ## Godot ENet fallback
}

enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	FAILED
}

enum LobbyPrivacy {
	PUBLIC,        ## Anyone can join
	FRIENDS_ONLY,  ## Friends only
	PRIVATE        ## Invite only
}

# =============================================================================
# ITEMS & LOOT
# =============================================================================

enum Rarity {
	BASIC,         ## White - common drops
	UNCOMMON,      ## Green - slightly better stats
	RARE,          ## Blue - notable improvements
	MYTHIC,        ## Purple - powerful items
	PRIMORDIAL,    ## Orange - very rare, unique abilities
	UNIQUE         ## Gold - one-of-a-kind named items
}

enum ItemType {
	NONE,
	STAFF_PART,
	WAND_PART,
	GEM,
	EQUIPMENT,
	CONSUMABLE,
	GRIMOIRE,
	MISC
}

enum EquipmentSlot {
	NONE,
	HEAD,          ## Hat
	BODY,          ## Clothes
	BELT,          ## Belt
	FEET,          ## Shoes
	WEAPON_PRIMARY,   ## Staff
	WEAPON_SECONDARY, ## Wand
	GRIMOIRE,      ## Spell book
	POTION         ## Quick-use potion
}

# =============================================================================
# STAFF/WAND PARTS
# =============================================================================

enum StaffPart {
	HEAD,          ## Holds gem slots (1-3)
	EXTERIOR,      ## Shell - affects fire rate
	INTERIOR,      ## Internals - affects damage
	HANDLE,        ## Handling, stability, accuracy
	CHARM          ## Optional augment
}

enum WandPart {
	HEAD,          ## Single gem slot
	EXTERIOR,      ## Shell
	HANDLE         ## Optional
}

# =============================================================================
# ELEMENTS & DAMAGE
# =============================================================================

enum Element {
	NONE,          ## Pure arcane
	FIRE,          ## Burns, DoT
	ICE,           ## Slows, freeze
	LIGHTNING,     ## Chain, stun
	EARTH,         ## Knockback, armor
	WIND,          ## Speed, push
	WATER,         ## Heal, cleanse
	LIGHT,         ## Blind, holy damage
	DARK,          ## Curse, life steal
	SHADOW,        ## Stealth, shadow damage
	HOLY,          ## Holy damage, undead weakness
	ARCANE,        ## Raw magic damage
	POISON         ## Poison damage, DoT
}

enum DamageType {
	PHYSICAL,
	MAGICAL,
	ELEMENTAL,      ## Element-based damage
	SHADOW,         ## Shadow-based damage
	HOLY,           ## Holy-based damage
	TRUE            ## Ignores resistances
}

# =============================================================================
# SPELLS
# =============================================================================

enum SpellDelivery {
	HITSCAN,       ## Instant ray
	PROJECTILE,    ## Traveling projectile
	AOE,           ## Area of effect at point
	BEAM,          ## Continuous ray
	SELF,          ## Cast on self
	SUMMON,        ## Create entity
	CONE,          ## Cone-shaped area
	CHAIN          ## Bounces between targets
}

enum SpellEffectType {
	DAMAGE,        ## Deal damage
	HEAL,          ## Restore health
	BUFF,          ## Positive status effect
	DEBUFF,        ## Negative status effect
	DOT,           ## Damage over time
	HOT,           ## Heal over time
	KNOCKBACK,     ## Push target
	PULL,          ## Pull target
	TELEPORT,      ## Move instantly
	SHIELD,        ## Absorb damage
	SUMMON,        ## Create entity
	MODIFY_STAT    ## Change a stat temporarily
}

enum TargetType {
	ENEMY,
	ALLY,
	SELF,
	ALL,
	GROUND         ## Target location, not entity
}

# =============================================================================
# STATUS EFFECTS
# =============================================================================

enum StatusEffect {
	NONE,
	# Debuffs
	BURNING,       ## Fire DoT
	FROZEN,        ## Cannot move
	CHILLED,       ## Slowed
	SHOCKED,       ## Stunned briefly
	POISONED,      ## Nature DoT
	CURSED,        ## Reduced stats
	BLINDED,       ## Reduced accuracy
	SILENCED,      ## Cannot cast
	WEAKENED,      ## Reduced damage
	VULNERABLE,    ## Takes more damage
	# Buffs
	HASTE,         ## Increased speed
	FORTIFIED,     ## Increased defense
	EMPOWERED,     ## Increased damage
	REGENERATING,  ## Health regen
	SHIELDED,      ## Damage absorption
	INVISIBLE      ## Cannot be targeted
}

# =============================================================================
# PLAYER / COMBAT
# =============================================================================

enum StatType {
	HEALTH,
	MAGIKA,
	STAMINA,
	HEALTH_REGEN,
	MAGIKA_REGEN,
	STAMINA_REGEN,
	MOVE_SPEED,
	CAST_SPEED,
	DAMAGE,
	DEFENSE,
	CRITICAL_CHANCE,
	CRITICAL_DAMAGE
}

enum PlayerState {
	IDLE,
	MOVING,
	SPRINTING,
	JUMPING,
	CROUCHING,
	CASTING,
	STUNNED,
	DEAD
}

# =============================================================================
# ENEMIES
# =============================================================================

enum EnemyType {
	BASIC,         ## Standard mob
	ELITE,         ## Stronger variant
	MINIBOSS,      ## Area boss
	BOSS,          ## Dungeon boss
	DEMON_LORD,    ## Final boss
	# Specific enemy types
	TROLL,         ## Troll enemy
	WRAITH,        ## Wraith enemy
	GOBLIN,        ## Goblin enemy
	SKELETON       ## Skeleton enemy
}

enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	FLEE,
	DEAD
}

# =============================================================================
# QUEST SYSTEM
# =============================================================================

enum QuestState {
	LOCKED,        ## Prerequisites not met
	AVAILABLE,     ## Can be started
	ACTIVE,        ## In progress
	COMPLETED,     ## Finished successfully
	FAILED         ## Failed (timed out, etc.)
}

enum ObjectiveType {
	KILL_ENEMY,       ## Kill X of enemy_type
	KILL_SPECIFIC,    ## Kill a specific named enemy
	COLLECT_ITEM,     ## Collect X of item_id
	TALK_TO_NPC,      ## Talk to npc_id
	DISCOVER_AREA,    ## Enter trigger area
	DEFEAT_BOSS,      ## Defeat boss_id
	SURVIVE_TIME,     ## Stay alive for X seconds in area
	ESCORT_NPC,       ## Keep npc alive until destination
	INTERACT_OBJECT,  ## Interact with specific object
	CUSTOM            ## Script callback for complex logic
}

# =============================================================================
# SKILL SYSTEM
# =============================================================================

enum SkillType {
	PASSIVE,       ## Always active stat boost
	ACTIVE,        ## Usable ability with cooldown
	SPELL_AUGMENT  ## Modifies spells of certain type/element
}

enum SkillCategory {
	OFFENSE,       ## Damage-focused skills
	DEFENSE,       ## Survivability skills
	UTILITY,       ## Movement, resource management
	ELEMENTAL      ## Element-specific augments
}