## Player - FPS Character Controller
## Handles movement, camera, and input for first-person gameplay
class_name Player
extends CharacterBody3D

# Preload needed systems
const InventorySystemClass = preload("res://scripts/systems/inventory_system.gd")

# =============================================================================
# SIGNALS
# =============================================================================

signal player_died()
signal player_respawned()

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Movement")
@export var walk_speed: float = Constants.WALK_SPEED
@export var sprint_speed: float = Constants.SPRINT_SPEED
@export var crouch_speed: float = Constants.CROUCH_SPEED
@export var jump_velocity: float = Constants.JUMP_VELOCITY
@export var acceleration: float = 10.0
@export var air_control: float = 0.3

@export_group("Camera")
@export var mouse_sensitivity: float = Constants.MOUSE_SENSITIVITY
@export var max_look_up: float = Constants.MAX_LOOK_UP
@export var max_look_down: float = Constants.MAX_LOOK_DOWN

@export_group("Stamina Costs")
@export var sprint_stamina_cost: float = Constants.SPRINT_STAMINA_COST
@export var jump_stamina_cost: float = Constants.JUMP_STAMINA_COST

# =============================================================================
# CONSTANTS
# =============================================================================

const STARTER_STAFF_SCENE = preload("res://resources/items/weapons/starter_staff.tscn")

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var stats: StatsComponent = $StatsComponent
@onready var spell_caster: SpellCaster = $SpellCaster
@onready var weapon_holder: Node3D = $CameraPivot/Camera3D/WeaponHolder
@onready var raycast: RayCast3D = $CameraPivot/Camera3D/RayCast3D

# Inventory management
var _inventory_system: InventorySystem = null

# Public accessor for inventory system
var inventory: InventorySystem:
	get:
		# Initialize inventory system if needed
		if _inventory_system == null:
			_inventory_system = InventorySystemClass.new()
			_inventory_system.initialize(self)
			add_child(_inventory_system)
		return _inventory_system

# =============================================================================
# PROPERTIES
# =============================================================================

var is_local_player: bool = false
var player_state: Enums.PlayerState = Enums.PlayerState.IDLE
var current_weapon: Staff = null

## Movement state
var is_sprinting: bool = false
var is_crouching: bool = false
var _target_speed: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * Constants.GRAVITY_MULTIPLIER

## Camera state
var _camera_rotation: Vector2 = Vector2.ZERO

## Crouch state
var _default_height: float = 2.0
var _crouch_height: float = 1.0
var _current_height: float = 2.0

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Add player to group for targeting/detection
	add_to_group("player")
	
	# Store default collision height
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		_default_height = collision_shape.shape.height
		_crouch_height = _default_height * 0.5
	
	# Set up for local vs remote player
	if is_local_player:
		camera.current = true
		# Connect stats signals
		stats.died.connect(_on_died)
		stats.respawned.connect(_on_respawned)
		# Equip starter weapon
		_equip_starter_weapon()
		# Apply allocated stat points from save data
		if SaveManager and SaveManager.player_data:
			var allocated_stats = SaveManager.player_data.get("allocated_stats", {})
			if not allocated_stats.is_empty():
				stats.apply_allocated_stats(allocated_stats)
			
			# Load inventory and equipment
			if ItemDatabase:
				# Trigger inventory initialization if needed
				var inv = self.inventory
				inv.load_save_data(SaveManager.player_data, ItemDatabase._items)
	else:
		# Remote players don't need active camera
		camera.current = false
		set_process_input(false)


func _input(event: InputEvent) -> void:
	if not is_local_player:
		return
	
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event)


func _physics_process(delta: float) -> void:
	if not is_local_player:
		return
	
	if stats.is_dead:
		return
	
	_process_movement(delta)
	_update_player_state()


func _process(delta: float) -> void:
	if not is_local_player:
		return
	
	_process_crouch(delta)
	
	# Initialize inventory system if needed
	if _inventory_system == null:
		_inventory_system = InventorySystemClass.new()
		_inventory_system.initialize(self)
		add_child(_inventory_system)

# =============================================================================
# MOVEMENT
# =============================================================================

func _process_movement(delta: float) -> void:
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle sprinting
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching and input_dir.y < 0
	if is_sprinting and stats.has_stamina(sprint_stamina_cost * delta):
		_target_speed = sprint_speed
		stats.drain_stamina(sprint_stamina_cost * delta)
	elif is_crouching:
		_target_speed = crouch_speed
	else:
		_target_speed = walk_speed
		is_sprinting = false
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		if stats.use_stamina(jump_stamina_cost):
			velocity.y = jump_velocity
	
	# Calculate horizontal movement
	var accel = acceleration if is_on_floor() else acceleration * air_control
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * _target_speed, accel * delta * _target_speed)
		velocity.z = move_toward(velocity.z, direction.z * _target_speed, accel * delta * _target_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, accel * delta * _target_speed)
		velocity.z = move_toward(velocity.z, 0, accel * delta * _target_speed)
	
	# Handle crouch input
	if Input.is_action_just_pressed("crouch"):
		is_crouching = not is_crouching
	
	move_and_slide()

# =============================================================================
# CAMERA
# =============================================================================

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	_camera_rotation.x -= event.relative.y * mouse_sensitivity
	_camera_rotation.y -= event.relative.x * mouse_sensitivity
	
	# Clamp vertical rotation
	_camera_rotation.x = clamp(_camera_rotation.x, deg_to_rad(max_look_down), deg_to_rad(max_look_up))
	
	# Apply rotation
	rotation.y = _camera_rotation.y
	camera_pivot.rotation.x = _camera_rotation.x

# =============================================================================
# CROUCH
# =============================================================================

func _process_crouch(delta: float) -> void:
	var target_height = _crouch_height if is_crouching else _default_height
	
	# Check if we can stand up (only if player is trying to stand)
	if not is_crouching and _current_height < _default_height:
		# Raycast upward to check if there's space to stand
		if not _can_stand_up():
			target_height = _current_height  # Stay crouched if ceiling is too low
	
	# Smoothly interpolate height
	_current_height = move_toward(_current_height, target_height, delta * 10.0)
	
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = _current_height
		collision_shape.position.y = _current_height / 2.0
		camera_pivot.position.y = _current_height - 0.2


func _can_stand_up() -> bool:
	## Raycast upward to check if there's enough space to stand
	if not is_node_ready():
		return true
	
	var space_state = get_world_3d().direct_space_state
	var from_pos = global_position + Vector3(0, _current_height / 2.0, 0)
	var to_pos = from_pos + Vector3(0, _default_height / 2.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
	query.exclude = [self]
	query.collision_mask = Constants.LAYER_WORLD
	
	var result = space_state.intersect_ray(query)
	
	# Can stand if no collision found
	return result.is_empty()

# =============================================================================
# STATE
# =============================================================================

func _update_player_state() -> void:
	"""Update player state based on current actions with proper priority system.
	
	Priority (highest to lowest):
	1. SPRINTING (overrides all movement states)
	2. CROUCHING (overrides MOVING/IDLE)
	3. JUMPING (when airborne)
	4. MOVING (when moving on floor)
	5. IDLE (default state)
	"""
	# Determine base state based on vertical velocity
	var is_airborne = not is_on_floor()
	var is_moving = velocity.length_squared() > 0.01  # Use squared to avoid sqrt
	
	# Apply state with priority system
	if is_sprinting:
		# SPRINTING has highest priority
		player_state = Enums.PlayerState.SPRINTING
	elif is_crouching:
		# CROUCHING has second priority
		player_state = Enums.PlayerState.CROUCHING
	elif is_airborne:
		# JUMPING when airborne
		player_state = Enums.PlayerState.JUMPING
	elif is_moving:
		# MOVING when on floor with velocity
		player_state = Enums.PlayerState.MOVING
	else:
		# IDLE by default
		player_state = Enums.PlayerState.IDLE

# =============================================================================
# WEAPONS
# =============================================================================

func _equip_starter_weapon() -> void:
	## Equips the starter staff for new players
	if current_weapon != null:
		return  # Already have a weapon
	
	var starter_staff = STARTER_STAFF_SCENE.instantiate()
	equip_weapon(starter_staff)


func equip_weapon(weapon: Node3D) -> void:
	## Equips a weapon to the player
	if current_weapon != null:
		unequip_weapon()
	
	current_weapon = weapon as Staff
	if current_weapon == null:
		push_warning("Attempted to equip non-Staff weapon")
		return
	
	# Add to weapon holder
	weapon_holder.add_child(current_weapon)
	current_weapon.initialize(self)
	
	# Connect spell caster to weapon
	if spell_caster:
		spell_caster.projectile_spawn_point = current_weapon.get_node_or_null("SpawnPoint")


func unequip_weapon() -> Staff:
	## Unequips current weapon and returns it
	if current_weapon == null:
		return null
	
	var weapon = current_weapon
	weapon_holder.remove_child(weapon)
	current_weapon = null
	return weapon


func get_current_spell() -> SpellData:
	## Returns the current spell from equipped weapon
	if current_weapon:
		return current_weapon.get_current_spell()
	return null

# =============================================================================
# COMBAT
# =============================================================================

func get_aim_point() -> Vector3:
	## Returns the point the player is aiming at
	if raycast.is_colliding():
		return raycast.get_collision_point()
	else:
		return camera.global_position + -camera.global_transform.basis.z * Constants.HITSCAN_RANGE


func get_aim_direction() -> Vector3:
	## Returns the direction the player is aiming
	return -camera.global_transform.basis.z


func get_camera_position() -> Vector3:
	return camera.global_position

# =============================================================================
# DEATH / RESPAWN
# =============================================================================

func _on_died() -> void:
	player_state = Enums.PlayerState.DEAD
	player_died.emit()
	
	# Disable movement
	set_physics_process(false)
	
	# Request respawn from server
	if GameManager.is_host:
		# Schedule respawn
		await get_tree().create_timer(Constants.RESPAWN_TIME).timeout
		var game = get_tree().current_scene
		if game.has_method("respawn_player"):
			game.respawn_player(NetworkManager.local_peer_id)
	else:
		# Client requests respawn from host
		if is_multiplayer_authority():
			# Only authority can send RPC
			_rpc_request_respawn.rpc_id(1, NetworkManager.local_peer_id)
		else:
			push_warning("Cannot send RPC: not authority")


func _on_respawned() -> void:
	player_state = Enums.PlayerState.IDLE
	player_respawned.emit()
	set_physics_process(true)


func respawn() -> void:
	stats.respawn()


@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_respawn(peer_id: int) -> void:
	## Client requests respawn - only host processes this
	# SECURITY: Only host should process respawn requests
	if not GameManager.is_host:
		push_warning("Non-host received respawn request, ignoring")
		return
	
	# SECURITY: Validate the peer_id is valid
	if peer_id <= 0:
		push_error("Invalid peer_id for respawn: " + str(peer_id))
		return
	
	# SECURITY: Verify the requester is actually the peer_id they claim to be
	var sender = multiplayer.get_remote_sender_id()
	if sender != peer_id:
		push_warning("Peer " + str(sender) + " requested respawn for different peer " + str(peer_id))
		return
	
	# SECURITY: Check if player is actually dead before respawning
	var player = get_tree().get_first_node_in_group("player")
	if player and player.stats and not player.stats.is_dead:
		push_warning("Respawn request for player who is not dead")
		return
	
	# Schedule respawn on host
	await get_tree().create_timer(Constants.RESPAWN_TIME).timeout
	var game = get_tree().current_scene
	if game.has_method("respawn_player"):
		game.respawn_player(peer_id)

# =============================================================================
# NETWORK SYNC
# =============================================================================

func get_sync_data() -> Dictionary:
	return {
		"position": position,
		"rotation": rotation,
		"camera_rotation": _camera_rotation,
		"velocity": velocity,
		"state": player_state,
		"health": stats.current_health,
		"magika": stats.current_magika,
		"stamina": stats.current_stamina
	}


func apply_sync_data(data: Dictionary) -> void:
	if data.has("position"):
		position = data.position
	if data.has("rotation"):
		rotation = data.rotation
	if data.has("camera_rotation"):
		_camera_rotation = data.camera_rotation
		camera_pivot.rotation.x = _camera_rotation.x
	if data.has("velocity"):
		velocity = data.velocity
	if data.has("state"):
		player_state = data.state

# =============================================================================
# WEAPON PROGRESSION
# =============================================================================

## Grant experience points to currently equipped weapon
func grant_weapon_xp(amount: float) -> void:
	if not current_weapon:
		return
	
	# Pass through to weapon's leveling system if it exists
	if current_weapon.has_method("gain_experience"):
		current_weapon.gain_experience(amount)

# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

## Get a player stat (delegates to StatsComponent)
## Example: get_stat(Enums.StatType.HEALTH) -> returns current health value
func get_stat(stat_type: int) -> float:
	if stats and stats.has_method("get_stat"):
		return stats.get_stat(stat_type)
	return 0.0

## Equip an item to a specific slot
## Returns true if successful, false if equipment slot is invalid or item is wrong type
func equip_item(item: ItemData, slot: int) -> void:
	if _inventory_system and _inventory_system.has_method("equip_item"):
		_inventory_system.equip_item(item, slot)

## Grant experience points (generic version)
## Delegates to WeaponLevelingSystem for the current weapon
func grant_xp(amount: int) -> void:
	grant_weapon_xp(float(amount))

## Apply damage to the player
## Delegates to StatsComponent.take_damage()
func take_damage(amount: float) -> void:
	if stats and stats.has_method("take_damage"):
		stats.take_damage(amount)

## Add an item to the player's inventory
## Returns the slot index where the item was added (-1 if failed)
func add_item(item: ItemData) -> int:
	if _inventory_system and _inventory_system.has_method("add_item"):
		return _inventory_system.add_item(item)
	return -1
