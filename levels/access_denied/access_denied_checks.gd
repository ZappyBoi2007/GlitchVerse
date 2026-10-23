extends SceneTree

## Headless contract checks for Jefin's environment plus the Level 1 gameplay adapter.

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


func count_collidable_csg(node: Node) -> int:
	var count := 1 if node is CSGShape3D and node.use_collision else 0
	for child in node.get_children():
		count += count_collidable_csg(child)
	return count


func _run() -> void:
	await _check_level_contract()
	await _check_flow_failure_restart_and_completion()
	print("ACCESS DENIED CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check_level_contract() -> void:
	var level_scene := load("res://levels/access_denied/access_denied_level.tscn") as PackedScene
	var level := level_scene.instantiate() as AccessDeniedLevel
	root.add_child(level)
	await settle()

	check(level != null, "Level 1 root extends GameplayLevel")
	check(level.has_valid_player_spawn(), "Level 1 exposes a valid PlayerSpawn")
	check(level.environment_root.get_node_or_null("Geometry/StartRoom") != null, "Jefin start room is preserved")
	check(level.environment_root.get_node_or_null("Geometry/BridgeChallenge") != null, "Jefin bridge route is preserved")
	check(level.environment_root.get_node_or_null("Geometry/ExitRoom") != null, "Jefin exit room is preserved")
	check(count_collidable_csg(level.environment_root) >= 180, "authored environment retains broad collision coverage")
	var placeholder := level.environment_root.get_node(
		"PuzzlePlaceholders/PhaseBarrier01/BarrierPanel"
	) as CSGBox3D
	check(not placeholder.use_collision, "static phase placeholder collision is disabled")
	var phase_shape := level.phase_barrier.get_node("SolidCollision").shape as BoxShape3D
	check(
		phase_shape.size.x * level.phase_barrier.scale.x >= placeholder.size.x
		and phase_shape.size.y * level.phase_barrier.scale.y >= placeholder.size.y,
		"functional PHASE collider covers authored placeholder footprint"
	)
	check(not level.is_puzzle_complete(), "Level 1 puzzle starts incomplete")
	check(not level.is_exit_unlocked(), "Level 1 exit starts locked")

	var player := CharacterBody3D.new()
	player.add_to_group("player")
	root.add_child(player)
	check(level.access_relay.try_activate(player), "player can activate exit-approach relay")
	await settle(2)
	check(not level.is_puzzle_complete(), "relay alone cannot bypass PHASE objective")
	check(not level.is_exit_unlocked(), "relay alone leaves exit locked")
	level.phase_barrier.apply_ability(&"phase", level)
	await settle(3)
	check(level.puzzle_controller.phase_learned, "PHASE interaction latches tutorial objective")
	check(level.puzzle_controller.relay_reached, "relay traversal latches route objective")
	check(level.is_puzzle_complete(), "both objectives complete Level 1 puzzle")
	check(level.is_exit_unlocked(), "both objectives unlock standard exit")

	player.queue_free()
	level.queue_free()
	await settle(3)


func _check_flow_failure_restart_and_completion() -> void:
	var preview_scene := load("res://levels/access_denied/access_denied_preview.tscn") as PackedScene
	var flow := preview_scene.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(10)
	var first_level := flow.current_level as AccessDeniedLevel
	check(first_level != null, "preview loads Access Denied through GameFlowManager")
	check(first_level.fall_hazard.try_trigger(flow.player), "fall hazard recognizes player")
	await settle(2)
	check(flow.flow_state == GameFlowManager.STATE_FAILED, "fall hazard enters recoverable failure state")

	flow.restart_current_level()
	await settle(10)
	var restarted_level := flow.current_level as AccessDeniedLevel
	check(restarted_level != first_level, "retry reloads a fresh Level 1 instance")
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "retry restores playing state")
	check(not restarted_level.puzzle_controller.phase_learned, "retry resets PHASE objective")
	check(not restarted_level.access_relay.is_activated, "retry resets relay objective")
	check(not restarted_level.is_exit_unlocked(), "retry relocks exit")

	restarted_level.phase_barrier.apply_ability(&"phase", restarted_level)
	await settle(2)
	check(not restarted_level.is_puzzle_complete(), "PHASE alone cannot unlock exit")
	restarted_level.access_relay.try_activate(flow.player)
	await settle(3)
	check(restarted_level.is_exit_unlocked(), "intended PHASE then relay sequence unlocks exit")
	restarted_level.puzzle_exit._on_exit_trigger_body_entered(flow.player)
	await settle(5)
	check(flow.flow_state == GameFlowManager.STATE_VICTORY, "exit reports completion through normal one-level flow")

	flow.queue_free()
	await settle(3)
