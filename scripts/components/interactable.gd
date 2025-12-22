## Interactable - Base class for all interactable objects
## Handles proximity detection and interaction input
class_name Interactable
extends Area3D

# =============================================================================
# SIGNALS
# =============================================================================

signal interaction_started(player: Node)
# signal interaction_ended(player: Node)  # Currently unused but kept for future implementation
signal player_entered_range(player: Node)
signal player_exited_range(player: Node)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var interaction_prompt: String = "[E] Interact"
@export var interaction_range: float = 2.5
@export var can_interact: bool = true
@export var one_time_only: bool = false

# =============================================================================
# PROPERTIES
# =============================================================================

var players_in_range: Array = []
var has_been_used: bool = false

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Set up collision
	collision_layer = Constants.LAYER_TRIGGERS
	collision_mask = Constants.LAYER_PLAYERS
	
	# Create collision shape if not present
	if get_node_or_null("CollisionShape3D") == null:
		var collision = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = interaction_range
		collision.shape = shape
		add_child(collision)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _input(event: InputEvent) -> void:
	if not can_interact:
		return
	
	if one_time_only and has_been_used:
		return
	
	if event.is_action_pressed("interact"):
		_try_interact()

# =============================================================================
# INTERACTION
# =============================================================================

func _try_interact() -> void:
	if players_in_range.is_empty():
		return
	
	# Get closest player
	var closest_player = _get_closest_player()
	if closest_player == null:
		return
	
	# Only local player can interact
	if not closest_player.is_local_player:
		return
	
	_perform_interaction(closest_player)


func _perform_interaction(player: Node) -> void:
	## Override in subclasses to implement interaction logic
	interaction_started.emit(player)
	
	if one_time_only:
		has_been_used = true
		can_interact = false


func _get_closest_player() -> Node:
	var closest: Node = null
	var closest_dist: float = INF
	
	for player in players_in_range:
		if not is_instance_valid(player):
			continue
		
		var dist = global_position.distance_to(player.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = player
	
	return closest

# =============================================================================
# RANGE DETECTION
# =============================================================================

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		players_in_range.append(body)
		player_entered_range.emit(body)
		
		# Show interact prompt for local player
		if body.is_local_player:
			_show_interact_prompt(body)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		players_in_range.erase(body)
		player_exited_range.emit(body)
		
		# Hide interact prompt
		if body.is_local_player:
			_hide_interact_prompt(body)


func _show_interact_prompt(player: Node) -> void:
	if not can_interact:
		return
	if one_time_only and has_been_used:
		return
	
	# Find player's HUD and show prompt
	var hud = _get_player_hud(player)
	if hud and hud.has_method("show_interact_prompt"):
		hud.show_interact_prompt(interaction_prompt)


func _hide_interact_prompt(player: Node) -> void:
	var hud = _get_player_hud(player)
	if hud and hud.has_method("hide_interact_prompt"):
		hud.hide_interact_prompt()


func _get_player_hud(_player: Node) -> Node:
	# Try to find HUD in the scene
	var game = get_tree().current_scene
	if game:
		return game.get_node_or_null("HUD/PlayerHUD")
	return null

# =============================================================================
# UTILITY
# =============================================================================

func set_interactable(value: bool) -> void:
	can_interact = value
	
	# Update prompts for players in range
	for player in players_in_range:
		if player.is_local_player:
			if value:
				_show_interact_prompt(player)
			else:
				_hide_interact_prompt(player)
