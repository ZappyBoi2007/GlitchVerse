class_name GrappleAnchor
extends StaticBody3D

@export var enabled := true
@export var target_prompt := "E // SWING"
@export_range(0.0, 30.0, 0.1) var maximum_initial_rope_length := 0.0
@export_range(0.0, 12.0, 0.25) var automatic_reel_in_speed := 0.0
@export_range(0.25, 2.0, 0.05) var attachment_assist_multiplier := 1.0
@export var preferred_travel_direction := Vector3.ZERO

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


func get_grapple_prompt() -> String:
	return target_prompt


func get_grapple_rope_limit() -> float:
	return maximum_initial_rope_length


func get_grapple_reel_in_speed() -> float:
	return automatic_reel_in_speed


func get_grapple_assist_multiplier() -> float:
	return attachment_assist_multiplier


func get_grapple_travel_direction() -> Vector3:
	if preferred_travel_direction.is_zero_approx():
		return Vector3.ZERO
	return (global_basis * preferred_travel_direction).normalized()


func set_grapple_highlight(value: bool) -> void:
	highlight.visible = value and enabled
