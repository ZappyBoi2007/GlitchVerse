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


func subtree_has_no_collision(node: Node) -> bool:
	if not node.find_children("*", "CollisionObject3D", true, false).is_empty():
		return false
	for shape in node.find_children("*", "CSGShape3D", true, false):
		if (shape as CSGShape3D).use_collision:
			return false
	return true


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
	check(level.environment.scene_file_path.is_empty(), "Level 1 environment is authored directly in the playable scene for full editor access")
	check(level.get_node_or_null("Environment") == level.environment, "Level 1 contains exactly one expanded authored environment root")
	check(level.environment.get_node_or_null("Environment/ArrivalChamber") != null, "Level 1 expanded hierarchy exposes the complete arrival chamber")
	var level_one_art := level.environment.get_node("Environment/ArrivalChamber/ProductionArtPass")
	check(level_one_art != null, "Level 1 uses Jefin's latest production art pass")
	check(subtree_has_no_collision(level_one_art), "Level 1 production art adds no duplicate collision")
	check(not (level.environment.get_node("Environment/ArrivalChamber/ProductionArtPass/LobbyFloorInlayA") as Node3D).visible, "overscaled Level 1 lobby inlay A cannot contain the spawn camera")
	check(not (level.environment.get_node("Environment/ArrivalChamber/ProductionArtPass/LobbyFloorInlayB") as Node3D).visible, "overscaled Level 1 lobby inlay B cannot obstruct the arrival route")
	check(level.environment.transform.is_equal_approx(Transform3D.IDENTITY), "production environment has no accidental wrapper transform")
	check(flow.player.scale.is_equal_approx(Vector3.ONE), "shared player keeps unit scale in Level 1")
	check(level.has_valid_player_spawn(), "Level 1 resolves Jefin's PlayerSpawn marker")
	check(level.get_player_spawn_transform().origin.is_equal_approx(Vector3(-2.0, 0.4, 35.0)), "Level 1 begins at the intended unobstructed observation spawn")
	check(level.get_node_or_null("GrappleAnchor_01_Runtime") is GrappleAnchor, "first real grapple marker is integrated")
	check(level.get_node_or_null("GrappleAnchor_02_Runtime") is GrappleAnchor, "second real grapple marker is integrated")
	var encounter := level.enemy_encounter
	check(encounter != null and encounter.enabled and encounter.spawn_marker_paths.size() == 11, "Level 1 multi-room encounter exposes every authored marker in the editor")
	check(encounter.maximum_simultaneous_enemies == RandomEnemyEncounter.MAX_ALIVE_ENEMIES and encounter.maximum_total_enemies == 5, "encounter uses the hard four-alive global cap and finite five-enemy objective")
	check(encounter.spawn_marker_paths.size() == encounter.spawn_marker_room_ids.size(), "every enemy marker has an explicit room identity")
	var arrival_excluded := true
	for marker_path in encounter.spawn_marker_paths:
		arrival_excluded = arrival_excluded and not String(marker_path).contains("PlayerSpawn") and encounter.get_spawn_room_for_marker(marker_path) != &"arrival_chamber"
	check(arrival_excluded, "the arrival chamber and PlayerSpawn are excluded from all enemy spawn sources")
	check(encounter.get_accessible_room_ids() == PackedStringArray(["security_interception"]), "locked rooms are ineligible before their progression state opens")
	check(encounter.minimum_spawn_interval == 5.0 and encounter.maximum_spawn_interval == 9.0, "random spawn interval remains within the configured 5-9 second range")
	var seeded_delays_a := encounter.sample_spawn_delays(5, 2468)
	var seeded_delays_b := encounter.sample_spawn_delays(5, 2468)
	check(seeded_delays_a == seeded_delays_b, "two seeded encounter runs produce reproducible spawn delays")
	var delays_in_bounds := true
	for delay in seeded_delays_a:
		delays_in_bounds = delays_in_bounds and delay >= encounter.minimum_spawn_interval and delay <= encounter.maximum_spawn_interval
	check(delays_in_bounds, "seeded random spawn delays stay inside configured bounds")
	check(is_equal_approx(encounter.get_attack_interval_for_wave(1), 1.8), "wave 1 uses the fair initial attack interval")
	check(is_equal_approx(encounter.get_attack_interval_for_wave(2), 1.5), "wave 2 moderately increases attack speed")
	check(is_equal_approx(encounter.get_attack_interval_for_wave(3), 1.2), "wave 3 moderately increases attack speed")
	check(is_equal_approx(encounter.get_attack_interval_for_wave(20), 1.0), "attack interval respects the hard minimum cap")
	var enemy_at_authored_spawn := false
	var enemy_planar := Vector2(level.enemy.global_position.x, level.enemy.global_position.z)
	for marker_path in encounter.spawn_marker_paths:
		var marker := encounter.get_node(marker_path) as Marker3D
		var marker_planar := Vector2(marker.global_position.x, marker.global_position.z)
		if enemy_planar.distance_to(marker_planar) < 0.1:
			enemy_at_authored_spawn = true
	check(enemy_at_authored_spawn, "Level 1 initial enemy selects one of the authored arena markers")
	check(level.enemy.obstacle_probe != null and level.enemy.obstacle_probe.enabled, "enemy obstacle jump probe is authored and enabled")
	check(level.enemy.movement_speed >= 6.0 and level.enemy.dash_speed > level.enemy.movement_speed, "enemy chase and dash speeds support agile pursuit")
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
	var gate_body := level.environment.get_node("Environment/FinalContainmentExit/ContainmentDoor/ImportedGateCollision") as StaticBody3D
	var gate_collision := gate_body.get_node("CollisionShape3D") as CollisionShape3D
	var imported_gate_visual := level.environment.get_node("Environment/FinalContainmentExit/ProductionArtPass/FinalDoorArchitecture/ImportedGate") as Node3D
	var final_door_panel := level.environment.get_node("Environment/FinalContainmentExit/ContainmentDoor/LockedDoorPanel") as CSGShape3D
	check(not gate_collision.disabled and imported_gate_visual.visible, "closed imported gate has synchronized visible collision")
	check(not final_door_panel.use_collision, "closed gate uses exactly one authored blocking collider")
	var gate_probe_body := CharacterBody3D.new()
	var gate_probe_shape_node := CollisionShape3D.new()
	var gate_probe_shape := CapsuleShape3D.new()
	gate_probe_shape.radius = 0.35
	gate_probe_shape.height = 1.8
	gate_probe_shape_node.position.y = 0.9
	gate_probe_shape_node.shape = gate_probe_shape
	gate_probe_body.add_child(gate_probe_shape_node)
	root.add_child(gate_probe_body)
	gate_probe_body.global_position = Vector3(31.2, 0.65, 30.0)
	await settle_physics(2)
	var closed_gate_hit := gate_probe_body.move_and_collide(Vector3(4.0, 0.0, 0.0), true)
	check(closed_gate_hit != null and closed_gate_hit.get_collider() == gate_body, "closed imported gate blocks a CharacterBody3D sweep with its authored collider")
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
	var crossing_rooms := encounter.get_eligible_spawn_room_ids()
	check(crossing_rooms.has("broken_crossing") and crossing_rooms.has("security_interception"), "bridge deployment enables two distinct reachable enemy-spawn rooms")
	check(not crossing_rooms.has("power_diversion") and not crossing_rooms.has("final_containment"), "Power Diversion and Final Containment remain locked before their progression events")
	var all_spawn_markers_have_floor := true
	for marker_path in encounter.spawn_marker_paths:
		var spawn_marker := encounter.get_node(marker_path) as Node3D
		var floor_query := PhysicsRayQueryParameters3D.create(spawn_marker.global_position + Vector3.UP, spawn_marker.global_position + Vector3.DOWN)
		all_spawn_markers_have_floor = all_spawn_markers_have_floor and not physics.intersect_ray(floor_query).is_empty()
	check(all_spawn_markers_have_floor, "every authored multi-room spawn marker stands over solid collision")

	encounter.force_activate()
	check(encounter.total_spawned == 1 and encounter.get_active_enemies().size() == 1, "encounter registers the authored initial enemy exactly once")
	check(encounter.try_spawn_now() and encounter.try_spawn_now() and encounter.try_spawn_now(), "encounter fills globally available slots up to four living enemies")
	check(not encounter.try_spawn_now() and not encounter.try_spawn_now() and encounter.get_global_alive_count() == 4, "same-frame spawn attempts cannot create a fifth living enemy")
	var first_wave_enemies := encounter.get_active_enemies()
	check(is_equal_approx(first_wave_enemies[0].attack_cooldown, 1.8) and is_equal_approx(first_wave_enemies[1].attack_cooldown, 1.8), "first two enemies retain wave 1 attack timing")
	check(is_equal_approx(first_wave_enemies[2].attack_cooldown, 1.5), "third spawned enemy receives wave 2 attack timing")
	check(is_equal_approx(first_wave_enemies[3].attack_cooldown, 1.5), "fourth spawned enemy retains wave 2 attack timing")
	first_wave_enemies[0].take_damage(first_wave_enemies[0].maximum_health)
	await settle(2)
	check(encounter.get_global_alive_count() == 3, "a defeated guard immediately frees one global living-enemy slot")
	check(encounter.time_until_spawn >= encounter.minimum_spawn_interval and encounter.time_until_spawn <= encounter.maximum_spawn_interval, "replacement keeps the normal configured spawn delay after a death")
	encounter.time_until_spawn = 0.0
	await settle(2)
	check(encounter.total_spawned == encounter.maximum_total_enemies and encounter.get_global_alive_count() == 4, "one delayed replacement occupies the freed slot without exceeding four alive")
	check(not encounter.try_spawn_now(), "finite mandatory budget refuses an extra spawn before the clear-all objective completes")
	for active_enemy in encounter.get_active_enemies():
		active_enemy.take_damage(active_enemy.maximum_health)
	await settle(3)
	check(encounter.is_completed() and encounter.total_defeated == encounter.maximum_total_enemies, "finite enemy budget completes after every security guard is defeated")
	check(level.relay_a.available, "completed finite security encounter unlocks Relay A")
	check(encounter.try_spawn_now() and encounter.get_global_alive_count() == 1, "non-gating reinforcement mode can reuse a free slot after mandatory completion")
	var removable_reinforcement := encounter.get_active_enemies()[0]
	removable_reinforcement.queue_free()
	await settle(3)
	check(encounter.get_global_alive_count() == 0, "removing a live guard clears its stale global registry reference")
	check(level.objective_description.contains("WEST CYAN BEACON"), "Relay A objective supplies spatial guidance instead of only a relay name")
	check(bool(level.relay_a.interact(flow.player).success), "Relay A restores through F-interaction contract")
	check(encounter.is_room_accessible(&"power_diversion"), "Relay A makes Power Diversion spawn markers eligible")
	check(not level.is_exit_unlocked(), "one restored relay cannot unlock the final exit")
	check(level.rewire_console.available, "Relay A unlocks REWIRE console")
	check(bool(level.rewire_console.interact(flow.player).success), "REWIRE routes power to door state")
	check(encounter.is_room_accessible(&"final_containment"), "powered route makes Final Containment spawn markers eligible")
	var machinery := level.environment.get_node("Environment/PowerDiversion/Machinery")
	check(not (machinery.get_node("SecurityField_Energized") as CSGShape3D).use_collision, "REWIRE disables security field collision")
	check(not (machinery.get_node("PoweredDoor_Locked") as CSGShape3D).use_collision, "REWIRE opens powered door collision")
	check(level.relay_b.available and bool(level.relay_b.interact(flow.player).success), "REWIRE makes Relay B accessible and restorable")
	await settle_physics(2)
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "both relays clear lockdown and unlock exit")
	check(not encounter.try_spawn_now(), "opening the containment exit stops every further reinforcement spawn")
	check(gate_collision.disabled and not imported_gate_visual.visible, "opened imported gate hides its closed mesh and disables its collider")
	check(not final_door_panel.visible and not final_door_panel.use_collision, "containment door becomes visibly and physically passable")
	gate_probe_body.global_position = Vector3(31.2, 0.65, 30.0)
	var open_gate_hit := gate_probe_body.move_and_collide(Vector3(4.0, 0.0, 0.0), true)
	check(open_gate_hit == null, "opened imported gate permits CharacterBody3D passage without an invisible wall")
	gate_probe_body.queue_free()
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
	check(level.enemy_encounter.total_spawned == 1 and level.enemy_encounter.get_active_enemies().size() == 1, "replay resets the encounter without duplicate enemies or callbacks")
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
	check(level.environment.scene_file_path.ends_with("inverted_production_environment.tscn"), "INVERTED instances Jefin's production environment")
	check(level.get_node_or_null("InvertedProductionEnvironment") == level.environment, "INVERTED contains exactly one production environment instance")
	check(level.environment.transform.is_equal_approx(Transform3D.IDENTITY), "INVERTED production environment uses identity transform")
	check(level.get_player_spawn_transform().origin.is_equal_approx(Vector3(0.0, 0.05, 16.0)), "INVERTED uses the production PlayerSpawn marker")
	var floor_shell := level.environment.get_node("Environment/Architecture/FloorShell") as CSGShape3D
	var floor_inset := level.environment.get_node("Environment/Architecture/FloorInset") as CSGShape3D
	check(not floor_shell.visible and not floor_inset.visible, "unsupported broad production floor shells are hidden")
	check(subtree_has_no_collision(level.environment), "INVERTED production art contributes no duplicate collision")
	var supported_surfaces := true
	var inverted_physics := level.get_world_3d().direct_space_state
	for support in [
		["ArrivalDeck", Vector3(0, 2, 14), Vector3(0, -2, 14)],
		["ReactorDeck", Vector3(0, 2, 0), Vector3(0, -2, 0)],
		["UpperExitDeck", Vector3(0, 6, -14), Vector3(0, 2, -14)],
		["LeftCatwalk", Vector3(-8, 4, -7), Vector3(-8, 0, -7)],
		["RightCatwalk", Vector3(8, 4, -7), Vector3(8, 0, -7)],
	]:
		var support_body := level.get_node(support[0]) as StaticBody3D
		var support_mesh := support_body.get_node("Mesh") as MeshInstance3D
		var support_shape := support_body.get_node("CollisionShape3D") as CollisionShape3D
		var support_hit := inverted_physics.intersect_ray(PhysicsRayQueryParameters3D.create(support[1], support[2]))
		supported_surfaces = supported_surfaces and not support_mesh.visible and not support_shape.disabled and support_hit.get("collider") == support_body
	check(supported_surfaces, "each visible production deck/catwalk is backed by retained procedural collision")
	check(level.get_node_or_null("EntryGrappleAnchor") is GrappleAnchor, "INVERTED supplies TETHER traversal")
	check(level.get_node_or_null("ExitGrappleAnchor") is GrappleAnchor, "INVERTED upper route has a dedicated visible anchor")
	check(not (level.get_node("EntryGrappleAnchor/Mesh") as MeshInstance3D).visible and not (level.get_node("ExitGrappleAnchor/Mesh") as MeshInstance3D).visible, "production fixtures replace only the functional anchor spheres")
	check((level.get_node("EntryGrappleAnchor/CollisionShape3D") as CollisionShape3D).disabled == false and (level.get_node("ExitGrappleAnchor/CollisionShape3D") as CollisionShape3D).disabled == false, "both hidden anchor spheres retain gameplay collision")
	var entry_marker := level.markers.get_node("EntryGrappleAnchor") as Node3D
	var exit_anchor_marker := level.markers.get_node("ExitGrappleAnchor") as Node3D
	check((level.get_node("EntryGrappleAnchor") as Node3D).global_position.is_equal_approx(entry_marker.global_position), "entry TETHER anchor aligns with production fixture marker")
	check((level.get_node("ExitGrappleAnchor") as Node3D).global_position.is_equal_approx(exit_anchor_marker.global_position), "exit TETHER anchor aligns with production fixture marker")
	var entry_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 1.6, 16), entry_marker.global_position)
	var exit_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 2.7, -6.6), exit_anchor_marker.global_position)
	check(inverted_physics.intersect_ray(entry_ray).get("collider") == level.get_node("EntryGrappleAnchor"), "entry fixture has direct physics line of sight to its TETHER anchor")
	check(inverted_physics.intersect_ray(exit_ray).get("collider") == level.get_node("ExitGrappleAnchor"), "upper launch perch has direct physics line of sight to its TETHER anchor")
	check(level.get_node_or_null("ExitLaunchStepC") is StaticBody3D, "INVERTED supplies a distinct upper-route launch perch")
	check(level.get_node_or_null("UpperLandingGlow") is StaticBody3D, "INVERTED marks the intended landing edge")
	check(level.get_node_or_null("MaintenanceVectorWall") is VectorRunSurface, "INVERTED supplies marked VECTOR RUN geometry")
	var direct_procedural_lights := 0
	for child in level.get_children():
		if child is Light3D:
			direct_procedural_lights += 1
	check(direct_procedural_lights == 0, "production lighting replaces all procedural Level 2 lights")
	var visible_exit_frame := level.environment.get_node("Environment/ExitAssembly/UpperExitFrame") as Node3D
	check(is_equal_approx(visible_exit_frame.global_position.z, InvertedLevel.VISIBLE_EXIT_PLANE_Z), "decorative upper doorway is aligned to the supported physical exit deck")
	check(level.campaign_exit.global_position.z < InvertedLevel.VISIBLE_EXIT_PLANE_Z and level.campaign_exit.global_position.z >= -18.0, "completion trigger is beyond the visible doorway and remains on physical deck collision")
	check(not level.campaign_exit.beacon.visible, "production exit deck replaces the legacy beacon disc")
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
	flow.player.global_position = (level.markers.get_node("CampaignExit") as Node3D).global_position
	await settle_physics(3)
	check(flow.flow_state == GameFlowManager.STATE_PLAYING, "former z=-15.5 exit marker cannot complete before crossing the visible doorway")
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
	var clock_art := level.environment.get_node("Environment/TimingChamber/ProductionArtPass")
	check(clock_art != null, "CLOCK FAILURE uses Jefin's latest production art pass")
	check(subtree_has_no_collision(clock_art), "CLOCK FAILURE production art adds no duplicate collision")
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
	level.security_construct.take_damage(level.security_construct.maximum_health)
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
	var kernel_art := level.environment.get_node("Environment/CorePowerNetwork/ProductionArtPass")
	check(kernel_art != null, "KERNEL PANIC uses Jefin's latest production art pass")
	check(subtree_has_no_collision(kernel_art), "KERNEL PANIC production art adds no duplicate collision")
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
	level.security_construct.take_damage(level.security_construct.maximum_health)
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
