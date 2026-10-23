extends Control

## Temporary adapter for the prototype HUD. Final UI can subscribe to the same manager signals.

@onready var level_label: Label = $Level
@onready var timer_label: Label = $Timer
@onready var score_label: Label = $Score
@onready var objective_label: Label = $Objective
@onready var result_panel: ColorRect = $ResultPanel
@onready var result_title: Label = $ResultPanel/Title
@onready var result_detail: Label = $ResultPanel/Detail

var _flow: GameFlowManager


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_connect_flow")


func _connect_flow() -> void:
	_flow = get_tree().get_first_node_in_group("game_flow") as GameFlowManager
	if _flow == null:
		objective_label.text = "GAME FLOW // OFFLINE"
		return
	_flow.level_started.connect(_on_level_started)
	_flow.objective_updated.connect(_on_objective_updated)
	_flow.time_updated.connect(_on_time_updated)
	_flow.score_updated.connect(_on_score_updated)
	_flow.puzzle_completed.connect(_on_puzzle_completed)
	_flow.game_failed.connect(_on_game_failed)
	_flow.game_victory.connect(_on_game_victory)
	_flow.replay_started.connect(_on_replay_started)
	level_label.text = _flow.get_current_level_name()
	_on_time_updated(_flow.level_elapsed_seconds)
	_on_score_updated(_flow.total_score)


func _on_level_started(level_index: int, level_name: String) -> void:
	level_label.text = "LEVEL %02d // %s" % [level_index + 1, level_name]
	objective_label.text = "INITIALIZING OBJECTIVE..."
	result_panel.visible = false


func _on_objective_updated(description: String, completed_steps: int, total_steps: int) -> void:
	objective_label.text = "OBJECTIVE %d/%d // %s" % [completed_steps, total_steps, description]


func _on_time_updated(elapsed_seconds: float) -> void:
	var total_seconds := int(elapsed_seconds)
	timer_label.text = "TIME %02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _on_score_updated(score: int) -> void:
	score_label.text = "SCORE %05d" % score


func _on_puzzle_completed(_level_index: int, _elapsed_seconds: float) -> void:
	objective_label.text = "PUZZLE SOLVED // EXIT UNLOCKED"
	objective_label.modulate = Color("69ff9f")


func _on_game_failed(reason: String) -> void:
	result_panel.visible = true
	result_title.text = "SIMULATION FAILED"
	result_title.modulate = Color("ff596d")
	result_detail.text = "%s\nPress R to restart the level" % reason


func _on_game_victory(total_time: float, total_score: int) -> void:
	result_panel.visible = true
	result_title.text = "SIMULATION COMPLETE"
	result_title.modulate = Color("69ff9f")
	result_detail.text = "TIME %0.1fs   SCORE %d\nPress R to replay" % [total_time, total_score]


func _on_replay_started() -> void:
	result_panel.visible = false
	objective_label.modulate = Color.WHITE
