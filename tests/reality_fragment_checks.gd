extends SceneTree

## Focused collectible and NULL SPINDLE gate/reload checks. These exercise the
## logical pickup path headlessly; physical overlap and presentation need a human.

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		print("FAIL: ", description)


func settle(frames := 6) -> void:
	for _frame in range(frames):
		await process_frame


func _run() -> void:
	await _check_pickup_contract()
	await _check_level_gate_and_restart()
	print("REALITY FRAGMENT CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check_pickup_contract() -> void:
	var fragment_scene := load("res://interactive/reality_fragment.tscn") as PackedScene
	var fragment := fragment_scene.instantiate() as RealityFragment
	fragment.fragment_id = &"contract_test"
	root.add_child(fragment)
	await settle(2)

	var pickup_events := [0]
	fragment.fragment_collected.connect(func(_fragment_id: StringName) -> void: pickup_events[0] += 1)
	var impostor := CharacterBody3D.new()
	root.add_child(impostor)
	check(not fragment.try_collect(impostor), "CharacterBody3D without player group is rejected")
	check(not fragment.is_collected(), "incorrect actor leaves fragment available")

	var player := CharacterBody3D.new()
	player.add_to_group("player")
	root.add_child(player)
	check(fragment.try_collect(player), "player can collect fragment")
	check(fragment.is_collected(), "successful pickup latches collected state")
	check(pickup_events[0] == 1, "successful pickup emits exactly one event")
	check(not fragment.try_collect(player), "duplicate pickup is rejected")
	check(pickup_events[0] == 1, "duplicate pickup cannot emit or score twice")

	impostor.queue_free()
	player.queue_free()
	fragment.queue_free()
	await settle(2)


func _check_level_gate_and_restart() -> void:
	var preview_scene := load(
		"res://levels/experiments/null_spindle/null_spindle_preview.tscn"
	) as PackedScene
	var flow := preview_scene.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(10)

	var level := flow.current_level as NullSpindleLevel
	check(level != null, "preview loads NULL SPINDLE through GameFlowManager")
	check(level.get_fragment_snapshot().collected == 0, "fresh level starts with zero fragments")
	check(level.get_fragment_snapshot().required == 2, "fragment threshold is two")
	check(level.get_fragment_snapshot().total == 3, "three fragments are registered")

	var player := flow.player
	var fragments := level.get_node("RealityFragments")
	(fragments.get_node("IntroFragment") as RealityFragment).try_collect(player)
	await settle(2)
	check(level.get_fragment_snapshot().collected == 1, "first pickup advances fragment progress")

	level.get_node("PhaseableBarrier").apply_ability(&"phase", level)
	level.get_node("GravityCrate").apply_ability(&"gravity", level)
	level.get_node("MovingHazard").apply_ability(&"freeze", level)
	await settle(4)
	check(level.puzzle_controller.is_solved, "existing three-ability puzzle can still be solved")
	check(not level.is_puzzle_complete(), "puzzle plus one fragment cannot complete level objective")
	check(not level.is_exit_unlocked(), "exit stays locked below fragment threshold")

	(fragments.get_node("MaintenanceFragment") as RealityFragment).try_collect(player)
	await settle(4)
	check(level.get_fragment_snapshot().collected == 2, "second pickup meets fragment threshold")
	check(level.is_puzzle_complete(), "puzzle and fragment threshold complete combined objective")
	check(level.is_exit_unlocked(), "combined objective unlocks exit")

	(fragments.get_node("ObservationBonusFragment") as RealityFragment).try_collect(player)
	await settle(2)
	check(level.get_fragment_snapshot().collected == 3, "optional third fragment is collectible")
	check(level.is_exit_unlocked(), "optional bonus does not disturb completed gate")

	flow.restart_current_level()
	await settle(10)
	var restarted_level := flow.current_level as NullSpindleLevel
	check(restarted_level != level, "restart replaces the level instance")
	check(restarted_level.get_fragment_snapshot().collected == 0, "restart resets fragment count")
	check(restarted_level.get_node("RealityFragments").get_child_count() == 3, "restart restores all pickups")
	check(not restarted_level.is_puzzle_complete(), "restart resets combined puzzle state")
	check(not restarted_level.is_exit_unlocked(), "restart relocks exit")

	flow.queue_free()
	await settle(3)
