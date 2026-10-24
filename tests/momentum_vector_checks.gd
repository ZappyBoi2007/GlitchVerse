extends SceneTree

## Deterministic movement contracts. Subjective swing feel, camera comfort and
## hand timing remain manual-test responsibilities.

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


func settle_physics(frames := 6) -> void:
	for _frame in range(frames):
		await physics_frame


func _run() -> void:
	var grapple_events := InputMap.action_get_events("grapple")
	check(grapple_events.size() == 1 and grapple_events[0] is InputEventKey, "grapple owns one keyboard binding")
	check((grapple_events[0] as InputEventKey).physical_keycode == KEY_E, "E is the grapple toggle")
	check(InputMap.has_action("interact"), "F interaction action is reserved")
	var interact_events := InputMap.action_get_events("interact")
	check(interact_events.size() == 1 and (interact_events[0] as InputEventKey).physical_keycode == KEY_F, "F is reserved for interaction")

	var preview_scene := load("res://levels/experiments/breach_lab/breach_lab.tscn") as PackedScene
	var flow := preview_scene.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(12)
	var level := flow.current_level as BreachLabLevel
	var player := flow.player
	var grapple := player.find_child("GrappleController", true, false) as GrappleController
	var vector_run := player.find_child("VectorRunController", true, false) as VectorRunController
	var debug_overlay := player.find_child("MovementDebugOverlay", true, false)
	var health := player.find_child("PlayerHealth", true, false) as PlayerHealth
	var wall := level.get_node("VectorRunWall") as VectorRunSurface
	var anchor := level.get_node("PrimaryGrappleAnchor") as GrappleAnchor
	check(grapple != null and vector_run != null, "action player owns both movement components")
	check(debug_overlay != null and not debug_overlay.debug_enabled and not debug_overlay.visible, "development movement telemetry exists and is disabled by default")
	check(is_zero_approx(grapple.reel_in_speed), "swing rope does not silently shorten while attached")
	check(wall != null and wall.is_in_group("vector_run_surface"), "BREACH LAB wall uses the marked surface contract")
	wall.enabled = false
	check(not vector_run.is_vector_surface(wall), "disabled marked wall is rejected")
	wall.enabled = true

	var ordinary := StaticBody3D.new()
	root.add_child(ordinary)
	check(not vector_run.is_vector_surface(ordinary), "ordinary geometry is rejected for VECTOR RUN")
	check(not vector_run.begin_wall_run(ordinary, Vector3.LEFT, 1), "wall run cannot begin on ordinary geometry")

	player.global_position = Vector3(0, 3.0, 14.0)
	player.velocity = Vector3.ZERO
	check(grapple.try_attach_target(anchor), "swing attaches from an airborne neutral state")
	check(player.velocity.length() > 0.5 and player.velocity.length() <= grapple.maximum_attach_assist + 0.1, "neutral attachment receives bounded initial swing assistance")
	var gravity_start_y := player.global_position.y
	await settle_physics(12)
	check(player.global_position.y < gravity_start_y, "gravity continues to drive the attached swing")
	check(
		player.global_position.distance_to(anchor.get_grapple_point())
		<= grapple.get_rope_length() + grapple.rope_extension_tolerance + 0.2,
		"rope remains within its collision-safe extension tolerance"
	)
	grapple.cancel_grapple(&"gravity_check_complete")

	var preferred := Vector3.FORWARD
	var right_wall_tangent := vector_run.get_run_tangent(Vector3.LEFT, preferred)
	var left_wall_tangent := vector_run.get_run_tangent(Vector3.RIGHT, preferred)
	check(right_wall_tangent.dot(preferred) > 0.99, "right-side wall chooses forward-aligned tangent")
	check(left_wall_tangent.dot(preferred) > 0.99, "left-side wall chooses forward-aligned tangent")

	# Exercise actual right ray acquisition with the authored wall.
	player.global_position = Vector3(6.15, 2.5, 7.25)
	player.velocity = Vector3(0, 0, -7.0)
	Input.action_press("sprint")
	Input.action_press("move_forward")
	await settle_physics(3)
	check(vector_run.is_wall_running(), "airborne forward sprint enters VECTOR RUN near marked wall")
	check(vector_run.wall_side == 1, "authored wall is detected on the player's right")
	vector_run.stop_wall_run(&"test")

	# Wall jump pushes away/up while retaining travel tangent.
	player.velocity = Vector3(0, 0, -8.0)
	check(vector_run.begin_wall_run(wall, Vector3.LEFT, 1), "marked wall accepts explicit wall-run state")
	vector_run._wall_jump_queued = true
	vector_run._before_player_move(1.0 / 60.0)
	check(not vector_run.is_wall_running(), "wall-jump exits VECTOR RUN")
	check(player.velocity.x < -4.0 and player.velocity.y >= vector_run.wall_jump_upward_speed, "wall-jump applies away and upward impulses")
	check(player.velocity.z < -4.0, "wall-jump preserves forward momentum")
	check(vector_run._reattach_remaining > 0.0, "wall-jump starts reattachment lockout")

	# Timeout remains bounded.
	vector_run._reattach_remaining = 0.0
	player.velocity = Vector3(0, 0, -8.0)
	check(vector_run.begin_wall_run(wall, Vector3.LEFT, 1), "wall run can restart after lockout expires")
	vector_run.elapsed = vector_run.maximum_duration
	vector_run._before_player_move(1.0 / 60.0)
	check(not vector_run.is_wall_running(), "wall run ends at configured duration")

	# State priority: grapple stops a wall run; an active grapple rejects wall run;
	# releasing it preserves velocity and allows the next wall-run state.
	player.global_position = Vector3(6.15, 2.5, 7.25)
	player.velocity = Vector3(0, 0, -8.0)
	check(vector_run.begin_wall_run(wall, Vector3.LEFT, 1), "wall run starts before grapple transition")
	check(grapple.try_attach_target(anchor), "grapple can attach during wall run")
	check(not vector_run.is_wall_running() and grapple.is_grappling(), "grapple has priority and ends wall run")
	check(not vector_run.begin_wall_run(wall, Vector3.LEFT, 1), "active grapple blocks competing wall-run state")
	var momentum_before_release := player.velocity
	grapple.cancel_grapple(&"test_release")
	check(
		player.velocity.distance_to(momentum_before_release * grapple.release_momentum_multiplier) < 0.01,
		"grapple release preserves momentum with the configured bounded release boost"
	)
	check(vector_run.begin_wall_run(wall, Vector3.LEFT, 1), "wall run can begin after grapple release")
	vector_run.stop_wall_run(&"test")

	# Death cleanup cannot leave a movement override or cable behind.
	check(grapple.try_attach_target(anchor), "grapple reattaches for cleanup check")
	health.reset_health()
	health.take_damage(health.maximum_health)
	await settle(2)
	check(not grapple.is_grappling() and not grapple.tether_beam.visible, "death clears grapple and tether visual")
	check(not player.has_movement_override(), "death clears movement ownership")

	Input.action_release("sprint")
	Input.action_release("move_forward")
	ordinary.queue_free()
	flow.queue_free()
	await settle(3)
	print("MOMENTUM VECTOR CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
