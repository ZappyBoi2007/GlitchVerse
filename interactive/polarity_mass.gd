class_name PolarityMass
extends AnimatableBody3D

signal state_changed(inverted: bool)

@export var travel_offset := Vector3(0, 4.0, 0)
@export_range(0.2, 3.0, 0.1) var travel_duration := 0.8
@export var one_shot := true
@onready var core: MeshInstance3D = $Core
@onready var highlight: MeshInstance3D = $Highlight
@onready var label: Label3D = $Label3D

var inverted := false
var _origin := Vector3.ZERO
var _moving := false
var _core_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("polarity_target")
	_origin = global_position
	_core_material = StandardMaterial3D.new()
	_core_material.metallic = 0.7
	_core_material.roughness = 0.25
	_core_material.emission_enabled = true
	_core_material.emission_energy_multiplier = 1.5
	core.material_override = _core_material
	_update_visual()


func toggle_polarity(_source: Node) -> bool:
	if _moving or (one_shot and inverted):
		return false
	inverted = not inverted
	_moving = true
	_update_visual()
	var target := _origin + (travel_offset if inverted else Vector3.ZERO)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target, travel_duration)
	tween.finished.connect(_finish_move, CONNECT_ONE_SHOT)
	return true


func set_polarity_highlight(value: bool) -> void:
	highlight.visible = value and not _moving and (not one_shot or not inverted)


func _finish_move() -> void:
	_moving = false
	state_changed.emit(inverted)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(&"polarity_shift", global_position, -3.0, 1.0, 22.0)


func _update_visual() -> void:
	var color := Color("b06cff") if inverted else Color("ffb43d")
	_core_material.albedo_color = color.darkened(0.55)
	_core_material.emission = color
	label.text = "POLARITY\n%s" % ("INVERTED" if inverted else "Q // INVERT")
	label.modulate = color
	highlight.visible = false
