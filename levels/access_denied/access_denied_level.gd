class_name AccessDeniedLevel
extends GameplayLevel

## Gameplay adapter around Jefin's untouched Access Denied environment.

@onready var environment_root: Node3D = $Environment
@onready var phase_barrier: PhaseableBarrier = $PhaseBarrier
@onready var access_relay: AccessRelay = $AccessRelay
@onready var puzzle_exit: PuzzleExit = $PuzzleExit
@onready var puzzle_controller: AccessDeniedPuzzle = $AccessDeniedPuzzle
@onready var fall_hazard: FallHazard = $FallHazard


func _ready() -> void:
	_disable_visual_phase_placeholder()
	puzzle_controller.progress_changed.connect(report_objective)
	puzzle_controller.puzzle_solved.connect(_on_puzzle_solved)
	puzzle_exit.exit_reached.connect(_on_exit_reached)
	fall_hazard.failure_requested.connect(fail_level)


func _disable_visual_phase_placeholder() -> void:
	var placeholder := environment_root.get_node_or_null("PuzzlePlaceholders/PhaseBarrier01") as Node3D
	var barrier_panel := environment_root.get_node_or_null(
		"PuzzlePlaceholders/PhaseBarrier01/BarrierPanel"
	) as CSGBox3D
	if placeholder == null or barrier_panel == null:
		fail_level("ACCESS DENIED REQUIRES JEFIN'S PHASE BARRIER PLACEHOLDER")
		return
	placeholder.visible = false
	barrier_panel.use_collision = false


func _on_puzzle_solved() -> void:
	mark_puzzle_completed()
	puzzle_exit.unlock_exit()
	mark_exit_unlocked()


func _on_exit_reached() -> void:
	finish_level()
