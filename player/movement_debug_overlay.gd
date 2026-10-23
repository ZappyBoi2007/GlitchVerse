extends CanvasLayer

## Development-only movement telemetry. It is intentionally disabled in the
## shipped player scene; enable debug_enabled in the inspector while tuning.

@export var debug_enabled := false

@onready var readout: Label = $Panel/Margin/Readout

var player: CharacterBody3D
var grapple: GrappleController
var vector_run: VectorRunController


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	grapple = player.find_child("GrappleController", true, false) as GrappleController
	vector_run = player.find_child("VectorRunController", true, false) as VectorRunController
	visible = debug_enabled
	set_process(debug_enabled)


func _process(_delta: float) -> void:
	if not debug_enabled or player == null or grapple == null:
		return
	var data := grapple.get_debug_snapshot()
	var movement_state := "VECTOR RUN" if vector_run != null and vector_run.is_wall_running() else str(data.state)
	readout.text = (
		"MOVEMENT DEBUG\n"
		+ "State: %s\n" % movement_state
		+ "Horizontal: %.2f m/s\n" % float(data.horizontal_speed)
		+ "Rope: %.2f m\n" % float(data.rope_length)
		+ "Swing: %.2f m/s\n" % float(data.swing_speed)
		+ "Grounded: %s\n" % str(player.is_on_floor())
		+ "Release: %.2f m/s" % float(data.last_release_speed)
	)
