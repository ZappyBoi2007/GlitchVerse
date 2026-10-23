class_name CampaignExit
extends Area3D

signal exit_reached

@onready var beacon: MeshInstance3D = $Beacon
@onready var label: Label3D = $Label3D
var is_unlocked := false
var _reported := false
var _beacon_material: StandardMaterial3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_beacon_material = StandardMaterial3D.new()
	_beacon_material.emission_enabled = true
	_beacon_material.emission_energy_multiplier = 1.8
	beacon.material_override = _beacon_material
	_update_state()


func unlock_exit() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	_update_state()


func _on_body_entered(body: Node3D) -> void:
	if is_unlocked and not _reported and body is CharacterBody3D and body.is_in_group("player"):
		_reported = true
		exit_reached.emit()


func _update_state() -> void:
	var color := Color("55ff9a") if is_unlocked else Color("ff3d62")
	_beacon_material.albedo_color = color.darkened(0.55)
	_beacon_material.emission = color
	label.text = "EXIT // OPEN" if is_unlocked else "EXIT // LOCKED"
	label.modulate = color
