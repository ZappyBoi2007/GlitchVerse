class_name PolarityController
extends Node3D

signal target_changed(target: Node, valid: bool)
signal polarity_result(message: String, success: bool)

@export_range(2.0, 20.0, 0.5) var maximum_range := 12.0
@onready var ray: RayCast3D = $PolarityRay

var player: CharacterBody3D
var current_target: Node


func _ready() -> void:
	player = _find_player()
	ray.target_position = Vector3(0, 0, -maximum_range)
	if player != null:
		ray.add_exception(player)


func _physics_process(_delta: float) -> void:
	ray.force_raycast_update()
	var next_target: Node
	if ray.is_colliding():
		next_target = _find_polarity_target(ray.get_collider())
	if next_target == current_target:
		return
	_set_highlight(current_target, false)
	current_target = next_target
	_set_highlight(current_target, true)
	target_changed.emit(current_target, current_target != null)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("polarity") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		try_activate()
		get_viewport().set_input_as_handled()


func try_activate() -> bool:
	if current_target == null or not current_target.has_method("toggle_polarity"):
		polarity_result.emit("POLARITY // INVALID TARGET", false)
		return false
	var success := bool(current_target.call("toggle_polarity", player))
	polarity_result.emit("POLARITY // INVERTED" if success else "POLARITY // TARGET LOCKED", success)
	return success


func set_target_for_test(target: Node) -> void:
	current_target = target


func _find_polarity_target(collider: Object) -> Node:
	var candidate := collider as Node
	while candidate != null:
		if candidate.is_in_group("polarity_target") and candidate.has_method("toggle_polarity"):
			return candidate
		candidate = candidate.get_parent()
	return null


func _set_highlight(target: Node, enabled: bool) -> void:
	if is_instance_valid(target) and target.has_method("set_polarity_highlight"):
		target.call("set_polarity_highlight", enabled)


func _find_player() -> CharacterBody3D:
	var candidate: Node = self
	while candidate != null:
		if candidate is CharacterBody3D:
			return candidate
		candidate = candidate.get_parent()
	return null
