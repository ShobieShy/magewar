## SaveNetworkManager - Handles save synchronization and corruption prevention in multiplayer
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal save_lock_acquired(peer_id: int)
signal save_lock_released(peer_id: int)
signal save_conflict_detected(conflicting_saves: Array)
signal save_synchronized(peer_id: int, save_data: Dictionary)

# =============================================================================
# CONSTANTS
# =============================================================================

const SAVE_LOCK_TIMEOUT: float = 30.0  # Seconds before lock expires
const SAVE_RETRY_ATTEMPTS: int = 3
const SAVE_RETRY_DELAY: float = 1.0

# =============================================================================
# PROPERTIES
# =============================================================================

var save_locks: Dictionary = {}  # peer_id -> lock_data
var pending_saves: Array = []    # Queue of saves waiting for lock
var active_save_operations: Dictionary = {}  # save_id -> operation_data
var save_checksums: Dictionary = {}  # save_type -> checksum

# Network sync
var last_save_sync: float = 0.0
var save_sync_interval: float = 5.0  # Sync every 5 seconds

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Connect to network signals
	if NetworkManager:
		NetworkManager.player_connected.connect(_on_player_connected)
		NetworkManager.player_disconnected.connect(_on_player_disconnected)

	# Connect to save manager signals
	if SaveManager:
		SaveManager.save_completed.connect(_on_save_completed)
		SaveManager.load_completed.connect(_on_load_completed)

func _process(delta: float) -> void:
	last_save_sync += delta

	# Periodic save synchronization
	if last_save_sync >= save_sync_interval:
		last_save_sync = 0.0
		_sync_save_state()

	# Check for expired locks
	_check_expired_locks(delta)

	# Process pending saves
	_process_pending_saves()

# =============================================================================
# SAVE LOCKING SYSTEM
# =============================================================================

func request_save_lock(save_type: String, requester_peer_id: int) -> bool:
	"""Request exclusive lock for saving - server-side validation"""
	# SERVER AUTHORITY CHECK: Only the server can grant locks
	if NetworkManager and not NetworkManager.is_server:
		push_warning("Non-server attempted to request save lock")
		return false
	
	# Validate the requester is actually connected
	if requester_peer_id <= 0:
		push_error("Invalid peer ID for save lock: " + str(requester_peer_id))
		return false
	
	var lock_key = save_type
	var current_time = Time.get_unix_time_from_system()

	# Check if lock is already held
	if save_locks.has(lock_key):
		var lock_data = save_locks[lock_key]
		if lock_data.peer_id != requester_peer_id:
			# Lock held by someone else
			if current_time - lock_data.timestamp < SAVE_LOCK_TIMEOUT:
				# Lock still valid, queue the request
				_queue_save_request(save_type, requester_peer_id)
				return false
			else:
				# Lock expired, break it
				_release_save_lock(lock_key, false)

	# Acquire lock
	save_locks[lock_key] = {
		"peer_id": requester_peer_id,
		"timestamp": current_time,
		"save_type": save_type
	}

	save_lock_acquired.emit(requester_peer_id)

	# Broadcast lock acquisition
	_broadcast_save_lock(lock_key, requester_peer_id)

	return true

func release_save_lock(save_type: String, peer_id: int) -> void:
	"""Release save lock"""
	var lock_key = save_type

	if save_locks.has(lock_key) and save_locks[lock_key].peer_id == peer_id:
		_release_save_lock(lock_key, true)

func _release_save_lock(lock_key: String, notify: bool) -> void:
	"""Internal lock release"""
	if save_locks.has(lock_key):
		var lock_data = save_locks[lock_key]
		var peer_id = lock_data.peer_id

		save_locks.erase(lock_key)

		if notify:
			save_lock_released.emit(peer_id)
			_broadcast_save_unlock(lock_key, peer_id)

		# Process next pending save
		_process_next_pending_save(lock_key)

func _check_expired_locks(delta: float) -> void:
	"""Check for and clean up expired locks"""
	var current_time = Time.get_unix_time_from_system()
	var expired_locks = []

	for lock_key in save_locks:
		var lock_data = save_locks[lock_key]
		if current_time - lock_data.timestamp >= SAVE_LOCK_TIMEOUT:
			expired_locks.append(lock_key)

	for lock_key in expired_locks:
		print("Save lock expired: " + lock_key)
		_release_save_lock(lock_key, false)

# =============================================================================
# SAVE QUEUEING SYSTEM
# =============================================================================

func _queue_save_request(save_type: String, peer_id: int) -> void:
	"""Queue a save request when lock is unavailable"""
	var request = {
		"save_type": save_type,
		"peer_id": peer_id,
		"timestamp": Time.get_unix_time_from_system(),
		"attempts": 0
	}

	pending_saves.append(request)

func _process_pending_saves() -> void:
	"""Process queued save requests"""
	var to_remove = []

	for request in pending_saves:
		var save_type = request.save_type
		var peer_id = request.peer_id

		# Check if we can acquire lock now
		if request_save_lock(save_type, peer_id):
			to_remove.append(request)
			# Trigger the actual save
			_execute_queued_save(request)

	for request in to_remove:
		pending_saves.erase(request)

func _process_next_pending_save(lock_key: String) -> void:
	"""Process the next save waiting for a specific lock"""
	for request in pending_saves:
		if request.save_type == lock_key:
			if request_save_lock(lock_key, request.peer_id):
				_execute_queued_save(request)
				pending_saves.erase(request)
			break

func _execute_queued_save(request: Dictionary) -> void:
	"""Execute a queued save operation"""
	var save_type = request.save_type
	var peer_id = request.peer_id

	# Trigger the appropriate save based on type
	match save_type:
		"player":
			if SaveManager:
				SaveManager.save_player_data()
		"world":
			if SaveManager and GameManager.is_host:
				SaveManager.save_world_data()
		"settings":
			if SaveManager:
				SaveManager.save_settings()

# =============================================================================
# SAVE SYNCHRONIZATION
# =============================================================================

func synchronize_save_data(save_type: String, save_data: Dictionary, peer_id: int) -> void:
	"""Synchronize save data between players - server-validated"""
	# SERVER AUTHORITY CHECK: Only the server processes save data
	if NetworkManager and not NetworkManager.is_server:
		push_warning("Non-server attempted to synchronize save data")
		return
	
	# Validate save type
	if save_type not in ["player", "world", "settings"]:
		push_error("Invalid save type: " + save_type)
		return
	
	# Validate world saves only come from host
	if save_type == "world" and not GameManager.is_host:
		push_error("Non-host attempted to save world data")
		return
	
	# Validate save data is not empty
	if save_data.size() == 0:
		push_warning("Empty save data provided by peer " + str(peer_id))
		return
	
	var save_id = str(peer_id) + "_" + save_type + "_" + str(Time.get_ticks_msec())

	var sync_data = {
		"save_id": save_id,
		"save_type": save_type,
		"save_data": save_data,
		"checksum": _calculate_checksum(save_data),
		"timestamp": Time.get_unix_time_from_system(),
		"peer_id": peer_id
	}

	# Store locally
	active_save_operations[save_id] = sync_data

	# Check for conflicts
	var conflicts = _check_save_conflicts(save_type, sync_data)
	if conflicts.size() > 0:
		save_conflict_detected.emit(conflicts)
		_resolve_save_conflict(conflicts)
		return

	# Broadcast to other players
	_broadcast_save_data(sync_data)

func _check_save_conflicts(save_type: String, new_save: Dictionary) -> Array:
	"""Check for save conflicts with existing data"""
	var conflicts = []

	for operation_id in active_save_operations:
		var operation = active_save_operations[operation_id]
		if operation.save_type == save_type and operation.save_id != new_save.save_id:
			# Check timestamp difference (within 5 seconds = conflict)
			if abs(operation.timestamp - new_save.timestamp) < 5.0:
				conflicts.append({
					"existing": operation,
					"new": new_save
				})

	return conflicts

func _resolve_save_conflict(conflicts: Array) -> void:
	"""Resolve save conflicts using timestamp priority"""
	for conflict in conflicts:
		var existing = conflict.existing
		var new_save = conflict.new

		# Use the newer save (higher timestamp wins)
		if new_save.timestamp > existing.timestamp:
			# New save wins, update our data
			_apply_save_data(new_save.save_type, new_save.save_data)
			active_save_operations[new_save.save_id] = new_save
		else:
			# Existing save wins, discard new one
			pass

		# Clean up old operation
		active_save_operations.erase(existing.save_id)

# =============================================================================
# NETWORK COMMUNICATION
# =============================================================================

func _broadcast_save_lock(lock_key: String, peer_id: int) -> void:
	"""Broadcast save lock acquisition"""
	var packet = {
		"type": "save_lock",
		"data": {
			"lock_key": lock_key,
			"peer_id": peer_id,
			"timestamp": Time.get_unix_time_from_system()
		},
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

func _broadcast_save_unlock(lock_key: String, peer_id: int) -> void:
	"""Broadcast save lock release"""
	var packet = {
		"type": "save_unlock",
		"data": {
			"lock_key": lock_key,
			"peer_id": peer_id
		},
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

func _broadcast_save_data(sync_data: Dictionary) -> void:
	"""Broadcast save data to other players"""
	var packet = {
		"type": "save_sync",
		"data": sync_data,
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

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
		"save_lock":
			_process_save_lock_packet(packet.data, sender)
		"save_unlock":
			_process_save_unlock_packet(packet.data, sender)
		"save_sync":
			_process_save_sync_packet(packet.data, sender)

# =============================================================================
# PACKET PROCESSORS
# =============================================================================

func _process_save_lock_packet(data: Dictionary, sender: int) -> void:
	"""Process save lock acquisition"""
	var lock_key = data.get("lock_key", "")
	var peer_id = data.get("peer_id", 0)
	var timestamp = data.get("timestamp", 0)

	if peer_id != multiplayer.get_unique_id():
		# Someone else acquired a lock
		save_locks[lock_key] = {
			"peer_id": peer_id,
			"timestamp": timestamp,
			"save_type": lock_key
		}

func _process_save_unlock_packet(data: Dictionary, sender: int) -> void:
	"""Process save lock release"""
	var lock_key = data.get("lock_key", "")
	var peer_id = data.get("peer_id", 0)

	if peer_id != multiplayer.get_unique_id():
		# Someone else released a lock
		if save_locks.has(lock_key) and save_locks[lock_key].peer_id == peer_id:
			save_locks.erase(lock_key)

func _process_save_sync_packet(data: Dictionary, sender: int) -> void:
	"""Process save data synchronization"""
	var save_id = data.get("save_id", "")
	var save_type = data.get("save_type", "")
	var save_data = data.get("save_data", {})
	var checksum = data.get("checksum", "")
	var timestamp = data.get("timestamp", 0.0)

	# Validate checksum
	var calculated_checksum = _calculate_checksum(save_data)
	if calculated_checksum != checksum:
		push_warning("Save data checksum mismatch from peer " + str(sender))
		return

	# Store operation
	active_save_operations[save_id] = data

	# Check for conflicts
	var conflicts = _check_save_conflicts(save_type, data)
	if conflicts.size() > 0:
		_resolve_save_conflict(conflicts)
	else:
		# No conflicts, apply the save
		_apply_save_data(save_type, save_data)

	save_synchronized.emit(sender, save_data)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func _calculate_checksum(data: Dictionary) -> String:
	"""Calculate checksum for save data validation"""
	var json_string = JSON.stringify(data)
	return json_string.md5_text()

func _apply_save_data(save_type: String, save_data: Dictionary) -> void:
	"""Apply synchronized save data"""
	if not SaveManager:
		return

	match save_type:
		"player":
			# Merge player data
			for key in save_data:
				SaveManager.player_data[key] = save_data[key]
			# Ensure all required fields are present after merge
			SaveManager._ensure_required_player_fields()
		"world":
			# Only host should apply world data
			if GameManager.is_host:
				for key in save_data:
					SaveManager.world_data[key] = save_data[key]
				# Ensure all required fields are present after merge
				SaveManager._ensure_required_world_fields()
		"settings":
			# Merge settings
			for section in save_data:
				if not SaveManager.settings_data.has(section):
					SaveManager.settings_data[section] = {}
				for key in save_data[section]:
					SaveManager.settings_data[section][key] = save_data[section][key]
			# Ensure all required fields are present after merge
			SaveManager._ensure_required_settings_fields()

func _sync_save_state() -> void:
	"""Periodically sync save state with other players"""
	if NetworkManager.network_mode == Enums.NetworkMode.OFFLINE:
		return

	# Send current checksums
	var checksum_data = {}
	for save_type in save_checksums:
		checksum_data[save_type] = save_checksums[save_type]

	var packet = {
		"type": "save_state_sync",
		"data": {
			"checksums": checksum_data,
			"locks": save_locks.keys()
		},
		"sender": multiplayer.get_unique_id()
	}

	_send_network_packet(packet)

# =============================================================================
# SAVE MANAGER INTEGRATION
# =============================================================================

func _on_save_completed(success: bool) -> void:
	"""Handle save completion"""
	if success:
		# Update checksums
		_update_save_checksums()

		# Release any locks we hold
		for lock_key in save_locks.keys():
			var lock_data = save_locks[lock_key]
			if lock_data.peer_id == multiplayer.get_unique_id():
				release_save_lock(lock_key, multiplayer.get_unique_id())

func _on_load_completed(success: bool) -> void:
	"""Handle load completion"""
	if success:
		_update_save_checksums()

func _update_save_checksums() -> void:
	"""Update checksums for all save types"""
	if SaveManager:
		save_checksums["player"] = _calculate_checksum(SaveManager.player_data)
		save_checksums["world"] = _calculate_checksum(SaveManager.world_data)
		save_checksums["settings"] = _calculate_checksum(SaveManager.settings_data)

# =============================================================================
# PLAYER CONNECTION HANDLING
# =============================================================================

func _on_player_connected(peer_id: int) -> void:
	"""Handle new player connection"""
	print("Player connected to save network: " + str(peer_id))

	# Send current save state
	_sync_save_state()

func _on_player_disconnected(peer_id: int) -> void:
	"""Handle player disconnection"""
	print("Player disconnected from save network: " + str(peer_id))

	# Release any locks held by this player
	var locks_to_release = []
	for lock_key in save_locks:
		if save_locks[lock_key].peer_id == peer_id:
			locks_to_release.append(lock_key)

	for lock_key in locks_to_release:
		_release_save_lock(lock_key, false)

	# Clean up save operations
	var operations_to_remove = []
	for operation_id in active_save_operations:
		var operation = active_save_operations[operation_id]
		if operation.get("sender", 0) == peer_id:
			operations_to_remove.append(operation_id)

	for operation_id in operations_to_remove:
		active_save_operations.erase(operation_id)

# =============================================================================
# DEBUGGING
# =============================================================================

func get_save_network_stats() -> Dictionary:
	"""Get network statistics for debugging"""
	return {
		"active_locks": save_locks.size(),
		"pending_saves": pending_saves.size(),
		"active_operations": active_save_operations.size(),
		"save_checksums": save_checksums.size()
	}

func force_release_all_locks() -> void:
	"""Force release all save locks (for debugging)"""
	var lock_keys = save_locks.keys()
	for lock_key in lock_keys:
		_release_save_lock(lock_key, false)