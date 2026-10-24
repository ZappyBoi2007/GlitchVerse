extends SceneTree

## Real-geometry crossing checks. Subjective comfort still requires a human,
## but these runs use the production player, collision, anchor and fall volume.

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


func _run() -> void:
	var preview := load("res://levels/access_denied/access_denied_system_breach_preview.tscn") as PackedScene
	var flow := preview.instantiate() as GameFlowManager
	root.add_child(flow)
	await settle(14)
	var level := flow.current_level as AccessDeniedSystemBreachLevel
	var player := flow.player
	var grapple := player.find_child("GrappleController", true, false) as GrappleController
	var launch := level.markers.get_node("TetherLaunch_01") as Marker3D
	var anchor := level.get_node("GrappleAnchor_01_Runtime") as GrappleAnchor
	var fall_top := (level.markers.get_node("FallZoneMarker") as Marker3D).global_position.y + 0.5

	for release_frame in [78, 90, 102]:
		if grapple.is_grappling():
			grapple.cancel_grapple(&"test_reset")
		player.global_transform = launch.global_transform
		player.velocity = Vector3.LEFT * 5.0
		Input.action_press("move_forward")
		var attached := grapple.try_attach_target(anchor)
		var minimum_y := player.global_position.y
		for frame in range(release_frame + 56):
			await physics_frame
			minimum_y = minf(minimum_y, player.global_position.y)
			if frame == release_frame:
				grapple.cancel_grapple(&"test_release")
		Input.action_release("move_forward")
		var on_destination := (
			player.global_position.x <= -32.0
			and player.global_position.x >= -42.0
			and player.global_position.z >= 20.0
			and player.global_position.z <= 32.0
			and player.is_on_floor()
		)
		check(attached, "release %d: first anchor attaches" % release_frame)
		check(minimum_y > fall_top, "release %d: attached arc stays above the kill volume" % release_frame)
		check(on_destination, "release %d: forward release lands on the destination ledge" % release_frame)
		check(flow.flow_state == GameFlowManager.STATE_PLAYING, "release %d: crossing does not produce unexplained failure" % release_frame)

	flow.queue_free()
	await settle(3)
	print("ACCESS DENIED TETHER CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
