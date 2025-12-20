## QuestTrigger - Generic trigger node for quest objectives
## Place in maps to trigger various quest objective types
## Configurable via exports for easy map-making
class_name QuestTrigger
extends Area3D

# =============================================================================
# SIGNALS
# =============================================================================

signal triggered(trigger: QuestTrigger, body: Node)
signal objective_completed(trigger: QuestTrigger)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Trigger Info")
@export var trigger_id: String = ""  ## Unique ID for this trigger
@export var objective_type: Enums.ObjectiveType = Enums.ObjectiveType.DISCOVER_AREA
@export var description: String = ""  ## Optional description for editor

@export_group("Activation")
@export var trigger_once: bool = true  ## Only trigger once
@export var requires_quest: String = ""  ## Only active if this quest is active
@export var requires_objective: String = ""  ## Only for specific objective ID
@export var auto_report: bool = true  ## Automatically report to QuestManager

@export_group("Player Detection")
@export var detect_players: bool = true
@export var require_all_players: bool = false  ## All players must be in trigger

@export_group("Survive Time Settings")
@export var survive_duration: float = 0.0  ## For SURVIVE_TIME objectives
@export var reset_on_exit: bool = true  ## Reset timer when player leaves

@export_group("Escort Settings")
@export var is_escort_destination: bool = false  ## This is where escort NPC should reach
@export var escort_npc_id: String = ""  ## Which NPC this destination is for

@export_group("Custom Trigger")
@export var custom_quest_id: String = ""  ## For CUSTOM objectives
@export var custom_objective_id: String = ""

@export_group("Visual Feedback")
@export var show_area_indicator: bool = false
@export var indicator_color: Color = Color(0.0, 1.0, 0.5, 0.3)

# =============================================================================
# PROPERTIES
# =============================================================================

var has_triggered: bool = false
var players_in_area: Array[Node] = []
var _survive_timer: float = 0.0
var _is_surviving: bool = false

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Set up collision
	collision_layer = 0
	collision_mask = Constants.LAYER_PLAYERS
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create collision shape if none exists
	if get_child_count() == 0 or not has_node("CollisionShape3D"):
		_create_default_collision()
	
	# Create visual indicator if enabled
	if show_area_indicator:
		_create_area_indicator()


func _process(delta: float) -> void:
	if not _is_surviving:
		return
	
	# Update survive timer
	if objective_type == Enums.ObjectiveType.SURVIVE_TIME:
		_survive_timer += delta
		if _survive_timer >= survive_duration:
			_complete_survive_objective()

# =============================================================================
# COLLISION HANDLING
# =============================================================================

func _on_body_entered(body: Node) -> void:
	if not detect_players:
		return
	
	if not _is_player(body):
		return
	
	if body not in players_in_area:
		players_in_area.append(body)
	
	_check_trigger_condition(body)


func _on_body_exited(body: Node) -> void:
	if body in players_in_area:
		players_in_area.erase(body)
	
	# Reset survive timer if configured
	if objective_type == Enums.ObjectiveType.SURVIVE_TIME and reset_on_exit:
		if players_in_area.is_empty():
			_survive_timer = 0.0
			_is_surviving = false


func _is_player(body: Node) -> bool:
	return body.is_in_group("players") or body.get_script() and body.get_script().get_global_name() == "Player"

# =============================================================================
# TRIGGER LOGIC
# =============================================================================

func _check_trigger_condition(triggering_body: Node) -> void:
	# Check if already triggered
	if trigger_once and has_triggered:
		return
	
	# Check quest requirement
	if not requires_quest.is_empty():
		if not QuestManager.is_quest_active(requires_quest):
			return
	
	# Check all players requirement
	if require_all_players:
		# Would need to check against total player count
		var total_players = get_tree().get_nodes_in_group("players").size()
		if players_in_area.size() < total_players:
			return
	
	# Handle based on objective type
	match objective_type:
		Enums.ObjectiveType.DISCOVER_AREA:
			_trigger_discover()
		
		Enums.ObjectiveType.SURVIVE_TIME:
			_start_survive()
		
		Enums.ObjectiveType.INTERACT_OBJECT:
			# This type is handled by manual interaction, not auto-trigger
			pass
		
		Enums.ObjectiveType.CUSTOM:
			_trigger_custom()
		
		_:
			# Default behavior - just report the trigger
			_trigger_generic()
	
	triggered.emit(self, triggering_body)


func _trigger_discover() -> void:
	has_triggered = true
	
	if auto_report:
		QuestManager.report_area_entered(trigger_id)
	
	# Also discover location in SaveManager
	if not trigger_id.is_empty():
		SaveManager.discover_location(trigger_id)
	
	objective_completed.emit(self)


func _start_survive() -> void:
	if _is_surviving:
		return
	
	_is_surviving = true
	_survive_timer = 0.0


func _complete_survive_objective() -> void:
	_is_surviving = false
	has_triggered = true
	
	if auto_report:
		# Report to quest with the trigger_id as the area
		QuestManager.report_area_entered(trigger_id)
	
	objective_completed.emit(self)


func _trigger_custom() -> void:
	has_triggered = true
	
	if auto_report and not custom_quest_id.is_empty() and not custom_objective_id.is_empty():
		QuestManager.report_custom_objective(custom_quest_id, custom_objective_id, true)
	
	objective_completed.emit(self)


func _trigger_generic() -> void:
	has_triggered = true
	
	if auto_report:
		QuestManager.report_area_entered(trigger_id)
	
	objective_completed.emit(self)

# =============================================================================
# MANUAL TRIGGERS
# =============================================================================

func interact() -> void:
	## Called when player manually interacts with this trigger
	if trigger_once and has_triggered:
		return
	
	# Check quest requirement
	if not requires_quest.is_empty():
		if not QuestManager.is_quest_active(requires_quest):
			return
	
	has_triggered = true
	
	if auto_report:
		match objective_type:
			Enums.ObjectiveType.INTERACT_OBJECT:
				QuestManager.report_object_interacted(trigger_id)
			Enums.ObjectiveType.CUSTOM:
				if not custom_quest_id.is_empty() and not custom_objective_id.is_empty():
					QuestManager.report_custom_objective(custom_quest_id, custom_objective_id, true)
			_:
				QuestManager.report_area_entered(trigger_id)
	
	triggered.emit(self, null)
	objective_completed.emit(self)


func report_escort_arrived(npc: Node) -> void:
	## Called when an escort NPC reaches this destination
	if not is_escort_destination:
		return
	
	if not escort_npc_id.is_empty() and npc.get("npc_id") != escort_npc_id:
		return
	
	has_triggered = true
	
	if auto_report:
		QuestManager.report_escort_progress(escort_npc_id, true, false)
	
	objective_completed.emit(self)

# =============================================================================
# RESET
# =============================================================================

func reset_trigger() -> void:
	has_triggered = false
	_survive_timer = 0.0
	_is_surviving = false

# =============================================================================
# VISUAL HELPERS
# =============================================================================

func _create_default_collision() -> void:
	var shape = CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	
	var box = BoxShape3D.new()
	box.size = Vector3(4, 2, 4)
	shape.shape = box
	
	add_child(shape)


func _create_area_indicator() -> void:
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape == null:
		return
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "AreaIndicator"
	
	if collision_shape.shape is BoxShape3D:
		var box_mesh = BoxMesh.new()
		box_mesh.size = collision_shape.shape.size
		mesh_instance.mesh = box_mesh
	elif collision_shape.shape is SphereShape3D:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = collision_shape.shape.radius
		sphere_mesh.height = collision_shape.shape.radius * 2
		mesh_instance.mesh = sphere_mesh
	elif collision_shape.shape is CylinderShape3D:
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.top_radius = collision_shape.shape.radius
		cylinder_mesh.bottom_radius = collision_shape.shape.radius
		cylinder_mesh.height = collision_shape.shape.height
		mesh_instance.mesh = cylinder_mesh
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = indicator_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

# =============================================================================
# EDITOR HELPERS
# =============================================================================

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if trigger_id.is_empty():
		warnings.append("Trigger ID is empty - this trigger won't report to QuestManager")
	
	if objective_type == Enums.ObjectiveType.SURVIVE_TIME and survive_duration <= 0:
		warnings.append("Survive duration is 0 or negative for SURVIVE_TIME objective")
	
	if objective_type == Enums.ObjectiveType.CUSTOM:
		if custom_quest_id.is_empty():
			warnings.append("Custom quest ID is empty for CUSTOM objective")
		if custom_objective_id.is_empty():
			warnings.append("Custom objective ID is empty for CUSTOM objective")
	
	if is_escort_destination and escort_npc_id.is_empty():
		warnings.append("Escort NPC ID is empty for escort destination")
	
	return warnings
