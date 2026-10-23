class_name RetractableBridge
extends AnimatableBody3D

signal deployment_started
signal deployment_completed

@export var deployed_offset := Vector3(0, 4.5, 0)
@export_range(0.1, 3.0, 0.05) var deployment_duration := 0.7

var is_deployed := false
var _start_position := Vector3.ZERO


func _ready() -> void:
	_start_position = position


func activate() -> bool:
	if is_deployed:
		return false
	is_deployed = true
	deployment_started.emit()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", _start_position + deployed_offset, deployment_duration)
	tween.finished.connect(_on_deployment_completed, CONNECT_ONE_SHOT)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(&"bridge_deploy", global_position, -4.0, 1.0, 28.0)
	return true


func _on_deployment_completed() -> void:
	deployment_completed.emit()
