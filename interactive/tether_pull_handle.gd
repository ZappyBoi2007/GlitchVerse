class_name TetherPullHandle
extends StaticBody3D

signal pulled

@export var mechanism_path: NodePath
@export var one_shot := true

@onready var highlight: MeshInstance3D = $Highlight
@onready var grapple_point: Marker3D = $GrapplePoint
@onready var label: Label3D = $Label3D

var is_pulled := false


func _ready() -> void:
	add_to_group("grapple_target")
	add_to_group("tether_pull_handle")
	highlight.visible = false
	if not mechanism_path.is_empty():
		var mechanism := get_node_or_null(mechanism_path)
		if mechanism != null and mechanism.has_method("activate"):
			pulled.connect(mechanism.call.bind("activate"))


func can_grapple() -> bool:
	return not one_shot or not is_pulled


func pulls_player() -> bool:
	return false


func get_grapple_point() -> Vector3:
	return grapple_point.global_position


func get_grapple_prompt() -> String:
	return "E // DEPLOY BRIDGE"


func on_grapple_attached(_source: Node) -> void:
	if one_shot and is_pulled:
		return
	is_pulled = true
	label.text = "BRIDGE CONTROL // DEPLOYED"
	label.modulate = Color("79ffbd")
	highlight.visible = false
	pulled.emit()


func set_grapple_highlight(value: bool) -> void:
	highlight.visible = value and can_grapple()
