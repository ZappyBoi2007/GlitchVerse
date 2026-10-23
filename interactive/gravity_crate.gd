class_name GravityCrate
extends RigidBody3D

## A vertically constrained RigidBody3D whose gravity direction can be inverted.

@export var interaction_name := "GRAVITY CRATE"
@export_range(1.0, 8.0, 0.25) var upward_travel_limit := 3.1
@export var normal_material: Material
@export var inverted_material: Material

@onready var mesh: MeshInstance3D = $MeshInstance3D

var gravity_inverted := false
var _spawn_position := Vector3.ZERO


func _ready() -> void:
	_spawn_position = global_position
	_update_state()


func get_interaction_name() -> String:
	return interaction_name


func get_ability_status(ability: StringName) -> Dictionary:
	if ability != RealityDebugger.GRAVITY:
		return {"compatible": false, "message": "This crate accepts GRAVITY only."}
	return {"compatible": true, "message": ""}


func apply_ability(ability: StringName, _source: Node) -> String:
	if ability != RealityDebugger.GRAVITY:
		return "This crate accepts GRAVITY only."
	gravity_inverted = not gravity_inverted
	_update_state()
	return "GRAVITY CRATE // %s" % ("UPWARD" if gravity_inverted else "DOWNWARD")


func _update_state() -> void:
	gravity_scale = -1.0 if gravity_inverted else 1.0
	mesh.material_override = inverted_material if gravity_inverted else normal_material
	sleeping = false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var body_transform := state.transform
	var limited_position := body_transform.origin
	limited_position.x = _spawn_position.x
	limited_position.z = _spawn_position.z
	limited_position.y = clampf(
		limited_position.y,
		_spawn_position.y,
		_spawn_position.y + upward_travel_limit
	)
	if not limited_position.is_equal_approx(body_transform.origin):
		body_transform.origin = limited_position
		state.transform = body_transform
		var limited_velocity := state.linear_velocity
		limited_velocity.x = 0.0
		limited_velocity.z = 0.0
		if (
			(limited_position.y <= _spawn_position.y and limited_velocity.y < 0.0)
			or (limited_position.y >= _spawn_position.y + upward_travel_limit and limited_velocity.y > 0.0)
		):
			limited_velocity.y = 0.0
		state.linear_velocity = limited_velocity
