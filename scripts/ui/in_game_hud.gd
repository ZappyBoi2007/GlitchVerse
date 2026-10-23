class_name InGameHUD
extends CanvasLayer

## Modular In-Game Gameplay & Tactical Research HUD for GlitchVerse.
## Implements mission progression, performance metrics, survival/health tracking,
## contextual targeting/tether feedback, equipment status, and transient notifications.

signal notification_displayed(message: String, is_alert: bool)
signal health_warning_triggered(current: float, max_health: float)
signal tool_selected(tool_id: String)

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

# Top-Left Mission Nodes
@onready var chamber_code: Label = %ChamberCode
@onready var chamber_name: Label = %ChamberName
@onready var objective_label: Label = %ObjectiveLabel
@onready var objective_progress_row: HBoxContainer = %ObjectiveProgressRow
@onready var progress_tag: Label = %ProgressTag
@onready var progress_bar: ProgressBar = %ObjectiveProgressBar
@onready var progress_label: Label = %ProgressLabel

# Top-Right Performance Nodes
@onready var timer_label: Label = %TimerLabel
@onready var score_label: Label = %ScoreLabel

# Center Notification Nodes
@onready var notification_panel: PanelContainer = %NotificationPanel
@onready var notification_label: Label = %NotificationLabel

# Center Targeting & Interaction Nodes
@onready var reticle_h: ColorRect = %ReticleH
@onready var reticle_v: ColorRect = %ReticleV
@onready var reticle_dot: ColorRect = %ReticleDot
@onready var grapple_ring: Control = %GrappleRing
@onready var target_prompt_label: Label = %TargetPromptLabel

# Bottom-Left Survival & Control Nodes
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var low_health_alert: Label = %LowHealthAlert
@onready var control_hints: Label = %ControlHints

# Bottom-Right Equipment Nodes
@onready var tether_label: Label = %TetherLabel
@onready var tether_status: Label = %TetherStatus
@onready var blade_label: Label = %BladeLabel
@onready var blade_status: Label = %BladeStatus
@onready var ability_badge: Label = %AbilityBadge
@onready var ability_name_label: Label = %AbilityNameLabel
@onready var aux_status: Label = %AuxStatus

# Internal State
var _score: int = 0
var _session_time: float = 0.0
var _internal_timer_active: bool = true
var _health_initialized: bool = false
var _current_health: float = 0.0
var _max_health: float = 0.0
var _selected_ability: String = ""
var _notification_tween: Tween = null

var _debugger: Node = null
var _game_flow: Node = null


func _ready() -> void:
	_apply_level_data()
	set_score(0)
	_reset_to_uninitialized_state()
	call_deferred("_connect_reality_debugger")
	call_deferred("_connect_game_flow_manager")


func _reset_to_uninitialized_state() -> void:
	_health_initialized = false
	if health_bar != null:
		health_bar.value = 0.0
	if health_label != null:
		health_label.text = "-- / -- HP"
		health_label.modulate = UIColors.COLOR_TEXT_MUTED
	if low_health_alert != null:
		low_health_alert.visible = false
	if objective_progress_row != null:
		objective_progress_row.visible = false
	if tether_status != null:
		tether_status.text = "STANDBY"
		tether_status.modulate = UIColors.COLOR_TEXT_MUTED
	if blade_status != null:
		blade_status.text = "STANDBY"
		blade_status.modulate = UIColors.COLOR_TEXT_MUTED
	if ability_name_label != null:
		ability_name_label.text = "--"
		ability_name_label.modulate = UIColors.COLOR_TEXT_MUTED
	if ability_badge != null:
		ability_badge.modulate = UIColors.COLOR_TEXT_MUTED
	if aux_status != null:
		aux_status.text = "STANDBY"
		aux_status.modulate = UIColors.COLOR_TEXT_MUTED
	if control_hints != null:
		control_hints.text = ""


func _process(delta: float) -> void:
	if _internal_timer_active:
		_session_time += delta
		_update_timer_display()


# Public Callable API — Mission
func set_level(level_id: int) -> void:
	current_level_id = level_id


func set_level_name(level_name: String, code: String = "") -> void:
	if chamber_name != null:
		chamber_name.text = level_name.to_upper()
	if not code.is_empty() and chamber_code != null:
		chamber_code.text = code


func set_objective(text: String) -> void:
	if objective_label != null:
		objective_label.text = "OBJECTIVE: %s" % text


func set_objective_progress(completed: int, total: int, step_desc: String = "") -> void:
	if objective_progress_row == null:
		return
	if total <= 0:
		objective_progress_row.visible = false
		return
	objective_progress_row.visible = true
	if progress_tag != null:
		progress_tag.text = (step_desc.to_upper() + ":") if not step_desc.is_empty() else "PROGRESS:"
	if progress_label != null:
		progress_label.text = "%d/%d" % [completed, total]
	if progress_bar != null:
		progress_bar.max_value = float(total)
		progress_bar.value = float(completed)
		if completed >= total:
			progress_bar.modulate = UIColors.COLOR_CONFIRMED
		else:
			progress_bar.modulate = UIColors.COLOR_CONTROLLED


# Public Callable API — Performance
func set_timer_seconds(seconds: float) -> void:
	_session_time = maxf(0.0, seconds)
	_internal_timer_active = false
	_update_timer_display()


func set_score(points: int) -> void:
	_score = maxi(0, points)
	if score_label != null:
		score_label.text = "SCORE: %05d" % _score


# Public Callable API — Survival
func set_health(current: float, max_h: float = -1.0) -> void:
	if max_h > 0.0:
		_max_health = max_h
	elif not _health_initialized:
		_max_health = maxf(1.0, current)

	_current_health = clampf(current, 0.0, _max_health)
	_health_initialized = true
	var ratio := _current_health / _max_health if _max_health > 0.0 else 0.0

	if health_bar != null:
		health_bar.max_value = _max_health
		health_bar.value = _current_health
	if health_label != null:
		health_label.text = "%d / %d HP" % [int(ceil(_current_health)), int(ceil(_max_health))]

	if ratio <= 0.30:
		if low_health_alert != null:
			low_health_alert.visible = true
		if health_bar != null:
			health_bar.modulate = UIColors.COLOR_CRITICAL
		if health_label != null:
			health_label.modulate = UIColors.COLOR_CRITICAL
		health_warning_triggered.emit(_current_health, _max_health)
	else:
		if low_health_alert != null:
			low_health_alert.visible = false
		if health_bar != null:
			health_bar.modulate = UIColors.COLOR_CONTROLLED
		if health_label != null:
			health_label.modulate = UIColors.COLOR_TEXT_PRIMARY


# Public Callable API — Equipment
func set_tether_status(status_text: String, is_attached: bool = false) -> void:
	if tether_status == null:
		return
	tether_status.text = status_text.to_upper()
	if is_attached:
		tether_status.modulate = UIColors.COLOR_CONFIRMED
	elif status_text.to_upper() == "READY":
		tether_status.modulate = UIColors.COLOR_TOOL_TETHER
	else:
		tether_status.modulate = UIColors.COLOR_TEXT_MUTED


func set_blade_status(status_text: String, is_ready: bool = true) -> void:
	if blade_status == null:
		return
	blade_status.text = status_text.to_upper()
	blade_status.modulate = UIColors.COLOR_TOOL_BLADE if is_ready else UIColors.COLOR_TEXT_MUTED


func set_equipped_tool(tool_id: String, tool_label: String = "", tool_status: String = "READY", tool_color: Color = Color.WHITE) -> void:
	var id_upper := tool_id.to_upper()
	var display_name := tool_label if not tool_label.is_empty() else id_upper
	var col := tool_color if tool_color != Color.WHITE else UIColors.get_tool_color(id_upper)

	if ability_name_label != null:
		ability_name_label.text = display_name
		ability_name_label.modulate = col
	if ability_badge != null:
		ability_badge.modulate = col
	if aux_status != null:
		aux_status.text = tool_status.to_upper()
		aux_status.modulate = col
	tool_selected.emit(tool_id)


func set_ability(mode: String) -> void:
	_selected_ability = mode.to_upper()
	var col := UIColors.get_ability_color(_selected_ability)

	if ability_name_label != null:
		ability_name_label.text = _selected_ability
		ability_name_label.modulate = col
	if ability_badge != null:
		ability_badge.modulate = col
	if aux_status != null:
		aux_status.text = "ACTIVE"
		aux_status.modulate = col


# Public Callable API — Targeting & Context
func set_grapple_target(has_target: bool, is_valid: bool = false, anchor_label: String = "") -> void:
	if grapple_ring == null:
		return
	grapple_ring.visible = has_target
	if not has_target:
		if target_prompt_label != null and target_prompt_label.text.begins_with("[E] TETHER"):
			target_prompt_label.text = ""
		_reset_reticle()
		return

	var col: Color = UIColors.COLOR_CONFIRMED if is_valid else UIColors.COLOR_CRITICAL
	grapple_ring.modulate = col
	if reticle_dot != null:
		reticle_dot.color = col

	if target_prompt_label != null:
		if is_valid:
			var desc := anchor_label if not anchor_label.is_empty() else "CONDUIT ANCHOR"
			target_prompt_label.text = "[E] TETHER // %s" % desc.to_upper()
			target_prompt_label.modulate = UIColors.COLOR_CONTROLLED
		else:
			target_prompt_label.text = "INVALID ANCHOR // OUT OF RANGE"
			target_prompt_label.modulate = UIColors.COLOR_CRITICAL


func show_interaction_prompt(prompt_text: String, key_hint: String = "F") -> void:
	if target_prompt_label == null:
		return
	if prompt_text.is_empty():
		target_prompt_label.text = ""
		return
	target_prompt_label.text = "[%s] %s" % [key_hint.to_upper(), prompt_text.to_upper()]
	target_prompt_label.modulate = UIColors.COLOR_CONTROLLED


func hide_interaction_prompt() -> void:
	if target_prompt_label != null:
		target_prompt_label.text = ""


func set_target_prompt(prompt_text: String, is_compatible: bool = true) -> void:
	if target_prompt_label == null:
		return
	if prompt_text.is_empty():
		target_prompt_label.text = ""
		_reset_reticle()
		return

	target_prompt_label.text = "[LMB] %s" % prompt_text.to_upper()
	var col: Color = UIColors.COLOR_CONTROLLED if is_compatible else UIColors.COLOR_TEXT_MUTED
	target_prompt_label.modulate = col
	if reticle_dot != null:
		reticle_dot.color = col


# Public Callable API — Contextual Notifications & Hints
func show_notification(message: String, is_alert: bool = false, duration: float = 2.5) -> void:
	if message.is_empty() or notification_panel == null or notification_label == null:
		return
	notification_label.text = message.to_upper()
	var col: Color = UIColors.COLOR_CRITICAL if is_alert else UIColors.COLOR_CONTROLLED
	notification_label.modulate = col
	notification_panel.self_modulate = col
	notification_panel.visible = true

	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()

	notification_panel.modulate.a = 0.0
	_notification_tween = create_tween()
	_notification_tween.tween_property(notification_panel, "modulate:a", 1.0, 0.12)
	_notification_tween.tween_interval(duration)
	_notification_tween.tween_property(notification_panel, "modulate:a", 0.0, 0.3)
	_notification_tween.tween_callback(func():
		if notification_panel != null:
			notification_panel.visible = false
	)
	notification_displayed.emit(message, is_alert)


func set_control_hints(hints_text: String) -> void:
	if control_hints != null:
		control_hints.text = hints_text


# Internal Formatting & Autoconnection Logic
func _update_timer_display() -> void:
	if timer_label == null:
		return
	var total_seconds := int(_session_time)
	var mins := total_seconds / 60
	var secs := total_seconds % 60
	var hundredths := int((_session_time - float(total_seconds)) * 100.0)
	timer_label.text = "%02d:%02d.%02d" % [mins, secs, hundredths]


func _reset_reticle() -> void:
	if reticle_dot != null:
		reticle_dot.color = UIColors.COLOR_TEXT_PRIMARY
	if grapple_ring != null:
		grapple_ring.visible = false


func _apply_level_data() -> void:
	var data: Dictionary = UIColors.get_level_data(current_level_id)
	if chamber_code != null:
		chamber_code.text = String(data.get("code", "GV-01"))
	if chamber_name != null:
		chamber_name.text = String(data.get("name", "ACCESS DENIED"))
	if objective_label != null:
		objective_label.text = "OBJECTIVE: %s" % String(data.get("objective", "Restore chamber access."))
	anomaly_corruption = float(data.get("corruption", 0.0))


func _apply_anomaly_state() -> void:
	if chamber_name == null or chamber_code == null:
		return
	if anomaly_corruption >= 0.8:
		chamber_name.modulate = UIColors.COLOR_CRITICAL
		chamber_code.modulate = UIColors.COLOR_MAGENTA
	elif anomaly_corruption >= 0.4:
		chamber_name.modulate = UIColors.COLOR_MAGENTA
		chamber_code.modulate = UIColors.COLOR_TEXT_PRIMARY
	else:
		chamber_name.modulate = UIColors.COLOR_TEXT_PRIMARY
		chamber_code.modulate = UIColors.COLOR_TEXT_MUTED


func _connect_reality_debugger() -> void:
	_debugger = get_tree().get_first_node_in_group("reality_debugger")
	if _debugger == null:
		return
	if _debugger.has_signal("ability_changed"):
		_debugger.connect("ability_changed", Callable(self, "_on_debugger_ability_changed"))
	if _debugger.has_signal("target_changed"):
		_debugger.connect("target_changed", Callable(self, "_on_debugger_target_changed"))
	if _debugger.has_signal("feedback_changed"):
		_debugger.connect("feedback_changed", Callable(self, "_on_debugger_feedback_changed"))


func _connect_game_flow_manager() -> void:
	_game_flow = get_tree().get_first_node_in_group("game_flow")
	if _game_flow == null:
		_game_flow = get_tree().get_first_node_in_group("game_flow_manager")
	if _game_flow == null:
		return

	if _game_flow.has_signal("level_started"):
		_game_flow.connect("level_started", Callable(self, "_on_flow_level_started"))
	if _game_flow.has_signal("objective_updated"):
		_game_flow.connect("objective_updated", Callable(self, "_on_flow_objective_updated"))
	if _game_flow.has_signal("time_updated"):
		_game_flow.connect("time_updated", Callable(self, "set_timer_seconds"))
	if _game_flow.has_signal("score_updated"):
		_game_flow.connect("score_updated", Callable(self, "set_score"))
	if _game_flow.has_signal("puzzle_completed"):
		_game_flow.connect("puzzle_completed", Callable(self, "_on_flow_puzzle_completed"))
	if _game_flow.has_signal("exit_unlocked"):
		_game_flow.connect("exit_unlocked", Callable(self, "_on_flow_exit_unlocked"))
	if _game_flow.has_signal("game_failed"):
		_game_flow.connect("game_failed", Callable(self, "_on_flow_game_failed"))
	if _game_flow.has_signal("game_victory"):
		_game_flow.connect("game_victory", Callable(self, "_on_flow_game_victory"))


func _on_debugger_ability_changed(label: String, _color: Color) -> void:
	set_ability(label)


func _on_debugger_target_changed(label: String, compatible: bool, has_target: bool) -> void:
	set_target_prompt(label, compatible)
	set_grapple_target(has_target, compatible, label)


func _on_debugger_feedback_changed(message: String, is_error: bool) -> void:
	show_notification(message, is_error, 2.0)


func _on_flow_level_started(level_index: int, level_title: String) -> void:
	set_level_name(level_title, "GV-%02d" % (level_index + 1))
	set_objective("INITIALIZING MISSION OBJECTIVE...")
	show_notification("LEVEL %02d // %s" % [level_index + 1, level_title], false, 3.0)


func _on_flow_objective_updated(desc: String, completed_steps: int, total_steps: int) -> void:
	set_objective(desc)
	set_objective_progress(completed_steps, total_steps)


func _on_flow_puzzle_completed(_level_index: int, _elapsed: float) -> void:
	show_notification("PUZZLE SOLVED // EXIT UNLOCKED", false, 3.5)


func _on_flow_exit_unlocked(_level_index: int) -> void:
	show_notification("CONTAINMENT EXIT UNLOCKED", false, 3.0)


func _on_flow_game_failed(reason: String) -> void:
	show_notification("CRITICAL FAILURE: %s" % reason, true, 4.0)


func _on_flow_game_victory(_time: float, _points: int) -> void:
	show_notification("SIMULATION COMPLETE // ALL SECTORS CLEARED", false, 5.0)
