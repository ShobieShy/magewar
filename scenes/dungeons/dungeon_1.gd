class_name Dungeon1
extends ProceduralDungeon

# =============================================================================
# SETUP
# =============================================================================

func _init() -> void:
	dungeon_id = 1
	dungeon_name = "Abandoned Mine"
	max_floors = 20 # Can be overridden by template system

func _ready() -> void:
	super._ready()

func setup_dungeon() -> void:
	# Call parent setup first to load data
	super.setup_dungeon()
	
	# Dungeon 1 specific setup
	setup_treasure_room()
	bake_navigation_mesh()

func setup_treasure_room() -> void:
	"""Set up all dungeon chests with appropriate loot"""
	# ... (Keep existing treasure room logic or adapt)
	var treasure_chest = find_child("TreasureChest", true, false)
	if treasure_chest:
		treasure_chest.connect("opened", Callable(self, "_on_treasure_opened"))
		# ... set loot table based on current floor/difficulty
		
func _on_treasure_opened() -> void:
	# Custom logic
	pass

func bake_navigation_mesh() -> void:
	var nav_region = find_child("NavigationRegion3D", true, false)
	if nav_region:
		nav_region.bake_navigation_mesh()

# Override collect_spawn_points to match scene structure if needed
func collect_spawn_points() -> void:
	spawn_points.clear()
	var spawn_nodes = find_children("*", "Node3D", true, false)
	for node in spawn_nodes:
		if node.name.to_lower().contains("spawn"):
			spawn_points.append(node.global_position)
	
	if spawn_points.is_empty():
		# Fallback points from original Dungeon1
		spawn_points.append_array([
			Vector3(-15, 0, 15),
			Vector3(-17, 0, 17),
			Vector3(15, 0, 15),
			Vector3(17, 0, 13),
			Vector3(0, 0, 15),
			Vector3(0, 0, 20),
		])
