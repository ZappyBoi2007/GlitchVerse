extends CharacterBody3D

## Reusable first-person controller for GlitchVerse.
## The body handles yaw while the Head node handles vertical camera pitch.

@export_category("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var ground_acceleration: float = 24.0
@export var air_acceleration: float = 7.0
@export var jump_velocity: float = 5.2

@export_category("Camera")
@export_range(0.0005, 0.01, 0.0001) var mouse_sensitivity: float = 0.0022
@export_range(45.0, 89.0, 1.0) var vertical_look_limit: float = 85.0

@onready var head: Node3D = $Head

var _gravity: float = 9.8


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := direction * target_speed
	var acceleration := ground_acceleration if is_on_floor() else air_acceleration

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	move_and_slide()
