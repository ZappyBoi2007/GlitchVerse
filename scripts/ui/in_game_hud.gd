class_name InGameHUD
extends CanvasLayer


## Modular In-Game Gameplay & Tactical Research HUD for GlitchVerse.
## Implements mission wayfinding, contextual hints, performance tracking,
## player integrity monitoring, interactive targeting, equipment loadout status,
## and transient notifications across all campaign levels.

signal notification_displayed(message: String, is_alert: bool)
signal health_warning_triggered(current: float, max_health: float)
signal tool_selected(tool_id: String)
signal objective_hint_updated(hint_text: String)

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
@onready var objective_hint_label: Label = %ObjectiveHintLabel

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
@onready var polarity_row: HBoxContainer = get_node_or_null("%PolarityRow") as HBoxContainer
@onready var polarity_label: Label = get_node_or_null("%PolarityLabel") as Label
@onready var polarity_status: Label = get_node_or_null("%PolarityStatus") as Label
@onready var rewire_row: HBoxContainer = get_node_or_null("%RewireRow") as HBoxContainer
@onready var rewire_label: Label = get_node_or_null("%RewireLabel") as Label
@onready var rewire_status: Label = get_node_or_null("%RewireStatus") as Label
@onready var vector_row: HBoxContainer = get_node_or_null("%VectorRow") as HBoxContainer
@onready var vector_label: Label = get_node_or_null("%VectorLabel") as Label
@onready var vector_status: Label = get_node_or_null("%VectorStatus") as Label
@onready var aux_row: HBoxContainer = get_node_or_null("%AuxRow") as HBoxContainer
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
var _current_hint: String = ""
var _selected_ability: String = ""
var _notification_tween: Tween = null
var _interaction_prompt_active: bool = false

var _bound_flow: Node = null
var _bound_player: Node = null
var _bound_health: Node = null
var _bound_grapple: Node = null
var _bound_sword: Node = null
var _bound_interaction: Node = null
var _bound_polarity: Node = null
var _bound_vector: Node = null
var _bound_debugger: Node = null


func _ready() -> void:
	UIAudio.initialize_audio_service(self)
	_apply_level_data()
	set_score(0)
	_reset_to_uninitialized_state()
	call_deferred("_bind_gameplay_runtime")


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
	if objective_hint_label != null:
		objective_hint_label.visible = false
		objective_hint_label.text = ""
	if tether_status != null:
		tether_status.text = "STANDBY"
		tether_status.modulate = UIColors.COLOR_TEXT_MUTED
	if blade_status != null:
		blade_status.text = "STANDBY"
		blade_status.modulate = UIColors.COLOR_TEXT_MUTED
	if polarity_status != null:
		polarity_status.text = "STANDBY"
		polarity_status.modulate = UIColors.COLOR_TEXT_MUTED
	if rewire_status != null:
		rewire_status.text = "STANDBY"
		rewire_status.modulate = UIColors.COLOR_TEXT_MUTED
	if vector_status != null:
		vector_status.text = "STANDBY"
		vector_status.modulate = UIColors.COLOR_TEXT_MUTED
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


# ==============================================================================
# Public API — Mission & Wayfinding
# ==============================================================================

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
	_auto_update_wayfinding_hint(text)


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


func set_objective_hint(hint_text: String) -> void:
	_current_hint = hint_text
	if objective_hint_label != null:
		if hint_text.is_empty():
			objective_hint_label.visible = false
			objective_hint_label.text = ""
		else:
			objective_hint_label.visible = true
			objective_hint_label.text = ">> HINT: %s" % hint_text
	objective_hint_updated.emit(hint_text)


# ==============================================================================
# Public API — Performance Metrics
# ==============================================================================

func set_timer_seconds(seconds: float) -> void:
	_internal_timer_active = false
	_session_time = maxf(0.0, seconds)
	_update_timer_display()


func set_score(points: int) -> void:
	_score = maxi(0, points)
	if score_label != null:
		score_label.text = "SCORE: %05d" % _score


# ==============================================================================
# Public API — Survival & Health
# ==============================================================================

func set_health(current: float, max_health: float = -1.0) -> void:
	if max_health > 0.0:
		_max_health = max_health
	elif not _health_initialized:
		_max_health = maxf(1.0, current)

	_health_initialized = true
	_current_health = clampf(current, 0.0, _max_health)

	var ratio: float = _current_health / _max_health if _max_health > 0.0 else 0.0
	if health_bar != null:
		health_bar.max_value = 100.0
		health_bar.value = ratio * 100.0

	if health_label != null:
		if _max_health <= 10.0:
			health_label.text = "%d / %d HP" % [int(round(_current_health)), int(round(_max_health))]
		else:
			health_label.text = "%d / %d HP" % [int(round(_current_health)), int(round(_max_health))]
		health_label.modulate = UIColors.COLOR_TEXT_PRIMARY

	var was_critical := low_health_alert != null and low_health_alert.visible
	var is_critical := (_current_health <= 1.0 and _max_health <= 5.0) or (ratio <= 0.30 and _current_health > 0.0)
	if low_health_alert != null:
		low_health_alert.visible = is_critical
		if is_critical and not was_critical:
			UIAudio.play_error(self)
			health_warning_triggered.emit(_current_health, _max_health)


# ==============================================================================
# Public API — Tactical Equipment Status
# ==============================================================================

func set_tether_status(status_text: String, is_active: bool = false) -> void:
	if tether_status == null:
		return
	tether_status.text = status_text.to_upper()
	if is_active or status_text.to_upper() in ["READY", "ATTACHED", "LOCKED"]:
		tether_status.modulate = UIColors.COLOR_TOOL_TETHER
	elif status_text.to_upper() == "STANDBY":
		tether_status.modulate = UIColors.COLOR_TEXT_MUTED
	else:
		tether_status.modulate = UIColors.COLOR_TEXT_PRIMARY


func set_blade_status(status_text: String, is_active: bool = false) -> void:
	if blade_status == null:
		return
	blade_status.text = status_text.to_upper()
	if is_active or status_text.to_upper() in ["READY", "STRIKE"]:
		blade_status.modulate = UIColors.COLOR_TOOL_BLADE
	elif status_text.to_upper() in ["COOLDOWN", "RECOVERY"]:
		blade_status.modulate = UIColors.COLOR_CRITICAL
	elif status_text.to_upper() == "STANDBY":
		blade_status.modulate = UIColors.COLOR_TEXT_MUTED
	else:
		blade_status.modulate = UIColors.COLOR_TEXT_PRIMARY


func set_polarity_status(status_text: String, is_active: bool = false) -> void:
	if polarity_status == null:
		return
	polarity_status.text = status_text.to_upper()
	if is_active or status_text.to_upper() in ["READY", "INVERT", "ACTIVE"]:
		polarity_status.modulate = UIColors.COLOR_TOOL_POLARITY
	elif status_text.to_upper() == "STANDBY":
		polarity_status.modulate = UIColors.COLOR_TEXT_MUTED
	else:
		polarity_status.modulate = UIColors.COLOR_TEXT_PRIMARY


func set_rewire_status(status_text: String, is_active: bool = false) -> void:
	if rewire_status == null:
		return
	rewire_status.text = status_text.to_upper()
	if is_active or status_text.to_upper() in ["READY", "DIVERTED", "ONLINE", "ACTIVE"]:
		rewire_status.modulate = UIColors.COLOR_TOOL_REWIRE
	elif status_text.to_upper() == "STANDBY":
		rewire_status.modulate = UIColors.COLOR_TEXT_MUTED
	else:
		rewire_status.modulate = UIColors.COLOR_TEXT_PRIMARY


func set_vector_status(status_text: String, is_active: bool = false) -> void:
	if vector_status == null:
		return
	vector_status.text = status_text.to_upper()
	if is_active or status_text.to_upper() in ["ACTIVE", "WALL-RUN", "WALL-JUMP"]:
		vector_status.modulate = UIColors.COLOR_TOOL_VECTOR
	elif status_text.to_upper() == "STANDBY":
		vector_status.modulate = UIColors.COLOR_TEXT_MUTED
	else:
		vector_status.modulate = UIColors.COLOR_TEXT_PRIMARY


func set_equipped_tool(tool_id: String, tool_name: String = "", status_text: String = "ACTIVE", color: Color = Color.WHITE) -> void:
	if ability_name_label != null:
		ability_name_label.text = tool_name if not tool_name.is_empty() else tool_id.to_upper()
		ability_name_label.modulate = color if color != Color.WHITE else UIColors.get_tool_color(tool_id)
	if ability_badge != null:
		ability_badge.modulate = color if color != Color.WHITE else UIColors.get_tool_color(tool_id)
	if aux_status != null:
		aux_status.text = status_text.to_upper()
		aux_status.modulate = color if color != Color.WHITE else UIColors.get_tool_color(tool_id)
	tool_selected.emit(tool_id)


func set_ability(ability_name: String) -> void:
	_selected_ability = ability_name.to_upper()
	var color := UIColors.get_ability_color(_selected_ability)
	set_equipped_tool(_selected_ability, _selected_ability, "ACTIVE", color)


# ==============================================================================
# Public API — Targeting, Reticle & Prompts
# ==============================================================================

func set_grapple_target(has_target: bool, is_valid: bool = false, target_name: String = "") -> void:
	if grapple_ring != null:
		grapple_ring.visible = has_target
		grapple_ring.modulate = UIColors.COLOR_CONTROLLED if is_valid else UIColors.COLOR_CRITICAL
	if reticle_dot != null:
		reticle_dot.color = UIColors.COLOR_CONTROLLED if is_valid else (UIColors.COLOR_CRITICAL if has_target else UIColors.COLOR_TEXT_PRIMARY)

	if not _interaction_prompt_active:
		if has_target:
			if is_valid:
				set_target_prompt(target_name if not target_name.is_empty() else "E // TETHER", true)
			else:
				set_target_prompt("CANNOT ATTACH // OUT OF RANGE", false)
		else:
			set_target_prompt("", true)


func set_reticle_state(color: Color, show_grapple: bool = false) -> void:
	if reticle_dot != null:
		reticle_dot.color = color
	if grapple_ring != null:
		grapple_ring.visible = show_grapple
		grapple_ring.modulate = color


func set_target_prompt(prompt_text: String, is_compatible: bool = true) -> void:
	if target_prompt_label == null:
		return
	target_prompt_label.text = prompt_text
	target_prompt_label.modulate = UIColors.COLOR_CONTROLLED if is_compatible else UIColors.COLOR_CRITICAL


func show_interaction_prompt(prompt_text: String, is_available: bool = true) -> void:
	_interaction_prompt_active = true
	if target_prompt_label != null:
		target_prompt_label.text = prompt_text
		target_prompt_label.modulate = UIColors.COLOR_CONTROLLED if is_available else UIColors.COLOR_TEXT_MUTED
	if reticle_dot != null:
		reticle_dot.color = UIColors.COLOR_CONTROLLED if is_available else UIColors.COLOR_TEXT_MUTED


func hide_interaction_prompt() -> void:
	_interaction_prompt_active = false
	if target_prompt_label != null:
		target_prompt_label.text = ""
	_reset_reticle()


# ==============================================================================
# Public API — Notifications & Control Hints
# ==============================================================================

func show_notification(message: String, is_alert: bool = false, duration: float = 2.5) -> void:
	if notification_panel == null or notification_label == null:
		return

	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()

	notification_label.text = message
	notification_label.modulate = UIColors.COLOR_CRITICAL if is_alert else UIColors.COLOR_TEXT_PRIMARY

	if is_alert:
		UIAudio.play_error(self)

	notification_panel.visible = true
	notification_panel.modulate.a = 0.0

	_notification_tween = create_tween()
	_notification_tween.tween_property(notification_panel, "modulate:a", 1.0, 0.2)
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


# ==============================================================================
# Internal Formatting & Runtime Autoconnection Logic
# ==============================================================================

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
	_update_default_level_hint(current_level_id)


func _update_default_level_hint(level_id: int) -> void:
	match level_id:
		1:
			set_objective_hint("TETHER across broken crossing // Deploy bridge with pull handle")
		2:
			set_objective_hint("Aim at reactor stabilizers // Press Q to invert polarity")
		3:
			set_objective_hint("Defeat construct // Press F at Rewire console to disable sweep")
		4:
			set_objective_hint("Press Q on power component // Rewire core shield power [F]")
		_:
			set_objective_hint("")
	set_control_hints("E TETHER  |  F INTERACT  |  Q POLARITY  |  LMB BLADE  |  SHIFT VECTOR  |  SPACE JUMP")


func _auto_update_wayfinding_hint(objective_desc: String) -> void:
	var upper := objective_desc.to_upper()
	if "BRIDGE" in upper or "CROSSING" in upper:
		set_objective_hint("TETHER anchors across gap // Pull amber latch to extend bridge")
	elif "SECURITY CONSTRUCT" in upper or "CONSTRUCT" in upper:
		set_objective_hint("Use BLADE [LMB] to strike and disable Security Construct")
	elif "RELAY A" in upper:
		set_objective_hint("Approach cyan Relay A beacon and press [F] to restore")
	elif "REWIRE" in upper or "POWER ROUTE" in upper or "POWER" in upper:
		set_objective_hint("Operate REWIRE console [F] to redirect power to door circuit")
	elif "RELAY B" in upper:
		set_objective_hint("Field disabled! Proceed through opened route to Relay B [F]")
	elif "STABILIZER" in upper or "INVERT" in upper:
		set_objective_hint("Aim directly at stabilizer masses and press [Q] to invert polarity")
	elif "UPPER EXIT" in upper or "REACTOR EXIT" in upper or "EXIT" in upper or "LOCKDOWN CLEARED" in upper:
		set_objective_hint("Containment exit unlocked! Follow markers to extraction gate")
	elif "SYNC A" in upper:
		set_objective_hint("Press [F] at Sync Terminal A to align timing signal")
	elif "SYNC B" in upper:
		set_objective_hint("Sync A online! Proceed forward to Sync Terminal B [F]")
	elif "SHUTDOWN" in upper:
		set_objective_hint("Approach central shutdown console and press [F] to execute")


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


# ==============================================================================
# Safe Runtime Autoconnection to Gameplay Nodes
# ==============================================================================

func _bind_gameplay_runtime() -> void:
	_connect_game_flow_manager()
	_connect_player_and_components()
	_connect_reality_debugger()


func _connect_game_flow_manager() -> void:
	var flow := get_tree().get_first_node_in_group("game_flow")
	if flow == null:
		flow = get_tree().get_first_node_in_group("game_flow_manager")
	if flow == null:
		return

	_bound_flow = flow
	if flow.has_signal("level_started") and not flow.is_connected("level_started", Callable(self, "_on_flow_level_started")):
		flow.connect("level_started", Callable(self, "_on_flow_level_started"))
	if flow.has_signal("objective_updated") and not flow.is_connected("objective_updated", Callable(self, "_on_flow_objective_updated")):
		flow.connect("objective_updated", Callable(self, "_on_flow_objective_updated"))
	if flow.has_signal("time_updated") and not flow.is_connected("time_updated", Callable(self, "set_timer_seconds")):
		flow.connect("time_updated", Callable(self, "set_timer_seconds"))
	if flow.has_signal("score_updated") and not flow.is_connected("score_updated", Callable(self, "set_score")):
		flow.connect("score_updated", Callable(self, "set_score"))
	if flow.has_signal("puzzle_completed") and not flow.is_connected("puzzle_completed", Callable(self, "_on_flow_puzzle_completed")):
		flow.connect("puzzle_completed", Callable(self, "_on_flow_puzzle_completed"))
	if flow.has_signal("exit_unlocked") and not flow.is_connected("exit_unlocked", Callable(self, "_on_flow_exit_unlocked")):
		flow.connect("exit_unlocked", Callable(self, "_on_flow_exit_unlocked"))
	if flow.has_signal("game_failed") and not flow.is_connected("game_failed", Callable(self, "_on_flow_game_failed")):
		flow.connect("game_failed", Callable(self, "_on_flow_game_failed"))
	if flow.has_signal("game_victory") and not flow.is_connected("game_victory", Callable(self, "_on_flow_game_victory")):
		flow.connect("game_victory", Callable(self, "_on_flow_game_victory"))

	if flow.has_method("get_snapshot"):
		var snapshot: Dictionary = flow.call("get_snapshot")
		if snapshot.has("level_index"):
			current_level_id = int(snapshot.get("level_index", 0)) + 1
		if snapshot.has("level_name") and not str(snapshot.get("level_name", "")).is_empty():
			set_level_name(str(snapshot.get("level_name")), "GV-%02d" % current_level_id)
		if snapshot.has("objective") and not str(snapshot.get("objective", "")).is_empty():
			set_objective(str(snapshot.get("objective")))
			set_objective_progress(int(snapshot.get("completed_steps", 0)), int(snapshot.get("total_steps", 0)))
		if snapshot.has("total_score"):
			set_score(int(snapshot.get("total_score", 0)))


func _connect_player_and_components() -> void:
	var player := get_tree().get_first_node_in_group("action_player")
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	_bound_player = player

	# 1. Player Health
	var health := player.find_child("PlayerHealth", true, false)
	if health == null:
		health = get_tree().get_first_node_in_group("player_health")
	if health != null and health != _bound_health:
		_bound_health = health
		if health.has_signal("health_changed") and not health.is_connected("health_changed", Callable(self, "_on_runtime_health_changed")):
			health.connect("health_changed", Callable(self, "_on_runtime_health_changed"))
		var cur: int = int(health.get("current_health")) if "current_health" in health else 3
		var mx: int = int(health.get("maximum_health")) if "maximum_health" in health else 3
		set_health(float(cur), float(mx))

	# 2. Grapple Controller (Tether)
	var grapple := player.find_child("GrappleController", true, false)
	if grapple != null and grapple != _bound_grapple:
		_bound_grapple = grapple
		if grapple.has_signal("target_changed") and not grapple.is_connected("target_changed", Callable(self, "_on_runtime_grapple_target")):
			grapple.connect("target_changed", Callable(self, "_on_runtime_grapple_target"))
		if grapple.has_signal("grapple_attached") and not grapple.is_connected("grapple_attached", Callable(self, "_on_runtime_grapple_attached")):
			grapple.connect("grapple_attached", Callable(self, "_on_runtime_grapple_attached"))
		if grapple.has_signal("grapple_detached") and not grapple.is_connected("grapple_detached", Callable(self, "_on_runtime_grapple_detached")):
			grapple.connect("grapple_detached", Callable(self, "_on_runtime_grapple_detached"))
		set_tether_status("READY", true)

	# 3. Sword Controller (Blade)
	var sword := player.find_child("SwordController", true, false)
	if sword != null and sword != _bound_sword:
		_bound_sword = sword
		if sword.has_signal("attack_started") and not sword.is_connected("attack_started", Callable(self, "_on_runtime_sword_attack_started")):
			sword.connect("attack_started", Callable(self, "_on_runtime_sword_attack_started"))
		if sword.has_signal("attack_finished") and not sword.is_connected("attack_finished", Callable(self, "_on_runtime_sword_attack_finished")):
			sword.connect("attack_finished", Callable(self, "_on_runtime_sword_attack_finished"))
		if sword.has_signal("hit_confirmed") and not sword.is_connected("hit_confirmed", Callable(self, "_on_runtime_sword_hit")):
			sword.connect("hit_confirmed", Callable(self, "_on_runtime_sword_hit"))
		set_blade_status("READY", true)

	# 4. Interaction Controller (Relays, Rewire consoles)
	var interaction := player.find_child("InteractionController", true, false)
	if interaction != null and interaction != _bound_interaction:
		_bound_interaction = interaction
		if interaction.has_signal("target_changed") and not interaction.is_connected("target_changed", Callable(self, "_on_runtime_interaction_target")):
			interaction.connect("target_changed", Callable(self, "_on_runtime_interaction_target"))
		if interaction.has_signal("interaction_result") and not interaction.is_connected("interaction_result", Callable(self, "_on_runtime_action_result")):
			interaction.connect("interaction_result", Callable(self, "_on_runtime_action_result"))

	# 5. Polarity Controller (Gravity stabilizers, Power masses)
	var polarity := player.find_child("PolarityController", true, false)
	if polarity != null and polarity != _bound_polarity:
		_bound_polarity = polarity
		if polarity.has_signal("target_changed") and not polarity.is_connected("target_changed", Callable(self, "_on_runtime_polarity_target")):
			polarity.connect("target_changed", Callable(self, "_on_runtime_polarity_target"))
		if polarity.has_signal("polarity_result") and not polarity.is_connected("polarity_result", Callable(self, "_on_runtime_action_result")):
			polarity.connect("polarity_result", Callable(self, "_on_runtime_action_result"))
		set_polarity_status("READY", true)

	# 6. Vector Run Controller
	var vector_run := player.find_child("VectorRunController", true, false)
	if vector_run != null and vector_run != _bound_vector:
		_bound_vector = vector_run
		if vector_run.has_signal("wall_run_started") and not vector_run.is_connected("wall_run_started", Callable(self, "_on_runtime_wall_run_started")):
			vector_run.connect("wall_run_started", Callable(self, "_on_runtime_wall_run_started"))
		if vector_run.has_signal("wall_run_ended") and not vector_run.is_connected("wall_run_ended", Callable(self, "_on_runtime_wall_run_ended")):
			vector_run.connect("wall_run_ended", Callable(self, "_on_runtime_wall_run_ended"))
		if vector_run.has_signal("wall_jumped") and not vector_run.is_connected("wall_jumped", Callable(self, "_on_runtime_wall_jumped")):
			vector_run.connect("wall_jumped", Callable(self, "_on_runtime_wall_jumped"))
		set_vector_status("STANDBY", false)


func _connect_reality_debugger() -> void:
	var debugger := get_tree().get_first_node_in_group("reality_debugger")
	if debugger == null or debugger == _bound_debugger:
		return
	_bound_debugger = debugger
	if debugger.has_signal("ability_changed") and not debugger.is_connected("ability_changed", Callable(self, "_on_debugger_ability_changed")):
		debugger.connect("ability_changed", Callable(self, "_on_debugger_ability_changed"))
	if debugger.has_signal("target_changed") and not debugger.is_connected("target_changed", Callable(self, "_on_debugger_target_changed")):
		debugger.connect("target_changed", Callable(self, "_on_debugger_target_changed"))
	if debugger.has_signal("feedback_changed") and not debugger.is_connected("feedback_changed", Callable(self, "_on_debugger_feedback_changed")):
		debugger.connect("feedback_changed", Callable(self, "_on_debugger_feedback_changed"))


# ==============================================================================
# Runtime Event Handlers
# ==============================================================================

func _on_runtime_health_changed(current: int, maximum: int) -> void:
	set_health(float(current), float(maximum))


func _on_runtime_grapple_target(_target: Node, valid: bool) -> void:
	set_grapple_target(valid, valid, "E // TETHER" if valid else "")


func _on_runtime_grapple_attached(_target: Node) -> void:
	set_tether_status("ATTACHED", true)
	show_notification("TETHER LOCKED // BUILD MOMENTUM", false, 1.8)


func _on_runtime_grapple_detached(_reason: StringName) -> void:
	set_tether_status("READY", true)


func _on_runtime_sword_attack_started() -> void:
	set_blade_status("STRIKE", true)


func _on_runtime_sword_attack_finished() -> void:
	set_blade_status("READY", true)


func _on_runtime_sword_hit(_target: Node, damage: int) -> void:
	show_notification("BLADE IMPACT // %d DAMAGE CONFIRMED" % damage, false, 1.2)


func _on_runtime_interaction_target(_target: Node, prompt: String) -> void:
	if not prompt.is_empty():
		show_interaction_prompt(prompt, true)
	else:
		hide_interaction_prompt()


func _on_runtime_polarity_target(_target: Node, valid: bool) -> void:
	if valid:
		show_interaction_prompt("Q // INVERT POLARITY", true)
		set_polarity_status("TARGET", true)
	else:
		if not _interaction_prompt_active:
			hide_interaction_prompt()
		set_polarity_status("READY", true)


func _on_runtime_action_result(message: String, success: bool) -> void:
	show_notification(message, not success, 2.5)


func _on_runtime_wall_run_started(_surface: Node, _side: int) -> void:
	set_vector_status("WALL-RUN", true)
	show_notification("VECTOR RUN ACTIVE // SPACE TO WALL-JUMP", false, 1.5)


func _on_runtime_wall_run_ended(_reason: StringName) -> void:
	set_vector_status("STANDBY", false)


func _on_runtime_wall_jumped() -> void:
	set_vector_status("WALL-JUMP", true)
	show_notification("VECTOR IMPULSE // MOMENTUM RETAINED", false, 1.5)


func _on_flow_level_started(level_index: int, level_title: String) -> void:
	current_level_id = level_index + 1
	set_level_name(level_title, "GV-%02d" % current_level_id)
	_update_default_level_hint(current_level_id)
	show_notification("SECTOR %02d INITIALIZED // %s" % [current_level_id, level_title], false, 3.5)
	call_deferred("_connect_player_and_components")


func _on_flow_objective_updated(desc: String, completed_steps: int, total_steps: int) -> void:
	set_objective(desc)
	set_objective_progress(completed_steps, total_steps)


func _on_flow_puzzle_completed(_level_index: int, _elapsed: float) -> void:
	show_notification("OBJECTIVES CLEAR // ACCESS UNLOCKED", false, 3.5)
	var am := UIAudio._get_audio_manager(self)
	if am != null and am.has_method("play_sfx"):
		am.call("play_sfx", &"relay_restore", -4.0)


func _on_flow_exit_unlocked(_level_index: int) -> void:
	set_objective_hint("CONTAINMENT EXIT UNLOCKED // PROCEED TO EXTRACTION GATE")
	show_notification("CONTAINMENT EXIT UNLOCKED", false, 3.5)
	var am := UIAudio._get_audio_manager(self)
	if am != null and am.has_method("play_sfx"):
		am.call("play_sfx", &"exit_unlock", -4.0)


func _on_flow_game_failed(reason: String) -> void:
	show_notification("CRITICAL FAILURE: %s" % reason, true, 4.0)


func _on_flow_game_victory(_total_time: float, _total_score: int) -> void:
	show_notification("SIMULATION COMPLETE // ALL SECTORS CLEARED", false, 5.0)


func _on_debugger_ability_changed(label: String, _color: Color) -> void:
	set_ability(label)


func _on_debugger_target_changed(label: String, compatible: bool, has_target: bool) -> void:
	set_target_prompt(label, compatible)
	set_grapple_target(has_target, compatible, label)


func _on_debugger_feedback_changed(message: String, is_error: bool) -> void:
	show_notification(message, is_error, 2.0)
