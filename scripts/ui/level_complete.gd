class_name LevelComplete
extends Control


## Level Complete / Simulation Complete (Victory) screen for GlitchVerse.
## Hierarchy: Completion status, Score, Time, Next Action.

signal next_level_requested(next_level_id: int)
signal retry_requested(current_level_id: int)
signal menu_requested

@export var current_level_id: int = 1:
	set(value):
		current_level_id = clampi(value, 1, 4)
		if is_node_ready():
			_update_display()

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubTitleLabel
@onready var chamber_label: Label = %ChamberLabel
@onready var score_label: Label = %ScoreMetric
@onready var time_label: Label = %TimeMetric
@onready var paradox_label: Label = %ParadoxMetric

@onready var next_button: Button = %NextButton
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton

var _final_score: int = 1450


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIAudio.initialize_audio_service(self)
	next_button.pressed.connect(_on_next_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	UIAudio.attach_all_buttons(self)
	_update_display()
	hide()


func show_completion(level_id: int, elapsed_seconds: float = 47.23, score: int = 1450, is_victory: bool = false) -> void:
	UIAudio.play_level_complete(self)
	current_level_id = level_id
	_final_score = score
	var mins := int(elapsed_seconds) / 60
	var secs := int(elapsed_seconds) % 60
	if time_label != null:
		time_label.text = "%02d:%02d SEC" % [mins, secs]
	if score_label != null:
		score_label.text = "%d PTS" % _final_score
	if paradox_label != null:
		paradox_label.text = "RESOLVED"

	if is_victory or level_id >= 4:
		if title_label != null:
			title_label.text = "SIMULATION COMPLETE"
		if subtitle_label != null:
			subtitle_label.text = "REALITY RESTORED"
			subtitle_label.modulate = UIColors.COLOR_CONTROLLED
		if next_button != null:
			next_button.text = "[ EXPERIMENT CONCLUDED // RETURN TO TERMINAL ]"
	else:
		if title_label != null:
			title_label.text = "LEVEL COMPLETE"
		if subtitle_label != null:
			subtitle_label.text = "DATA RECOVERED"
			subtitle_label.modulate = UIColors.COLOR_TEXT_MUTED
		var next_data: Dictionary = UIColors.get_level_data(level_id + 1)
		if next_button != null:
			next_button.text = "[ ADVANCE TO %s: %s ]" % [next_data.get("code", "GV"), next_data.get("name", "NEXT")]

	_update_display()
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if next_button != null:
		next_button.grab_focus()


func _update_display() -> void:
	var data: Dictionary = UIColors.get_level_data(current_level_id)
	if chamber_label != null:
		chamber_label.text = "%s // %s" % [data.get("code", "GV-01"), data.get("name", "ACCESS DENIED")]


func _on_next_pressed() -> void:
	UIAudio.play_confirm(self)
	hide()
	if current_level_id >= 4:
		menu_requested.emit()
	else:
		var next_id := mini(current_level_id + 1, 4)
		next_level_requested.emit(next_id)


func _on_retry_pressed() -> void:
	UIAudio.play_click(self)
	hide()
	retry_requested.emit(current_level_id)


func _on_menu_pressed() -> void:
	UIAudio.play_back(self)
	hide()
	menu_requested.emit()
