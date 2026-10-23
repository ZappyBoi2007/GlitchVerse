class_name RealityDebugger
extends RayCast3D

## Player-side ability selector and interaction ray.
## Interactables use a small duck-typed API, keeping this system independent of UI.

signal ability_changed(ability_label: String, ability_color: Color)
signal target_changed(target_label: String, compatible: bool, has_target: bool)
signal feedback_changed(message: String, is_error: bool)

const PHASE: StringName = &"phase"
const GRAVITY: StringName = &"gravity"
const FREEZE: StringName = &"freeze"

@export_range(2.0, 30.0, 0.5) var interaction_distance: float = 12.0

var selected_ability: StringName = PHASE
var _last_target_signature := ""


func _ready() -> void:
	target_position = Vector3(0.0, 0.0, -interaction_distance)
	enabled = true
	collide_with_bodies = true
	collide_with_areas = true
	add_to_group("reality_debugger")
	_exclude_player_body()
	call_deferred("_broadcast_initial_state")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_phase"):
		_select_ability(PHASE)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_gravity"):
		_select_ability(GRAVITY)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_freeze"):
		_select_ability(FREEZE)
		get_viewport().set_input_as_handled()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	):
		_activate_selected_ability()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	_update_target_feedback()


func get_selected_ability_label() -> String:
	return String(selected_ability).to_upper()


func get_selected_ability_color() -> Color:
	match selected_ability:
		GRAVITY:
			return Color("ff4ac6")
		FREEZE:
			return Color("7a8cff")
		_:
			return Color("25ecff")


func _broadcast_initial_state() -> void:
	ability_changed.emit(get_selected_ability_label(), get_selected_ability_color())
	feedback_changed.emit("Select a target and left-click to rewrite reality.", false)
	_update_target_feedback()


func _select_ability(ability: StringName) -> void:
	if selected_ability == ability:
		return
	selected_ability = ability
	_last_target_signature = ""
	ability_changed.emit(get_selected_ability_label(), get_selected_ability_color())
	feedback_changed.emit("%s selected." % get_selected_ability_label(), false)
	_update_target_feedback()


func _activate_selected_ability() -> void:
	force_raycast_update()
	if not is_colliding():
		feedback_changed.emit("NO TARGET // Move within %d metres." % int(interaction_distance), true)
		return

	var interactable := _find_interactable(get_collider())
	if interactable == null:
		feedback_changed.emit("INCOMPATIBLE // Static environment cannot use %s." % get_selected_ability_label(), true)
		return

	var status: Dictionary = interactable.call("get_ability_status", selected_ability)
	if not bool(status.get("compatible", false)):
		feedback_changed.emit("INCOMPATIBLE // %s" % String(status.get("message", "Wrong ability.")), true)
		return

	var result_message := String(interactable.call("apply_ability", selected_ability, self))
	feedback_changed.emit(result_message, false)
	_last_target_signature = ""
	call_deferred("_update_target_feedback")


func _update_target_feedback() -> void:
	force_raycast_update()
	var target_label := "NO TARGET"
	var compatible := false
	var has_target := is_colliding()
	var target_id := 0

	if has_target:
		var interactable := _find_interactable(get_collider())
		if interactable == null:
			target_label = "STATIC ENVIRONMENT"
		else:
			target_id = interactable.get_instance_id()
			target_label = String(interactable.call("get_interaction_name"))
			var status: Dictionary = interactable.call("get_ability_status", selected_ability)
			compatible = bool(status.get("compatible", false))

	var signature := "%s|%s|%s|%s" % [target_id, selected_ability, compatible, has_target]
	if signature != _last_target_signature:
		_last_target_signature = signature
		target_changed.emit(target_label, compatible, has_target)


func _find_interactable(collider: Object) -> Node:
	var candidate := collider as Node
	while candidate != null:
		if (
			candidate.has_method("get_interaction_name")
			and candidate.has_method("get_ability_status")
			and candidate.has_method("apply_ability")
		):
			return candidate
		candidate = candidate.get_parent()
	return null


func _exclude_player_body() -> void:
	var candidate := get_parent()
	while candidate != null:
		if candidate is CollisionObject3D:
			add_exception(candidate)
			return
		candidate = candidate.get_parent()
