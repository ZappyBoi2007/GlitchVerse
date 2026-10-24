class_name SwordController
extends Node3D

signal attack_started
signal attack_finished
signal hit_confirmed(target: Node, damage: int)
signal attack_missed

@export_range(1, 1000, 1) var damage := 25
@export_range(0.1, 2.0, 0.05) var attack_cooldown := 0.42
@export_range(0.5, 4.0, 0.1) var attack_reach := 2.1
@export_range(0.1, 1.5, 0.05) var hit_radius := 0.72
@export_range(0.01, 0.3, 0.01) var hit_delay := 0.07

@onready var blade_pivot: Node3D = $BladePivot
@onready var blade_mesh: MeshInstance3D = $BladePivot/Blade

var player: CharacterBody3D
var camera: Camera3D
var _cooldown_remaining := 0.0
var _attack_generation := 0
var _hit_target_ids: Dictionary = {}


func _ready() -> void:
	camera = get_parent() as Camera3D
	player = _find_player()


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("sword_attack")
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		and player != null
		and player.is_physics_processing()
	):
		try_attack()
		get_viewport().set_input_as_handled()


func try_attack() -> bool:
	if _cooldown_remaining > 0.0 or player == null or camera == null:
		return false
	_cooldown_remaining = attack_cooldown
	_attack_generation += 1
	_hit_target_ids.clear()
	attack_started.emit()
	_play_audio_2d(&"sword_swing", -5.0)
	_play_swing_animation()
	var generation := _attack_generation
	get_tree().create_timer(hit_delay).timeout.connect(
		_perform_hit_query.bind(generation), CONNECT_ONE_SHOT
	)
	return true


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func _play_swing_animation() -> void:
	blade_pivot.rotation_degrees = Vector3(25, 35, -10)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(blade_pivot, "rotation_degrees", Vector3(-12, -8, -82), 0.085)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blade_pivot, "rotation_degrees", Vector3(25, 35, -10), 0.17)
	tween.finished.connect(attack_finished.emit, CONNECT_ONE_SHOT)


func _perform_hit_query(generation: int) -> void:
	if generation != _attack_generation or not is_instance_valid(player) or not player.is_inside_tree():
		return
	var shape := SphereShape3D.new()
	shape.radius = hit_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	# Center the volume inside the full reach so enemies pressed close to the
	# player are not skipped by a sphere placed only at the maximum distance.
	query.transform = Transform3D(
		Basis.IDENTITY,
		camera.global_position - camera.global_basis.z * (attack_reach * 0.62)
	)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]
	var results := player.get_world_3d().direct_space_state.intersect_shape(query, 16)
	var closest_target: Node
	var closest_distance := INF
	for result in results:
		var target := _find_damage_target(result.get("collider"))
		if target == null or target.get_instance_id() in _hit_target_ids:
			continue
		var target_node := target as Node3D
		var distance := camera.global_position.distance_squared_to(target_node.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	if closest_target == null:
		_play_audio_2d(&"sword_miss", -11.0)
		attack_missed.emit()
		return
	_damage_target_once(closest_target)


func _damage_target_once(target: Node) -> bool:
	if target == null or not target.has_method("take_damage"):
		return false
	var target_id := target.get_instance_id()
	if target_id in _hit_target_ids:
		return false
	_hit_target_ids[target_id] = true
	var accepted := bool(target.call("take_damage", damage, player))
	if not accepted:
		return false
	hit_confirmed.emit(target, damage)
	var impact_position := (target as Node3D).global_position if target is Node3D else camera.global_position
	_play_audio_3d(&"sword_hit", impact_position, -3.0)
	var tween := create_tween()
	tween.tween_property(blade_mesh, "scale", Vector3(1.18, 1.18, 1.18), 0.04)
	tween.tween_property(blade_mesh, "scale", Vector3.ONE, 0.08)
	return true


func _find_damage_target(collider: Object) -> Node:
	var candidate := collider as Node
	while candidate != null:
		if candidate.has_method("take_damage"):
			return candidate
		candidate = candidate.get_parent()
	return null


func _find_player() -> CharacterBody3D:
	var candidate: Node = self
	while candidate != null:
		if candidate is CharacterBody3D:
			return candidate
		candidate = candidate.get_parent()
	return null


func _play_audio_2d(event_name: StringName, volume_db: float) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(event_name, volume_db)


func _play_audio_3d(event_name: StringName, world_position: Vector3, volume_db: float) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(event_name, world_position, volume_db, 1.0, 18.0)
