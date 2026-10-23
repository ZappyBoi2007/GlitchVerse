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
