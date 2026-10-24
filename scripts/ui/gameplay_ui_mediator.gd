class_name GameplayUIMediator
extends CanvasLayer


## Bridges live gameplay flow signals with UI modals (PauseMenu, GameOver, FinalVictory).

@export var pause_menu: PauseMenu
@export var game_over_screen: GameOver
@export var victory_screen: FinalVictory

var _flow: GameFlowManager
var _current_level_id: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	UIAudio.initialize_audio_service(self)
	_connect_ui_signals()
	call_deferred("_bind_flow")


func _bind_flow() -> void:
	_flow = get_tree().get_first_node_in_group("game_flow") as GameFlowManager
	if _flow != null:
		if not _flow.level_started.is_connected(_on_level_started):
			_flow.level_started.connect(_on_level_started)
		if not _flow.game_failed.is_connected(_on_game_failed):
			_flow.game_failed.connect(_on_game_failed)
		if not _flow.game_victory.is_connected(_on_game_victory):
			_flow.game_victory.connect(_on_game_victory)
		var snapshot: Dictionary = _flow.get_snapshot()
		if snapshot.has("level_index"):
			_current_level_id = int(snapshot["level_index"]) + 1


func _connect_ui_signals() -> void:
	if pause_menu != null:
		pause_menu.hide()
		if not pause_menu.restarted.is_connected(_on_pause_restarted):
			pause_menu.restarted.connect(_on_pause_restarted)
		if not pause_menu.aborted_to_menu.is_connected(_return_to_main_menu):
			pause_menu.aborted_to_menu.connect(_return_to_main_menu)

	if game_over_screen != null:
		game_over_screen.hide()
		if not game_over_screen.retry_requested.is_connected(_on_game_over_retry):
			game_over_screen.retry_requested.connect(_on_game_over_retry)
		if not game_over_screen.menu_requested.is_connected(_return_to_main_menu):
			game_over_screen.menu_requested.connect(_return_to_main_menu)

	if victory_screen != null:
		victory_screen.hide()
		if not victory_screen.replay_requested.is_connected(_on_victory_replay):
			victory_screen.replay_requested.connect(_on_victory_replay)
		if not victory_screen.menu_requested.is_connected(_return_to_main_menu):
			victory_screen.menu_requested.connect(_return_to_main_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_handle_pause_toggle()


func _handle_pause_toggle() -> void:
	if game_over_screen != null and game_over_screen.visible:
		return
	if victory_screen != null and victory_screen.visible:
		return
	if pause_menu == null:
		return

	if pause_menu.visible:
		pause_menu.close()
		get_viewport().set_input_as_handled()
	else:
		if _flow != null and _flow.flow_state == GameFlowManager.STATE_PLAYING:
			pause_menu.open(_current_level_id)
			get_viewport().set_input_as_handled()


func _on_level_started(level_index: int, _level_name: String) -> void:
	_current_level_id = level_index + 1
	if pause_menu != null and pause_menu.visible:
		pause_menu.close()
	if game_over_screen != null:
		game_over_screen.hide()
	if victory_screen != null:
		victory_screen.hide()


func _on_game_failed(reason: String) -> void:
	if pause_menu != null and pause_menu.visible:
		pause_menu.close()
	if game_over_screen != null:
		game_over_screen.show_game_over(_current_level_id, reason, "0x%03X_SYS_DESYNC" % randi_range(100, 999))


func _on_game_victory(total_time: float, total_score: int) -> void:
	if pause_menu != null and pause_menu.visible:
		pause_menu.close()
	if victory_screen != null:
		victory_screen.show_victory(total_time, total_score)


func _on_pause_restarted() -> void:
	if _flow != null:
		_flow.restart_current_level()


func _on_game_over_retry(_level_id: int) -> void:
	if _flow != null:
		_flow.restart_current_level()


func _on_victory_replay() -> void:
	if _flow != null:
		_flow.replay_game()


func _return_to_main_menu() -> void:
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
