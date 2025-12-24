class_name Dungeon2
extends ProceduralDungeon

func _init() -> void:
	dungeon_id = 2
	dungeon_name = "The Forgotten Caves"
	max_floors = 40 # Can be overridden by template system

func _ready() -> void:
	super._ready()

func setup_dungeon() -> void:
	super.setup_dungeon()
	setup_treasure_room()
	bake_navigation_mesh()

func setup_treasure_room() -> void:
	var treasure_chest = find_child("TreasureChest", true, false)
	if treasure_chest:
		treasure_chest.connect("opened", Callable(self, "_on_treasure_opened"))
		# Set loot table via template system if possible

func _on_treasure_opened() -> void:
	# Custom logic
	pass

func bake_navigation_mesh() -> void:
	var nav_region = find_child("NavigationRegion3D", true, false)
	if nav_region:
		nav_region.bake_navigation_mesh()
