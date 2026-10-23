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


func settle_physics(frames := 6) -> void:
	for _frame in range(frames):
		await physics_frame


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
	check(level.get_node_or_null("Environment") == level.environment, "Level 1 contains exactly one production environment instance")
	check(level.environment.transform.is_equal_approx(Transform3D.IDENTITY), "production environment has no accidental wrapper transform")
	check(flow.player.scale.is_equal_approx(Vector3.ONE), "shared player keeps unit scale in Level 1")
	check(level.has_valid_player_spawn(), "Level 1 resolves Jefin's PlayerSpawn marker")
	check(level.get_player_spawn_transform().origin.is_equal_approx(Vector3(-2.0, 0.4, 35.0)), "Level 1 begins at the intended unobstructed observation spawn")
	check(level.get_node_or_null("GrappleAnchor_01_Runtime") is GrappleAnchor, "first real grapple marker is integrated")
	check(level.get_node_or_null("GrappleAnchor_02_Runtime") is GrappleAnchor, "second real grapple marker is integrated")
	var primary_anchor := level.get_node("GrappleAnchor_01_Runtime") as GrappleAnchor
	var secondary_anchor := level.get_node("GrappleAnchor_02_Runtime") as GrappleAnchor
	var grapple := flow.player.find_child("GrappleController", true, false) as GrappleController
	var launch_marker := level.markers.get_node("TetherLaunch_01") as Marker3D
	var fall_marker := level.markers.get_node("FallZoneMarker") as Marker3D
	var initial_rope_distance := launch_marker.global_position.distance_to(primary_anchor.get_grapple_point())
	var fall_volume_top := fall_marker.global_position.y + 0.5
	check(absf(initial_rope_distance - 7.647876) < 0.001, "Level 1 first launch-to-anchor distance is measured at 7.65 metres")
	check(is_equal_approx(fall_volume_top, -4.5), "Level 1 fall volume begins at y=-4.5")
	check(primary_anchor.get_grapple_point().y - primary_anchor.maximum_initial_rope_length > fall_volume_top + 4.0, "primary anchor safe rope target clears the fall volume by over four metres")
	check(primary_anchor.get_grapple_prompt() == "E // SWING", "cyan anchor exposes the SWING prompt")
	check(level.pull_handle.get_grapple_prompt() == "E // DEPLOY BRIDGE", "amber handle exposes the machinery prompt")
	var hud := flow.get_node("CampaignHUD") as CampaignHUD
	hud._on_grapple_target(primary_anchor, true)
	check(hud.prompt_label.text == "E // SWING", "HUD shows SWING only for a valid grapple anchor ray target")
	hud._on_grapple_target(primary_anchor, false)
	check(hud.prompt_label.text.is_empty(), "HUD clears a stale tether prompt when the grapple ray loses its target")
	hud._on_grapple_target(level.pull_handle, true)
	check(hud.prompt_label.text == "E // DEPLOY BRIDGE", "HUD distinguishes the machinery pull handle from a swing anchor")
	hud._on_grapple_target(level.pull_handle, false)

	var approach := level.environment.get_node("Environment/SecurityInterception/PowerApproach")
	var approach_floor := approach.get_node("ApproachFloor") as CSGBox3D
	var approach_left_rail := approach.get_node("ApproachLeftRail") as CSGBox3D
	var approach_right_rail := approach.get_node("ApproachRightRail") as CSGBox3D
	check(approach_floor.position.is_equal_approx(Vector3(-37.7, 0.0, -7.2)), "integration wrapper aligns the diagonal power walkway with both wall openings")
	check(approach_left_rail.size.y <= 1.0 and approach_right_rail.size.y <= 1.0, "power walkway rails remain below the first-person sight line")
	check(approach_left_rail.use_collision and approach_right_rail.use_collision, "corrected power walkway rails preserve matching collision")
	check(not is_equal_approx(approach_left_rail.position.x, -39.1), "left rail uses the walkway's rotated local offset instead of the authored world-X offset")
	var physics := flow.player.get_world_3d().direct_space_state
	var corridor_forward := Basis.from_euler(Vector3(0.0, deg_to_rad(-48.0), 0.0)) * Vector3.FORWARD
	var floor_hits := 0
	var sample_distances: Array[float] = [-7.0, -3.5, 0.0, 3.5, 7.0]
	for distance in sample_distances:
		var floor_sample: Vector3 = approach_floor.global_position + corridor_forward * distance + Vector3.UP * 1.5
		var floor_query := PhysicsRayQueryParameters3D.create(floor_sample, floor_sample + Vector3.DOWN * 3.0)
		var floor_hit := physics.intersect_ray(floor_query)
		if floor_hit.get("collider") == approach_floor:
			floor_hits += 1
	check(floor_hits == 5, "corrected power walkway has continuous matching collision along its centre line")
	var local_right := Basis.from_euler(Vector3(0.0, deg_to_rad(-48.0), 0.0)) * Vector3.RIGHT
	var left_query := PhysicsRayQueryParameters3D.create(approach_floor.global_position + Vector3.UP * 0.65, approach_floor.global_position - local_right * 3.0 + Vector3.UP * 0.65)
	var right_query := PhysicsRayQueryParameters3D.create(approach_floor.global_position + Vector3.UP * 0.65, approach_floor.global_position + local_right * 3.0 + Vector3.UP * 0.65)
	check(physics.intersect_ray(left_query).get("collider") == approach_left_rail, "left corrected rail blocks the walkway edge")
	check(physics.intersect_ray(right_query).get("collider") == approach_right_rail, "right corrected rail blocks the walkway edge")
	check(level.get_node_or_null("IntegrationRouteGuides/PowerApproachGuide_01") is StaticBody3D, "wrapper supplies lightweight amber route guidance")
	check(level.environment.get_node_or_null("Lighting/PowerApproachFill") is OmniLight3D, "power approach receives a shadowless readability fill light")
	check(primary_anchor.maximum_initial_rope_length < initial_rope_distance and secondary_anchor.maximum_initial_rope_length <= 5.0, "Level 1 anchors use scene-specific safe rope limits")
	check(not level.is_exit_unlocked(), "Level 1 exit starts locked")
	check(level.get_node_or_null("ExitSafetyGeometry/NorthDoorSeal") is StaticBody3D, "wrapper seals the north door bypass without editing Jefin's scene")
	check(level.get_node_or_null("ExitSafetyGeometry/SouthDoorSeal") is StaticBody3D, "wrapper seals the south door bypass without editing Jefin's scene")
	check(level.campaign_exit.global_position.x > AccessDeniedSystemBreachLevel.DOOR_PLANE_X + 1.4, "Level 1 exit trigger sits fully beyond the door plane")
	level.campaign_exit._on_body_entered(flow.player)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "locked Level 1 trigger cannot complete progression")

	# Reproduce the reported late attach: already below the ledge and falling fast.
	# A valid connection must remove unsafe outward fall speed and reel toward the
	# authored safe radius without teleporting the CharacterBody3D.
	flow.player.global_position = Vector3(-20.5, -3.5, 30.0)
	flow.player.velocity = Vector3(0.0, -7.0, 0.0)
	check(grapple.try_attach_target(primary_anchor), "late but valid first-anchor acquisition succeeds")
	await settle_physics(66)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "late attached player remains above the failure volume")
	check(flow.player.global_position.y > fall_volume_top, "safe reeling prevents the attached player entering the kill plane")
	check(grapple.get_rope_length() <= primary_anchor.maximum_initial_rope_length + 0.05, "late attachment converges to the anchor's safe rope length")
	grapple.cancel_grapple(&"crossing_safety_test")
	flow.player.global_transform = level.get_player_spawn_transform()
	flow.player.velocity = Vector3.ZERO
	await settle_physics(2)

	level.pull_handle.on_grapple_attached(null)
	await wait_seconds(level.bridge.deployment_duration + 0.12)
	check(level.bridge.is_deployed and level._bridge_deployed, "grapple handle deploys authored bridge")
	check(level.bridge.bridge_shape.use_collision, "deployed authored bridge enables collision")

	for _hit in range(3):
		level.enemy.take_damage(1)
	await settle(3)
	check(level.enemy.is_deactivated() and level.relay_a.available, "security defeat unlocks Relay A")
	check(level.objective_description.contains("WEST CYAN BEACON"), "Relay A objective supplies spatial guidance instead of only a relay name")
	check(bool(level.relay_a.interact(flow.player).success), "Relay A restores through F-interaction contract")
	check(not level.is_exit_unlocked(), "one restored relay cannot unlock the final exit")
	check(level.rewire_console.available, "Relay A unlocks REWIRE console")
	check(bool(level.rewire_console.interact(flow.player).success), "REWIRE routes power to door state")
	var machinery := level.environment.get_node("Environment/PowerDiversion/Machinery")
	check(not (machinery.get_node("SecurityField_Energized") as CSGShape3D).use_collision, "REWIRE disables security field collision")
	check(not (machinery.get_node("PoweredDoor_Locked") as CSGShape3D).use_collision, "REWIRE opens powered door collision")
	check(level.relay_b.available and bool(level.relay_b.interact(flow.player).success), "REWIRE makes Relay B accessible and restorable")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "both relays clear lockdown and unlock exit")
	var final_door := level.environment.get_node("Environment/FinalContainmentExit/ContainmentDoor/LockedDoorPanel") as CSGShape3D
	check(not final_door.visible and not final_door.use_collision, "containment door becomes visibly and physically passable")
	var door_label := level.environment.get_node("Environment/FinalContainmentExit/ContainmentDoor/ContainmentExitLabel") as Label3D
	check(door_label.text.contains("OPEN"), "unlocked doorway is visibly identified from the approach")
	flow.player.global_position = Vector3(31.5, 0.4, 30.0)
	await settle_physics(3)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "approach-side proximity cannot trigger Level 1 completion")
	flow.player.global_position = level.campaign_exit.global_position
	await settle_physics(5)
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
	check(level.get_node_or_null("ExitGrappleAnchor") is GrappleAnchor, "INVERTED upper route has a dedicated visible anchor")
	check(level.get_node_or_null("ExitLaunchStepC") is StaticBody3D, "INVERTED supplies a distinct upper-route launch perch")
	check(level.get_node_or_null("UpperLandingGlow") is StaticBody3D, "INVERTED marks the intended landing edge")
	check(level.get_node_or_null("MaintenanceVectorWall") is VectorRunSurface, "INVERTED supplies marked VECTOR RUN geometry")
	level.campaign_exit._on_body_entered(flow.player)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "locked INVERTED trigger cannot complete progression")
	var start_a := level.stabilizer_a.global_position
	var start_b := level.stabilizer_b.global_position
	check(level.stabilizer_a.toggle_polarity(flow.player), "POLARITY activates Stabilizer A")
	check(level.stabilizer_b.toggle_polarity(flow.player), "POLARITY activates Stabilizer B")
	await wait_seconds(level.stabilizer_a.travel_duration + 0.15)
	check(level.stabilizer_a.global_position.y > start_a.y + 3.5, "Stabilizer A physically changes position")
	check(level.stabilizer_b.global_position.y > start_b.y + 3.5, "Stabilizer B physically changes position")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "two stabilizers unlock INVERTED exit")
	check(level.objective_description.contains("VIOLET BEACONS"), "INVERTED completion reports a contextual upper-route hint")
	flow.player.global_position = Vector3(0, 0.05, -6.0)
	await settle_physics(3)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "lower launch area cannot prematurely complete INVERTED")
	flow.player.global_position = level.campaign_exit.global_position
	await settle_physics(5)
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
	check(level.environment.scene_file_path.ends_with("clock_failure_environment.tscn"), "CLOCK FAILURE instances Jefin's production environment")
	check(level.get_node_or_null("EntryPlatform") == null, "CLOCK FAILURE does not overlap the retired procedural greybox")
	check(level.get_player_spawn_transform().origin.is_equal_approx(Vector3(0.0, 0.4, 35.0)), "CLOCK FAILURE uses the production PlayerSpawn")
	check(level.grapple_anchor_a != null and level.grapple_anchor_b != null, "CLOCK FAILURE binds both production TETHER markers")
	var clock_tether_visuals := level.environment.get_node("Environment/TimingChamber/TetherVisuals")
	check(not (clock_tether_visuals.get_node("AnchorMount_01") as CSGShape3D).use_collision, "CLOCK FAILURE decorative mount cannot intercept TETHER anchor A")
	check(not (clock_tether_visuals.get_node("AnchorMount_02") as CSGShape3D).use_collision, "CLOCK FAILURE decorative mount cannot intercept TETHER anchor B")
	var clock_physics := level.get_world_3d().direct_space_state
	var clock_ray_a := PhysicsRayQueryParameters3D.create(Vector3(0, 1.6, 19), level.grapple_anchor_a.get_grapple_point())
	var clock_ray_b := PhysicsRayQueryParameters3D.create(Vector3(-4, 3.1, 10), level.grapple_anchor_b.get_grapple_point())
	check(clock_physics.intersect_ray(clock_ray_a).get("collider") == level.grapple_anchor_a, "CLOCK FAILURE launch A has direct physics line of sight to its real anchor")
	check(clock_physics.intersect_ray(clock_ray_b).get("collider") == level.grapple_anchor_b, "CLOCK FAILURE launch B has direct physics line of sight to its real anchor")
	check(level.cycle_hazards.size() == 2, "CLOCK FAILURE binds both documented timing hazards")
	var clock_states := level.environment.get_node("Environment/PowerRoutingRoom/StateVisuals")
	var clock_hazard_wall := clock_states.get_node("TimingHazard_Active") as CSGShape3D
	var blocked_route := clock_states.get_node("BlockedRoute_Locked") as CSGShape3D
	check(clock_hazard_wall.visible and clock_hazard_wall.use_collision, "CLOCK FAILURE timing machinery starts visibly and physically active")
	check(blocked_route.visible and blocked_route.use_collision, "CLOCK FAILURE blocked route starts visibly and physically locked")
	check(level.campaign_exit.global_position.z < ClockFailureLevel.EXIT_DOOR_PLANE_Z, "CLOCK FAILURE completion trigger is beyond the real exit door")
	check(not level.sync_a.available, "Sync A starts gated")
	level.campaign_exit._on_body_entered(flow.player)
	check(
		flow.flow_state == GameFlowManager.STATE_PLAYING,
		"locked CLOCK FAILURE exit cannot complete progression (state=%s reason=%s)" % [flow.flow_state, flow.failure_reason]
	)
	level.cycle_hazard._on_body_entered(flow.player)
	await settle(3)
	check(flow.flow_state == GameFlowManager.STATE_FAILED, "live hazard produces recoverable failure")
	flow.restart_current_level()
	await settle(12)
	level = flow.current_level as ClockFailureLevel
	clock_states = level.environment.get_node("Environment/PowerRoutingRoom/StateVisuals")
	clock_hazard_wall = clock_states.get_node("TimingHazard_Active") as CSGShape3D
	blocked_route = clock_states.get_node("BlockedRoute_Locked") as CSGShape3D
	for _hit in range(3):
		level.security_construct.take_damage(1)
	await settle(2)
	check(not level.sync_a.available, "security defeat alone cannot bypass REWIRE")
	check(bool(level.rewire_console.interact(flow.player).success), "CLOCK FAILURE REWIRE accepts interaction")
	await settle(2)
	check(level.cycle_hazards.all(func(hazard: CycleHazard) -> bool: return hazard.is_disabled), "REWIRE physically disables both cyclic hazards")
	check(not clock_hazard_wall.visible and not clock_hazard_wall.use_collision, "REWIRE removes production timing-hazard visuals and collision")
	check(not blocked_route.visible and not blocked_route.use_collision, "REWIRE opens the production blocked route")
	check(level.sync_a.available, "security plus REWIRE unlock Sync A")
	check(bool(level.sync_a.interact(flow.player).success), "Sync A restores")
	check(level.sync_b.available and bool(level.sync_b.interact(flow.player).success), "ordered Sync B restores")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "CLOCK FAILURE terminals unlock exit")
	var clock_exit_door := level.environment.get_node("Environment/ExitChamber/ExitDoorStates/Exit_Locked") as CSGShape3D
	check(not clock_exit_door.visible and not clock_exit_door.use_collision, "CLOCK FAILURE real exit door opens visually and physically")
	flow.player.global_position = (level.markers.get_node("ExitMarker") as Node3D).global_position
	await settle_physics(3)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "CLOCK FAILURE approach-side marker cannot trigger completion")
	flow.player.global_position = level.campaign_exit.global_position
	await settle_physics(4)
	check(
		level.campaign_exit.overlaps_body(flow.player),
		"CLOCK FAILURE player overlaps the post-door exit trigger (player=%s exit=%s)" % [flow.player.global_position, level.campaign_exit.global_position]
	)
	check(
		flow.flow_state == GameFlowManager.STATE_VICTORY,
		"CLOCK FAILURE isolated preview completes (state=%s reason=%s)" % [flow.flow_state, flow.failure_reason]
	)
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
	check(level.environment.scene_file_path.ends_with("kernel_panic_environment.tscn"), "KERNEL PANIC instances Jefin's production environment")
	check(level.get_node_or_null("EntryDeck") == null, "KERNEL PANIC does not overlap the retired procedural greybox")
	check(level.get_player_spawn_transform().origin.is_equal_approx(Vector3(0.0, 0.4, 39.0)), "KERNEL PANIC uses the production PlayerSpawn")
	check(level.grapple_anchor_a != null and level.grapple_anchor_b != null, "KERNEL PANIC binds both production TETHER markers")
	var kernel_tether_visuals := level.environment.get_node("Environment/GravityDistortion/TetherVisuals")
	check(not (kernel_tether_visuals.get_node("AnchorMount_01") as CSGShape3D).use_collision, "KERNEL PANIC decorative mount cannot intercept TETHER anchor A")
	check(not (kernel_tether_visuals.get_node("AnchorMount_02") as CSGShape3D).use_collision, "KERNEL PANIC decorative mount cannot intercept TETHER anchor B")
	var kernel_physics := level.get_world_3d().direct_space_state
	var kernel_ray_a := PhysicsRayQueryParameters3D.create(Vector3(0, 1.6, 25), level.grapple_anchor_a.get_grapple_point())
	var kernel_ray_b := PhysicsRayQueryParameters3D.create(Vector3(-2, 7.0, 16), level.grapple_anchor_b.get_grapple_point())
	check(kernel_physics.intersect_ray(kernel_ray_a).get("collider") == level.grapple_anchor_a, "KERNEL PANIC launch A has direct physics line of sight to its real anchor")
	check(kernel_physics.intersect_ray(kernel_ray_b).get("collider") == level.grapple_anchor_b, "KERNEL PANIC landing has direct physics line of sight to anchor B")
	check(level.campaign_exit.global_position.z < KernelPanicLevel.VICTORY_GATE_PLANE_Z, "KERNEL PANIC victory trigger is beyond the real gate")
	level.campaign_exit._on_body_entered(flow.player)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "locked KERNEL PANIC gate cannot complete the campaign")
	check(level.polarity_component.toggle_polarity(flow.player), "first production platform accepts POLARITY")
	await wait_seconds(level.polarity_component.travel_duration + 0.12)
	check(not level.rewire_console.available, "one POLARITY platform cannot bypass the gravity route")
	var platforms := level.environment.get_node("Environment/GravityDistortion/Platforms")
	var target_a := platforms.get_node("PolarityPlatformA_Target") as CSGShape3D
	check(target_a.visible and target_a.use_collision, "first POLARITY action creates its production landing platform")
	check(level.polarity_component_b.toggle_polarity(flow.player), "second production platform accepts POLARITY")
	await wait_seconds(level.polarity_component_b.travel_duration + 0.12)
	var target_b := platforms.get_node("PolarityPlatformB_Target") as CSGShape3D
	check(target_b.visible and target_b.use_collision, "second POLARITY action creates its production landing platform")
	check(level.rewire_console.available, "both POLARITY platforms unlock core REWIRE")
	check(bool(level.rewire_console.interact(flow.player).success), "core REWIRE disables shield power")
	await settle(2)
	check(not level.core_shield.visible and not level.core_shield.use_collision, "production core shield becomes visibly and physically nonblocking")
	var disabled_shield := level.environment.get_node("Environment/CorePowerNetwork/Machinery/CoreShield_Disabled") as CSGShape3D
	check(disabled_shield.visible, "REWIRE exposes the production disabled-shield state")
	for _hit in range(3):
		level.security_construct.take_damage(1)
	await settle(2)
	check(level.shutdown_terminal.available, "POLARITY, REWIRE and combat unlock shutdown terminal")
	check(bool(level.shutdown_terminal.interact(flow.player).success), "kernel shutdown interaction completes")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "shutdown unlocks final extraction")
	var victory_gate := level.environment.get_node("Environment/KernelShutdown/VictoryGateStates/VictoryGate_Locked") as CSGShape3D
	check(not victory_gate.visible and not victory_gate.use_collision, "kernel shutdown opens the real victory gate")
	flow.player.global_position = (level.markers.get_node("FinalVictoryMarker") as Node3D).global_position
	await settle_physics(3)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "approach-side victory marker cannot end the campaign")
	flow.player.global_position = level.campaign_exit.global_position
	await settle_physics(4)
	check(
		level.campaign_exit.overlaps_body(flow.player),
		"KERNEL PANIC player overlaps the post-gate victory trigger (player=%s exit=%s)" % [flow.player.global_position, level.campaign_exit.global_position]
	)
	check(
		flow.flow_state == GameFlowManager.STATE_VICTORY,
		"KERNEL PANIC isolated preview reaches victory (state=%s reason=%s)" % [flow.flow_state, flow.failure_reason]
	)
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
