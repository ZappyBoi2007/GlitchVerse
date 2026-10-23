extends SceneTree

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		print("FAIL: ", description)


func settle(frames := 8) -> void:
	for _frame in range(frames):
		await process_frame


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	await _check_level_one()
	await _check_level_two()
	await _check_level_three()
	await _check_level_four()
	await _check_campaign_progression()
	print("FINAL CAMPAIGN CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _check_level_one() -> void:
	var preview := load("res://levels/access_denied/access_denied_system_breach_preview.tscn") as PackedScene
	var flow := preview.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(14)
	var level := flow.current_level as AccessDeniedSystemBreachLevel
	check(level != null, "production ACCESS DENIED loads through GameFlowManager")
	check(level.environment.scene_file_path.ends_with("access_denied_system_breach_environment.tscn"), "Level 1 instances Jefin's production environment")
	check(level.has_valid_player_spawn(), "Level 1 resolves Jefin's PlayerSpawn marker")
	check(level.get_node_or_null("GrappleAnchor_01_Runtime") is GrappleAnchor, "first real grapple marker is integrated")
	check(level.get_node_or_null("GrappleAnchor_02_Runtime") is GrappleAnchor, "second real grapple marker is integrated")
	check(not level.is_exit_unlocked(), "Level 1 exit starts locked")

	level.pull_handle.on_grapple_attached(null)
	await wait_seconds(level.bridge.deployment_duration + 0.12)
	check(level.bridge.is_deployed and level._bridge_deployed, "grapple handle deploys authored bridge")
	check(level.bridge.bridge_shape.use_collision, "deployed authored bridge enables collision")

	for _hit in range(3):
		level.enemy.take_damage(1)
	await settle(3)
	check(level.enemy.is_deactivated() and level.relay_a.available, "security defeat unlocks Relay A")
	check(bool(level.relay_a.interact(flow.player).success), "Relay A restores through F-interaction contract")
	check(level.rewire_console.available, "Relay A unlocks REWIRE console")
	check(bool(level.rewire_console.interact(flow.player).success), "REWIRE routes power to door state")
	var machinery := level.environment.get_node("Environment/PowerDiversion/Machinery")
	check(not (machinery.get_node("SecurityField_Energized") as CSGShape3D).use_collision, "REWIRE disables security field collision")
	check(not (machinery.get_node("PoweredDoor_Locked") as CSGShape3D).use_collision, "REWIRE opens powered door collision")
	check(level.relay_b.available and bool(level.relay_b.interact(flow.player).success), "REWIRE makes Relay B accessible and restorable")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "both relays clear lockdown and unlock exit")
	var final_door := level.environment.get_node("Environment/FinalContainmentExit/ContainmentDoor/LockedDoorPanel") as CSGShape3D
	check(not final_door.visible and not final_door.use_collision, "containment door becomes visibly and physically passable")
	level.campaign_exit._on_body_entered(flow.player)
	await settle(5)
	check(flow.flow_state == GameFlowManager.STATE_VICTORY, "Level 1 completion reaches victory in isolated preview")

	flow.replay_game()
	await settle(14)
	level = flow.current_level as AccessDeniedSystemBreachLevel
	check(not level.bridge.is_deployed and not level.relay_a.is_restored and not level.rewire_console.door_powered, "replay reconstructs bridge, relay, and REWIRE state")
	flow.queue_free()
	await settle(3)


func _check_level_two() -> void:
	var preview := load("res://levels/inverted/inverted_preview.tscn") as PackedScene
	var flow := preview.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(12)
	var level := flow.current_level as InvertedLevel
	check(level != null and level.has_valid_player_spawn(), "INVERTED loads with a valid spawn")
	check(level.get_node_or_null("EntryGrappleAnchor") is GrappleAnchor, "INVERTED supplies TETHER traversal")
	check(level.get_node_or_null("MaintenanceVectorWall") is VectorRunSurface, "INVERTED supplies marked VECTOR RUN geometry")
	var start_a := level.stabilizer_a.global_position
	var start_b := level.stabilizer_b.global_position
	check(level.stabilizer_a.toggle_polarity(flow.player), "POLARITY activates Stabilizer A")
	check(level.stabilizer_b.toggle_polarity(flow.player), "POLARITY activates Stabilizer B")
	await wait_seconds(level.stabilizer_a.travel_duration + 0.15)
	check(level.stabilizer_a.global_position.y > start_a.y + 3.5, "Stabilizer A physically changes position")
	check(level.stabilizer_b.global_position.y > start_b.y + 3.5, "Stabilizer B physically changes position")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "two stabilizers unlock INVERTED exit")
	level.campaign_exit._on_body_entered(flow.player)
	await settle(4)
	check(flow.flow_state == GameFlowManager.STATE_VICTORY, "INVERTED isolated preview completes")
	flow.queue_free()
	await settle(3)


func _check_level_three() -> void:
	var preview := load("res://levels/clock_failure/clock_failure_preview.tscn") as PackedScene
	var flow := preview.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(12)
	var level := flow.current_level as ClockFailureLevel
	check(level != null and not level.cycle_hazard.is_disabled, "CLOCK FAILURE starts with live cyclic hazard")
	check(not level.sync_a.available, "Sync A starts gated")
	level.cycle_hazard._on_body_entered(flow.player)
	await settle(3)
	check(flow.flow_state == GameFlowManager.STATE_FAILED, "live hazard produces recoverable failure")
	flow.restart_current_level()
	await settle(12)
	level = flow.current_level as ClockFailureLevel
	for _hit in range(3):
		level.security_construct.take_damage(1)
	await settle(2)
	check(not level.sync_a.available, "security defeat alone cannot bypass REWIRE")
	check(bool(level.rewire_console.interact(flow.player).success), "CLOCK FAILURE REWIRE accepts interaction")
	await settle(2)
	check(level.cycle_hazard.is_disabled, "REWIRE physically disables cyclic hazard")
	check(level.sync_a.available, "security plus REWIRE unlock Sync A")
	check(bool(level.sync_a.interact(flow.player).success), "Sync A restores")
	check(level.sync_b.available and bool(level.sync_b.interact(flow.player).success), "ordered Sync B restores")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "CLOCK FAILURE terminals unlock exit")
	level.campaign_exit._on_body_entered(flow.player)
	await settle(4)
	check(flow.flow_state == GameFlowManager.STATE_VICTORY, "CLOCK FAILURE isolated preview completes")
	flow.queue_free()
	await settle(3)


func _check_level_four() -> void:
	var preview := load("res://levels/kernel_panic/kernel_panic_preview.tscn") as PackedScene
	var flow := preview.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(12)
	var level := flow.current_level as KernelPanicLevel
	check(level != null and not level.shutdown_terminal.available, "KERNEL PANIC shutdown starts safeguarded")
	check(level.polarity_component.toggle_polarity(flow.player), "kernel power component accepts POLARITY")
	await wait_seconds(level.polarity_component.travel_duration + 0.12)
	check(level.rewire_console.available, "POLARITY unlocks core REWIRE")
	check(bool(level.rewire_console.interact(flow.player).success), "core REWIRE disables shield power")
	await settle(2)
	var shield_collision := level.core_shield.get_node_or_null("CollisionShape3D") as CollisionShape3D
	check(shield_collision != null, "core shield exposes deterministic collision node")
	check(
		shield_collision != null and not level.core_shield.visible and shield_collision.disabled,
		"core shield becomes visibly and physically nonblocking"
	)
	for _hit in range(3):
		level.security_construct.take_damage(1)
	await settle(2)
	check(level.shutdown_terminal.available, "POLARITY, REWIRE and combat unlock shutdown terminal")
	check(bool(level.shutdown_terminal.interact(flow.player).success), "kernel shutdown interaction completes")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "shutdown unlocks final extraction")
	level.campaign_exit._on_body_entered(flow.player)
	await settle(4)
	check(flow.flow_state == GameFlowManager.STATE_VICTORY, "KERNEL PANIC isolated preview reaches victory")
	flow.queue_free()
	await settle(3)


func _check_campaign_progression() -> void:
	var main_scene := load("res://main.tscn") as PackedScene
	var flow := main_scene.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(14)
	var expected_paths := [
		"res://levels/access_denied/access_denied_system_breach_level.tscn",
		"res://levels/inverted/inverted_level.tscn",
		"res://levels/clock_failure/clock_failure_level.tscn",
		"res://levels/kernel_panic/kernel_panic_level.tscn",
	]
	check(flow.level_scenes.size() == 4, "main registers exactly four campaign levels")
	for index in range(expected_paths.size()):
		check(flow.level_scenes[index].resource_path == expected_paths[index], "campaign level %d path is correct" % (index + 1))
	check(flow.current_level is AccessDeniedSystemBreachLevel, "F5 campaign begins in ACCESS DENIED")
	for level_index in range(4):
		check(flow.current_level_index == level_index, "campaign reaches level index %d" % level_index)
		flow.current_level.mark_puzzle_completed()
		flow.current_level.mark_exit_unlocked()
		flow.current_level.finish_level()
		await settle(12)
	check(flow.flow_state == GameFlowManager.STATE_VICTORY, "fourth completion produces final campaign victory")
	check(flow.total_score >= 400, "campaign accumulates nonzero scored results")
	flow.replay_game()
	await settle(14)
	check(flow.current_level_index == 0 and flow.total_score == 0, "replay resets score and returns to Level 1")
	flow.queue_free()
	await settle(3)
