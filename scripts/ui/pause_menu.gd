class_name PauseMenu
extends Control

## Emergency Protocol Suspension (Pause Menu) for GlitchVerse.
## Restrained, floating typography with rectangular buttons.

signal resumed
signal restarted
signal aborted_to_menu

@export var auto_reload_scene: bool = false

@onready var chamber_label: Label = %PauseChamber
@onready var status_label: Label = %PauseStatus
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var abort_button: Button = %AbortButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	abort_button.pressed.connect(_on_abort_pressed)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open(level_id: int = 1) -> void:
	var data: Dictionary = UIColors.get_level_data(level_id)
	if chamber_label != null:
		chamber_label.text = "%s // %s" % [data.get("code", "GV-01"), data.get("name", "ACCESS DENIED")]
	if status_label != null:
		status_label.text = String(data.get("status", "SIMULATION ACTIVE"))
	show()
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if resume_button != null:
		resume_button.grab_focus()


func close() -> void:
	hide()
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()


func _on_resume_pressed() -> void:
	close()


func _on_restart_pressed() -> void:
	hide()
	get_tree().paused = false
	restarted.emit()
	if auto_reload_scene and get_tree().current_scene != null:
		get_tree().reload_current_scene()


func _on_abort_pressed() -> void:
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	aborted_to_menu.emit()
