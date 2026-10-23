class_name FallHazard
extends Area3D

## Reusable player-only failure volume. The owning GameplayLevel decides how a
## failure is handled, so this stays independent from GameFlowManager.

signal failure_requested(reason: String)

@export var failure_reason := "PLAYER LOST OUTSIDE THE SIMULATION"

var _failure_reported := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func try_trigger(body: Node3D) -> bool:
	if _failure_reported or body == null:
		return false
	if not body is CharacterBody3D or not body.is_in_group("player"):
		return false
	_failure_reported = true
	failure_requested.emit(failure_reason)
	return true


func _on_body_entered(body: Node3D) -> void:
	try_trigger(body)
