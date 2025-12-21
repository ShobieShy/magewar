## StatsComponent - Manages Health, Magika, and Stamina
## Handles regeneration, damage, and stat modifications
class_name StatsComponent
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal health_changed(current: float, maximum: float)
signal magika_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal died()
signal respawned()
signal stat_depleted(stat_type: Enums.StatType)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Health")
@export var max_health: float = Constants.DEFAULT_HEALTH
@export var health_regen_rate: float = Constants.HEALTH_REGEN_RATE
@export var health_regen_delay: float = 3.0  # Delay after taking damage

@export_group("Magika")
@export var max_magika: float = Constants.DEFAULT_MAGIKA
@export var magika_regen_rate: float = Constants.MAGIKA_REGEN_RATE
@export var magika_regen_delay: float = 1.0

@export_group("Stamina")
@export var max_stamina: float = Constants.DEFAULT_STAMINA
@export var stamina_regen_rate: float = Constants.STAMINA_REGEN_RATE
@export var stamina_regen_delay: float = Constants.STAMINA_REGEN_DELAY

# =============================================================================
# RUNTIME PROPERTIES
# =============================================================================

var current_health: float = 0.0:
	get:
		return _current_health
	set(value):
		var old_value = _current_health
		_current_health = clampf(value, 0.0, max_health)
		if _current_health != old_value:
			health_changed.emit(_current_health, max_health)
			if _current_health <= 0.0 and old_value > 0.0:
				died.emit()

var current_magika: float = 0.0:
	get:
		return _current_magika
	set(value):
		var old_value = _current_magika
		_current_magika = clampf(value, 0.0, max_magika)
		if _current_magika != old_value:
			magika_changed.emit(_current_magika, max_magika)

var current_stamina: float = 0.0:
	get:
		return _current_stamina
	set(value):
		var old_value = _current_stamina
		_current_stamina = clampf(value, 0.0, max_stamina)
		if _current_stamina != old_value:
			stamina_changed.emit(_current_stamina, max_stamina)
			if _current_stamina <= 0.0 and old_value > 0.0:
				stat_depleted.emit(Enums.StatType.STAMINA)

var is_dead: bool = false

# Backing variables for properties
var _current_health: float = 0.0
var _current_magika: float = 0.0
var _current_stamina: float = 0.0

# Regen timers
var _health_regen_timer: float = 0.0
var _magika_regen_timer: float = 0.0
var _stamina_regen_timer: float = 0.0

# Track time since last damage for regeneration mechanics
var time_since_last_damage: float = 0.0

# Stat modifiers (from buffs, equipment, etc.)
var _stat_modifiers: Dictionary = {}

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Initialize to max values
	reset_stats()


func _process(delta: float) -> void:
	if is_dead:
		return
	
	_process_regeneration(delta)

# =============================================================================
# INITIALIZATION
# =============================================================================

func reset_stats() -> void:
	current_health = max_health
	current_magika = max_magika
	current_stamina = max_stamina
	is_dead = false
	_health_regen_timer = 0.0
	_magika_regen_timer = 0.0
	_stamina_regen_timer = 0.0


func initialize_from_data(data: Dictionary) -> void:
	if data.has("max_health"):
		max_health = data.max_health
	if data.has("max_magika"):
		max_magika = data.max_magika
	if data.has("max_stamina"):
		max_stamina = data.max_stamina
	if data.has("health_regen"):
		health_regen_rate = data.health_regen
	if data.has("magika_regen"):
		magika_regen_rate = data.magika_regen
	if data.has("stamina_regen"):
		stamina_regen_rate = data.stamina_regen
	
	reset_stats()

# =============================================================================
# REGENERATION
# =============================================================================

func _process_regeneration(delta: float) -> void:
	# Track time since last damage
	time_since_last_damage += delta
	
	# Health regeneration
	if _health_regen_timer <= 0.0 and current_health < max_health:
		current_health += _get_modified_stat(Enums.StatType.HEALTH_REGEN, health_regen_rate) * delta
	else:
		_health_regen_timer -= delta
	
	# Magika regeneration
	if _magika_regen_timer <= 0.0 and current_magika < max_magika:
		current_magika += _get_modified_stat(Enums.StatType.MAGIKA_REGEN, magika_regen_rate) * delta
	else:
		_magika_regen_timer -= delta
	
	# Stamina regeneration
	if _stamina_regen_timer <= 0.0 and current_stamina < max_stamina:
		current_stamina += _get_modified_stat(Enums.StatType.STAMINA_REGEN, stamina_regen_rate) * delta
	else:
		_stamina_regen_timer -= delta

# =============================================================================
# HEALTH
# =============================================================================

func take_damage(amount: float, damage_type: Enums.DamageType = Enums.DamageType.MAGICAL) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	
	# Apply defense modifier (except for true damage)
	var actual_damage = amount
	if damage_type != Enums.DamageType.TRUE:
		var defense = _get_modified_stat(Enums.StatType.DEFENSE, 0.0)
		actual_damage = maxf(amount - defense, amount * 0.1)  # Min 10% damage
	
	current_health -= actual_damage
	_health_regen_timer = health_regen_delay
	time_since_last_damage = 0.0  # Reset damage timer
	
	if current_health <= 0.0:
		is_dead = true
	
	return actual_damage


func heal(amount: float) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	
	var old_health = current_health
	current_health += amount
	return current_health - old_health


func respawn() -> void:
	is_dead = false
	reset_stats()
	respawned.emit()

# =============================================================================
# MAGIKA
# =============================================================================

func use_magika(amount: float) -> bool:
	if amount <= 0.0:
		return true
	
	if current_magika >= amount:
		current_magika -= amount
		_magika_regen_timer = magika_regen_delay
		return true
	
	return false


func has_magika(amount: float) -> bool:
	return current_magika >= amount


func restore_magika(amount: float) -> float:
	var old_magika = current_magika
	current_magika += amount
	return current_magika - old_magika

# =============================================================================
# STAMINA
# =============================================================================

func use_stamina(amount: float) -> bool:
	if amount <= 0.0:
		return true
	
	if current_stamina >= amount:
		current_stamina -= amount
		_stamina_regen_timer = stamina_regen_delay
		return true
	
	return false


func has_stamina(amount: float) -> bool:
	return current_stamina >= amount


func drain_stamina(amount: float) -> void:
	## Drain stamina over time (e.g., for sprinting)
	current_stamina -= amount
	_stamina_regen_timer = stamina_regen_delay


func restore_stamina(amount: float) -> float:
	var old_stamina = current_stamina
	current_stamina += amount
	return current_stamina - old_stamina

# =============================================================================
# STAT MODIFIERS
# =============================================================================

func add_modifier(stat_type: Enums.StatType, modifier_id: String, value: float, is_percentage: bool = false) -> void:
	if not _stat_modifiers.has(stat_type):
		_stat_modifiers[stat_type] = {}
	
	_stat_modifiers[stat_type][modifier_id] = {
		"value": value,
		"is_percentage": is_percentage
	}


func remove_modifier(stat_type: Enums.StatType, modifier_id: String) -> void:
	if _stat_modifiers.has(stat_type):
		_stat_modifiers[stat_type].erase(modifier_id)


func clear_modifiers(stat_type: Enums.StatType = Enums.StatType.HEALTH) -> void:
	## Clear modifiers for a specific stat or all stats if stat_type is null
	## Note: Pass HEALTH to clear a specific stat (arbitrary choice since enum has no NONE)
	## Use clear_all_modifiers() to clear everything
	_stat_modifiers.erase(stat_type)


func clear_all_modifiers() -> void:
	## Clear all stat modifiers at once
	_stat_modifiers.clear()


func _get_modified_stat(stat_type: Enums.StatType, base_value: float) -> float:
	var result = base_value
	var percentage_bonus = 1.0
	
	if _stat_modifiers.has(stat_type):
		for modifier_data in _stat_modifiers[stat_type].values():
			if modifier_data.is_percentage:
				percentage_bonus += modifier_data.value
			else:
				result += modifier_data.value
	
	return result * percentage_bonus

# =============================================================================
# GETTERS
# =============================================================================

func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


func get_magika_percent() -> float:
	return current_magika / max_magika if max_magika > 0 else 0.0


func get_stamina_percent() -> float:
	return current_stamina / max_stamina if max_stamina > 0 else 0.0


func get_stat(stat_type: Enums.StatType) -> float:
	match stat_type:
		Enums.StatType.HEALTH:
			return current_health
		Enums.StatType.MAGIKA:
			return current_magika
		Enums.StatType.STAMINA:
			return current_stamina
		Enums.StatType.HEALTH_REGEN:
			return _get_modified_stat(stat_type, health_regen_rate)
		Enums.StatType.MAGIKA_REGEN:
			return _get_modified_stat(stat_type, magika_regen_rate)
		Enums.StatType.STAMINA_REGEN:
			return _get_modified_stat(stat_type, stamina_regen_rate)
		_:
			return _get_modified_stat(stat_type, 0.0)
