class_name GameOver
extends Control

## Simulation Failure / Containment Breach screen for GlitchVerse.
## Hierarchy: Failure status, relevant reason/status, restart, return.

signal retry_requested(current_level_id: int)
signal menu_requested

@export var current_level_id: int = 1:
	set(value):
		current_level_id = clampi(value, 1, 4)
		if is_node_ready():
			_update_display()

@onready var chamber_label: Label = %ChamberLabel
@onready var error_label: Label = %ErrorCodeLabel
@onready var reason_label: Label = %ReasonLabel
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	_update_display()


func show_game_over(level_id: int, reason: String = "CONTAINMENT BREACH // MATRIX COLLAPSED", error_code: String = "0x88F_TEMPORAL_DESYNC") -> void:
	current_level_id = level_id
	if error_label != null:
		error_label.text = "EXCEPTION DUMP: %s" % error_code
	if reason_label != null:
		reason_label.text = reason
	_update_display()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if retry_button != null:
		retry_button.grab_focus()


func _update_display() -> void:
	var data: Dictionary = UIColors.get_level_data(current_level_id)
	if chamber_label != null:
		chamber_label.text = "%s // %s" % [data.get("code", "GV-01"), data.get("name", "ACCESS DENIED")]


func _on_retry_pressed() -> void:
	hide()
	retry_requested.emit(current_level_id)


func _on_menu_pressed() -> void:
	hide()
	menu_requested.emit()
