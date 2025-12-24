class_name Dungeon5
extends ProceduralDungeon

func _init() -> void:
	dungeon_id = 5
	dungeon_name = "Demon's Lair"
	max_floors = 100

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

func _on_treasure_opened() -> void:
	pass

func bake_navigation_mesh() -> void:
	var nav_region = find_child("NavigationRegion3D", true, false)
	if nav_region:
		nav_region.bake_navigation_mesh()
