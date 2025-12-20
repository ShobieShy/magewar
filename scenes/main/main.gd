## Main scene - Entry point and scene loader
extends Node

func _ready() -> void:
	# Load main menu on start (deferred to avoid node removal during setup)
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/menus/main_menu.tscn")
