class_name SystemBreachBridge
extends Node

signal deployment_completed

@export_range(0.2, 3.0, 0.1) var deployment_duration := 0.8
var bridge_shape: CSGShape3D
var target_marker: Node3D
var is_deployed := false


func configure(shape: CSGShape3D, target: Node3D) -> void:
	bridge_shape = shape
	target_marker = target


func activate() -> void:
	if is_deployed or bridge_shape == null or target_marker == null:
		return
	is_deployed = true
	bridge_shape.visible = true
	bridge_shape.use_collision = true
	var target_position := target_marker.global_position - Vector3.UP * 0.3
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(bridge_shape, "global_position", target_position, deployment_duration)
	tween.finished.connect(_finish_deployment, CONNECT_ONE_SHOT)


func _finish_deployment() -> void:
	deployment_completed.emit()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(&"bridge_deploy", bridge_shape.global_position, -3.0, 1.0, 26.0)
