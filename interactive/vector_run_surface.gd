class_name VectorRunSurface
extends StaticBody3D

@export var enabled := true

@onready var indicator: MeshInstance3D = $Indicator


func _ready() -> void:
	add_to_group("vector_run_surface")
	indicator.visible = enabled


func can_vector_run() -> bool:
	return enabled
