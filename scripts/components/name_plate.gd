## NamePlate - Displays entity name as 3D billboard text
class_name NamePlate
extends Node3D

# =============================================================================
# PROPERTIES
# =============================================================================

@export var display_name: String = "Entity"
@export var height_offset: float = 3.0
@export var font_size: int = 32
@export var text_color: Color = Color.WHITE
@export var outline_color: Color = Color.BLACK
@export var outline_width: float = 2.0

# =============================================================================
# NODE REFERENCES
# =============================================================================

var label_3d: Label3D = null

# =============================================================================
# BUILT-IN CALLBACKS
# =============================================================================

func _ready() -> void:
	# Create Label3D dynamically
	label_3d = Label3D.new()
	label_3d.text = display_name
	label_3d.font_size = font_size
	label_3d.modulate = text_color
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.no_depth_test = false
	label_3d.outline_size = outline_width
	
	# Create outline material
	var outline_material = StandardMaterial3D.new()
	outline_material.emission = outline_color
	
	add_child(label_3d)
	
	# Position above entity
	label_3d.position.y = height_offset


func set_name_plate_text(text: String) -> void:
	"""Update the display text"""
	display_name = text
	if label_3d:
		label_3d.text = text


func set_name_plate_color(color: Color) -> void:
	"""Update the text color"""
	text_color = color
	if label_3d:
		label_3d.modulate = color
