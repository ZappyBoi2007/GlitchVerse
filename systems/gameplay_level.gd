class_name GameplayLevel
extends Node3D

## Contract shared by every GlitchVerse level.
## Level-specific puzzle scripts call these methods; GameFlowManager listens to the signals.

signal puzzle_completed
signal exit_unlocked
signal level_completed
signal level_failed(reason: String)
signal objective_updated(description: String, completed_steps: int, total_steps: int)

@export var level_id := "level"
@export var level_display_name := "UNNAMED SIMULATION"
@export_range(10.0, 1800.0, 1.0) var par_time_seconds := 120.0
@export_range(100, 10000, 50) var base_score := 1000
@export var player_spawn_path := NodePath("PlayerSpawn")

var _puzzle_is_complete := false
var _exit_is_unlocked := false
var _level_is_complete := false
var _level_has_failed := false
var objective_description := ""
var objective_completed_steps := 0
var objective_total_steps := 0


func has_valid_player_spawn() -> bool:
	return not player_spawn_path.is_empty() and get_node_or_null(player_spawn_path) is Node3D


func get_player_spawn_transform() -> Transform3D:
	var spawn := get_node_or_null(player_spawn_path) as Node3D
	return spawn.global_transform if spawn != null else global_transform


func is_puzzle_complete() -> bool:
	return _puzzle_is_complete


func is_exit_unlocked() -> bool:
	return _exit_is_unlocked


func mark_puzzle_completed() -> void:
	if _puzzle_is_complete or _level_has_failed:
		return
	_puzzle_is_complete = true
	puzzle_completed.emit()


func mark_exit_unlocked() -> void:
	if _exit_is_unlocked or not _puzzle_is_complete or _level_has_failed:
		return
	_exit_is_unlocked = true
	exit_unlocked.emit()


func finish_level() -> void:
	if _level_is_complete or not _exit_is_unlocked or not _puzzle_is_complete or _level_has_failed:
		return
	_level_is_complete = true
	level_completed.emit()


func fail_level(reason: String) -> void:
	if _level_is_complete or _level_has_failed:
		return
	_level_has_failed = true
	level_failed.emit(reason)


func report_objective(description: String, completed_steps: int, total_steps: int) -> void:
	objective_description = description
	objective_completed_steps = completed_steps
	objective_total_steps = total_steps
	objective_updated.emit(description, completed_steps, total_steps)
