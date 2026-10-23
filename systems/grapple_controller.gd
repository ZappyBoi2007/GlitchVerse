class_name GrappleController
extends Node3D

## Lightweight pendulum tether for CharacterBody3D. The rope never writes the
## player's position: it constrains velocity before the controller's one
## collision-aware move_and_slide() call.

signal target_changed(target: Node, valid: bool)
signal grapple_attached(target: Node)
signal grapple_detached(reason: StringName)

@export_category("Targeting")
@export_range(2.0, 40.0, 0.5) var maximum_range := 22.0
@export_range(1.5, 8.0, 0.25) var minimum_rope_length := 3.0
@export_range(4.0, 40.0, 0.5) var maximum_rope_length := 22.0
@export_range(0.5, 3.0, 0.1) var anchor_arrival_cutoff := 1.25

@export_category("Swing Feel")
@export_range(0.0, 20.0, 0.25) var swing_acceleration := 7.0
@export_range(0.0, 20.0, 0.25) var air_steering_strength := 3.5
@export_range(0.0, 2.0, 0.01) var swing_damping := 0.02
@export_range(5.0, 40.0, 0.5) var maximum_speed := 18.0
@export_range(0.8, 1.3, 0.01) var release_momentum_multiplier := 1.0
@export_range(1.0, 20.0, 0.5) var attachment_responsiveness := 7.0
@export_range(0.0, 3.0, 0.05) var reel_in_speed := 0.0
@export_range(0.0, 12.0, 0.25) var minimum_attach_tangent_speed := 4.5
@export_range(0.0, 8.0, 0.25) var maximum_attach_assist := 3.0
@export_range(0.0, 1.0, 0.05) var grounded_assist_multiplier := 0.55
@export_range(0.0, 3.0, 0.1) var maximum_vertical_attach_assist := 0.8

@export_category("Safety")
@export_range(0.1, 2.0, 0.05) var rope_extension_tolerance := 0.65
@export_range(1.0, 6.0, 0.25) var rope_break_extension := 2.5
@export_range(0.1, 2.0, 0.05) var obstruction_grace_seconds := 0.45
@export_range(10.0, 80.0, 1.0) var extreme_speed_limit := 32.0

@onready var target_ray: RayCast3D = $TargetRay
@onready var tether_beam: MeshInstance3D = $TetherBeam

var player: CharacterBody3D
var camera: Camera3D
var active_target: Node3D
var rope_length := 0.0
var _hover_target: Node3D
var _anchor_position := Vector3.ZERO
var _environment_release_remaining := 0.0
var _obstruction_elapsed := 0.0
var _last_distance := 0.0
var last_release_speed := 0.0


func _ready() -> void:
	camera = get_parent() as Camera3D
	player = _find_player()
	target_ray.target_position = Vector3(0, 0, -maximum_range)
	target_ray.enabled = true
	target_ray.collide_with_bodies = true
	target_ray.collide_with_areas = true
	tether_beam.top_level = true
	tether_beam.visible = false
	if player != null:
		player.pre_move.connect(_apply_tether_velocity)
		player.post_move.connect(_after_player_move)
		_exclude_player()
		var health := player.find_child("PlayerHealth", true, false) as PlayerHealth
		if health != null:
			health.player_defeated.connect(_on_player_defeated)


func _exit_tree() -> void:
	_clear_grapple(false, &"scene_exit")


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or player == null or not player.is_physics_processing():
		return
	if event.is_action_pressed("grapple"):
		if active_target != null:
			cancel_grapple(&"manual")
		else:
			try_attach_from_camera()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if player == null or not player.is_physics_processing():
		if active_target != null:
			cancel_grapple(&"inactive")
		return
	_update_hover_target()
	if active_target == null:
		return
	if not is_instance_valid(active_target) or not _is_valid_target(active_target):
		cancel_grapple(&"target_lost")
		return
	_anchor_position = _get_target_point(active_target)
	_update_tether_visual()
	if _environment_release_remaining > 0.0:
		_environment_release_remaining -= delta
		if _environment_release_remaining <= 0.0:
			cancel_grapple(&"mechanism_activated")


func try_attach_from_camera() -> bool:
	target_ray.force_raycast_update()
	if not target_ray.is_colliding():
		_play_audio(&"grapple_invalid", -8.0)
		return false
	var target := _find_grapple_target(target_ray.get_collider())
	if not try_attach_target(target):
		_play_audio(&"grapple_invalid", -8.0)
		return false
	return true


func try_attach_target(target: Node) -> bool:
	if active_target != null or not is_instance_valid(target) or not _is_valid_target(target):
		return false
	var target_node := target as Node3D
	var point := _get_target_point(target_node)
	var distance := player.global_position.distance_to(point)
	if distance > maximum_range or distance <= anchor_arrival_cutoff:
		return false
	active_target = target_node
	_anchor_position = point
	rope_length = clampf(distance, minimum_rope_length, minf(maximum_rope_length, maximum_range))
	_last_distance = distance
	_obstruction_elapsed = 0.0
	tether_beam.visible = true
	_set_target_highlight(active_target, true)
	if active_target.has_method("on_grapple_attached"):
		active_target.call("on_grapple_attached", self)
	if _target_pulls_player(active_target):
		player.set_movement_override(self, true)
		_apply_attachment_assist(point)
	else:
		_environment_release_remaining = 0.24
	_update_tether_visual()
	_play_audio(&"grapple_attach", -4.0)
	grapple_attached.emit(active_target)
	return true


func cancel_grapple(reason: StringName = &"cancelled") -> void:
	_clear_grapple(true, reason)


func _clear_grapple(emit_feedback: bool, reason: StringName) -> void:
	if player != null:
		player.set_movement_override(self, false)
	if active_target == null:
		tether_beam.visible = false
		return
	var previous := active_target
	if is_instance_valid(previous) and previous.has_method("on_grapple_detached"):
		previous.call("on_grapple_detached", self)
	_set_target_highlight(previous, false)
	if _hover_target == previous:
		_hover_target = null
	if is_instance_valid(previous) and _target_pulls_player(previous) and player != null:
		player.velocity *= release_momentum_multiplier
		last_release_speed = player.velocity.length()
	active_target = null
	rope_length = 0.0
	tether_beam.visible = false
	_environment_release_remaining = 0.0
	_obstruction_elapsed = 0.0
	if emit_feedback:
		_play_audio(&"grapple_detach", -8.0)
		grapple_detached.emit(reason)


func is_grappling() -> bool:
	return is_instance_valid(active_target) and _target_pulls_player(active_target)


func get_rope_length() -> float:
	return rope_length


func get_debug_snapshot() -> Dictionary:
	var horizontal_speed := 0.0
	var swing_speed := 0.0
	if player != null:
		horizontal_speed = Vector3(player.velocity.x, 0.0, player.velocity.z).length()
		if is_grappling():
			var radial := player.global_position - _anchor_position
			if not radial.is_zero_approx():
				radial = radial.normalized()
				swing_speed = (player.velocity - radial * player.velocity.dot(radial)).length()
	return {
		"state": "ATTACHED" if is_grappling() else "IDLE",
		"horizontal_speed": horizontal_speed,
		"rope_length": rope_length,
		"swing_speed": swing_speed,
		"last_release_speed": last_release_speed,
	}


func _apply_attachment_assist(anchor_point: Vector3) -> void:
	if player == null or minimum_attach_tangent_speed <= 0.0 or maximum_attach_assist <= 0.0:
		return
	var radial_out := player.global_position - anchor_point
	if radial_out.length_squared() <= 0.001:
		return
	radial_out = radial_out.normalized()
	var horizontal_velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var preferred := horizontal_velocity.normalized()
	if preferred.is_zero_approx():
		preferred = -camera.global_basis.z
		preferred.y = 0.0
		preferred = preferred.normalized()
	var tangent := preferred - radial_out * preferred.dot(radial_out)
	if tangent.length_squared() <= 0.001:
		return
	tangent = tangent.normalized()
	var current_speed := maxf(0.0, player.velocity.dot(tangent))
	var assist_speed := minf(maximum_attach_assist, maxf(0.0, minimum_attach_tangent_speed - current_speed))
	if player.is_on_floor():
		assist_speed *= grounded_assist_multiplier
	var assist_velocity := tangent * assist_speed
	assist_velocity.y = clampf(assist_velocity.y, -maximum_vertical_attach_assist, maximum_vertical_attach_assist)
	player.velocity += assist_velocity


func _apply_tether_velocity(delta: float) -> void:
	if not is_grappling():
		return
	_anchor_position = _get_target_point(active_target)
	var rope_offset := player.global_position - _anchor_position
	var distance := rope_offset.length()
	if distance <= anchor_arrival_cutoff:
		cancel_grapple(&"anchor_cutoff")
		return
	if distance > maximum_range + rope_break_extension:
		cancel_grapple(&"range_exceeded")
		return
	if reel_in_speed > 0.0:
		rope_length = maxf(minimum_rope_length, rope_length - reel_in_speed * delta)

	var radial_out := rope_offset / distance
	var has_swing_input := _apply_swing_input(radial_out, delta)
	var radial_speed := player.velocity.dot(radial_out)
	var predicted_distance := (rope_offset + player.velocity * delta).length()
	var taut := distance >= rope_length - 0.08 or predicted_distance > rope_length
	if taut:
		# Remove only outward radial velocity. Tangential and inward momentum
		# survive, producing a gravity-driven arc rather than a direct pull.
		if radial_speed > 0.0:
			player.velocity -= radial_out * radial_speed
		var tangential_velocity := player.velocity - radial_out * player.velocity.dot(radial_out)
		var centripetal_speed := tangential_velocity.length_squared() / maxf(rope_length, 0.1) * delta
		var stretch := maxf(0.0, distance - rope_length)
		var correction_speed := minf(
			stretch * attachment_responsiveness + centripetal_speed,
			maximum_speed * 0.55
		)
		player.velocity -= radial_out * correction_speed
		if not has_swing_input and swing_damping > 0.0:
			var idle_tangent := player.velocity - radial_out * player.velocity.dot(radial_out)
			player.velocity -= idle_tangent * minf(1.0, swing_damping * delta)
	player.velocity = player.velocity.limit_length(maximum_speed)


func _apply_swing_input(radial_out: Vector3, delta: float) -> bool:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_vector.is_zero_approx():
		return false
	var desired := (
		player.global_basis.x * input_vector.x
		+ player.global_basis.z * input_vector.y
	).normalized()
	var tangent_input := desired - radial_out * desired.dot(radial_out)
	if tangent_input.length_squared() <= 0.001:
		return false
	tangent_input = tangent_input.normalized()
	var tangent_velocity := player.velocity - radial_out * player.velocity.dot(radial_out)
	var target_speed := minf(maximum_speed, maxf(tangent_velocity.length(), minimum_attach_tangent_speed))
	var desired_tangent := tangent_input * target_speed
	var steering_delta := (desired_tangent - tangent_velocity).limit_length(air_steering_strength * delta)
	player.velocity += steering_delta
	# A small tangential pump keeps WASD useful without instantly redirecting momentum.
	player.velocity += tangent_input * swing_acceleration * delta * 0.35
	return true


func _after_player_move(delta: float) -> void:
	if not is_grappling():
		return
	var distance := player.global_position.distance_to(_anchor_position)
	var extending := distance > _last_distance + 0.01
	var collision_blocked := false
	for index in range(player.get_slide_collision_count()):
		var collision := player.get_slide_collision(index)
		var toward_anchor := player.global_position.direction_to(_anchor_position)
		if collision.get_normal().dot(toward_anchor) < -0.38:
			collision_blocked = true
			break
	if collision_blocked and extending and distance > rope_length + rope_extension_tolerance:
		_obstruction_elapsed += delta
	else:
		_obstruction_elapsed = maxf(0.0, _obstruction_elapsed - delta * 2.0)
	if _obstruction_elapsed >= obstruction_grace_seconds:
		cancel_grapple(&"obstructed")
		return
	if distance > rope_length + rope_break_extension or player.velocity.length() > extreme_speed_limit:
		cancel_grapple(&"safety_release")
		return
	_last_distance = distance


func _update_hover_target() -> void:
	target_ray.force_raycast_update()
	var next_target: Node3D
	if target_ray.is_colliding():
		next_target = _find_grapple_target(target_ray.get_collider()) as Node3D
		if next_target != null:
			var distance := camera.global_position.distance_to(_get_target_point(next_target))
			if distance > maximum_range or distance <= anchor_arrival_cutoff:
				next_target = null
	if next_target == _hover_target:
		return
	if is_instance_valid(_hover_target) and _hover_target != active_target:
		_set_target_highlight(_hover_target, false)
	_hover_target = next_target
	if is_instance_valid(_hover_target):
		_set_target_highlight(_hover_target, true)
	target_changed.emit(_hover_target, _hover_target != null)


func _update_tether_visual() -> void:
	if active_target == null:
		return
	var start := camera.global_position + camera.global_basis * Vector3(0.31, -0.26, -0.5)
	var offset := _anchor_position - start
	var length := offset.length()
	if length <= 0.01:
		return
	var up := offset / length
	var right := Vector3.UP.cross(up)
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT.cross(up)
	right = right.normalized()
	var forward := right.cross(up).normalized()
	tether_beam.global_transform = Transform3D(Basis(right, up, forward), start + offset * 0.5)
	tether_beam.scale = Vector3(1.0, length, 1.0)


func _find_player() -> CharacterBody3D:
	var candidate: Node = self
	while candidate != null:
		if candidate is CharacterBody3D:
			return candidate
		candidate = candidate.get_parent()
	return null


func _exclude_player() -> void:
	target_ray.add_exception(player)


func _find_grapple_target(collider: Object) -> Node:
	var candidate := collider as Node
	while candidate != null:
		if candidate.is_in_group("grapple_target") and candidate.has_method("get_grapple_point"):
			return candidate
		candidate = candidate.get_parent()
	return null


func _is_valid_target(target: Node) -> bool:
	if not target is Node3D or not target.is_in_group("grapple_target"):
		return false
	return not target.has_method("can_grapple") or bool(target.call("can_grapple"))


func _get_target_point(target: Node3D) -> Vector3:
	return target.call("get_grapple_point") as Vector3


func _target_pulls_player(target: Node) -> bool:
	return not target.has_method("pulls_player") or bool(target.call("pulls_player"))


func _set_target_highlight(target: Node, enabled: bool) -> void:
	if is_instance_valid(target) and target.has_method("set_grapple_highlight"):
		target.call("set_grapple_highlight", enabled)


func _on_player_defeated() -> void:
	cancel_grapple(&"player_defeated")


func _play_audio(event_name: StringName, volume_db: float) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(event_name, volume_db)
