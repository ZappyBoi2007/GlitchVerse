extends SceneTree

## Run: Godot.exe --headless --path . --script res://tests/integration_checks.gd
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
	for frame in range(4):
		await process_frame

func physics_steps(count: int) -> void:
	for frame in range(count):
		await physics_frame
	await process_frame

func solve(level: GameplayLevel) -> void:
	level.get_node("PhaseableBarrier").apply_ability(&"phase", level)
	level.get_node("GravityCrate").apply_ability(&"gravity", level)
	level.get_node("MovingHazard").apply_ability(&"freeze", level)

func make_fixture(with_spawn: bool, fail_on_ready: bool = false) -> PackedScene:
	var node := Node3D.new()
	node.set_script(load("res://tests/ready_level_fixture.gd"))
	node.set("fail_on_ready", fail_on_ready)
	if with_spawn:
		var marker := Marker3D.new()
		marker.name = "PlayerSpawn"
		node.add_child(marker)
		marker.owner = node
	var packed := PackedScene.new()
	check(packed.pack(node) == OK, "pack test-only lifecycle fixture")
	node.free()
	return packed

func _run() -> void:
	var flow = load("res://main.tscn").instantiate()
	root.add_child(flow)
	await settle()
	check(flow.flow_state == &"playing", "main starts playing")
	flow.advance_to_next_level()
	await settle()
	check(flow.flow_state == &"playing" and flow.current_level_index == 0, "advance cannot bypass puzzle")
	flow.start_game()
	await settle()
	flow.player.get_node("Head").rotation.x = 1.0
	flow.restart_current_level()
	await settle()
	check(is_zero_approx(flow.player.get_node("Head").rotation.x), "restart resets camera pitch")
	flow.load_level(-1)
	await settle()
	check(flow.flow_state == &"failed", "invalid level index fails rather than winning")
	flow.start_game()
	await settle()
	var level = flow.current_level
	level.mark_exit_unlocked()
	level.finish_level()
	await settle()
	check(flow.flow_state == &"playing", "exit contract cannot complete unsolved puzzle")
	var demo: PackedScene = flow.level_scenes[0]
	flow.level_scenes.append(demo) # Repeat existing chamber only inside this test.
	flow.level_transition_delay = 0.2
	flow.set_process(false) # Deterministic score/time checks.
	flow.level_elapsed_seconds = 0.0
	flow._process(12.5)
	check(is_equal_approx(flow.level_elapsed_seconds, 12.5), "timer advances while playing")
	solve(level)
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "all three interactions unlock exit")
	level.finish_level()
	var awarded: int = flow.total_score
	check(awarded == 1775, "par score calculated exactly once")
	level.finish_level()
	check(flow.total_score == awarded, "duplicate finish does not award twice")
	flow._process(10.0)
	check(is_equal_approx(flow.level_elapsed_seconds, 12.5), "timer stops at completion")
	await create_timer(0.08).timeout
	flow.restart_current_level()
	await settle()
	level = flow.current_level
	check(flow.total_score == 0 and is_zero_approx(flow.total_elapsed_seconds), "restart completed attempt rolls back its score and time")
	check(not level.get_node("PhaseableBarrier").is_phased and not level.get_node("GravityCrate").gravity_inverted and not level.get_node("MovingHazard").is_frozen, "restart resets all puzzle states")
	solve(level)
	level.finish_level()
	await create_timer(0.13).timeout
	check(flow.current_level_index == 0 and flow.flow_state == &"level_complete", "stale transition timer cannot advance new attempt")
	await create_timer(0.12).timeout
	check(flow.current_level_index == 1 and flow.flow_state == &"playing", "automatic transition advances once")
	check(flow.current_level.level_completed.get_connections().size() == 1, "new level has one manager completion subscriber")
	flow.fail_current_level("TEST FAILURE")
	flow._process(10.0)
	check(flow.flow_state == &"failed" and is_zero_approx(flow.level_elapsed_seconds), "failure stops timer")
	flow.current_level.mark_puzzle_completed()
	flow.current_level.mark_exit_unlocked()
	flow.current_level.finish_level()
	check(flow.flow_state == &"failed", "late finish cannot override failure")
	flow.restart_current_level()
	await settle()
	check(flow.flow_state == &"playing" and flow.total_score == 1900, "failed-level retry preserves earlier score")
	solve(flow.current_level)
	flow.level_transition_delay = 0.0
	flow.current_level.finish_level()
	await settle()
	check(flow.flow_state == &"victory" and flow.total_score == 3800, "last registered level wins with aggregate score")
	flow.replay_game()
	await settle()
	check(flow.current_level_index == 0 and flow.total_score == 0, "replay clears run results")

	# Invalid configuration is explicit, with no origin fallback or false victory.
	flow.level_scenes.assign([make_fixture(false)])
	flow.start_game()
	await settle()
	check(flow.flow_state == &"failed" and "PlayerSpawn" in flow.failure_reason, "missing spawn fails with actionable message")
	flow.level_scenes.assign([make_fixture(true)])
	flow.start_game()
	await settle()
	check(flow.get_snapshot()["objective"] == "READY OBJECTIVE", "objective emitted during ready remains available to UI")
	flow.level_scenes.assign([make_fixture(true, true)])
	flow.start_game()
	await settle()
	check(flow.flow_state == &"failed" and flow.failure_reason == "READY FAILURE", "failure emitted during ready is not lost")
	flow.level_scenes.clear()
	flow.start_game()
	await settle()
	check(flow.flow_state == &"failed", "empty registry fails instead of winning")
	flow.level_scenes.assign([null])
	flow.start_game()
	await settle()
	check(flow.flow_state == &"failed", "null registry slot fails explicitly")
	flow.level_scenes.assign([load("res://interactive/gravity_crate.tscn")])
	flow.start_game()
	await settle()
	check(flow.flow_state == &"failed", "wrong level root type fails explicitly")

	# Exercise real camera raycasts and physics triggers; no direct exit callback.
	flow.level_scenes.assign([demo, demo])
	flow.start_game()
	await settle()
	flow.player.set_physics_process(false)
	level = flow.current_level
	var debugger = flow.player.get_node("Head/Camera3D/RealityDebugger")
	var camera: Camera3D = flow.player.get_node("Head/Camera3D")
	camera.look_at(level.get_node("PhaseableBarrier").global_position)
	await physics_steps(3)
	debugger._select_ability(&"phase")
	debugger._activate_selected_ability()
	check(level.get_node("PhaseableBarrier").is_phased, "camera ray activates PHASE")
	flow.player.global_position = Vector3(0, 0.05, 16.7)
	await physics_steps(3)
	check(not level.get_node("PhaseableBarrier").get_ability_status(&"phase")["compatible"], "phase occupancy prevents solidifying on player")
	flow.player.global_position = Vector3(0, 0.05, 18.4)
	camera.look_at(level.get_node("GravityCrate").global_position)
	await physics_steps(3)
	debugger._select_ability(&"gravity")
	debugger._activate_selected_ability()
	var crate: RigidBody3D = level.get_node("GravityCrate")
	check(crate.gravity_scale < 0.0, "camera ray inverts crate gravity")
	await physics_steps(130)
	check(crate.position.y > 3.0 and crate.position.y < 4.1, "inverted crate moves upward within bounds")
	flow.player.global_position = Vector3(2, 0.05, 21)
	camera.look_at(level.get_node("MovingHazard").global_position)
	debugger._select_ability(&"freeze")
	debugger._activate_selected_ability()
	var hazard = level.get_node("MovingHazard")
	await physics_steps(2)
	var stopped_at: Vector3 = hazard.position
	await physics_steps(4)
	check(hazard.is_frozen and hazard.position.is_equal_approx(stopped_at) and not hazard.get_node("CollisionShape3D").disabled, "ray freezes hazard with solid collision")
	check(level.is_puzzle_complete(), "ray-driven puzzle unlocks exit")
	var npc := CharacterBody3D.new()
	level.add_child(npc)
	level.get_node("PuzzleExit")._on_exit_trigger_body_entered(npc)
	check(flow.flow_state == &"playing", "non-player character cannot complete exit")
	npc.queue_free()
	flow.player.global_position = Vector3(0, 0.05, 24)
	camera.rotation = Vector3.ZERO
	flow.player.set_physics_process(true)
	Input.action_press("move_forward")
	await physics_steps(45)
	Input.action_release("move_forward")
	check(flow.current_level_index == 1 and flow.flow_state == &"playing", "actual exit Area3D safely loads next level with zero transition delay")
	solve(flow.current_level)
	flow.current_level.finish_level()
	await settle()
	check(flow.flow_state == &"victory", "second completed level reaches victory")
	# Unlocking while already in a trigger must not require leaving and re-entering.
	var isolated_exit = load("res://interactive/puzzle_exit.tscn").instantiate()
	isolated_exit.position = Vector3(40, 2.1, 0)
	root.add_child(isolated_exit)
	var entries := [0]
	isolated_exit.exit_reached.connect(func(): entries[0] += 1)
	flow.player.global_position = Vector3(40, 0.05, 0.9)
	await physics_steps(3)
	check(entries[0] == 0, "locked exit ignores overlapping player")
	isolated_exit.unlock_exit()
	await settle()
	check(entries[0] == 1, "unlock detects existing player overlap once")
	isolated_exit.unlock_exit()
	await settle()
	check(entries[0] == 1, "repeated unlock does not complete twice")
	isolated_exit.queue_free()
	flow.replay_game()
	await settle()
	flow.player.global_position.y = -30.0
	flow._process(0.1)
	check(flow.flow_state == &"failed", "falling below kill height triggers failure")
	flow.queue_free()
	await settle()
	var menu_flow = load("res://main.tscn").instantiate()
	menu_flow.auto_start = false
	root.add_child(menu_flow)
	await settle()
	check(menu_flow.flow_state == &"boot" and menu_flow.current_level == null and not menu_flow.player.is_physics_processing(), "menu can defer starting gameplay")
	menu_flow.start_game()
	await settle()
	check(menu_flow.flow_state == &"playing", "menu start command loads gameplay")
	menu_flow.queue_free()
	await settle()
	print("AUDIT CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
