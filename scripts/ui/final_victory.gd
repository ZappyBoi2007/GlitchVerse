class_name FinalVictory
extends Control


## Campaign Final Victory / Containment Restoration screen for GlitchVerse.
## Hierarchy: Campaign victory status, total elapsed time, total score, sectors cleared,
## replay simulation, and return to main menu requests.

signal replay_requested
signal menu_requested

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var time_label: Label = %TimeMetric
@onready var score_label: Label = %ScoreMetric
@onready var sectors_label: Label = %SectorsMetric
@onready var status_label: Label = %StatusMetric

@onready var replay_button: Button = %ReplayButton
@onready var menu_button: Button = %MenuButton

var _total_score: int = 0
var _total_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIAudio.initialize_audio_service(self)
	if replay_button != null:
		replay_button.pressed.connect(_on_replay_pressed)
	if menu_button != null:
		menu_button.pressed.connect(_on_menu_pressed)
	UIAudio.attach_all_buttons(self)
	hide()


func show_victory(total_seconds: float = 0.0, total_score: int = 0) -> void:
	UIAudio.play_victory(self)
	_total_time = total_seconds
	_total_score = total_score

	var mins := int(_total_time) / 60
	var secs := int(_total_time) % 60
	if time_label != null:
		time_label.text = "%02d:%02d SEC" % [mins, secs]
	if score_label != null:
		score_label.text = "%d PTS" % _total_score
	if sectors_label != null:
		sectors_label.text = "4 / 4 SECTORS CLEARED"
	if status_label != null:
		status_label.text = "EQUILIBRIUM RESTORED"

	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if replay_button != null:
		replay_button.grab_focus()


func _on_replay_pressed() -> void:
	UIAudio.play_confirm(self)
	hide()
	replay_requested.emit()


func _on_menu_pressed() -> void:
	UIAudio.play_back(self)
	hide()
	menu_requested.emit()
