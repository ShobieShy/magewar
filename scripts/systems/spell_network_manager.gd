## SpellNetworkManager - Handles synchronization of spell casting and effects in multiplayer
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal spell_cast_received(peer_id: int, spell_data: Dictionary)
signal spell_effect_received(peer_id: int, effect_data: Dictionary)
signal spell_projectile_received(peer_id: int, projectile_data: Dictionary)

# =============================================================================
# CONSTANTS
# =============================================================================

const NETWORK_UPDATE_RATE: float = 0.05  # 20 updates per second
const INTERPOLATION_BUFFER_SIZE: int = 5
const MAX_ACTIVE_PROJECTILES: int = 500
const MAX_PENDING_SPELL_CASTS: int = 200
const MAX_ACTIVE_SPELL_EFFECTS: int = 1000

# =============================================================================
# PROPERTIES
# =============================================================================

var last_network_update: float = 0.0

# Spell casting synchronization
var pending_spell_casts: Array = []
var active_spell_effects: Dictionary = {}  # effect_id -> effect_data

# Projectile synchronization
var active_projectiles: Dictionary = {}  # projectile_id -> projectile_data
var projectile_interpolation: Dictionary = {}  # projectile_id -> position_history

# Network prediction
var spell_cast_predictions: Dictionary = {}  # prediction_id -> predicted_cast
var prediction_errors: Array = []

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Connect to network signals
	if NetworkManager:
		NetworkManager.player_connected.connect(_on_player_connected)
		NetworkManager.player_disconnected.connect(_on_player_disconnected)

	# Connect to spell casting signals
	if SpellManager:
		SpellManager.spell_cast_started.connect(_on_spell_cast_started)
		SpellManager.spell_cast_completed.connect(_on_spell_cast_completed)

func _process(delta: float) -> void:
	last_network_update += delta

	# Send network updates at regular intervals
	if last_network_update >= NETWORK_UPDATE_RATE:
		last_network_update = 0.0
		_send_network_updates()

	# Process pending spell casts
	_process_pending_casts()

	# Update projectile interpolation
	_update_projectile_interpolation(delta)

# =============================================================================
# NETWORK UPDATES
# =============================================================================

func _send_network_updates() -> void:
	"""Send periodic network updates for spell synchronization"""
	# This function sends periodic updates to synchronize spell states
	# Implementation depends on specific networking requirements
	pass

# =============================================================================
# SPELL CASTING SYNCHRONIZATION
# =============================================================================

func cast_spell_network(spell_id: String, caster_position: Vector3, aim_point: Vector3, aim_direction: Vector3, prediction_id: int = 0) -> void:
	"""Send spell cast to all other players"""
	var spell_data = {
		"spell_id": spell_id,
		"caster_position": caster_position,
		"aim_point": aim_point,
		"aim_direction": aim_direction,
		"prediction_id": prediction_id,
		"timestamp": Time.get_unix_time_from_system()
	}

	# Send to network
	_send_spell_cast(spell_data)

	# If we're predicting, store for reconciliation
	if prediction_id > 0:
		spell_cast_predictions[prediction_id] = spell_data

func _send_spell_cast(spell_data: Dictionary) -> void:
	"""Send spell cast data over network"""
	if NetworkManager.network_mode == Enums.NetworkMode.OFFLINE:
		return

	var packet = {
		"type": "spell_cast",
		"data": spell_data,
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

func _on_spell_cast_started(spell: SpellData) -> void:
	"""Local spell cast started - prepare for network sync"""
	if NetworkManager.network_mode == Enums.NetworkMode.OFFLINE:
		return

	# Generate prediction ID for client-side prediction
	var prediction_id = randi()
	var caster = get_parent()
	if caster and caster is Player:
		var aim_point = caster.get_aim_point()
		var aim_direction = caster.get_aim_direction()

		cast_spell_network(spell.spell_name, caster.global_position, aim_point, aim_direction, prediction_id)

func _on_spell_cast_completed(spell: SpellData) -> void:
	"""Local spell cast completed - confirm with network"""
	if NetworkManager.network_mode == Enums.NetworkMode.OFFLINE:
		return

	# Send completion confirmation
	var packet = {
		"type": "spell_cast_complete",
		"data": {
			"spell_id": spell.spell_name,
			"timestamp": Time.get_unix_time_from_system()
		},
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

# =============================================================================
# SPELL EFFECT SYNCHRONIZATION
# =============================================================================

func synchronize_spell_effect(effect_id: String, effect_type: String, position: Vector3, affected_targets: Array, effect_data: Dictionary) -> void:
	"""Synchronize spell effect application"""
	var effect_packet = {
		"effect_id": effect_id,
		"effect_type": effect_type,
		"position": position,
		"affected_targets": affected_targets,
		"effect_data": effect_data,
		"timestamp": Time.get_unix_time_from_system()
	}

	# Store locally
	active_spell_effects[effect_id] = effect_packet

	# Send to network
	var packet = {
		"type": "spell_effect",
		"data": effect_packet,
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

# =============================================================================
# PROJECTILE SYNCHRONIZATION
# =============================================================================

func synchronize_projectile(projectile_id: String, projectile_type: String, position: Vector3, velocity: Vector3, projectile_data: Dictionary) -> void:
	"""Synchronize projectile creation and movement"""
	var projectile_packet = {
		"projectile_id": projectile_id,
		"projectile_type": projectile_type,
		"position": position,
		"velocity": velocity,
		"projectile_data": projectile_data,
		"timestamp": Time.get_unix_time_from_system()
	}

	# Check if we're at max projectiles
	if active_projectiles.size() >= MAX_ACTIVE_PROJECTILES:
		push_warning("SpellNetworkManager: Max active projectiles exceeded (%d). Ignoring new projectile." % MAX_ACTIVE_PROJECTILES)
		return
	
	# Store locally
	active_projectiles[projectile_id] = projectile_packet
	
	# Initialize interpolation buffer
	projectile_interpolation[projectile_id] = []

	# Send to network
	var packet = {
		"type": "projectile_sync",
		"data": projectile_packet,
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

func update_projectile_position(projectile_id: String, position: Vector3, velocity: Vector3) -> void:
	"""Update projectile position for interpolation"""
	if active_projectiles.has(projectile_id):
		# Ensure interpolation buffer exists (might be out of sync with active_projectiles)
		if not projectile_interpolation.has(projectile_id):
			projectile_interpolation[projectile_id] = []
		
		var update_data = {
			"position": position,
			"velocity": velocity,
			"timestamp": Time.get_unix_time_from_system()
		}
		
		# Add to interpolation buffer
		projectile_interpolation[projectile_id].append(update_data)
		
		# Keep buffer size limited
		if projectile_interpolation[projectile_id].size() > INTERPOLATION_BUFFER_SIZE:
			projectile_interpolation[projectile_id].pop_front()

		# Send update
		var packet = {
			"type": "projectile_update",
			"data": {
				"projectile_id": projectile_id,
				"update": update_data
			},
			"sender": multiplayer.get_unique_id()
		}

		_send_network_packet(packet)

func destroy_projectile(projectile_id: String) -> void:
	"""Notify network of projectile destruction"""
	if active_projectiles.has(projectile_id):
		active_projectiles.erase(projectile_id)
		projectile_interpolation.erase(projectile_id)

		var packet = {
			"type": "projectile_destroy",
			"data": {"projectile_id": projectile_id},
			"sender": multiplayer.get_unique_id()
		}

		_send_network_packet(packet)

# =============================================================================
# NETWORK PACKET HANDLING
# =============================================================================

func _send_network_packet(packet: Dictionary) -> void:
	"""Send packet through appropriate network system"""
	match NetworkManager.network_mode:
		Enums.NetworkMode.STEAM:
			_send_steam_packet(packet)
		Enums.NetworkMode.ENET:
			_send_enet_packet(packet)
		_:
			pass  # Offline mode

func _send_steam_packet(packet: Dictionary) -> void:
	"""Send packet via Steam P2P"""
	if not SteamManager.is_initialized:
		return

	var packet_data = JSON.stringify(packet).to_utf8_buffer()

	# Send to all connected players
	for peer_id in NetworkManager._steam_to_peer:
		if peer_id != SteamManager.steam_id:
			SteamManager.send_p2p_packet(peer_id, packet_data, SteamManager.P2P_SEND_RELIABLE)

func _send_enet_packet(packet: Dictionary) -> void:
	"""Send packet via ENet multiplayer"""
	if multiplayer.multiplayer_peer:
		rpc("_receive_network_packet", packet)

@rpc("any_peer", "call_remote", "reliable")
func _receive_network_packet(packet: Dictionary) -> void:
	"""Receive network packet from another player"""
	var sender = multiplayer.get_remote_sender_id()

	# Process packet based on type
	match packet.get("type", ""):
		"spell_cast":
			_process_spell_cast_packet(packet.data, sender)
		"spell_cast_complete":
			_process_spell_cast_complete_packet(packet.data, sender)
		"spell_effect":
			_process_spell_effect_packet(packet.data, sender)
		"projectile_sync":
			_process_projectile_sync_packet(packet.data, sender)
		"projectile_update":
			_process_projectile_update_packet(packet.data, sender)
		"projectile_destroy":
			_process_projectile_destroy_packet(packet.data, sender)

# =============================================================================
# PACKET PROCESSORS
# =============================================================================

func _process_spell_cast_packet(data: Dictionary, sender: int) -> void:
	"""Process incoming spell cast"""
	var spell_id = data.get("spell_id", "")
	var caster_position = data.get("caster_position", Vector3.ZERO)
	var aim_point = data.get("aim_point", Vector3.ZERO)
	var aim_direction = data.get("aim_direction", Vector3.FORWARD)
	var prediction_id = data.get("prediction_id", 0)

	# Find the caster player
	var caster = _get_player_by_peer_id(sender)
	if not caster:
		return

	# Queue spell cast for execution
	var cast_request = {
		"caster": caster,
		"spell_id": spell_id,
		"caster_position": caster_position,
		"aim_point": aim_point,
		"aim_direction": aim_direction,
		"prediction_id": prediction_id
	}

	pending_spell_casts.append(cast_request)
	spell_cast_received.emit(sender, data)

func _process_spell_cast_complete_packet(data: Dictionary, _sender: int) -> void:
	"""Process spell cast completion confirmation"""
	var spell_id = data.get("spell_id", "")

	# Could use this for lag compensation or validation
	print("Spell cast completed: " + spell_id)

func _process_spell_effect_packet(data: Dictionary, sender: int) -> void:
	"""Process incoming spell effect"""
	var effect_id = data.get("effect_id", "")
	var effect_type = data.get("effect_type", "")
	var position = data.get("position", Vector3.ZERO)
	var affected_targets = data.get("affected_targets", [])
	var effect_data = data.get("effect_data", {})

	# Apply effect locally
	_apply_network_spell_effect(effect_id, effect_type, position, affected_targets, effect_data)

	spell_effect_received.emit(sender, data)

func _process_projectile_sync_packet(data: Dictionary, sender: int) -> void:
	"""Process projectile creation"""
	var projectile_id = data.get("projectile_id", "")
	var projectile_type = data.get("projectile_type", "")
	var position = data.get("position", Vector3.ZERO)
	var velocity = data.get("velocity", Vector3.ZERO)
	var projectile_data = data.get("projectile_data", {})

	# Create projectile locally
	_create_network_projectile(projectile_id, projectile_type, position, velocity, projectile_data)

	spell_projectile_received.emit(sender, data)

func _process_projectile_update_packet(data: Dictionary, _sender: int) -> void:
	"""Process projectile position update"""
	var projectile_id = data.get("projectile_id", "")
	var update_data = data.get("update", {})

	if projectile_interpolation.has(projectile_id):
		projectile_interpolation[projectile_id].append(update_data)

		# Keep buffer size limited
		if projectile_interpolation[projectile_id].size() > INTERPOLATION_BUFFER_SIZE:
			projectile_interpolation[projectile_id].pop_front()

func _process_projectile_destroy_packet(data: Dictionary, _sender: int) -> void:
	"""Process projectile destruction"""
	var projectile_id = data.get("projectile_id", "")

	if active_projectiles.has(projectile_id):
		active_projectiles.erase(projectile_id)
		projectile_interpolation.erase(projectile_id)

		# Find and destroy local projectile
		_destroy_network_projectile(projectile_id)

# =============================================================================
# PENDING CAST PROCESSING
# =============================================================================

func _process_pending_casts() -> void:
	"""Process queued spell casts"""
	for cast_request in pending_spell_casts:
		var caster = cast_request.caster
		if not is_instance_valid(caster):
			continue

		# Check if caster has SpellCaster component
		var spell_caster = caster.get_node_or_null("SpellCaster")
		if not spell_caster:
			continue

		# Get spell data
		var spell = SpellManager.get_spell(cast_request.spell_id)
		if not spell:
			continue

		# Execute spell cast
		var success = spell_caster.cast_spell(spell, cast_request.aim_point, cast_request.aim_direction)

		if success:
			pending_spell_casts.erase(cast_request)

# =============================================================================
# PROJECTILE INTERPOLATION
# =============================================================================

func _update_projectile_interpolation(delta: float) -> void:
	"""Update projectile positions using interpolation"""
	for projectile_id in projectile_interpolation:
		var buffer = projectile_interpolation[projectile_id]
		if buffer.size() < 2:
			continue

		# Interpolate between last two positions
		var current = buffer[buffer.size() - 1]
		var previous = buffer[buffer.size() - 2]

		var time_diff = current.timestamp - previous.timestamp
		if time_diff > 0:
			var interpolation_factor = min(delta / time_diff, 1.0)
			var interpolated_pos = previous.position.lerp(current.position, interpolation_factor)

			# Update local projectile position
			_update_network_projectile_position(projectile_id, interpolated_pos)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _get_player_by_peer_id(peer_id: int) -> Node:
	"""Find player node by peer ID"""
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_meta("peer_id") and player.get_meta("peer_id") == peer_id:
			return player
	return null

func _apply_network_spell_effect(effect_id: String, effect_type: String, position: Vector3, affected_targets: Array, effect_data: Dictionary) -> void:
	"""Apply spell effect received from network"""
	# Create effect at position
	match effect_type:
		"damage":
			# Spawn damage numbers or effects
			for target_path in affected_targets:
				var target = get_node_or_null(target_path)
				if target and target.has_node("StatsComponent"):
					var stats = target.get_node_or_null("StatsComponent")
					var damage = effect_data.get("damage", 0)
					var damage_type = effect_data.get("damage_type", Enums.DamageType.PHYSICAL)
					stats.take_damage(damage, damage_type)

		"healing":
			# Apply healing
			for target_path in affected_targets:
				var target = get_node_or_null(target_path)
				if target and target.has_node("StatsComponent"):
					var stats = target.get_node_or_null("StatsComponent")
					var healing = effect_data.get("healing", 0)
					stats.heal(healing)

		"buff":
			# Apply buff effects
			pass

		"debuff":
			# Apply debuff effects
			pass

func _create_network_projectile(projectile_id: String, projectile_type: String, position: Vector3, velocity: Vector3, projectile_data: Dictionary) -> void:
	"""Create projectile instance from network data"""
	var projectile_scene = load("res://scenes/spells/projectile.tscn")
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		projectile.position = position
		projectile._velocity = velocity

		# Set projectile properties from data
		for property in projectile_data:
			if property in projectile:
				projectile.set(property, projectile_data[property])

		get_tree().current_scene.add_child(projectile)

		# Store reference
		active_projectiles[projectile_id] = projectile

func _update_network_projectile_position(projectile_id: String, position: Vector3) -> void:
	"""Update projectile position for interpolation"""
	if active_projectiles.has(projectile_id):
		var projectile = active_projectiles[projectile_id]
		if projectile and is_instance_valid(projectile):
			projectile.position = position

func _destroy_network_projectile(projectile_id: String) -> void:
	"""Destroy projectile instance"""
	if active_projectiles.has(projectile_id):
		var projectile = active_projectiles[projectile_id]
		if projectile and is_instance_valid(projectile):
			projectile.queue_free()
		active_projectiles.erase(projectile_id)

# =============================================================================
# PLAYER CONNECTION HANDLING
# =============================================================================

func _on_player_connected(peer_id: int) -> void:
	"""Handle new player connection"""
	print("Player connected to spell network: " + str(peer_id))

func _on_player_disconnected(peer_id: int) -> void:
	"""Handle player disconnection"""
	print("Player disconnected from spell network: " + str(peer_id))

	# Clean up any pending casts or effects from this player
	pending_spell_casts = pending_spell_casts.filter(func(cast): return cast.caster != _get_player_by_peer_id(peer_id))

# =============================================================================
# PREDICTION AND RECONCILIATION
# =============================================================================

func reconcile_spell_cast(prediction_id: int, actual_result: Dictionary) -> void:
	"""Reconcile predicted spell cast with actual result"""
	if spell_cast_predictions.has(prediction_id):
		var predicted = spell_cast_predictions[prediction_id]

		# Compare predicted vs actual
		var error = _calculate_spell_cast_error(predicted, actual_result)
		prediction_errors.append(error)

		# Remove prediction
		spell_cast_predictions.erase(prediction_id)

		# Adjust prediction parameters based on error
		_adjust_prediction_parameters(error)

func _calculate_spell_cast_error(predicted: Dictionary, actual: Dictionary) -> Dictionary:
	"""Calculate error between predicted and actual spell cast"""
	return {
		"position_error": predicted.caster_position.distance_to(actual.get("caster_position", Vector3.ZERO)),
		"timing_error": abs(predicted.timestamp - actual.get("timestamp", 0.0))
	}

func _adjust_prediction_parameters(error: Dictionary) -> void:
	"""Adjust prediction parameters based on errors"""
	# This could adjust network update rates, interpolation, etc.
	# For now, just track errors for debugging
	if prediction_errors.size() > 10:
		prediction_errors.pop_front()

# =============================================================================
# DEBUGGING
# =============================================================================

func get_network_stats() -> Dictionary:
	"""Get network statistics for debugging"""
	return {
		"active_projectiles": active_projectiles.size(),
		"pending_casts": pending_spell_casts.size(),
		"active_effects": active_spell_effects.size(),
		"prediction_errors": prediction_errors.size(),
		"avg_prediction_error": _calculate_average_prediction_error()
	}

func _calculate_average_prediction_error() -> float:
	"""Calculate average prediction error"""
	if prediction_errors.size() == 0:
		return 0.0

	var total_error = 0.0
	for error in prediction_errors:
		total_error += error.get("position_error", 0.0)

	return total_error / prediction_errors.size()