class_name AccessDeniedPuzzle
extends Node

## Tutorial objective: use PHASE on the security seal, then traverse Jefin's
## facility and reach the final access relay.

signal puzzle_solved
signal progress_changed(description: String, completed_steps: int, total_steps: int)

@export var phase_barrier_path: NodePath
@export var access_relay_path: NodePath

@onready var phase_barrier: PhaseableBarrier = get_node(phase_barrier_path)
@onready var access_relay: AccessRelay = get_node(access_relay_path)

var phase_learned := false
var relay_reached := false
var is_solved := false


func _ready() -> void:
	phase_barrier.state_changed.connect(_on_phase_state_changed)
	access_relay.relay_activated.connect(_on_relay_activated)
	call_deferred("_evaluate")


func _on_phase_state_changed(is_phased: bool) -> void:
	if is_phased:
		phase_learned = true
	_evaluate()


func _on_relay_activated() -> void:
	relay_reached = true
	_evaluate()


func _evaluate() -> void:
	var completed_steps := int(phase_learned) + int(relay_reached)
	var description: String
	if not phase_learned:
		description = "FOLLOW ACCESS ROUTE // USE PHASE ON THE CYAN SECURITY SEAL"
	elif not relay_reached:
		description = "RESTRICTED ACCESS OPEN // CROSS THE DAMAGED BRIDGE TO THE EXIT RELAY"
	else:
		description = "ACCESS VERIFIED // PROCEED TO THE CONTAINMENT EXIT"
	progress_changed.emit(description, completed_steps, 2)
	if completed_steps == 2 and not is_solved:
		is_solved = true
		puzzle_solved.emit()
