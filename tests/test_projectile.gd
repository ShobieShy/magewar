extends Node

func _ready():
    var scene = load("res://scenes/spells/projectile.tscn")
    if not scene:
        print("ERROR: Failed to load projectile scene")
        return
    
    print("Scene loaded: ", scene)
    print("Scene resource: ", scene.resource_path)
    
    var instance = scene.instantiate()
    if not instance:
        print("ERROR: Failed to instantiate projectile")
        return
    
    print("Projectile instantiated successfully: ", instance)
    print("Projectile name: ", instance.name)
    print("Projectile script: ", instance.get_script())
