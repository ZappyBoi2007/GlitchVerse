class_name PuzzleExit
extends StaticBody3D

signal exit_reached

@export var locked_material: Material
@export var unlocked_material: Material

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var label: Label3D = $Label3D
@onready var exit_trigger: Area3D = $ExitTrigger

var is_unlocked := false
var _completion_reported := false


func _ready() -> void:
	exit_trigger.body_entered.connect(_on_exit_trigger_body_entered)
	_update_state()


func unlock_exit() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	_update_state()


func _update_state() -> void:
	collision.set_deferred("disabled", is_unlocked)
	mesh.material_override = unlocked_material if is_unlocked else locked_material
	label.text = "EXIT // OPEN" if is_unlocked else "EXIT // LOCKED"
	label.outline_modulate = Color("55ff9a") if is_unlocked else Color("ff3d7f")


func _on_exit_trigger_body_entered(body: Node3D) -> void:
	if is_unlocked and not _completion_reported and body is CharacterBody3D:
		_completion_reported = true
		exit_reached.emit()
