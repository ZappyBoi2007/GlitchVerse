class_name InGameHUD
extends CanvasLayer

## Compact Experimental Research HUD for GlitchVerse.
## Prioritizes: Level/Chamber, Objective, Selected Ability, Timer, Score, Target Prompt.
## Clean and readable with standardized ability colors:
##   PHASE = Cyan (#39F5FF)
##   GRAVITY = Amber (#FFB830)
##   FREEZE = Violet (#A259FF)
##   RED (#FF4057) = Critical/Error only
##   MAGENTA (#FF2BD6) = World Anomaly/Corruption only

@export var current_level_id: int = 1:
	set(value):
		var clamped := clampi(value, 1, 4)
		current_level_id = clamped
		if is_node_ready():
			_apply_level_data()

@export_range(0.0, 1.0, 0.01) var anomaly_corruption: float = 0.0:
	set(value):
		anomaly_corruption = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_anomaly_state()

# HUD Nodes
@onready var chamber_code: Label = %ChamberCode
@onready var chamber_name: Label = %ChamberName
@onready var objective_label: Label = %ObjectiveLabel

@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel

@onready var ability_badge: Label = %AbilityBadge
@onready var ability_name_label: Label = %AbilityNameLabel
@onready var target_prompt_label: Label = %TargetPromptLabel

@onready var reticle_h: ColorRect = %ReticleH
@onready var reticle_v: ColorRect = %ReticleV
@onready var reticle_dot: ColorRect = %ReticleDot

var _score: int = 0
var _session_time: float = 0.0
var _internal_timer_active: bool = true
var _selected_ability: String = "PHASE"

var _debugger: Node = null
var _game_flow: Node = null


func _ready() -> void:
	_apply_level_data()
	set_ability("PHASE")
	set_score(0)
	call_deferred("_connect_reality_debugger")
	call_deferred("_connect_game_flow_manager")


func _process(delta: float) -> void:
	if _internal_timer_active:
		_session_time += delta
		_update_timer_display()


# Public Callable API (For GameFlowManager & External Systems)
func set_ability(mode: String) -> void:
	_selected_ability = mode.to_upper()
	var ability_col := UIColors.get_ability_color(_selected_ability)

	ability_name_label.text = _selected_ability
	ability_name_label.modulate = ability_col
	ability_badge.modulate = ability_col


func set_score(points: int) -> void:
	_score = maxi(0, points)
	score_label.text = "SCORE: %05d" % _score


func set_timer_seconds(seconds: float) -> void:
	_session_time = maxf(0.0, seconds)
	_internal_timer_active = false
	_update_timer_display()


func set_level(level_id: int) -> void:
	current_level_id = level_id


func set_objective(text: String) -> void:
	objective_label.text = "OBJECTIVE: %s" % text


func set_target_prompt(prompt_text: String, is_compatible: bool = true) -> void:
	if prompt_text.is_empty():
		target_prompt_label.text = ""
		_reset_reticle()
		return

	if is_compatible:
		target_prompt_label.text = "[LMB] REWRITE %s" % prompt_text.to_upper()
		target_prompt_label.modulate = UIColors.COLOR_CONTROLLED
		_set_reticle_color(UIColors.COLOR_CONTROLLED)
	else:
		target_prompt_label.text = "[INERT] %s" % prompt_text.to_upper()
		target_prompt_label.modulate = UIColors.COLOR_TEXT_MUTED
		_set_reticle_color(UIColors.COLOR_TEXT_MUTED)


func _apply_level_data() -> void:
	var data: Dictionary = UIColors.get_level_data(current_level_id)
	chamber_code.text = String(data.get("code", "GV-01"))
	chamber_name.text = String(data.get("name", "ACCESS DENIED"))
	set_objective(String(data.get("objective", "Restore chamber access.")))
	anomaly_corruption = float(data.get("corruption", 0.0))
	_apply_anomaly_state()


func _update_timer_display() -> void:
	timer_label.text = GlitchText.format_simulation_timer(_session_time, current_level_id)


func _apply_anomaly_state() -> void:
	# Subtle level visual progression (preserving readable functional text)
	match current_level_id:
		1:
			chamber_code.modulate = UIColors.COLOR_TEXT_MUTED
		2:
			chamber_code.modulate = UIColors.COLOR_CONTROLLED
		3:
			chamber_code.modulate = UIColors.COLOR_TEXT_MUTED
		4:
			chamber_code.modulate = UIColors.COLOR_MAGENTA


func _reset_reticle() -> void:
	_set_reticle_color(Color(0.557, 0.647, 0.667, 0.75))


func _set_reticle_color(col: Color) -> void:
	reticle_h.color = col
	reticle_v.color = col
	reticle_dot.color = col


# Gameplay Signal Connections
func _connect_reality_debugger() -> void:
	var nodes := get_tree().get_nodes_in_group("reality_debugger")
	if nodes.is_empty():
		return
	_debugger = nodes[0]

	if _debugger.has_signal("ability_changed"):
		_debugger.connect("ability_changed", _on_debugger_ability_changed)
	if _debugger.has_signal("target_changed"):
		_debugger.connect("target_changed", _on_debugger_target_changed)
	if _debugger.has_signal("feedback_changed"):
		_debugger.connect("feedback_changed", _on_debugger_feedback_changed)

	if _debugger.has_method("get_selected_ability_label"):
		set_ability(String(_debugger.call("get_selected_ability_label")))


func _on_debugger_ability_changed(ability_name: String, _color: Color) -> void:
	set_ability(ability_name)


func _on_debugger_target_changed(target_name: String, compatible: bool, has_target: bool) -> void:
	if not has_target:
		set_target_prompt("", false)
	else:
		set_target_prompt(target_name, compatible)


func _on_debugger_feedback_changed(message: String, is_error: bool) -> void:
	if is_error:
		target_prompt_label.text = message
		target_prompt_label.modulate = UIColors.COLOR_CRITICAL
		_set_reticle_color(UIColors.COLOR_CRITICAL)


func _connect_game_flow_manager() -> void:
	var nodes := get_tree().get_nodes_in_group("game_flow_manager")
	if not nodes.is_empty():
		_game_flow = nodes[0]
	elif get_tree().root.has_node("GameFlowManager"):
		_game_flow = get_tree().root.get_node("GameFlowManager")
	else:
		return

	if _game_flow.has_signal("level_started"):
		_game_flow.connect("level_started", func(lvl: int): set_level(lvl))
	if _game_flow.has_signal("objective_updated"):
		_game_flow.connect("objective_updated", func(obj: String): set_objective(obj))
	if _game_flow.has_signal("time_updated"):
		_game_flow.connect("time_updated", func(t: float): set_timer_seconds(t))
	if _game_flow.has_signal("score_updated"):
		_game_flow.connect("score_updated", func(s: int): set_score(s))
