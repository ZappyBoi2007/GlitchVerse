class_name FreezableHazard
extends AnimatableBody3D

## A local oscillating hazard. FREEZE stops only this instance; collision remains active.

signal state_changed(is_frozen: bool)

@export var interaction_name := "MOVING HAZARD"
@export var movement_axis := Vector3.RIGHT
@export_range(0.5, 8.0, 0.1) var travel_distance := 2.7
@export_range(0.1, 8.0, 0.1) var movement_speed := 1.8
@export var moving_material: Material
@export var frozen_material: Material

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var target_highlight: MeshInstance3D = $TargetHighlight

var is_frozen := false
var _origin := Vector3.ZERO
var _movement_time := 0.0


func _ready() -> void:
	_origin = position
	_update_state()


func _physics_process(delta: float) -> void:
	if is_frozen:
		return
	_movement_time += delta * movement_speed
	position = _origin + movement_axis.normalized() * sin(_movement_time) * travel_distance


func get_interaction_name() -> String:
	return interaction_name


func get_ability_status(ability: StringName) -> Dictionary:
	if ability != RealityDebugger.FREEZE:
		return {"compatible": false, "message": "This hazard accepts FREEZE only."}
	return {"compatible": true, "message": ""}


func apply_ability(ability: StringName, _source: Node) -> String:
	if ability != RealityDebugger.FREEZE:
		return "This hazard accepts FREEZE only."
	is_frozen = not is_frozen
	_update_state()
	state_changed.emit(is_frozen)
	return "MOVING HAZARD // %s" % ("FROZEN" if is_frozen else "ACTIVE")


func set_debugger_highlight(enabled: bool, _ability_color: Color) -> void:
	target_highlight.visible = enabled


func _update_state() -> void:
	mesh.material_override = frozen_material if is_frozen else moving_material
