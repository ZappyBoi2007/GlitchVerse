class_name InteractionController
extends Node3D

signal target_changed(target: Node, prompt: String)
signal interaction_result(message: String, success: bool)

@export_range(1.0, 8.0, 0.25) var interaction_range := 4.0
@onready var ray: RayCast3D = $InteractionRay

var player: CharacterBody3D
var current_target: Node


func _ready() -> void:
	player = _find_player()
	ray.target_position = Vector3(0, 0, -interaction_range)
	if player != null:
		ray.add_exception(player)


func _physics_process(_delta: float) -> void:
	ray.force_raycast_update()
	var next_target: Node
	if ray.is_colliding():
		next_target = _find_interactable(ray.get_collider())
	if next_target == current_target:
		return
	_set_highlight(current_target, false)
	current_target = next_target
	_set_highlight(current_target, true)
	target_changed.emit(current_target, get_current_prompt())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	try_interact()
	get_viewport().set_input_as_handled()


func try_interact() -> bool:
	if current_target == null or not current_target.has_method("interact"):
		interaction_result.emit("NO INTERACTION TARGET", false)
		return false
	var result: Variant = current_target.call("interact", player)
	var success := true
	var message := "INTERACTION COMPLETE"
	if result is Dictionary:
		success = bool(result.get("success", true))
		message = str(result.get("message", message))
	elif result is bool:
		success = result
	interaction_result.emit(message, success)
	return success


func get_current_prompt() -> String:
	if current_target == null:
		return ""
	if current_target.has_method("get_interaction_prompt"):
		return str(current_target.call("get_interaction_prompt"))
	return "F // INTERACT"


func set_target_for_test(target: Node) -> void:
	_set_highlight(current_target, false)
	current_target = target
	_set_highlight(current_target, true)
	target_changed.emit(current_target, get_current_prompt())


func _find_interactable(collider: Object) -> Node:
	var candidate := collider as Node
	while candidate != null:
		if candidate.is_in_group("player_interactable") and candidate.has_method("interact"):
			return candidate
		candidate = candidate.get_parent()
	return null


func _set_highlight(target: Node, enabled: bool) -> void:
	if is_instance_valid(target) and target.has_method("set_interaction_highlight"):
		target.call("set_interaction_highlight", enabled)


func _find_player() -> CharacterBody3D:
	var candidate: Node = self
	while candidate != null:
		if candidate is CharacterBody3D:
			return candidate
		candidate = candidate.get_parent()
	return null
