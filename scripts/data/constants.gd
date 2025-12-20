## Global constants for Magewar
## All game-wide constants are defined here for easy tuning
class_name Constants
extends RefCounted

# =============================================================================
# NETWORKING
# =============================================================================

const MAX_PLAYERS: int = 6
const STEAM_APP_ID: int = 480  # Spacewar test app ID
const DEFAULT_PORT: int = 7777
const TICK_RATE: int = 60
const NETWORK_INTERPOLATION_OFFSET: float = 0.1

# =============================================================================
# PLAYER DEFAULTS
# =============================================================================

const DEFAULT_HEALTH: float = 100.0
const DEFAULT_MAGIKA: float = 100.0
const DEFAULT_STAMINA: float = 100.0

const HEALTH_REGEN_RATE: float = 1.0      # Per second
const MAGIKA_REGEN_RATE: float = 5.0      # Per second
const STAMINA_REGEN_RATE: float = 15.0    # Per second

const STAMINA_REGEN_DELAY: float = 1.0    # Seconds after use before regen starts

# =============================================================================
# LEVELING & SKILLS
# =============================================================================

const SKILL_POINTS_PER_LEVEL: int = 2
const MAX_LEVEL: int = 50
const ACTIVE_ABILITY_COOLDOWN: float = 30.0  # Base cooldown for active abilities

# =============================================================================
# MOVEMENT
# =============================================================================

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const CROUCH_SPEED: float = 2.5
const JUMP_VELOCITY: float = 6.0
const GRAVITY_MULTIPLIER: float = 2.0

const MOUSE_SENSITIVITY: float = 0.002
const CONTROLLER_SENSITIVITY: float = 3.0

const MAX_LOOK_UP: float = 89.0    # Degrees
const MAX_LOOK_DOWN: float = -89.0 # Degrees

const SPRINT_STAMINA_COST: float = 10.0   # Per second
const JUMP_STAMINA_COST: float = 15.0     # Per jump

# =============================================================================
# COMBAT
# =============================================================================

const DEFAULT_CAST_TIME: float = 0.0
const GLOBAL_COOLDOWN: float = 0.25       # Minimum time between casts
const HITSCAN_RANGE: float = 100.0
const DEFAULT_PROJECTILE_SPEED: float = 30.0

const CRITICAL_CHANCE_BASE: float = 0.05  # 5%
const CRITICAL_DAMAGE_MULTIPLIER: float = 1.5

const FRIENDLY_FIRE_DAMAGE_MULTIPLIER: float = 0.5  # When enabled

# Charged attack modifiers (Staff secondary fire)
const CHARGED_ATTACK_DAMAGE_MULT: float = 2.0      # 200% damage
const CHARGED_ATTACK_COST_MULT: float = 2.5        # 250% magika cost
const CHARGED_ATTACK_COOLDOWN_MULT: float = 1.5    # 150% cooldown

# =============================================================================
# LOOT & ITEMS
# =============================================================================

## Rarity drop weights (higher = more common)
const RARITY_WEIGHTS: Dictionary = {
	Enums.Rarity.BASIC: 100,
	Enums.Rarity.UNCOMMON: 50,
	Enums.Rarity.RARE: 20,
	Enums.Rarity.MYTHIC: 5,
	Enums.Rarity.PRIMORDIAL: 1,
	Enums.Rarity.UNIQUE: 0  # Never random drop, specific sources only
}

## Rarity stat multipliers
const RARITY_STAT_MULTIPLIERS: Dictionary = {
	Enums.Rarity.BASIC: 1.0,
	Enums.Rarity.UNCOMMON: 1.15,
	Enums.Rarity.RARE: 1.35,
	Enums.Rarity.MYTHIC: 1.6,
	Enums.Rarity.PRIMORDIAL: 2.0,
	Enums.Rarity.UNIQUE: 2.5  # Plus unique effects
}

## Rarity colors for UI
const RARITY_COLORS: Dictionary = {
	Enums.Rarity.BASIC: Color.WHITE,
	Enums.Rarity.UNCOMMON: Color.GREEN,
	Enums.Rarity.RARE: Color.DODGER_BLUE,
	Enums.Rarity.MYTHIC: Color.MEDIUM_PURPLE,
	Enums.Rarity.PRIMORDIAL: Color.ORANGE,
	Enums.Rarity.UNIQUE: Color.GOLD
}

const INVENTORY_SIZE: int = 40
const STORAGE_SIZE: int = 100             # Home Tree storage chest
const LOOT_PICKUP_RANGE: float = 2.0
const LOOT_DESPAWN_TIME: float = 300.0    # 5 minutes

# Gold
const GOLD_DROP_BASE: int = 5             # Base gold from basic enemies
const GOLD_DROP_ELITE_MULT: float = 3.0   # Elite enemies drop 3x
const GOLD_DROP_BOSS_MULT: float = 10.0   # Bosses drop 10x
const SELL_PRICE_MULTIPLIER: float = 0.5  # Items sell for 50% of value

# =============================================================================
# STAFF/WAND
# =============================================================================

const STAFF_GEM_SLOTS_MIN: int = 1
const STAFF_GEM_SLOTS_MAX: int = 3
const WAND_GEM_SLOTS: int = 1

# =============================================================================
# UI
# =============================================================================

const UI_FADE_DURATION: float = 0.2
const DAMAGE_NUMBER_DURATION: float = 1.0
const DAMAGE_NUMBER_RISE: float = 50.0    # Pixels

# =============================================================================
# SAVE SYSTEM
# =============================================================================

const SAVE_VERSION: int = 1
const PLAYER_SAVE_FILE: String = "user://player_save.dat"
const WORLD_SAVE_FILE: String = "user://world_save.dat"
const SETTINGS_FILE: String = "user://settings.cfg"
const AUTO_SAVE_INTERVAL: float = 60.0    # Seconds

# =============================================================================
# RESPAWN
# =============================================================================

const RESPAWN_TIME: float = 5.0           # Seconds before respawn at checkpoint
const DEATH_CAMERA_TIME: float = 2.0      # Seconds to show death camera

# =============================================================================
# PHYSICS LAYERS
# =============================================================================

## Layer 1: World geometry
## Layer 2: Players
## Layer 3: Enemies
## Layer 4: Projectiles
## Layer 5: Pickups/Loot
## Layer 6: Triggers/Areas

const LAYER_WORLD: int = 1
const LAYER_PLAYERS: int = 2
const LAYER_ENEMIES: int = 3
const LAYER_PROJECTILES: int = 4
const LAYER_PICKUPS: int = 5
const LAYER_TRIGGERS: int = 6
const LAYER_ENVIRONMENT: int = 7
