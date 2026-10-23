extends CanvasLayer

## Developer-preview readout only. Production UI can consume the level's
## fragment_progress_changed signal instead.

var _panel: PanelContainer
var _label: Label
var _bound_level: NullSpindleLevel


func _ready() -> void:
	layer = 8
	_build_display()
	call_deferred("_bind_to_flow")


func _build_display() -> void:
	_panel = PanelContainer.new()
	_panel.name = "FragmentPanel"
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.position = Vector2(-278, 76)
	_panel.size = Vector2(254, 78)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.075, 0.9)
	panel_style.border_color = Color(0.2, 0.78, 0.88, 0.75)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(5)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	_label = Label.new()
	_label.text = "REALITY FRAGMENTS\n0 / 2 REQUIRED"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color("8eefff"))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)


func _bind_to_flow() -> void:
	var flow := get_tree().get_first_node_in_group("game_flow") as GameFlowManager
	if flow == null:
		return
	if not flow.level_started.is_connected(_on_level_started):
		flow.level_started.connect(_on_level_started)
	_bind_level(flow.current_level)


func _on_level_started(_level_index: int, _level_name: String) -> void:
	var flow := get_tree().get_first_node_in_group("game_flow") as GameFlowManager
	_bind_level(flow.current_level if flow != null else null)


func _bind_level(candidate: GameplayLevel) -> void:
	if is_instance_valid(_bound_level) and _bound_level.fragment_progress_changed.is_connected(_on_fragment_progress_changed):
		_bound_level.fragment_progress_changed.disconnect(_on_fragment_progress_changed)
	_bound_level = candidate as NullSpindleLevel
	if _bound_level == null:
		_panel.visible = false
		return
	_panel.visible = true
	_bound_level.fragment_progress_changed.connect(_on_fragment_progress_changed)
	var snapshot := _bound_level.get_fragment_snapshot()
	_on_fragment_progress_changed(snapshot.collected, snapshot.required, snapshot.total)


func _on_fragment_progress_changed(collected: int, required: int, total: int) -> void:
	if collected >= required:
		_label.text = "REALITY FRAGMENTS  %d / %d\nREQUIREMENT COMPLETE%s" % [
			collected, required, "  •  BONUS FOUND" if collected == total else ""
		]
		_label.add_theme_color_override("font_color", Color("7dffbd"))
	else:
		_label.text = "REALITY FRAGMENTS  %d / %d\n%d OPTIONAL IN FACILITY" % [collected, required, total]
		_label.add_theme_color_override("font_color", Color("8eefff"))
