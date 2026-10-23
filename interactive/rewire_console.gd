class_name RewireConsole
extends StaticBody3D

signal state_changed(door_powered: bool)

@export var available := true
@export var door_powered := false
@onready var route_a: MeshInstance3D = $RouteA
@onready var route_b: MeshInstance3D = $RouteB
@onready var highlight: MeshInstance3D = $Highlight
@onready var label: Label3D = $Label3D


func _ready() -> void:
	add_to_group("player_interactable")
	_update_state()


func set_available(value: bool) -> void:
	available = value
	_update_state()


func interact(_player: Node) -> Dictionary:
	if not available:
		return {"success": false, "message": "REWIRE // RESTORE PREREQUISITE RELAY"}
	if door_powered:
		return {"success": false, "message": "REWIRE // DOOR ROUTE ALREADY ACTIVE"}
	door_powered = true
	_update_state()
	state_changed.emit(true)
	_play_audio()
	return {"success": true, "message": "REWIRE // POWER ROUTED TO DOOR"}


func get_interaction_prompt() -> String:
	return "REWIRE // DOOR POWERED" if door_powered else ("F // REWIRE POWER" if available else "REWIRE // LOCKED")


func set_interaction_highlight(value: bool) -> void:
	highlight.visible = value and available and not door_powered


func _update_state() -> void:
	route_a.visible = not door_powered
	route_b.visible = door_powered
	label.text = "REWIRE\n%s" % ("DOOR POWER" if door_powered else ("F // SWITCH ROUTE" if available else "LOCKED"))
	label.modulate = Color("ffb43d") if door_powered else (Color("55e8ff") if available else Color("ff536b"))
	highlight.visible = false


func _play_audio() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(&"rewire_switch", global_position, -3.0, 1.0, 20.0)
