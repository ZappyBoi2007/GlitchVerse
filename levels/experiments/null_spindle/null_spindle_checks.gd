extends SceneTree

## Focused headless contract check for the experimental level.

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		print("FAIL: ", description)


func settle() -> void:
	for _frame in range(5):
		await process_frame


func _run() -> void:
	var level_scene := load("res://levels/experiments/null_spindle/null_spindle.tscn") as PackedScene
	var level := level_scene.instantiate() as GameplayLevel
	root.add_child(level)
	await settle()
	check(level != null, "level root implements GameplayLevel")
	check(level.has_valid_player_spawn(), "level exposes a valid PlayerSpawn")
	check(level.get_node_or_null("EnergySpindle") != null, "central reactor landmark is built")
	check(level.get_node_or_null("WestMaintenanceRamp") != null, "west descent is built")
	check(level.get_node_or_null("EastContainmentRamp") != null, "east ascent is built")
	check(not level.is_puzzle_complete(), "puzzle starts incomplete")
	check(not level.is_exit_unlocked(), "exit starts locked")

	level.get_node("PhaseableBarrier").apply_ability(&"phase", level)
	level.get_node("GravityCrate").apply_ability(&"gravity", level)
	level.get_node("MovingHazard").apply_ability(&"freeze", level)
	await settle()
	check(level.get_node("PhaseableBarrier").is_phased, "phase seal accepts PHASE")
	check(level.get_node("GravityCrate").gravity_inverted, "gate crate accepts GRAVITY")
	check(level.get_node("MovingHazard").is_frozen, "sweeper accepts FREEZE")
	check(not level.is_puzzle_complete(), "debugger puzzle alone does not bypass fragment gate")
	check(not level.is_exit_unlocked(), "exit remains locked without enough fragments")

	var player := CharacterBody3D.new()
	player.add_to_group("player")
	root.add_child(player)
	level.get_node("RealityFragments/IntroFragment").try_collect(player)
	level.get_node("RealityFragments/MaintenanceFragment").try_collect(player)
	await settle()
	check(level.is_puzzle_complete(), "debugger puzzle plus required fragments completes objective")
	check(level.is_exit_unlocked(), "combined objective unlocks containment exit")

	player.queue_free()
	level.queue_free()
	await settle()
	print("NULL SPINDLE CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
