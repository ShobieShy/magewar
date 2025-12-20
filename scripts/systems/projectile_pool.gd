## ProjectilePool - Object pooling system for projectiles
## Reduces GC pressure and improves performance by reusing projectile instances
class_name ProjectilePool
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const POOL_SIZE: int = 100  # Initial pool size
const MAX_POOL_SIZE: int = 200  # Maximum pool size before cleanup
const POOL_CLEANUP_THRESHOLD: int = 150  # Pool size before cleanup starts

# =============================================================================
# PROPERTIES
# =============================================================================

var _projectile_scene: PackedScene
var _available_pool: Array = []  # Array of inactive projectiles
var _active_pool: Array = []  # Array of active projectiles
var _total_instantiated: int = 0  # Total projectiles ever created

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	name = "ProjectilePool"
	_projectile_scene = preload("res://scenes/spells/projectile.tscn")
	
	# Pre-allocate pool
	for i in range(POOL_SIZE):
		_create_projectile()

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func get_projectile() -> SpellProjectile:
	"""Get a projectile from the pool or create new one if needed"""
	var projectile: SpellProjectile
	
	if _available_pool.is_empty():
		# No available projectiles, create new one
		projectile = _create_projectile()
		
		# Warn if pool is growing too large
		if _total_instantiated > MAX_POOL_SIZE:
			push_warning("ProjectilePool: Pool exceeded max size (%d). Consider increasing pool size." % MAX_POOL_SIZE)
	else:
		# Reuse existing projectile
		projectile = _available_pool.pop_back()
		projectile.show()
		projectile.set_physics_process(true)
	
	_active_pool.append(projectile)
	return projectile


func return_projectile(projectile: SpellProjectile) -> void:
	"""Return a projectile to the pool for reuse"""
	if projectile == null or not is_instance_valid(projectile):
		return
	
	# Remove from active pool
	var index = _active_pool.find(projectile)
	if index >= 0:
		_active_pool.remove_at(index)
	
	# Reset projectile state
	_reset_projectile(projectile)
	
	# Add back to available pool
	if _available_pool.size() < MAX_POOL_SIZE:
		_available_pool.append(projectile)
		projectile.hide()
		projectile.set_physics_process(false)
	else:
		# Pool is full, destroy the projectile
		projectile.queue_free()


func cleanup_inactive() -> void:
	"""Cleanup extra projectiles if pool is too large"""
	if _available_pool.size() > POOL_CLEANUP_THRESHOLD:
		var excess = _available_pool.size() - POOL_SIZE
		for i in range(excess):
			var projectile = _available_pool.pop_back()
			projectile.queue_free()


func get_pool_statistics() -> Dictionary:
	"""Get current pool statistics for debugging"""
	return {
		"available": _available_pool.size(),
		"active": _active_pool.size(),
		"total_instantiated": _total_instantiated,
		"pool_efficiency": float(_available_pool.size()) / float(_total_instantiated) if _total_instantiated > 0 else 0.0
	}


func clear_pool() -> void:
	"""Clear all projectiles from the pool (use on scene change)"""
	# Free all available projectiles
	for projectile in _available_pool:
		if projectile and is_instance_valid(projectile):
			projectile.queue_free()
	_available_pool.clear()
	
	# Free all active projectiles
	for projectile in _active_pool:
		if projectile and is_instance_valid(projectile):
			projectile.queue_free()
	_active_pool.clear()

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _create_projectile() -> SpellProjectile:
	"""Create a new projectile instance"""
	if _projectile_scene == null:
		push_error("ProjectilePool: Projectile scene not found")
		return null
	
	var projectile = _projectile_scene.instantiate() as SpellProjectile
	add_child(projectile)
	_total_instantiated += 1
	
	# Hide and disable initially
	projectile.hide()
	projectile.set_physics_process(false)
	
	return projectile


func _reset_projectile(projectile: SpellProjectile) -> void:
	"""Reset projectile to a clean state"""
	if projectile == null or not is_instance_valid(projectile):
		return
	
	# Reset position and velocity
	projectile.global_position = Vector3.ZERO
	projectile._velocity = Vector3.ZERO
	
	# Reset properties
	projectile.caster = null
	projectile.spell = null
	projectile.direction = Vector3.FORWARD
	projectile.speed = 30.0
	projectile.projectile_gravity = 0.0
	projectile.homing_strength = 0.0
	projectile.pierce_remaining = 0
	projectile.bounce_remaining = 0
	projectile.lifetime = 5.0
	projectile.effects.clear()
	
	# Reset internal state
	projectile._hit_targets.clear()
	projectile._homing_target = null
	projectile._age = 0.0
