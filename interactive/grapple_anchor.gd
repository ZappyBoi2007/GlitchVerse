class_name GrappleAnchor
extends StaticBody3D

@export var enabled := true

@onready var highlight: MeshInstance3D = $Highlight
@onready var grapple_point: Marker3D = $GrapplePoint


func _ready() -> void:
	add_to_group("grapple_target")
	highlight.visible = false


func can_grapple() -> bool:
	return enabled


func pulls_player() -> bool:
	return true


func get_grapple_point() -> Vector3:
	return grapple_point.global_position


func set_grapple_highlight(value: bool) -> void:
	highlight.visible = value and enabled
