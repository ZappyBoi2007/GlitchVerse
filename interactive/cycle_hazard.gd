class_name CycleHazard
extends Area3D

signal player_hit
signal disabled

@export var travel_axis := Vector3(1, 0, 0)
@export_range(0.0, 10.0, 0.25) var travel_distance := 5.0
@export_range(0.2, 4.0, 0.1) var cycle_seconds := 1.8
@onready var visual: MeshInstance3D = $Visual
@onready var collision: CollisionShape3D = $CollisionShape3D

var is_disabled := false
var _origin := Vector3.ZERO
var _elapsed := 0.0


func _ready() -> void:
	_origin = position
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if is_disabled:
		return
	_elapsed += delta
	var phase := sin(_elapsed / cycle_seconds * TAU)
	position = _origin + travel_axis.normalized() * travel_distance * phase


func disable_hazard() -> void:
	if is_disabled:
		return
	is_disabled = true
	monitoring = false
	collision.set_deferred("disabled", true)
	visual.visible = false
	disabled.emit()


func _on_body_entered(body: Node3D) -> void:
	if not is_disabled and body is CharacterBody3D and body.is_in_group("player"):
		player_hit.emit()
