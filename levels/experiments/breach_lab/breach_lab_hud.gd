extends CanvasLayer

var health_label: Label
var status_label: Label
var objective_label: Label
var crosshair: Label


func _ready() -> void:
	layer = 10
	_build_ui()
	call_deferred("_bind_runtime")


func _build_ui() -> void:
	health_label = Label.new()
	health_label.position = Vector2(24, 22)
	health_label.add_theme_font_size_override("font_size", 22)
	health_label.add_theme_color_override("font_color", Color("7dffbd"))
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_label)

	objective_label = Label.new()
	objective_label.position = Vector2(24, 54)
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color("8defff"))
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_label)

	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	status_label.position = Vector2(-330, -74)
	status_label.size = Vector2(660, 46)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text = "E: TETHER TOGGLE   •   SHIFT+W: VECTOR RUN   •   LMB: BLADE   •   R: RESTART"
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("d4e9f2"))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_label)

	crosshair = Label.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-12, -18)
	crosshair.size = Vector2(24, 36)
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 25)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crosshair)


func _bind_runtime() -> void:
	var health := get_tree().get_first_node_in_group("player_health") as PlayerHealth
	if health != null:
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.maximum_health)
	var player := get_tree().get_first_node_in_group("action_player") as CharacterBody3D
	if player != null:
		var grapple := player.find_child("GrappleController", true, false) as GrappleController
		var sword := player.find_child("SwordController", true, false) as SwordController
		var vector_run := player.find_child("VectorRunController", true, false) as VectorRunController
		if grapple != null:
			grapple.target_changed.connect(_on_grapple_target_changed)
			grapple.grapple_attached.connect(_on_grapple_attached)
			grapple.grapple_detached.connect(_on_grapple_detached)
		if sword != null:
			sword.hit_confirmed.connect(_on_sword_hit)
		if vector_run != null:
			vector_run.wall_run_started.connect(_on_wall_run_started)
			vector_run.wall_run_ended.connect(_on_wall_run_ended)
			vector_run.wall_jumped.connect(_on_wall_jumped)
	var flow := get_tree().get_first_node_in_group("game_flow") as GameFlowManager
	if flow != null:
		flow.objective_updated.connect(_on_objective_updated)
		var snapshot := flow.get_snapshot()
		_on_objective_updated(snapshot.objective, snapshot.completed_steps, snapshot.total_steps)


func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "INTEGRITY  %s%s" % ["■".repeat(current), "□".repeat(maximum - current)]


func _on_objective_updated(description: String, completed: int, total: int) -> void:
	objective_label.text = "OBJECTIVE %d/%d  //  %s" % [completed, total, description]


func _on_grapple_target_changed(_target: Node, valid: bool) -> void:
	crosshair.add_theme_color_override("font_color", Color("45e8ff") if valid else Color.WHITE)


func _on_grapple_attached(_target: Node) -> void:
	status_label.text = "TETHER LOCKED // PRESS E TO RELEASE // BUILD MOMENTUM WITH WASD"


func _on_grapple_detached(_reason: StringName) -> void:
	_set_default_status()


func _on_wall_run_started(_surface: Node, _side: int) -> void:
	status_label.text = "VECTOR RUN ACTIVE // SPACE TO WALL-JUMP"


func _on_wall_run_ended(_reason: StringName) -> void:
	_set_default_status()


func _on_wall_jumped() -> void:
	status_label.text = "VECTOR IMPULSE // MOMENTUM PRESERVED"


func _set_default_status() -> void:
	status_label.text = "E: TETHER TOGGLE   •   SHIFT+W: VECTOR RUN   •   LMB: BLADE   •   R: RESTART"


func _on_sword_hit(_target: Node, _damage: int) -> void:
	status_label.text = "BLADE IMPACT CONFIRMED"
	get_tree().create_timer(0.45).timeout.connect(
		_set_default_status,
		CONNECT_ONE_SHOT
	)
