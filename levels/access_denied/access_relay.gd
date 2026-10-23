class_name AccessRelay
extends Area3D

## A route checkpoint for ACCESS DENIED. It activates only for the player and
## latches for the current level instance.

signal relay_activated

@onready var label: Label3D = $Label3D

var is_activated := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func try_activate(body: Node3D) -> bool:
	if is_activated or body == null:
		return false
	if not body is CharacterBody3D or not body.is_in_group("player"):
		return false
	is_activated = true
	label.text = "ACCESS RELAY // VERIFIED"
	label.modulate = Color("79ffbd")
	relay_activated.emit()
	return true


func _on_body_entered(body: Node3D) -> void:
	try_activate(body)
