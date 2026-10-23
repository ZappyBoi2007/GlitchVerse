class_name PhaseableBarrier
extends StaticBody3D

## A solid barrier that can be phased while retaining a ray-targetable Area3D.

@export var interaction_name := "PHASE BARRIER"
@export var solid_material: Material
@export var phased_material: Material

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var solid_collision: CollisionShape3D = $SolidCollision
@onready var occupancy_sensor: Area3D = $OccupancySensor

var is_phased := false


func _ready() -> void:
	_update_state()


func get_interaction_name() -> String:
	return interaction_name


func get_ability_status(ability: StringName) -> Dictionary:
	if ability != RealityDebugger.PHASE:
		return {"compatible": false, "message": "This barrier accepts PHASE only."}
	if is_phased and _has_character_inside():
		return {"compatible": false, "message": "Exit the barrier volume before restoring collision."}
	return {"compatible": true, "message": ""}


func apply_ability(ability: StringName, _source: Node) -> String:
	var status := get_ability_status(ability)
	if not bool(status["compatible"]):
		return String(status["message"])
	is_phased = not is_phased
	_update_state()
	return "PHASE BARRIER // %s" % ("PHASED" if is_phased else "SOLID")


func _update_state() -> void:
	solid_collision.set_deferred("disabled", is_phased)
	mesh.material_override = phased_material if is_phased else solid_material


func _has_character_inside() -> bool:
	for body in occupancy_sensor.get_overlapping_bodies():
		if body is CharacterBody3D:
			return true
	return false
