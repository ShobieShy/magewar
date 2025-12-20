## PotionSystem - Manages quick-use potion slots and consumption
class_name PotionSystem
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal potion_used(potion: PotionData)
signal potion_equipped(slot: int, potion: PotionData)
signal potion_unequipped(slot: int)
signal cooldown_started(slot: int, duration: float)
signal cooldown_finished(slot: int)

# =============================================================================
# CONSTANTS
# =============================================================================

const MAX_POTION_SLOTS = 4
const GLOBAL_COOLDOWN = 1.0  # Global cooldown between any potion use

# =============================================================================
# PROPERTIES
# =============================================================================

## Quick-use potion slots
var potion_slots: Array[PotionData] = []
var slot_quantities: Array[int] = []
var slot_cooldowns: Array[float] = []

## References
var player: Node = null
var inventory_system: Node = null
var stats_component: Node = null

## Cooldown tracking
var global_cooldown_timer: float = 0.0
var slot_timers: Array[Timer] = []

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Initialize slots
	for i in MAX_POTION_SLOTS:
		potion_slots.append(null)
		slot_quantities.append(0)
		slot_cooldowns.append(0.0)
		
		# Create timer for each slot
		var timer = Timer.new()
		timer.one_shot = true
		timer.timeout.connect(_on_slot_cooldown_finished.bind(i))
		add_child(timer)
		slot_timers.append(timer)

func _process(delta: float) -> void:
	# Update global cooldown
	if global_cooldown_timer > 0:
		global_cooldown_timer = max(0, global_cooldown_timer - delta)
	
	# Update slot cooldowns for UI
	for i in MAX_POTION_SLOTS:
		if slot_cooldowns[i] > 0:
			slot_cooldowns[i] = max(0, slot_cooldowns[i] - delta)

func _input(event: InputEvent) -> void:
	# Quick-use potion hotkeys (1-4)
	for i in MAX_POTION_SLOTS:
		if event.is_action_pressed("potion_%d" % (i + 1)):
			use_potion(i)

# =============================================================================
# INITIALIZATION
# =============================================================================

func initialize(player_ref: Node, inventory: Node, stats: Node) -> void:
	player = player_ref
	inventory_system = inventory
	stats_component = stats

# =============================================================================
# POTION MANAGEMENT
# =============================================================================

func equip_potion(slot: int, potion: PotionData) -> bool:
	## Equip a potion to a quick-use slot
	if slot < 0 or slot >= MAX_POTION_SLOTS:
		push_warning("Invalid potion slot: %d" % slot)
		return false
	
	if not potion:
		unequip_potion(slot)
		return true
	
	# Check if player has the potion in inventory
	var quantity = inventory_system.get_item_count(potion.item_id) if inventory_system else 1
	if quantity <= 0:
		push_warning("No potions of type %s in inventory" % potion.item_name)
		return false
	
	# Unequip current potion if any
	if potion_slots[slot]:
		unequip_potion(slot)
	
	# Equip new potion
	potion_slots[slot] = potion
	slot_quantities[slot] = quantity
	
	potion_equipped.emit(slot, potion)
	return true

func unequip_potion(slot: int) -> void:
	## Remove a potion from a quick-use slot
	if slot < 0 or slot >= MAX_POTION_SLOTS:
		return
	
	potion_slots[slot] = null
	slot_quantities[slot] = 0
	slot_cooldowns[slot] = 0.0
	
	if slot_timers[slot].time_left > 0:
		slot_timers[slot].stop()
	
	potion_unequipped.emit(slot)

func use_potion(slot: int) -> bool:
	## Use a potion from a quick-use slot
	if slot < 0 or slot >= MAX_POTION_SLOTS:
		return false
	
	var potion = potion_slots[slot]
	if not potion:
		return false
	
	# Check global cooldown
	if global_cooldown_timer > 0:
		push_warning("Global potion cooldown active")
		return false
	
	# Check slot cooldown
	if slot_cooldowns[slot] > 0:
		push_warning("Potion on cooldown: %.1f seconds" % slot_cooldowns[slot])
		return false
	
	# Check quantity
	if slot_quantities[slot] <= 0:
		push_warning("No potions remaining in slot %d" % slot)
		unequip_potion(slot)
		return false
	
	# Check if player can use potion (not dead, not in cutscene, etc.)
	if not can_use_potion():
		return false
	
	# Apply potion effects
	apply_potion_effects(potion)
	
	# Consume from inventory
	if inventory_system:
		inventory_system.remove_item(potion.item_id, 1)
		slot_quantities[slot] = inventory_system.get_item_count(potion.item_id)
	else:
		slot_quantities[slot] -= 1
	
	# Start cooldowns
	global_cooldown_timer = GLOBAL_COOLDOWN
	slot_cooldowns[slot] = potion.cooldown
	slot_timers[slot].wait_time = potion.cooldown
	slot_timers[slot].start()
	
	cooldown_started.emit(slot, potion.cooldown)
	potion_used.emit(potion)
	
	# Unequip if no more potions
	if slot_quantities[slot] <= 0:
		unequip_potion(slot)
	
	return true

func can_use_potion() -> bool:
	## Check if player can currently use potions
	if not stats_component:
		return true
	
	# Can't use potions when dead
	if stats_component.current_health <= 0:
		return false
	
	# Add other conditions as needed (stunned, silenced, etc.)
	return true

func apply_potion_effects(potion: PotionData) -> void:
	## Apply the effects of a potion to the player
	if not stats_component:
		push_warning("No stats component to apply potion effects")
		return
	
	# Instant effects
	if potion.instant_health > 0:
		stats_component.heal(potion.instant_health)
	
	if potion.instant_mana > 0:
		stats_component.restore_mana(potion.instant_mana)
	
	if potion.instant_stamina > 0:
		stats_component.restore_stamina(potion.instant_stamina)
	
	# Apply buffs/debuffs
	if potion.buff_duration > 0:
		apply_potion_buff(potion)
	
	# Special effects
	if potion.remove_debuffs:
		stats_component.clear_debuffs()
	
	if potion.grant_immunity_duration > 0:
		stats_component.grant_immunity(potion.grant_immunity_duration)
	
	# Visual/audio feedback
	if player:
		show_potion_effect(potion)

func apply_potion_buff(potion: PotionData) -> void:
	## Apply temporary buffs from a potion
	if not stats_component:
		return
	
	var buff_data = {
		"name": potion.item_name,
		"duration": potion.buff_duration,
		"health_regen": potion.health_regen_per_second,
		"mana_regen": potion.mana_regen_per_second,
		"damage_boost": potion.damage_multiplier,
		"defense_boost": potion.defense_multiplier,
		"speed_boost": potion.movement_speed_multiplier,
		"resistances": {
			"physical": potion.physical_resistance_buff,
			"magical": potion.magical_resistance_buff
		}
	}
	
	stats_component.apply_buff(buff_data)

func show_potion_effect(potion: PotionData) -> void:
	## Show visual feedback for potion use
	if not player:
		return
	
	# Create particle effect
	var effect_color = Color.GREEN
	if potion.instant_health > 0:
		effect_color = Color.GREEN
	elif potion.instant_mana > 0:
		effect_color = Color.BLUE
	elif potion.instant_stamina > 0:
		effect_color = Color.YELLOW
	
	# This would create actual particle effects in the game
	print("Potion used: %s (Effect color: %s)" % [potion.item_name, effect_color])

# =============================================================================
# SLOT MANAGEMENT
# =============================================================================

func update_slot_quantities() -> void:
	## Update quantities from inventory
	if not inventory_system:
		return
	
	for i in MAX_POTION_SLOTS:
		if potion_slots[i]:
			slot_quantities[i] = inventory_system.get_item_count(potion_slots[i].item_id)
			if slot_quantities[i] <= 0:
				unequip_potion(i)

func get_slot_info(slot: int) -> Dictionary:
	## Get information about a potion slot
	if slot < 0 or slot >= MAX_POTION_SLOTS:
		return {}
	
	return {
		"potion": potion_slots[slot],
		"quantity": slot_quantities[slot],
		"cooldown": slot_cooldowns[slot],
		"cooldown_percent": slot_cooldowns[slot] / potion_slots[slot].cooldown if potion_slots[slot] else 0.0
	}

func _on_slot_cooldown_finished(slot: int) -> void:
	slot_cooldowns[slot] = 0.0
	cooldown_finished.emit(slot)

# =============================================================================
# SAVE/LOAD
# =============================================================================

func get_save_data() -> Dictionary:
	var equipped_potions = []
	for i in MAX_POTION_SLOTS:
		if potion_slots[i]:
			equipped_potions.append({
				"slot": i,
				"potion_id": potion_slots[i].item_id
			})
	
	return {
		"equipped_potions": equipped_potions
	}

func load_save_data(data: Dictionary) -> void:
	# Clear current slots
	for i in MAX_POTION_SLOTS:
		unequip_potion(i)
	
	# Load equipped potions
	var equipped = data.get("equipped_potions", [])
	for slot_data in equipped:
		var slot = slot_data.get("slot", 0)
		var potion_id = slot_data.get("potion_id", "")
		
		if potion_id and ItemDatabase:
			var potion = ItemDatabase.get_item(potion_id)
			if potion and potion is PotionData:
				equip_potion(slot, potion)