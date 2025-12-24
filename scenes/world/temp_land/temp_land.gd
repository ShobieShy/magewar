## TempLand - A procedurally generated large-scale location
## populated with hills and small towns.
extends Node3D

const TERRAIN_SIZE = 1000.0
const TERRAIN_RESOLUTION = 256
const MAX_HEIGHT = 50.0
const NUM_TOWNS = 10
const TOWN_RADIUS = 20.0

@onready var player_spawn: Marker3D = $PlayerSpawn

var terrain_noise: FastNoiseLite

func _ready() -> void:
	# Initialize noise
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = randi()
	terrain_noise.frequency = 0.005
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM

	_generate_world()
	
	# Initialize fast travel if available (after generation so we know height)
	if has_node("/root/FastTravelManager"):
		var spawn_height = get_height_at(0, 0)
		FastTravelManager.register_spawn_point("temp_land", Vector3(0, spawn_height + 2, 0))
		
		# Update player spawn marker
		player_spawn.position.y = spawn_height + 2
	
	# Add spawn to group so DungeonPortalSystem can find it
	player_spawn.add_to_group("spawn_points")
	
	# Create safety platform
	var platform = MeshInstance3D.new()
	platform.mesh = CylinderMesh.new()
	platform.mesh.top_radius = 5.0
	platform.mesh.bottom_radius = 5.0
	platform.mesh.height = 1.0
	platform.position = Vector3(0, player_spawn.position.y - 2.5, 0) # Just below spawn
	add_child(platform)
	
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	col.shape = CylinderShape3D.new()
	col.shape.radius = 5.0
	col.shape.height = 1.0
	sb.position = platform.position
	sb.add_child(col)
	add_child(sb)

func _generate_world() -> void:
	print("Generating TempLand...")
	
	# 1. Generate Terrain
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create a simple material for the terrain
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.5, 0.2) # Green grass
	st.set_material(material)
	
	# Generate vertices
	for z in range(TERRAIN_RESOLUTION + 1):
		for x in range(TERRAIN_RESOLUTION + 1):
			var world_x = (float(x) / TERRAIN_RESOLUTION - 0.5) * TERRAIN_SIZE
			var world_z = (float(z) / TERRAIN_RESOLUTION - 0.5) * TERRAIN_SIZE
			var height = get_height_at(world_x, world_z)
			
			var uv = Vector2(float(x) / TERRAIN_RESOLUTION, float(z) / TERRAIN_RESOLUTION) * 10.0 # Tiling UV
			st.set_uv(uv)
			st.add_vertex(Vector3(world_x, height, world_z))
			
	# Generate indices
	for z in range(TERRAIN_RESOLUTION):
		for x in range(TERRAIN_RESOLUTION):
			var top_left = z * (TERRAIN_RESOLUTION + 1) + x
			var top_right = top_left + 1
			var bottom_left = (z + 1) * (TERRAIN_RESOLUTION + 1) + x
			var bottom_right = bottom_left + 1
			
			st.add_index(top_left)
			st.add_index(bottom_left)
			st.add_index(top_right)
			
			st.add_index(top_right)
			st.add_index(bottom_left)
			st.add_index(bottom_right)
			
	st.generate_normals()
	var mesh = st.commit()
	
	# Create MeshInstance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "TerrainMesh"
	add_child(mesh_instance)
	
	# Create Collision
	var static_body = StaticBody3D.new()
	static_body.name = "TerrainBody"
	var col_shape = CollisionShape3D.new()
	col_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(col_shape)
	add_child(static_body)
	
	# 2. Generate Towns
	for i in range(NUM_TOWNS):
		var angle = randf() * TAU
		var dist = randf_range(50.0, TERRAIN_SIZE * 0.4)
		var town_x = cos(angle) * dist
		var town_z = sin(angle) * dist
		var town_y = get_height_at(town_x, town_z)
		
		_generate_town(Vector3(town_x, town_y, town_z))
		
	# 3. Add Environment

	var env = WorldEnvironment.new()
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var proc_sky = ProceduralSkyMaterial.new()
	sky.sky_material = proc_sky
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.shadow_enabled = true
	add_child(sun)

func _generate_town(center: Vector3) -> void:
	var town_node = Node3D.new()
	town_node.name = "Town_%d" % center.length()
	town_node.position = center
	add_child(town_node)
	
	# Flatten terrain under town (visual only hack: place a platform)
	var platform = MeshInstance3D.new()
	platform.mesh = CylinderMesh.new()
	platform.mesh.top_radius = TOWN_RADIUS
	platform.mesh.bottom_radius = TOWN_RADIUS
	platform.mesh.height = 1.0
	platform.position.y = -0.5
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2) # Dirt/Cobblestone
	platform.mesh.material = mat
	town_node.add_child(platform)
	
	# Add houses
	var num_houses = randi_range(3, 8)
	for i in range(num_houses):
		var angle = randf() * TAU
		var dist = randf_range(5.0, TOWN_RADIUS - 2.0)
		var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		
		_create_house(town_node, offset)

func _create_house(parent: Node, local_pos: Vector3) -> void:
	var house = Node3D.new()
	house.position = local_pos
	# Random rotation
	house.rotation.y = randf() * TAU
	parent.add_child(house)
	
	# Base
	var base = MeshInstance3D.new()
	base.mesh = BoxMesh.new()
	base.mesh.size = Vector3(4, 3, 4)
	base.position.y = 1.5
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.6, 0.5, 0.4)
	base.mesh.material = wall_mat
	house.add_child(base)
	
	# Roof
	var roof = MeshInstance3D.new()
	roof.mesh = PrismMesh.new()
	roof.mesh.size = Vector3(5, 2, 5)
	roof.position.y = 4.0
	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.4, 0.1, 0.1)
	roof.mesh.material = roof_mat
	house.add_child(roof)
	
	# Collision
	var sb = StaticBody3D.new()
	var col = CollisionShape3D.new()
	col.shape = BoxMesh.new().create_convex_shape() # Simplified
	# Actually simple box shape for base
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(4, 3, 4)
	col.shape = box_shape
	col.position.y = 1.5
	sb.add_child(col)
	house.add_child(sb)

# Helper to re-calculate height for town placement
func get_height_at(x: float, z: float, _unused_noise: FastNoiseLite = null) -> float:
	if terrain_noise == null:
		return 0.0
	
	var height = terrain_noise.get_noise_2d(x, z) * MAX_HEIGHT
	
	# Flatten center for spawn (replicate logic from generation)
	if Vector2(x, z).length() < 20.0:
		height = lerp(height, 0.0, 0.8)
		
	return height
