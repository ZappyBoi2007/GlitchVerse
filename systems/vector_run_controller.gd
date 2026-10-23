class_name VectorRunController
extends Node3D

## Passive, collision-aware wall run. Only colliders in vector_run_surface (or
## with an ancestor in that group) are valid.

signal wall_run_started(surface: Node, side: int)
signal wall_run_ended(reason: StringName)
signal wall_jumped

@export_category("Entry")
@export_range(1.0, 15.0, 0.25) var minimum_horizontal_speed := 5.5
@export_range(0.25, 2.0, 0.05) var wall_check_distance := 0.9
@export_range(0.0, 1.0, 0.05) var forward_input_threshold := 0.2

@export_category("Run")
@export_range(0.2, 3.0, 0.05) var maximum_duration := 1.35
@export_range(1.0, 20.0, 0.25) var wall_run_speed := 8.5
@export_range(0.0, 1.0, 0.05) var gravity_scale := 0.25
@export_range(0.0, 5.0, 0.1) var maximum_fall_speed := 1.5
@export_range(0.0, 8.0, 0.1) var wall_stick_speed := 1.4
@export_range(0.0, 15.0, 0.25) var tangent_acceleration := 7.0

@export_category("Wall Jump")
@export_range(1.0, 12.0, 0.25) var wall_jump_upward_speed := 5.5
@export_range(1.0, 12.0, 0.25) var wall_jump_away_speed := 5.0
@export_range(0.0, 1.0, 0.05) var forward_momentum_retention := 0.75
@export_range(0.1, 1.0, 0.05) var reattach_lockout := 0.4

@export_category("Feedback")
@export_range(0.0, 12.0, 0.25) var camera_roll_degrees := 5.0
@export_range(1.0, 20.0, 0.5) var camera_roll_speed := 10.0

@onready var left_ray: RayCast3D = $LeftWallRay
@onready var right_ray: RayCast3D = $RightWallRay

var player: CharacterBody3D
var camera: Camera3D
var grapple: GrappleController
var active_surface: Node3D
var wall_normal := Vector3.ZERO
var wall_side := 0
var elapsed := 0.0

var _gravity := 9.8
var _reattach_remaining := 0.0
var _wall_jump_queued := false


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	camera = player.get_node_or_null("Head/Camera3D") as Camera3D
	grapple = player.find_child("GrappleController", true, false) as GrappleController
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	left_ray.target_position = Vector3(-wall_check_distance, 0.0, 0.0)
	right_ray.target_position = Vector3(wall_check_distance, 0.0, 0.0)
	left_ray.add_exception(player)
	right_ray.add_exception(player)
	player.pre_move.connect(_before_player_move)
	player.post_move.connect(_after_player_move)
	if grapple != null:
		grapple.grapple_attached.connect(_on_grapple_attached)
	var health := player.find_child("PlayerHealth", true, false) as PlayerHealth
	if health != null:
		health.player_defeated.connect(_on_player_defeated)


func _exit_tree() -> void:
	stop_wall_run(&"scene_exit", false)


func _unhandled_input(event: InputEvent) -> void:
	if active_surface != null and event.is_action_pressed("jump"):
		_wall_jump_queued = true
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if camera == null:
		return
	var target_roll := 0.0
	if active_surface != null:
		target_roll = deg_to_rad(camera_roll_degrees * -wall_side)
	camera.rotation.z = move_toward(camera.rotation.z, target_roll, camera_roll_speed * delta)


func _before_player_move(delta: float) -> void:
	_reattach_remaining = maxf(0.0, _reattach_remaining - delta)
	if grapple != null and grapple.is_grappling():
		stop_wall_run(&"grapple_attached")
		return
	if active_surface == null:
		_try_start_from_rays()
		if active_surface == null:
			return
	if _wall_jump_queued:
		_perform_wall_jump()
		return
	if not _can_continue():
		stop_wall_run(&"conditions_lost")
		return
	elapsed += delta
	if elapsed >= maximum_duration:
		stop_wall_run(&"timeout")
		return
	_apply_wall_run_velocity(delta)


func _after_player_move(_delta: float) -> void:
	if active_surface == null:
		return
	var ray := left_ray if wall_side < 0 else right_ray
	ray.force_raycast_update()
	if not ray.is_colliding() or _find_vector_surface(ray.get_collider()) != active_surface:
		stop_wall_run(&"wall_lost")


func _try_start_from_rays() -> bool:
	if not _entry_conditions_met():
		return false
	left_ray.force_raycast_update()
	right_ray.force_raycast_update()
	if _try_ray(left_ray, -1):
		return true
	return _try_ray(right_ray, 1)


func _try_ray(ray: RayCast3D, side: int) -> bool:
	if not ray.is_colliding():
		return false
	var surface := _find_vector_surface(ray.get_collider())
	if surface == null:
		return false
	return begin_wall_run(surface, ray.get_collision_normal(), side)


func begin_wall_run(surface: Node, normal: Vector3, side: int) -> bool:
	if active_surface != null or not is_vector_surface(surface) or side == 0:
		return false
	if grapple != null and grapple.is_grappling():
		return false
	if normal.length_squared() < 0.5:
		return false
	active_surface = surface as Node3D
	wall_normal = normal.normalized()
	wall_side = -1 if side < 0 else 1
	elapsed = 0.0
	_wall_jump_queued = false
	player.set_movement_override(self, true)
	wall_run_started.emit(active_surface, wall_side)
	_play_audio(&"vector_run_start", -8.0)
	return true


func stop_wall_run(reason: StringName = &"stopped", emit_feedback := true) -> void:
	if player != null:
		player.set_movement_override(self, false)
	if active_surface == null:
		return
	active_surface = null
	wall_normal = Vector3.ZERO
	wall_side = 0
	elapsed = 0.0
	_wall_jump_queued = false
	if emit_feedback:
		wall_run_ended.emit(reason)


func is_wall_running() -> bool:
	return active_surface != null


func is_vector_surface(candidate: Node) -> bool:
	if candidate == null or not candidate.is_in_group("vector_run_surface"):
		return false
	return not candidate.has_method("can_vector_run") or bool(candidate.call("can_vector_run"))


func get_run_tangent(normal: Vector3, preferred_direction: Vector3) -> Vector3:
	var tangent := Vector3.UP.cross(normal).normalized()
	if tangent.dot(preferred_direction) < 0.0:
		tangent = -tangent
	return tangent


func _entry_conditions_met() -> bool:
	if _reattach_remaining > 0.0 or player.is_on_floor():
		return false
	if not Input.is_action_pressed("sprint") or Input.get_action_strength("move_forward") < forward_input_threshold:
		return false
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	return horizontal.length() >= minimum_horizontal_speed


func _can_continue() -> bool:
	if player.is_on_floor() or not Input.is_action_pressed("sprint"):
		return false
	if Input.get_action_strength("move_forward") < forward_input_threshold:
		return false
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	return horizontal.length() >= minimum_horizontal_speed * 0.65


func _apply_wall_run_velocity(delta: float) -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var preferred := horizontal if horizontal.length_squared() > 0.01 else -player.global_basis.z
	var tangent := get_run_tangent(wall_normal, preferred)
	var target_horizontal := tangent * maxf(wall_run_speed, horizontal.length())
	horizontal = horizontal.move_toward(target_horizontal, tangent_acceleration * delta)
	player.velocity.x = horizontal.x - wall_normal.x * wall_stick_speed
	player.velocity.z = horizontal.z - wall_normal.z * wall_stick_speed
	if player.velocity.y < 0.0:
		player.velocity.y += _gravity * (1.0 - gravity_scale) * delta
		player.velocity.y = maxf(player.velocity.y, -maximum_fall_speed)


func _perform_wall_jump() -> void:
	var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var tangent := get_run_tangent(wall_normal, horizontal)
	player.velocity = (
		tangent * horizontal.length() * forward_momentum_retention
		+ wall_normal * wall_jump_away_speed
		+ Vector3.UP * wall_jump_upward_speed
	)
	_reattach_remaining = reattach_lockout
	stop_wall_run(&"wall_jump")
	wall_jumped.emit()
	_play_audio(&"vector_wall_jump", -6.0)


func _find_vector_surface(collider: Object) -> Node:
	var candidate := collider as Node
	while candidate != null:
		if is_vector_surface(candidate):
			return candidate
		candidate = candidate.get_parent()
	return null


func _on_grapple_attached(_target: Node) -> void:
	stop_wall_run(&"grapple_attached")


func _on_player_defeated() -> void:
	stop_wall_run(&"player_defeated")


func _play_audio(event_name: StringName, volume_db: float) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(event_name, volume_db)
