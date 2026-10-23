class_name CampaignHUD
extends CanvasLayer

var level_label: Label
var objective_label: Label
var stats_label: Label
var health_label: Label
var prompt_label: Label
var status_label: Label
var state_panel: ColorRect
var state_label: Label
var crosshair: Label


func _ready() -> void:
	layer = 20
	_build_ui()
	call_deferred("_bind_runtime")


func _build_ui() -> void:
	level_label = _label(Vector2(24, 20), 22, Color("7eefff"))
	objective_label = _label(Vector2(24, 52), 17, Color("e4edf2"))
	stats_label = _label(Vector2(1035, 20), 18, Color("ffc05a"))
	health_label = _label(Vector2(24, 82), 18, Color("68ffac"))
	prompt_label = _label(Vector2(430, 610), 20, Color("ffe07a"))
	prompt_label.size = Vector2(420, 32)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label = _label(Vector2(310, 675), 15, Color("b7cbd6"))
	status_label.text = "WASD MOVE  |  SHIFT SPRINT/VECTOR  |  SPACE JUMP  |  E TETHER  |  F INTERACT  |  Q POLARITY  |  LMB BLADE"
	crosshair = _label(Vector2(625, 340), 26, Color.WHITE)
	crosshair.text = "+"

	state_panel = ColorRect.new()
	state_panel.position = Vector2(330, 220)
	state_panel.size = Vector2(620, 180)
	state_panel.color = Color(0.015, 0.025, 0.05, 0.92)
	state_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_panel.visible = false
	add_child(state_panel)
	state_label = Label.new()
	state_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 26)
	state_label.add_theme_color_override("font_color", Color("8eefff"))
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_panel.add_child(state_label)


func _label(position_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _bind_runtime() -> void:
	var flow := get_tree().get_first_node_in_group("game_flow") as GameFlowManager
	if flow != null:
		flow.level_started.connect(_on_level_started)
		flow.objective_updated.connect(_on_objective_updated)
		flow.time_updated.connect(_on_time_updated.bind(flow))
		flow.score_updated.connect(_on_score_updated.bind(flow))
		flow.game_failed.connect(_on_failed)
		flow.game_victory.connect(_on_victory)
		flow.flow_state_changed.connect(_on_flow_state_changed)
		var snapshot := flow.get_snapshot()
		level_label.text = str(snapshot.level_name)
		_on_objective_updated(snapshot.objective, snapshot.completed_steps, snapshot.total_steps)
		_update_stats(float(snapshot.elapsed_seconds), int(snapshot.total_score))

	var player := get_tree().get_first_node_in_group("action_player") as CharacterBody3D
	if player == null:
		return
	var health := player.find_child("PlayerHealth", true, false) as PlayerHealth
	if health != null:
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.maximum_health)
	var interaction := player.find_child("InteractionController", true, false) as InteractionController
	if interaction != null:
		interaction.target_changed.connect(_on_interaction_target)
		interaction.interaction_result.connect(_on_action_result)
	var polarity := player.find_child("PolarityController", true, false) as PolarityController
	if polarity != null:
		polarity.target_changed.connect(_on_polarity_target)
		polarity.polarity_result.connect(_on_action_result)
	var grapple := player.find_child("GrappleController", true, false) as GrappleController
	if grapple != null:
		grapple.target_changed.connect(_on_grapple_target)


func _on_level_started(_index: int, level_name: String) -> void:
	level_label.text = level_name
	state_panel.visible = false


func _on_objective_updated(description: String, completed: int, total: int) -> void:
	objective_label.text = "OBJECTIVE %d/%d // %s" % [completed, total, description]


func _on_time_updated(elapsed: float, flow: GameFlowManager) -> void:
	_update_stats(elapsed, flow.total_score)


func _on_score_updated(score: int, flow: GameFlowManager) -> void:
	_update_stats(flow.level_elapsed_seconds, score)


func _update_stats(elapsed: float, score: int) -> void:
	stats_label.text = "%02d:%02d  //  %05d" % [int(elapsed) / 60, int(elapsed) % 60, score]


func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "INTEGRITY  %s%s" % ["■".repeat(current), "□".repeat(maximum - current)]


func _on_interaction_target(_target: Node, prompt: String) -> void:
	prompt_label.text = prompt
	crosshair.modulate = Color("ffe06a") if not prompt.is_empty() else Color.WHITE


func _on_polarity_target(_target: Node, valid: bool) -> void:
	if valid:
		prompt_label.text = "Q // INVERT POLARITY"
		crosshair.modulate = Color("c07cff")


func _on_grapple_target(_target: Node, valid: bool) -> void:
	if valid:
		prompt_label.text = "E // TETHER"
		crosshair.modulate = Color("55eaff")


func _on_action_result(message: String, success: bool) -> void:
	prompt_label.text = message
	prompt_label.modulate = Color("72ffad") if success else Color("ff667d")


func _on_failed(reason: String) -> void:
	state_panel.visible = true
	state_label.text = "SIMULATION FAILURE\n%s\n\nPRESS R TO RETRY" % reason


func _on_victory(elapsed: float, score: int) -> void:
	state_panel.visible = true
	state_label.text = "SYSTEM BREACH COMPLETE\nTOTAL %02d:%02d // SCORE %05d\n\nPRESS R TO REPLAY" % [int(elapsed) / 60, int(elapsed) % 60, score]


func _on_flow_state_changed(state: StringName) -> void:
	if state in [GameFlowManager.STATE_PLAYING, GameFlowManager.STATE_BOOT]:
		state_panel.visible = false
