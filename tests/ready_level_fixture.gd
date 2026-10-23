extends GameplayLevel

## Test-only lifecycle fixture; never registered in Main.
@export var fail_on_ready := false

func _ready() -> void:
	report_objective("READY OBJECTIVE", 0, 1)
	if fail_on_ready:
		fail_level("READY FAILURE")
