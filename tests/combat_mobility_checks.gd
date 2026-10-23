extends SceneTree

## Headless contracts for the BREACH LAB vertical slice. Physical aim, camera
## feel, animation readability, and audio perception still require a human.

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


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _run() -> void:
	check(InputMap.has_action("grapple"), "grapple input action is registered")
	check(InputMap.has_action("sword_attack"), "sword input action is registered")
	check(InputMap.has_action("interact"), "future interaction input action is reserved")

	var preview_scene := load("res://levels/experiments/breach_lab/breach_lab.tscn") as PackedScene
	var flow := preview_scene.instantiate() as GameFlowManager
	flow.level_transition_delay = 0.0
	root.add_child(flow)
	await settle(12)

	var level := flow.current_level as BreachLabLevel
	var player := flow.player
	var grapple := player.find_child("GrappleController", true, false) as GrappleController
	var sword := player.find_child("SwordController", true, false) as SwordController
	var health := player.find_child("PlayerHealth", true, false) as PlayerHealth
	var vector_run := player.find_child("VectorRunController", true, false) as VectorRunController
	check(level != null, "BREACH LAB loads through GameFlowManager")
	check(player != null and player.is_in_group("action_player"), "preview spawns action-player variant")
	check(grapple != null and sword != null and health != null and vector_run != null, "player owns grapple, vector run, blade, and health components")
	check(not level.is_exit_unlocked(), "finish starts locked")

	var invalid_target := Node3D.new()
	root.add_child(invalid_target)
	check(not grapple.try_attach_target(invalid_target), "non-grapple object is rejected")
	var distant_anchor_scene := load("res://interactive/grapple_anchor.tscn") as PackedScene
	var distant_anchor := distant_anchor_scene.instantiate() as GrappleAnchor
	distant_anchor.position = Vector3(100, 0, 0)
	root.add_child(distant_anchor)
	await settle(2)
	check(not grapple.try_attach_target(distant_anchor), "valid anchor beyond maximum range is rejected")

	var primary_anchor := level.get_node("PrimaryGrappleAnchor") as GrappleAnchor
	var start_distance := player.global_position.distance_to(primary_anchor.get_grapple_point())
	var start_position := player.global_position
	check(grapple.try_attach_target(primary_anchor), "valid in-range anchor attaches")
	check(not grapple.try_attach_target(primary_anchor), "repeated attachment while active is rejected")
	check(grapple.tether_beam.visible, "attached grapple displays tether beam")
	check(is_equal_approx(grapple.get_rope_length(), start_distance), "attachment initializes rope length from player distance")
	check(player.global_position.is_equal_approx(start_position), "attachment never teleports or snaps player")
	var radial_out := primary_anchor.get_grapple_point().direction_to(player.global_position)
	var tangent := Vector3.UP.cross(radial_out).normalized()
	player.velocity = radial_out * 5.0 + tangent * 7.0
	grapple._apply_tether_velocity(1.0 / 60.0)
	check(player.velocity.dot(radial_out) <= 0.05, "taut rope removes outward radial velocity")
	check(player.velocity.dot(tangent) > 5.5, "taut rope preserves tangential momentum")
	var release_velocity := player.velocity
	grapple.cancel_grapple(&"test_cancel")
	check(not grapple.is_grappling() and not grapple.tether_beam.visible, "cancel clears attachment and tether")
	check(
		player.velocity.distance_to(release_velocity * grapple.release_momentum_multiplier) < 0.01,
		"release preserves current momentum with the configured bounded boost"
	)

	# The controller contributes velocity before the player's sole move_and_slide call.
	# A temporary wall verifies the body cannot be pulled through collision.
	player.global_position = Vector3(0, 0.05, 16)
	player.velocity = Vector3.ZERO
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 2, 12)
	var wall_shape_node := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(8, 4, 0.6)
	wall_shape_node.shape = wall_shape
	wall.add_child(wall_shape_node)
	root.add_child(wall)
	await settle_physics(2)
	check(grapple.try_attach_target(primary_anchor), "anchor can reattach after cancellation")
	player.velocity = Vector3(0, 0, -12)
	await settle_physics(25)
	check(player.global_position.z > 11.55, "grapple respects blocking collision")
	player.velocity = Vector3(0, 0, -grapple.extreme_speed_limit * 2.0)
	grapple._after_player_move(1.0 / 60.0)
	check(not grapple.is_grappling(), "extreme velocity triggers a safe tether release")
	wall.queue_free()
	await settle_physics(3)

	# Security attacks expose a readable windup and use the player's health API.
	var enemy := level.security_construct
	enemy.set_physics_process(false)
	enemy.player = player
	player.global_position = enemy.global_position + Vector3(0, 0, 1)
	health.reset_health()
	var telegraph_count := [0]
	enemy.attack_telegraphed.connect(func() -> void: telegraph_count[0] += 1)
	enemy._set_state(SecurityConstruct.STATE_WINDUP)
	check(telegraph_count[0] == 1, "construct emits attack telegraph before damage")
	enemy._resolve_attack(1.0)
	check(health.current_health == 2, "construct attack damages player by one segment")
	health.reset_health()

	# Pull handle changes real collision geometry and is one-shot.
	player.global_position = Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	grapple.cancel_grapple(&"test_setup")
	check(grapple.try_attach_target(level.pull_handle), "grapple accepts pull-handle target")
	check(level.pull_handle.is_pulled, "handle latches after tether attachment")
	await wait_seconds(level.bridge.deployment_duration + 0.12)
	check(level.bridge.is_deployed, "pull handle deploys bridge mechanism")
	check(level.bridge.position.is_equal_approx(Vector3(0, 0, -9.5)), "bridge reaches authored deployed position")
	grapple.cancel_grapple(&"test_setup")
	check(not grapple.try_attach_target(level.pull_handle), "one-shot handle rejects duplicate activation")

	# Scene reload resets machinery, enemy, and player health.
	enemy.take_damage(1, player)
	flow.restart_current_level()
	await settle(12)
	level = flow.current_level as BreachLabLevel
	player = flow.player
	grapple = player.find_child("GrappleController", true, false) as GrappleController
	sword = player.find_child("SwordController", true, false) as SwordController
	health = player.find_child("PlayerHealth", true, false) as PlayerHealth
	enemy = level.security_construct
	enemy.set_physics_process(false)
	check(not level.bridge.is_deployed and not level.pull_handle.is_pulled, "restart resets tether machinery")
	check(enemy.current_health == 3 and not enemy.is_deactivated(), "restart resets construct health/state")
	check(health.current_health == 3, "restart restores player integrity")

	# Solve the mechanism, then use actual shape-query sword attacks.
	player.global_position = Vector3(0, 0.05, 0)
	level.pull_handle.on_grapple_attached(grapple)
	await wait_seconds(level.bridge.deployment_duration + 0.12)
	check(not level.is_exit_unlocked(), "bridge alone cannot unlock finish")
	enemy.global_position = Vector3(0, 0.05, -1.55)
	player.global_position = Vector3(0, 0.05, 0)
	player.rotation = Vector3.ZERO
	player.get_node("Head").rotation = Vector3.ZERO
	await settle_physics(3)
	check(sword.try_attack(), "blade accepts first attack")
	check(not sword.try_attack(), "blade cooldown prevents attack spam")
	await wait_seconds(0.16)
	check(enemy.current_health == 2, "one slash applies exactly one damage")
	await wait_seconds(sword.attack_cooldown + 0.08)
	check(sword.try_attack(), "blade becomes ready after cooldown")
	await wait_seconds(0.16)
	check(enemy.current_health == 1, "second slash applies one damage")
	await wait_seconds(sword.attack_cooldown + 0.08)
	check(sword.try_attack(), "third attack begins normally")
	await wait_seconds(0.2)
	check(enemy.is_deactivated(), "construct deactivates after approximately three hits")
	check(level.is_puzzle_complete() and level.is_exit_unlocked(), "bridge plus enemy objective unlocks finish")

	level.puzzle_exit._on_exit_trigger_body_entered(player)
	await settle(5)
	check(flow.flow_state == GameFlowManager.STATE_VICTORY, "finish marker completes isolated mechanics run")

	invalid_target.queue_free()
	distant_anchor.queue_free()
	flow.queue_free()
	await settle(3)
	print("COMBAT MOBILITY CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
