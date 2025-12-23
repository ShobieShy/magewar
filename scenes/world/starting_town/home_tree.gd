## HomeTree - Player's personal home/base inside the great tree
## Contains storage chest, crafting station, and personal space
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================

signal storage_accessed()
signal assembly_accessed()
signal exit_triggered()

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export_group("Features")
@export var has_storage_chest: bool = true
@export var has_assembly_station: bool = true
@export var has_bed: bool = true

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var storage_chest: Node3D = $StorageChest
@onready var assembly_station: Node3D = $AssemblyStation
@onready var bed: Node3D = $Bed

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	_setup_storage()
	_setup_assembly()
	_setup_bed()
	
	# Register spawn point (deferred to ensure valid transform)
	call_deferred("_register_spawn")


func _register_spawn() -> void:
	FastTravelManager.register_spawn_point("home_tree", get_player_spawn_position())
	FastTravelManager.unlock_portal("home_tree")

# =============================================================================
# STORAGE CHEST
# =============================================================================

func _setup_storage() -> void:
	if not has_storage_chest:
		if storage_chest:
			storage_chest.queue_free()
		return
	
	if storage_chest == null:
		_create_storage_chest()
	
	if storage_chest and storage_chest.has_signal("storage_opened"):
		storage_chest.storage_opened.connect(_on_storage_opened)


func _create_storage_chest() -> void:
	var chest_script = load("res://scenes/world/storage_chest.gd")
	if chest_script == null:
		return
	
	storage_chest = StaticBody3D.new()
	storage_chest.set_script(chest_script)
	storage_chest.name = "StorageChest"
	storage_chest.chest_name = "Home Storage"
	
	# Add interactable child
	var interactable = Area3D.new()
	interactable.set_script(load("res://scripts/components/interactable.gd"))
	storage_chest.add_child(interactable)
	
	var spawn_marker = get_node_or_null("StorageChestSpawn")
	if spawn_marker:
		storage_chest.global_position = spawn_marker.global_position
	else:
		storage_chest.position = Vector3(-3, 0, 0)
	
	add_child(storage_chest)


func _on_storage_opened() -> void:
	storage_accessed.emit()

# =============================================================================
# ASSEMBLY STATION
# =============================================================================

func _setup_assembly() -> void:
	if not has_assembly_station:
		if assembly_station:
			assembly_station.queue_free()
		return
	
	if assembly_station == null:
		_create_assembly_station()
	
	if assembly_station and assembly_station.has_signal("station_opened"):
		assembly_station.station_opened.connect(_on_assembly_opened)


func _create_assembly_station() -> void:
	var station_script = load("res://scenes/world/assembly_station.gd")
	if station_script == null:
		return
	
	assembly_station = StaticBody3D.new()
	assembly_station.set_script(station_script)
	assembly_station.name = "AssemblyStation"
	assembly_station.station_name = "Home Workbench"
	
	# Add interactable child
	var interactable = Area3D.new()
	interactable.set_script(load("res://scripts/components/interactable.gd"))
	assembly_station.add_child(interactable)
	
	var spawn_marker = get_node_or_null("AssemblyStationSpawn")
	if spawn_marker:
		assembly_station.global_position = spawn_marker.global_position
	else:
		assembly_station.position = Vector3(3, 0, 0)
	
	add_child(assembly_station)


func _on_assembly_opened() -> void:
	assembly_accessed.emit()

# =============================================================================
# BED (REST/SAVE POINT)
# =============================================================================

func _setup_bed() -> void:
	if not has_bed:
		if bed:
			bed.queue_free()
		return
	
	# Bed can be used to save game manually and restore health
	if bed and bed.has_signal("interacted"):
		bed.interacted.connect(_on_bed_used)


func _on_bed_used(player: Node) -> void:
	# Restore player health
	if player.has_method("restore_health"):
		player.restore_health()
	
	# Save game
	SaveManager.save_all()
	
	# Show notification
	print("Game saved. Health restored.")

# =============================================================================
# UTILITY
# =============================================================================

func get_player_spawn_position() -> Vector3:
	if player_spawn:
		return player_spawn.global_position
	return Vector3(0, 1, 0)
