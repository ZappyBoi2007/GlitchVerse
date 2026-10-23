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

@export_range(1, 10, 1) var maximum_health := 3
@export_range(2.0, 30.0, 0.5) var detection_range := 13.0
@export_range(0.5, 4.0, 0.1) var attack_range := 1.7
@export_range(0.1, 8.0, 0.1) var movement_speed := 2.5
@export_range(0.2, 2.0, 0.05) var attack_windup := 0.7
@export_range(0.2, 4.0, 0.05) var attack_cooldown := 1.25
@export_range(1, 5, 1) var attack_damage := 1

@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var body_visual: Node3D = $BodyVisual
@onready var telegraph_light: OmniLight3D = $BodyVisual/Head/TelegraphLight
@onready var state_label: Label3D = $StateLabel

var current_health := 3
var state: StringName = STATE_IDLE
var player: CharacterBody3D
var _state_time := 0.0
var _gravity := 9.8
var _alert_played := false


func _ready() -> void:
	current_health = maximum_health
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	add_to_group("security_construct")
	_update_visual_state()
	call_deferred("_acquire_player")


func _physics_process(delta: float) -> void:
	if state == STATE_DEAD:
		return
	if not is_instance_valid(player):
		_acquire_player()
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	if player == null or not player.is_physics_processing():
		velocity.x = move_toward(velocity.x, 0.0, movement_speed * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, movement_speed * 4.0 * delta)
		move_and_slide()
		return

	var offset := player.global_position - global_position
	var planar := Vector3(offset.x, 0, offset.z)
	var distance := planar.length()
	match state:
		STATE_IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			if distance <= detection_range:
				_set_state(STATE_CHASE)
		STATE_CHASE:
			if distance > detection_range * 1.25:
				_set_state(STATE_IDLE)
			elif distance <= attack_range:
				_set_state(STATE_WINDUP)
			else:
				var direction := planar.normalized()
				velocity.x = direction.x * movement_speed
				velocity.z = direction.z * movement_speed
				look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		STATE_WINDUP:
			velocity.x = 0.0
			velocity.z = 0.0
			_state_time -= delta
			if _state_time <= 0.0:
				_resolve_attack(distance)
				_set_state(STATE_COOLDOWN)
		STATE_COOLDOWN:
			velocity.x = 0.0
			velocity.z = 0.0
			_state_time -= delta
			if _state_time <= 0.0:
				_set_state(STATE_CHASE)
	move_and_slide()


func take_damage(amount: int, _source: Node = null) -> bool:
	if amount <= 0 or state == STATE_DEAD:
		return false
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, maximum_health)
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
	state_label.text = "SECURITY // OFFLINE"
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
			state_label.text = "SECURITY // OFFLINE"
		STATE_WINDUP:
			telegraph_light.light_color = Color("ff3d55")
			telegraph_light.light_energy = 2.8
			state_label.text = "SECURITY // ATTACK CHARGING"
		STATE_COOLDOWN:
			telegraph_light.light_color = Color("ff9c3d")
			telegraph_light.light_energy = 0.7
			state_label.text = "SECURITY // COOLDOWN"
		STATE_CHASE:
			telegraph_light.light_color = Color("ffb23d")
			telegraph_light.light_energy = 1.4
			state_label.text = "SECURITY // HOSTILE"
		_:
			telegraph_light.light_color = Color("55e8e2")
			telegraph_light.light_energy = 0.8
			state_label.text = "SECURITY // SCANNING"


func _flash_hit() -> void:
	if state == STATE_DEAD:
		return
	telegraph_light.light_color = Color.WHITE
	telegraph_light.light_energy = 3.4
	var tween := create_tween()
	tween.tween_interval(0.08)
	tween.tween_callback(_update_visual_state)


func _play_audio(event_name: StringName, volume_db: float) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(event_name, global_position, volume_db, 1.0, 20.0)
