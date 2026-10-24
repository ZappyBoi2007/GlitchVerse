extends CharacterBody3D

## Reusable first-person controller for GlitchVerse.
## The body handles yaw while the Head node handles vertical camera pitch.

## Optional action components can adjust velocity immediately before the
## controller's single collision-safe move_and_slide() call.
signal pre_move(delta: float)
signal post_move(delta: float)

@export_category("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var ground_acceleration: float = 24.0
@export var air_acceleration: float = 12.0
@export_range(0.1, 1.0, 0.05) var air_speed_multiplier: float = 0.9
@export_range(0.0, 1.0, 0.05) var air_braking_multiplier: float = 0.35

@export_category("Jump")
@export var jump_velocity: float = 5.2
@export_range(0.5, 3.0, 0.05) var rising_gravity_multiplier: float = 1.05
@export_range(1.0, 4.0, 0.05) var falling_gravity_multiplier: float = 1.65
@export_range(1.0, 4.0, 0.05) var released_jump_gravity_multiplier: float = 2.0
@export_range(8.0, 40.0, 0.5) var maximum_fall_speed: float = 24.0
@export_range(0.0, 0.25, 0.01) var coyote_time: float = 0.1
@export_range(0.0, 0.25, 0.01) var jump_buffer_time: float = 0.1

@export_category("Camera")
@export_range(0.0005, 0.01, 0.0001) var mouse_sensitivity: float = 0.0022
@export_range(45.0, 89.0, 1.0) var vertical_look_limit: float = 85.0
@export_range(50.0, 100.0, 1.0) var base_fov: float = 78.0
@export_range(50.0, 110.0, 1.0) var sprint_fov: float = 88.0
@export_range(1.0, 24.0, 0.5) var fov_change_speed: float = 9.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var _gravity: float = 9.8
var _coyote_time_remaining := 0.0
var _jump_buffer_remaining := 0.0
var _movement_override_sources: Dictionary = {}


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	camera.fov = base_fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var sprinting := (
		Input.is_action_pressed("sprint")
		and horizontal_speed > walk_speed * 0.65
	)
	var speed_blend := clampf(
		(horizontal_speed - walk_speed * 0.65) / maxf(sprint_speed - walk_speed * 0.65, 0.01),
		0.0,
		1.0
	) if sprinting else 0.0
	var target_fov := lerpf(base_fov, sprint_fov, speed_blend)
	var blend_weight := 1.0 - exp(-fov_change_speed * delta)
	camera.fov = lerpf(camera.fov, target_fov, blend_weight)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion := event as InputEventMouseMotion
		rotate_y(-mouse_motion.screen_relative.x * mouse_sensitivity)
		head.rotate_x(-mouse_motion.screen_relative.y * mouse_sensitivity)
		head.rotation.x = clampf(
			head.rotation.x,
			deg_to_rad(-vertical_look_limit),
			deg_to_rad(vertical_look_limit)
		)
	elif event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	# Keep recapture unhandled so future interactive UI buttons receive clicks first.
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var grounded := is_on_floor()
	if grounded:
		_coyote_time_remaining = coyote_time
	else:
		_coyote_time_remaining = maxf(0.0, _coyote_time_remaining - delta)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_remaining = jump_buffer_time
	else:
		_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)

	if _jump_buffer_remaining > 0.0 and _coyote_time_remaining > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_remaining = 0.0
		_coyote_time_remaining = 0.0
		grounded = false

	if not grounded:
		var gravity_multiplier := falling_gravity_multiplier
		if velocity.y > 0.0:
			gravity_multiplier = (
				rising_gravity_multiplier
				if Input.is_action_pressed("jump")
				else released_jump_gravity_multiplier
			)
		velocity.y = maxf(
			velocity.y - _gravity * gravity_multiplier * delta,
			-maximum_fall_speed
		)

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	if not grounded:
		target_speed *= air_speed_multiplier
	var target_velocity := direction * target_speed
	var acceleration := ground_acceleration if grounded else air_acceleration
	if not grounded and input_vector.is_zero_approx():
		acceleration *= air_braking_multiplier

	if _movement_override_sources.is_empty():
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	pre_move.emit(delta)
	move_and_slide()
	post_move.emit(delta)


## Action movement components register while they own airborne horizontal
## velocity. Gravity, jumping, collision and the single move_and_slide() call
## remain authoritative here.
func set_movement_override(source: Object, enabled: bool) -> void:
	if source == null:
		return
	var source_id := source.get_instance_id()
	if enabled:
		_movement_override_sources[source_id] = true
	else:
		_movement_override_sources.erase(source_id)


func has_movement_override() -> bool:
	return not _movement_override_sources.is_empty()
