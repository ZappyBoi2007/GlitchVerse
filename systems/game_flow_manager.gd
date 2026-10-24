class_name GameFlowManager
extends Node

## Persistent run controller. Register level PackedScenes in order on the Main node.

signal flow_state_changed(state: StringName)
signal level_loading(level_index: int, level_path: String)
signal level_started(level_index: int, level_name: String)
signal puzzle_completed(level_index: int, elapsed_seconds: float)
signal exit_unlocked(level_index: int)
signal objective_updated(description: String, completed_steps: int, total_steps: int)
signal time_updated(elapsed_seconds: float)
signal score_updated(total_score: int)
signal level_completed(level_index: int, elapsed_seconds: float, awarded_score: int)
signal game_failed(reason: String)
signal game_victory(total_elapsed_seconds: float, total_score: int)
signal replay_started

const STATE_BOOT: StringName = &"boot"
const STATE_PLAYING: StringName = &"playing"
const STATE_LEVEL_COMPLETE: StringName = &"level_complete"
const STATE_FAILED: StringName = &"failed"
const STATE_VICTORY: StringName = &"victory"

@export var level_scenes: Array[PackedScene] = []
@export var auto_start := true
@export_range(0, 3, 1) var starting_level_index := 0
@export var level_container_path := NodePath("LevelContainer")
@export var player_path := NodePath("Player")
@export var failure_height := -20.0
@export_range(0.0, 5.0, 0.1) var level_transition_delay := 1.0

@onready var level_container: Node = get_node_or_null(level_container_path)
@onready var player: CharacterBody3D = get_node_or_null(player_path) as CharacterBody3D

var current_level: GameplayLevel
var current_level_index := -1
var flow_state: StringName = STATE_BOOT
var level_elapsed_seconds := 0.0
var total_elapsed_seconds := 0.0
var total_score := 0
var _last_reported_tenth := -1
var _load_generation := 0
var _completed_results: Dictionary = {}
var failure_reason := ""


func _ready() -> void:
	add_to_group("game_flow")
	_set_player_active(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if auto_start:
		call_deferred("start_game")


func _process(delta: float) -> void:
	if flow_state != STATE_PLAYING:
		return
	level_elapsed_seconds += delta
	var current_tenth := int(level_elapsed_seconds * 10.0)
	if current_tenth != _last_reported_tenth:
		_last_reported_tenth = current_tenth
		time_updated.emit(level_elapsed_seconds)
	if is_instance_valid(player) and player.global_position.y < failure_height:
		fail_current_level("PLAYER LOST OUTSIDE THE SIMULATION")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("restart_level"):
		return
	match flow_state:
		STATE_PLAYING, STATE_FAILED:
			restart_current_level()
		STATE_VICTORY:
			replay_game()
	get_viewport().set_input_as_handled()


func start_game() -> void:
	_completed_results.clear()
	total_elapsed_seconds = 0.0
	total_score = 0
	score_updated.emit(total_score)
	load_level(starting_level_index)


func load_level(level_index: int) -> void:
	# Defer scene-tree/physics mutations, including calls originating in Area3D signals.
	_load_generation += 1
	_set_player_active(false)
	_set_flow_state(STATE_BOOT)
	failure_reason = ""
	_perform_load.call_deferred(level_index, _load_generation)


func _perform_load(level_index: int, generation: int) -> void:
	if generation != _load_generation:
		return
	if level_container == null or player == null:
		fail_current_level("MAIN REQUIRES A LEVEL CONTAINER AND CharacterBody3D PLAYER")
		return
	if level_index < 0 or level_index >= level_scenes.size():
		fail_current_level("LEVEL INDEX %d IS NOT REGISTERED" % level_index)
		return
	var packed_level := level_scenes[level_index]
	if packed_level == null:
		fail_current_level("LEVEL %d IS NOT REGISTERED" % (level_index + 1))
		return

	level_loading.emit(level_index, packed_level.resource_path)
	if generation != _load_generation:
		return
	var level_instance := packed_level.instantiate()
	if not level_instance is GameplayLevel:
		level_instance.queue_free()
		fail_current_level("REGISTERED SCENE MUST EXTEND GameplayLevel")
		return
	var candidate := level_instance as GameplayLevel
	if not candidate.has_valid_player_spawn():
		candidate.queue_free()
		fail_current_level("LEVEL REQUIRES A VALID PlayerSpawn Node3D")
		return

	_clear_current_level()
	current_level = level_instance as GameplayLevel
	current_level_index = level_index
	_connect_level_signals()
	level_container.add_child(current_level)
	# A level may report a configuration failure from _ready().
	if generation != _load_generation or flow_state != STATE_BOOT:
		return
	for completed_index in _completed_results.keys():
		if int(completed_index) >= level_index:
			_completed_results.erase(completed_index)
	_update_totals()
	_reset_player_at_spawn()
	level_elapsed_seconds = 0.0
	_last_reported_tenth = -1
	_set_player_active(true)
	_set_flow_state(STATE_PLAYING)
	level_started.emit(current_level_index, current_level.level_display_name)
	time_updated.emit(0.0)
	objective_updated.emit(current_level.objective_description, current_level.objective_completed_steps, current_level.objective_total_steps)


func restart_current_level() -> void:
	if current_level_index < 0:
		return
	load_level(current_level_index)


func advance_to_next_level() -> void:
	if flow_state != STATE_LEVEL_COMPLETE:
		return
	if current_level_index + 1 == level_scenes.size():
		_finish_game()
	else:
		load_level(current_level_index + 1)


func fail_current_level(reason: String) -> void:
	if flow_state not in [STATE_BOOT, STATE_PLAYING]:
		return
	_load_generation += 1
	failure_reason = reason
	_set_player_active(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_flow_state(STATE_FAILED)
	game_failed.emit(reason)


func replay_game() -> void:
	replay_started.emit()
	start_game()


func get_current_level_name() -> String:
	return current_level.level_display_name if is_instance_valid(current_level) else "NO LEVEL"


func get_snapshot() -> Dictionary:
	# UI scenes can subscribe late without losing initial signals.
	return {
		"state": flow_state, "level_index": current_level_index,
		"level_name": get_current_level_name(), "elapsed_seconds": level_elapsed_seconds,
		"total_elapsed_seconds": total_elapsed_seconds, "total_score": total_score,
		"failure_reason": failure_reason,
		"objective": current_level.objective_description if is_instance_valid(current_level) else "",
		"completed_steps": current_level.objective_completed_steps if is_instance_valid(current_level) else 0,
		"total_steps": current_level.objective_total_steps if is_instance_valid(current_level) else 0,
		"exit_unlocked": current_level.is_exit_unlocked() if is_instance_valid(current_level) else false,
	}


func _connect_level_signals() -> void:
	current_level.puzzle_completed.connect(_on_puzzle_completed)
	current_level.exit_unlocked.connect(_on_exit_unlocked)
	current_level.level_completed.connect(_on_level_completed)
	current_level.level_failed.connect(fail_current_level)
	current_level.objective_updated.connect(_on_objective_updated)


func _on_puzzle_completed() -> void:
	puzzle_completed.emit(current_level_index, level_elapsed_seconds)


func _on_exit_unlocked() -> void:
	exit_unlocked.emit(current_level_index)


func _on_objective_updated(description: String, completed_steps: int, total_steps: int) -> void:
	objective_updated.emit(description, completed_steps, total_steps)


func _on_level_completed() -> void:
	if flow_state != STATE_PLAYING or not current_level.is_puzzle_complete() or not current_level.is_exit_unlocked():
		return
	var generation := _load_generation
	_set_player_active(false)
	_set_flow_state(STATE_LEVEL_COMPLETE)
	var awarded_score := _calculate_level_score()
	_completed_results[current_level_index] = {"score": awarded_score, "time": level_elapsed_seconds}
	_update_totals()
	level_completed.emit(current_level_index, level_elapsed_seconds, awarded_score)
	if level_transition_delay > 0.0:
		await get_tree().create_timer(level_transition_delay).timeout
	if generation == _load_generation and flow_state == STATE_LEVEL_COMPLETE:
		advance_to_next_level()


func _update_totals() -> void:
	total_score = 0
	total_elapsed_seconds = 0.0
	for result in _completed_results.values():
		total_score += int(result["score"])
		total_elapsed_seconds += float(result["time"])
	score_updated.emit(total_score)


func _calculate_level_score() -> int:
	var time_difference := current_level.par_time_seconds - level_elapsed_seconds
	var time_adjustment := int(time_difference * (10.0 if time_difference >= 0.0 else 5.0))
	return maxi(100, current_level.base_score + time_adjustment)


func _finish_game() -> void:
	if flow_state != STATE_LEVEL_COMPLETE:
		return
	_load_generation += 1
	_set_player_active(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_flow_state(STATE_VICTORY)
	game_victory.emit(total_elapsed_seconds, total_score)


func _clear_current_level() -> void:
	if not is_instance_valid(current_level):
		return
	current_level.puzzle_completed.disconnect(_on_puzzle_completed)
	current_level.exit_unlocked.disconnect(_on_exit_unlocked)
	current_level.level_completed.disconnect(_on_level_completed)
	current_level.level_failed.disconnect(fail_current_level)
	current_level.objective_updated.disconnect(_on_objective_updated)
	level_container.remove_child(current_level)
	current_level.queue_free()
	current_level = null


func _reset_player_at_spawn() -> void:
	var health := player.find_child("PlayerHealth", true, false) as PlayerHealth
	if health != null:
		health.reset_health()
	player.global_transform = current_level.get_player_spawn_transform()
	player.velocity = Vector3.ZERO
	var head := player.get_node_or_null("Head") as Node3D
	if head != null:
		head.rotation = Vector3.ZERO


func _set_player_active(active: bool) -> void:
	if not is_instance_valid(player):
		return
	player.set_physics_process(active)
	player.set_process_input(active)
	player.set_process_unhandled_input(active)
	var debugger := player.find_child("RealityDebugger", true, false)
	if debugger != null:
		debugger.set_physics_process(active)
		debugger.set_process_unhandled_input(active)
	if active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_flow_state(new_state: StringName) -> void:
	if flow_state == new_state:
		return
	flow_state = new_state
	flow_state_changed.emit(flow_state)
