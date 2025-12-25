extends Node3D

# References to the sub-scenes
const TOWN_SQUARE_SCENE = preload("res://scenes/world/starting_town/town_square.tscn")
const LANDFILL_SCENE = preload("res://scenes/world/landfill/landfill.tscn")
const TEMP_LAND_SCENE = preload("res://scenes/world/temp_land/temp_land.tscn")

# Layout configurations
var locations = {
	"town_square": {
		"scene": TOWN_SQUARE_SCENE,
		"position": Vector3.ZERO,
		"rotation": Vector3.ZERO
	},
	"landfill": {
		"scene": LANDFILL_SCENE,
		"position": Vector3(0, 0, -300), # North of town
		"rotation": Vector3.ZERO
	},
	"temp_land": {
		"scene": TEMP_LAND_SCENE,
		"position": Vector3(300, 0, 0), # East of town
		"rotation": Vector3.ZERO
	}
}

func _ready():
	_instantiate_world()
	_connect_locations()

func _instantiate_world():
	print("Instantiating Overworld...")
	
	for key in locations:
		var config = locations[key]
		var instance = config.scene.instantiate()
		instance.name = key.capitalize().replace(" ", "")
		add_child(instance)
		instance.global_position = config.position
		instance.rotation_degrees = config.rotation
		
		# Clean up duplicate environments/lights
		# We'll keep the ones from Town Square as the global default
		if key != "town_square":
			_remove_environment_nodes(instance)
			
	_create_connectors()

func _create_connectors():
	# Create ground connecting Town (0,0,0) to Landfill (0,0,-300)
	var path_to_landfill = StaticBody3D.new()
	path_to_landfill.name = "PathToLandfill"
	add_child(path_to_landfill)
	
	var col_shape1 = CollisionShape3D.new()
	var box1 = BoxShape3D.new()
	box1.size = Vector3(20, 1.0, 280)
	col_shape1.shape = box1
	path_to_landfill.add_child(col_shape1)
	path_to_landfill.global_position = Vector3(0, -0.5, -150)
	
	var mesh_inst1 = MeshInstance3D.new()
	var box_mesh1 = BoxMesh.new()
	box_mesh1.size = Vector3(20, 1.0, 280)
	mesh_inst1.mesh = box_mesh1
	path_to_landfill.add_child(mesh_inst1)
	
	# Create ground connecting Town (0,0,0) to Temp Land (300,0,0)
	var path_to_temp = StaticBody3D.new()
	path_to_temp.name = "PathToTempLand"
	add_child(path_to_temp)
	
	var col_shape2 = CollisionShape3D.new()
	var box2 = BoxShape3D.new()
	box2.size = Vector3(280, 1.0, 20)
	col_shape2.shape = box2
	path_to_temp.add_child(col_shape2)
	path_to_temp.global_position = Vector3(150, -0.5, 0)

	var mesh_inst2 = MeshInstance3D.new()
	var box_mesh2 = BoxMesh.new()
	box_mesh2.size = Vector3(280, 1.0, 20)
	mesh_inst2.mesh = box_mesh2
	path_to_temp.add_child(mesh_inst2)

func _remove_environment_nodes(node: Node):
	# Recursively remove WorldEnvironment and DirectionalLight3D from sub-scenes
	# to prevent conflicts, except for the main one
	for child in node.get_children():
		if child is WorldEnvironment or child is DirectionalLight3D:
			child.queue_free()
		# Don't recurse too deep, these are usually top-level
		
func _connect_locations():
	# Disable the portal in Town that leads to Landfill (now walkable)
	var town = get_node_or_null("TownSquare")
	if town:
		# The path is likely "Portals/PortalLandfill" based on town_square.tscn
		var portal = town.find_child("PortalLandfill", true, false)
		if portal:
			print("Disabling internal portal: PortalLandfill")
			portal.queue_free() # Remove it completely
			
	# Disable the portal in Landfill that leads to Town
	var landfill = get_node_or_null("Landfill")
	if landfill:
		# The path is likely "Portal" based on landfill.tscn
		var portal = landfill.find_child("Portal", true, false) # It's just named "Portal" and links to "entrance" of "town_square"
		if portal:
			# Verify it's the one linking to town
			if portal.get("dungeon_id") == "town_square":
				print("Disabling internal portal: Landfill Exit")
				portal.queue_free()

func load_world(path: String):
	# Compatibility for Game.gd calling load_world on the current scene
	# If we are already the Overworld, we might not need to do anything,
	# or Game.gd handles the actual switching. 
	# This function exists to satisfy the check in GameManager.load_scene
	pass
