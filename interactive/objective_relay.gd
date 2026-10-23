class_name ObjectiveRelay
extends StaticBody3D

signal restored

@export var relay_label := "RELAY"
@export var available := false
@onready var screen: MeshInstance3D = $Screen
@onready var highlight: MeshInstance3D = $Highlight
@onready var label: Label3D = $Label3D

var is_restored := false
var _screen_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("player_interactable")
	_screen_material = StandardMaterial3D.new()
	_screen_material.emission_enabled = true
	_screen_material.emission_energy_multiplier = 1.6
	screen.material_override = _screen_material
	_update_state()


func set_available(value: bool) -> void:
	available = value
	_update_state()


func interact(_player: Node) -> Dictionary:
	if is_restored:
		return {"success": false, "message": "%s // ALREADY RESTORED" % relay_label}
	if not available:
		return {"success": false, "message": "%s // ACCESS LOCKED" % relay_label}
	is_restored = true
	_update_state()
	restored.emit()
	_play_audio(&"relay_restore")
	return {"success": true, "message": "%s // RESTORED" % relay_label}


func get_interaction_prompt() -> String:
	if is_restored:
		return "%s // RESTORED" % relay_label
	return "F // RESTORE %s" % relay_label if available else "%s // LOCKED" % relay_label


func set_interaction_highlight(value: bool) -> void:
	highlight.visible = value and available and not is_restored


func _update_state() -> void:
	label.text = "%s\n%s" % [relay_label, "RESTORED" if is_restored else ("F // RESTORE" if available else "LOCKED")]
	label.modulate = Color("66ff9b") if is_restored else (Color("ffc45c") if available else Color("ff536b"))
	_screen_material.albedo_color = label.modulate.darkened(0.55)
	_screen_material.emission = label.modulate
	highlight.visible = false


func _play_audio(event_name: StringName) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(event_name, global_position, -4.0, 1.0, 18.0)
