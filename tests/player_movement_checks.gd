extends SceneTree

## Focused physics check for the reusable FPS controller's jump tuning.

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		print("FAIL: ", description)


func physics_steps(count: int) -> void:
	for _frame in range(count):
		await physics_frame
	await process_frame


func _run() -> void:
	var floor := StaticBody3D.new()
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(20, 1, 20)
	floor_collision.shape = floor_shape
	floor.position.y = -0.5
	floor.add_child(floor_collision)
	root.add_child(floor)

	var player := load("res://player/player.tscn").instantiate() as CharacterBody3D
	player.position = Vector3(0, 0.05, 0)
	root.add_child(player)
	await physics_steps(8)
	check(player.is_on_floor(), "player settles reliably on floor")

	Input.action_press("jump")
	await physics_steps(1)
	var first_rise_velocity := player.velocity.y
	check(first_rise_velocity > 0.0, "jump produces upward velocity")
	await physics_steps(1)
	var held_rise_drop := first_rise_velocity - player.velocity.y

	Input.action_press("move_right")
	Input.action_release("jump")
	var before_release_velocity := player.velocity.y
	await physics_steps(1)
	var released_rise_drop := before_release_velocity - player.velocity.y
	check(released_rise_drop > held_rise_drop * 1.5, "released jump shortens ascent")
	await physics_steps(5)
	check(player.velocity.x > 0.5, "air input provides useful steering")
	Input.action_release("move_right")

	var started_falling := false
	for _frame in range(60):
		await physics_frame
		if player.velocity.y < -0.1:
			started_falling = true
			break
	check(started_falling, "jump transitions into falling")
	await physics_steps(120)
	check(player.is_on_floor(), "player lands and regains grounded state")

	player.queue_free()
	floor.queue_free()
	await process_frame
	print("PLAYER MOVEMENT CHECKS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
