## ConsumableData - Usable items like potions
## Can restore health, magika, stamina, or apply effects
class_name ConsumableData
extends ItemData

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Consumable Type")
@export var consumable_type: ConsumableType = ConsumableType.HEALTH_POTION
@export var use_sound: AudioStream

@export_group("Restoration")
@export var health_restore: float = 0.0
@export var health_restore_percent: float = 0.0  ## Percentage of max health
@export var magika_restore: float = 0.0
@export var magika_restore_percent: float = 0.0
@export var stamina_restore: float = 0.0
@export var stamina_restore_percent: float = 0.0

@export_group("Effects")
@export var apply_status: Enums.StatusEffect = Enums.StatusEffect.NONE
@export var status_duration: float = 0.0
@export var spell_effect: SpellEffect  ## Custom effect to apply

@export_group("Usage")
@export var cooldown: float = 1.0  ## Time before can use another
@export var use_time: float = 0.0  ## Channel time (0 = instant)
@export var can_use_in_combat: bool = true

# =============================================================================
# ENUM
# =============================================================================

enum ConsumableType {
	HEALTH_POTION,
	MAGIKA_POTION,
	STAMINA_POTION,
	BUFF_POTION,
	ANTIDOTE,
	FOOD,
	SCROLL,
	OTHER
}

# =============================================================================
# STATIC COOLDOWN TRACKING
# =============================================================================

static var _last_use_time: float = 0.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	item_type = Enums.ItemType.CONSUMABLE
	stackable = true
	max_stack = 99

# =============================================================================
# METHODS
# =============================================================================

func can_use() -> bool:
	# Check cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_use_time < cooldown:
		return false
	
	return true


func use(user: Node) -> bool:
	if not can_use():
		return false
	
	var stats = user.get_node_or_null("StatsComponent") as StatsComponent
	if stats == null:
		return false
	
	# Apply restoration
	_apply_restoration(stats)
	
	# Apply status effect
	if apply_status != Enums.StatusEffect.NONE:
		_apply_status_effect(user, stats)
	
	# Apply spell effect
	if spell_effect:
		# Create temporary spell data for effect application
		var temp_spell = SpellData.new()
		spell_effect.apply(user, user, user.global_position, temp_spell)
	
	# Play sound
	if use_sound:
		_play_use_sound(user)
	
	# Update cooldown
	_last_use_time = Time.get_ticks_msec() / 1000.0
	
	return true


func _apply_restoration(stats: StatsComponent) -> void:
	# Health
	if health_restore > 0:
		stats.heal(health_restore)
	if health_restore_percent > 0:
		stats.heal(stats.max_health * health_restore_percent)
	
	# Magika
	if magika_restore > 0:
		stats.restore_magika(magika_restore)
	if magika_restore_percent > 0:
		stats.restore_magika(stats.max_magika * magika_restore_percent)
	
	# Stamina
	if stamina_restore > 0:
		stats.restore_stamina(stamina_restore)
	if stamina_restore_percent > 0:
		stats.restore_stamina(stats.max_stamina * stamina_restore_percent)


func _apply_status_effect(user: Node, stats: StatsComponent) -> void:
	# Try to apply via StatusEffectComponent if exists
	var status_component = user.get_node_or_null("StatusEffectComponent")
	if status_component and status_component.has_method("apply_status"):
		status_component.apply_status(apply_status, status_duration)
	else:
		# Fallback: apply stat modifiers directly based on status
		_apply_status_as_modifier(stats)


func _apply_status_as_modifier(stats: StatsComponent) -> void:
	var modifier_id = "consumable_status_" + str(randi())
	
	match apply_status:
		Enums.StatusEffect.HASTE:
			stats.add_modifier(Enums.StatType.MOVE_SPEED, modifier_id, 0.3, true)
		Enums.StatusEffect.FORTIFIED:
			stats.add_modifier(Enums.StatType.DEFENSE, modifier_id, 20.0, false)
		Enums.StatusEffect.EMPOWERED:
			stats.add_modifier(Enums.StatType.DAMAGE, modifier_id, 0.2, true)
		Enums.StatusEffect.REGENERATING:
			stats.add_modifier(Enums.StatType.HEALTH_REGEN, modifier_id, 10.0, false)
	
	# Remove modifier after duration
	if status_duration > 0:
		var timer = stats.get_tree().create_timer(status_duration)
		timer.timeout.connect(func(): 
			stats.remove_modifier(Enums.StatType.MOVE_SPEED, modifier_id)
			stats.remove_modifier(Enums.StatType.DEFENSE, modifier_id)
			stats.remove_modifier(Enums.StatType.DAMAGE, modifier_id)
			stats.remove_modifier(Enums.StatType.HEALTH_REGEN, modifier_id)
		)


func _play_use_sound(user: Node) -> void:
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = use_sound
	audio_player.finished.connect(audio_player.queue_free)
	user.add_child(audio_player)
	audio_player.play()

# =============================================================================
# TOOLTIP
# =============================================================================

func get_tooltip() -> String:
	var tooltip = super.get_tooltip()
	
	tooltip += "\n\n[u]Effects:[/u]\n"
	
	if health_restore > 0:
		tooltip += "Restores %.0f Health\n" % health_restore
	if health_restore_percent > 0:
		tooltip += "Restores %.0f%% Health\n" % (health_restore_percent * 100)
	if magika_restore > 0:
		tooltip += "Restores %.0f Magika\n" % magika_restore
	if magika_restore_percent > 0:
		tooltip += "Restores %.0f%% Magika\n" % (magika_restore_percent * 100)
	if stamina_restore > 0:
		tooltip += "Restores %.0f Stamina\n" % stamina_restore
	if stamina_restore_percent > 0:
		tooltip += "Restores %.0f%% Stamina\n" % (stamina_restore_percent * 100)
	
	if apply_status != Enums.StatusEffect.NONE:
		var status_name = Enums.StatusEffect.keys()[apply_status]
		tooltip += "Applies %s for %.1fs\n" % [status_name.capitalize(), status_duration]
	
	if cooldown > 0:
		tooltip += "\n[color=gray]Cooldown: %.1fs[/color]" % cooldown
	
	return tooltip
