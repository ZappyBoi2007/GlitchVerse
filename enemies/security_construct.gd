class_name SecurityConstruct
extends CharacterBody3D

signal health_changed(current_health: int, maximum_health: int)
signal attack_telegraphed
signal deactivated

const STATE_IDLE: StringName = &"idle"
const STATE_CHASE: StringName = &"chase"
const STATE_WINDUP: StringName = &"windup"
const STATE_COOLDOWN: StringName = &"cooldown"
const STATE_DEAD: StringName = &"dead"

@export_category("Combat")
@export_range(1, 1000, 1) var maximum_health := 100
@export_range(2.0, 30.0, 0.5) var detection_range := 18.0
@export_range(0.5, 4.0, 0.1) var attack_range := 1.7
@export_range(0.2, 2.0, 0.05) var attack_windup := 0.55
@export_range(0.2, 4.0, 0.05) var attack_cooldown := 1.8
@export_range(1, 1000, 1) var attack_damage := 20

@export_category("Agile Movement")
@export_range(0.1, 12.0, 0.1) var movement_speed := 6.0
@export_range(1.0, 60.0, 1.0) var ground_acceleration := 24.0
@export_range(1.0, 60.0, 1.0) var braking_acceleration := 32.0
@export_range(0.0, 1.0, 0.05) var strafe_weight := 0.48
@export_range(0.2, 4.0, 0.1) var minimum_strafe_interval := 0.7
@export_range(0.2, 5.0, 0.1) var maximum_strafe_interval := 1.5
@export_range(1.0, 16.0, 0.25) var dash_speed := 9.5
@export_range(0.05, 1.0, 0.05) var dash_duration := 0.28
@export_range(0.2, 8.0, 0.1) var minimum_dash_interval := 1.8
@export_range(0.2, 10.0, 0.1) var maximum_dash_interval := 3.2
@export_range(1.0, 12.0, 0.1) var jump_velocity := 5.0
@export_range(0.0, 1.0, 0.05) var pursuit_prediction_seconds := 0.3

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var obstacle_probe: RayCast3D = $ObstacleProbe
@onready var body_visual: Node3D = $BodyVisual
@onready var telegraph_light: OmniLight3D = $BodyVisual/Head/TelegraphLight
@onready var state_label: Label3D = $StateLabel
@onready var guard_head: Node3D = $BodyVisual/Head
@onready var left_arm: MeshInstance3D = $BodyVisual/LeftArm
@onready var right_arm: MeshInstance3D = $BodyVisual/RightArm
@onready var left_forearm: MeshInstance3D = $BodyVisual/LeftForearm
@onready var right_forearm: MeshInstance3D = $BodyVisual/RightForearm
@onready var left_hand: MeshInstance3D = $BodyVisual/LeftHand
@onready var right_hand: MeshInstance3D = $BodyVisual/RightHand
@onready var left_leg: MeshInstance3D = $BodyVisual/LeftLeg
@onready var right_leg: MeshInstance3D = $BodyVisual/RightLeg

var current_health := 100
var state: StringName = STATE_IDLE
var player: CharacterBody3D
var _state_time := 0.0
var _gravity := 9.8
var _alert_played := false
var _strafe_direction := 1.0
var _strafe_time_remaining := 0.0
var _dash_cooldown_remaining := 0.0
var _dash_time_remaining := 0.0
var _visual_time := 0.0
var _hit_reaction_remaining := 0.0
var _attack_pose_remaining := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	current_health = maximum_health
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_rng.randomize()
	_choose_new_strafe()
	_dash_cooldown_remaining = _random_dash_interval()
	add_to_group("security_construct")
	_update_visual_state()
	call_deferred("_acquire_player")


func _process(delta: float) -> void:
	_visual_time += delta
	_hit_reaction_remaining = maxf(0.0, _hit_reaction_remaining - delta)
	_attack_pose_remaining = maxf(0.0, _attack_pose_remaining - delta)
	if state == STATE_DEAD:
		return
	var speed_ratio := clampf(Vector2(velocity.x, velocity.z).length() / maxf(movement_speed, 0.1), 0.0, 1.4)
	var stride := sin(_visual_time * 10.0) * 0.48 * speed_ratio
	var left_arm_target := stride
	var right_arm_target := -stride
	var left_leg_target := -stride * 0.72
	var right_leg_target := stride * 0.72
	var torso_twist := sin(_visual_time * 10.0) * 0.06 * speed_ratio
	if state == STATE_WINDUP:
		left_arm_target = -0.35
		right_arm_target = 1.15
		torso_twist = -0.2
	elif _attack_pose_remaining > 0.0:
		left_arm_target = 0.25
		right_arm_target = -1.05
		torso_twist = 0.24
	elif state == STATE_COOLDOWN:
		left_arm_target = -0.15
		right_arm_target = -0.35
	var blend := clampf(delta * 13.0, 0.0, 1.0)
	left_arm.rotation.x = lerp_angle(left_arm.rotation.x, left_arm_target, blend)
	right_arm.rotation.x = lerp_angle(right_arm.rotation.x, right_arm_target, blend)
	left_forearm.rotation.x = lerp_angle(left_forearm.rotation.x, left_arm_target * 0.85, blend)
	right_forearm.rotation.x = lerp_angle(right_forearm.rotation.x, right_arm_target * 0.85, blend)
	left_hand.rotation.x = lerp_angle(left_hand.rotation.x, left_arm_target * 0.75, blend)
	right_hand.rotation.x = lerp_angle(right_hand.rotation.x, right_arm_target * 0.75, blend)
	left_leg.rotation.x = lerp_angle(left_leg.rotation.x, left_leg_target, blend)
	right_leg.rotation.x = lerp_angle(right_leg.rotation.x, right_leg_target, blend)
	guard_head.rotation.y = lerp_angle(
		guard_head.rotation.y,
		sin(_visual_time * 1.6) * 0.1 if state == STATE_IDLE else 0.0,
		blend
	)
	body_visual.position.y = absf(sin(_visual_time * 10.0)) * 0.035 * speed_ratio
	body_visual.rotation.y = lerp_angle(body_visual.rotation.y, torso_twist, blend)
	var hit_tilt := -0.16 if _hit_reaction_remaining > 0.0 else 0.0
	body_visual.rotation.z = lerp_angle(body_visual.rotation.z, hit_tilt, blend)


func _physics_process(delta: float) -> void:
	if state == STATE_DEAD:
		return
	if not is_instance_valid(player):
		_acquire_player()
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	if player == null or not player.is_physics_processing():
		_steer_horizontal(Vector3.ZERO, braking_acceleration, delta)
		move_and_slide()
		return

	var offset := player.global_position - global_position
	var planar := Vector3(offset.x, 0.0, offset.z)
	var distance := planar.length()
	match state:
		STATE_IDLE:
			_steer_horizontal(Vector3.ZERO, braking_acceleration, delta)
			if distance <= detection_range:
				_set_state(STATE_CHASE)
		STATE_CHASE:
			if distance > detection_range * 1.4:
				_set_state(STATE_IDLE)
			elif distance <= attack_range:
				_set_state(STATE_WINDUP)
			else:
				_chase_player(planar, distance, delta)
		STATE_WINDUP:
			_steer_horizontal(Vector3.ZERO, braking_acceleration, delta)
			_face_player(planar)
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_attack(distance)
				_set_state(STATE_COOLDOWN)
		STATE_COOLDOWN:
			var orbit_direction := _orbit_direction(planar)
			_steer_horizontal(orbit_direction * movement_speed * 0.38, ground_acceleration, delta)
			_face_player(planar)
			_state_time -= delta
			if _state_time <= 0.0:
				_set_state(STATE_CHASE)
	move_and_slide()


func _chase_player(planar: Vector3, distance: float, delta: float) -> void:
	_strafe_time_remaining -= delta
	_dash_cooldown_remaining -= delta
	_dash_time_remaining = maxf(0.0, _dash_time_remaining - delta)
	if _strafe_time_remaining <= 0.0:
		_choose_new_strafe()
	if _dash_cooldown_remaining <= 0.0 and distance > attack_range * 1.6:
		_dash_time_remaining = dash_duration
		_dash_cooldown_remaining = _random_dash_interval()
		_strafe_direction = -1.0 if _rng.randf() < 0.5 else 1.0

	var predicted_offset := planar
	if is_instance_valid(player):
		predicted_offset += Vector3(player.velocity.x, 0.0, player.velocity.z) * pursuit_prediction_seconds
	var forward := predicted_offset.normalized() if not predicted_offset.is_zero_approx() else Vector3.ZERO
	var side := Vector3(-forward.z, 0.0, forward.x)
	var desired_direction := (forward + side * _strafe_direction * strafe_weight).normalized()
	var target_speed := dash_speed if _dash_time_remaining > 0.0 else movement_speed
	_steer_horizontal(desired_direction * target_speed, ground_acceleration, delta)
	_face_player(planar)

	var needs_jump := obstacle_probe.is_colliding() and distance > attack_range * 1.45
	var player_above := player.global_position.y - global_position.y > 1.15 and distance < 5.5
	if is_on_floor() and (needs_jump or player_above):
		velocity.y = jump_velocity


func _orbit_direction(planar: Vector3) -> Vector3:
	if planar.is_zero_approx():
		return Vector3.ZERO
	var forward := planar.normalized()
	return Vector3(-forward.z, 0.0, forward.x) * _strafe_direction


func _face_player(planar: Vector3) -> void:
	if planar.length_squared() <= 0.0025:
		return
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)


func _steer_horizontal(target_velocity: Vector3, acceleration: float, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(Vector3(target_velocity.x, 0.0, target_velocity.z), acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _choose_new_strafe() -> void:
	_strafe_direction = -1.0 if _rng.randf() < 0.5 else 1.0
	_strafe_time_remaining = _rng.randf_range(
		minf(minimum_strafe_interval, maximum_strafe_interval),
		maxf(minimum_strafe_interval, maximum_strafe_interval)
	)


func _random_dash_interval() -> float:
	return _rng.randf_range(
		minf(minimum_dash_interval, maximum_dash_interval),
		maxf(minimum_dash_interval, maximum_dash_interval)
	)


func take_damage(amount: int, _source: Node = null) -> bool:
	if amount <= 0 or state == STATE_DEAD:
		return false
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, maximum_health)
	_update_state_label()
	_play_audio(&"construct_hurt", -4.0)
	_flash_hit()
	if current_health == 0:
		_deactivate()
	return true


func is_deactivated() -> bool:
	return state == STATE_DEAD


func _acquire_player() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D


func _set_state(next_state: StringName) -> void:
	if state == next_state or state == STATE_DEAD:
		return
	state = next_state
	match state:
		STATE_CHASE:
			if not _alert_played:
				_alert_played = true
				_play_audio(&"construct_alert", -5.0)
		STATE_WINDUP:
			_state_time = attack_windup
			attack_telegraphed.emit()
		STATE_COOLDOWN:
			_state_time = attack_cooldown
	_update_visual_state()


func _resolve_attack(distance: float) -> void:
	_attack_pose_remaining = 0.18
	_play_audio(&"construct_attack", -3.0)
	if distance > attack_range * 1.18 or not is_instance_valid(player):
		return
	var health := player.find_child("PlayerHealth", true, false) as PlayerHealth
	if health != null:
		health.take_damage(attack_damage, self)


func _deactivate() -> void:
	state = STATE_DEAD
	velocity = Vector3.ZERO
	collision.set_deferred("disabled", true)
	_update_state_label()
	telegraph_light.light_color = Color("44ff9a")
	telegraph_light.light_energy = 0.35
	_play_audio(&"construct_death", -2.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(body_visual, "scale", Vector3(1.0, 0.18, 1.0), 0.28)
	deactivated.emit()


func _update_visual_state() -> void:
	match state:
		STATE_DEAD:
			telegraph_light.light_color = Color("44ff9a")
			telegraph_light.light_energy = 0.35
		STATE_WINDUP:
			telegraph_light.light_color = Color("ff3d55")
			telegraph_light.light_energy = 2.8
		STATE_COOLDOWN:
			telegraph_light.light_color = Color("ff9c3d")
			telegraph_light.light_energy = 0.7
		STATE_CHASE:
			telegraph_light.light_color = Color("ffb23d")
			telegraph_light.light_energy = 1.4
		_:
			telegraph_light.light_color = Color("55e8e2")
			telegraph_light.light_energy = 0.8
	_update_state_label()


func _update_state_label() -> void:
	var status := "SCANNING"
	match state:
		STATE_DEAD:
			status = "OFFLINE"
		STATE_WINDUP:
			status = "ATTACK CHARGING"
		STATE_COOLDOWN:
			status = "COOLDOWN"
		STATE_CHASE:
			status = "HOSTILE"
	state_label.text = "SECURITY // %s\nHP %03d / %03d" % [status, current_health, maximum_health]


func _flash_hit() -> void:
	if state == STATE_DEAD:
		return
	_hit_reaction_remaining = 0.16
	telegraph_light.light_color = Color.WHITE
	telegraph_light.light_energy = 3.4
	var tween := create_tween()
	tween.tween_interval(0.08)
	tween.tween_callback(_update_visual_state)


func _play_audio(event_name: StringName, volume_db: float) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(event_name, global_position, volume_db, 1.0, 20.0)