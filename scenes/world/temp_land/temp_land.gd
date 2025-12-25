## TempLand - A flat open world location
## Editable in the editor.
extends Node3D

@onready var player_spawn: Marker3D = $PlayerSpawn

func _ready() -> void:
	# Initialize fast travel if available
	if has_node("/root/FastTravelManager"):
		# Register spawn point at height 0 (flat plane)
		FastTravelManager.register_spawn_point("temp_land", Vector3(0, 0, 0))
		
	# Update player spawn marker to be on the ground
	player_spawn.position.y = 0
	
	# Add spawn to group so DungeonPortalSystem can find it
	player_spawn.add_to_group("spawn_points")
