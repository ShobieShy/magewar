## TownSquare - Main hub area of Starting Town
## Central area with access to shops, NPCs, and travel points
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal npc_spawned(npc: Node)
signal portal_activated(portal_id: String)

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("NPCs")
@export var spawn_crazy_joe: bool = true
@export var spawn_bob: bool = true

@export_group("Portals")
@export var landfill_unlocked: bool = false

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var npc_spawns: Node3D = $NPCSpawns
@onready var portal_landfill: Node3D = $Portals/PortalLandfill

# =============================================================================
# PROPERTIES
# =============================================================================

var _npcs: Dictionary = {}  # npc_id -> NPC node

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Use call_deferred to ensure we are fully in the tree and transforms are valid
	call_deferred("_initialize_scene")


func _initialize_scene() -> void:
	_spawn_npcs()
	_setup_portals()
	_setup_shop()
	_spawn_vendor_npc()
	_spawn_skill_trainer_npc()
	
	# Register with FastTravelManager
	FastTravelManager.register_spawn_point("starting_town", get_player_spawn_position())

# =============================================================================
# NPC MANAGEMENT
# =============================================================================

func _spawn_npcs() -> void:
	if spawn_crazy_joe:
		_spawn_npc("crazy_joe", "CrazyJoeSpawn")
	
	if spawn_bob:
		_spawn_npc("bob", "BobSpawn")


func _spawn_npc(npc_id: String, spawn_node_name: String) -> void:
	var spawn_point = npc_spawns.get_node_or_null(spawn_node_name)
	if spawn_point == null:
		push_warning("NPC spawn point not found: " + spawn_node_name)
		return
	
	# Load NPC scene
	var npc_path = "res://scenes/npcs/%s.tscn" % npc_id
	if not ResourceLoader.exists(npc_path):
		# Try creating a generic NPC
		var npc = _create_generic_npc(npc_id)
		if npc:
			npc.global_position = spawn_point.global_position
			add_child(npc)
			_npcs[npc_id] = npc
			npc_spawned.emit(npc)
		return
	
	var npc_scene = load(npc_path)
	if npc_scene:
		var npc = npc_scene.instantiate()
		npc.global_position = spawn_point.global_position
		add_child(npc)
		_npcs[npc_id] = npc
		npc_spawned.emit(npc)


func _create_generic_npc(npc_id: String) -> Node:
	## Create a basic NPC node with the NPC script
	var npc_script = load("res://scripts/components/npc.gd")
	if npc_script == null:
		return null
	
	var npc = CharacterBody3D.new()
	npc.set_script(npc_script)
	npc.name = npc_id.capitalize().replace("_", "")
	npc.npc_id = npc_id
	
	# Configure based on NPC type
	match npc_id:
		"crazy_joe":
			npc.npc_name = "Crazy Joe"
			npc.dialogue_id = "crazy_joe_intro"
		"bob":
			npc.npc_name = "???"
			npc.dialogue_id = "bob_intro"
		_:
			npc.npc_name = npc_id.capitalize()
	
	# Add collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	collision.shape = shape
	collision.position = Vector3(0, 0.9, 0)
	npc.add_child(collision)
	
	# Add visual placeholder
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.35
	capsule_mesh.height = 1.6
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position = Vector3(0, 0.9, 0)
	npc.add_child(mesh_instance)
	
	return npc


func _spawn_vendor_npc() -> void:
	var vendor_scene = preload("res://scenes/world/starting_town/vendor_npc.tscn")
	if vendor_scene:
		var vendor = vendor_scene.instantiate()
		vendor.position = Vector3(-5, 0, 0)  # Position on left side of Town Square
		add_child(vendor)
		_npcs["vendor"] = vendor
		npc_spawned.emit(vendor)


func _spawn_skill_trainer_npc() -> void:
	var trainer_scene = preload("res://scenes/world/starting_town/skill_trainer_npc.tscn")
	if trainer_scene:
		var trainer = trainer_scene.instantiate()
		trainer.position = Vector3(5, 0, 0)  # Position on right side of Town Square
		add_child(trainer)
		_npcs["skill_trainer"] = trainer
		npc_spawned.emit(trainer)


func get_npc(npc_id: String) -> Node:
	return _npcs.get(npc_id)

# =============================================================================
# SHOP SETUP
# =============================================================================

func _setup_shop() -> void:
	# Load and register the town shop
	var shop_data = load("res://resources/shops/town_shop.tres")
	if shop_data:
		ShopManager.register_shop(shop_data)
	else:
		push_warning("Failed to load town_shop.tres")

# =============================================================================
# PORTALS
# =============================================================================

func _setup_portals() -> void:
	# Check which portals should be unlocked
	landfill_unlocked = SaveManager.is_quest_completed("tutorial_landfill") or \
						"landfill" in SaveManager.world_data.unlocked_portals
	
	if portal_landfill:
		if portal_landfill.has_method("set_active"):
			portal_landfill.set_active(landfill_unlocked)
		else:
			portal_landfill.visible = landfill_unlocked


func unlock_portal(portal_id: String) -> void:
	match portal_id:
		"landfill":
			landfill_unlocked = true
			if portal_landfill:
				portal_landfill.set_active(true)
	
	portal_activated.emit(portal_id)

# =============================================================================
# UTILITY
# =============================================================================

func get_player_spawn_position() -> Vector3:
	if player_spawn:
		return player_spawn.global_position
	return Vector3(0, 1, 0)
