class_name DemoPuzzleController
extends Node

## Demonstration condition: all three debugger states must be active together.

signal puzzle_solved
signal progress_changed(description: String, completed_steps: int, total_steps: int)

@export var phase_barrier_path: NodePath
@export var gravity_crate_path: NodePath
@export var moving_hazard_path: NodePath

@onready var phase_barrier: PhaseableBarrier = get_node(phase_barrier_path)
@onready var gravity_crate: GravityCrate = get_node(gravity_crate_path)
@onready var moving_hazard: FreezableHazard = get_node(moving_hazard_path)

var is_solved := false


func _ready() -> void:
	phase_barrier.state_changed.connect(_evaluate_puzzle)
	gravity_crate.state_changed.connect(_evaluate_puzzle)
	moving_hazard.state_changed.connect(_evaluate_puzzle)
	call_deferred("_evaluate_puzzle")


func _evaluate_puzzle(_unused_state: bool = false) -> void:
	if is_solved:
		return
	var completed_steps := 0
	completed_steps += 1 if phase_barrier.is_phased else 0
	completed_steps += 1 if gravity_crate.gravity_inverted else 0
	completed_steps += 1 if moving_hazard.is_frozen else 0
	var description := "PHASE barrier • INVERT crate • FREEZE hazard"
	progress_changed.emit(description, completed_steps, 3)
	if completed_steps == 3:
		is_solved = true
		puzzle_solved.emit()
