class_name RandomEnemyEncounter
extends Node

const MAX_ALIVE_ENEMIES := 4

signal enemy_spawned(enemy: SecurityConstruct, wave: int)
signal enemy_defeated(enemy: SecurityConstruct)
signal encounter_completed

@export_category("Encounter")
@export var enabled := true
@export var randomize_initial_enemy := true
@export var stop_when_objective_complete := true
@export_range(1, MAX_ALIVE_ENEMIES, 1) var maximum_simultaneous_enemies := MAX_ALIVE_ENEMIES
@export_range(1, 20, 1) var maximum_total_enemies := 5
@export_range(1.0, 30.0, 0.5) var activation_distance := 15.0
@export_range(0.0, 30.0, 0.5) var minimum_spawn_distance_from_player := 5.0
@export_range(0.5, 5.0, 0.1) var minimum_enemy_separation := 1.0
@export_range(0.3, 5.0, 0.1) var defeated_cleanup_delay := 1.0

@export_category("Timing")
@export_range(0.1, 30.0, 0.1) var minimum_spawn_interval := 5.0
@export_range(0.1, 30.0, 0.1) var maximum_spawn_interval := 9.0
@export var reproducible_seed := false
@export var random_seed := 1337

@export_category("Attack Difficulty")
@export_range(1, 10, 1) var enemies_per_wave := 2
@export_range(0.5, 4.0, 0.05) var initial_attack_interval := 1.8
@export_range(0.0, 1.0, 0.05) var attack_interval_reduction_per_wave := 0.3
@export_range(0.5, 3.0, 0.05) var minimum_attack_interval := 1.0

@export_category("Authored Nodes")
@export var enemy_scene: PackedScene
@export var initial_enemy_path: NodePath
@export var activation_marker_path: NodePath
@export var spawn_marker_paths: Array[NodePath] = []
@export var spawn_marker_room_ids: PackedStringArray = []
@export var initially_accessible_rooms: PackedStringArray = []

var total_spawned := 0
var total_defeated := 0
var time_until_spawn := 0.0

var _player: CharacterBody3D
var _active_enemies: Array[SecurityConstruct] = []
var _rng := RandomNumberGenerator.new()
var _running := false
var _activated := false
var _completed := false
var _spawn_in_progress := false
var _accessible_rooms: Dictionary = {}
var _last_spawn_room := &""


func _ready() -> void:
	set_process(false)


func begin(player_body: CharacterBody3D) -> void:
	_player = player_body
	_active_enemies.clear()
	total_spawned = 0
	total_defeated = 0
	_completed = false
	_activated = false
	_running = true
	_spawn_in_progress = false
	_last_spawn_room = &""
	_reset_accessible_rooms()
	_reset_rng()
	var initial_enemy := get_node_or_null(initial_enemy_path) as SecurityConstruct
	if initial_enemy != null and not initial_enemy.is_deactivated():
		if randomize_initial_enemy:
			var initial_marker := _choose_spawn_marker()
			if initial_marker != null:
				initial_enemy.global_transform = initial_marker.global_transform
				_last_spawn_room = _get_room_for_marker_node(initial_marker)
		_register_enemy(initial_enemy)
	_synchronize_global_enemy_registry()
	_schedule_next_spawn()
	set_process(true)


func _process(delta: float) -> void:
	if not _running or get_tree().paused:
		return
	_prune_active_enemies()
	if not _activated:
		_activated = _player_reached_activation_zone()
		if not _activated:
			return
	if not _completed and _should_complete():
		_complete_encounter()
		return
	if not enabled or (not _completed and total_spawned >= maximum_total_enemies):
		return
	if _active_enemies.size() >= _effective_alive_cap():
		return
	time_until_spawn -= delta
	if time_until_spawn <= 0.0:
		if not try_spawn_now():
			time_until_spawn = minf(minimum_spawn_interval, maximum_spawn_interval)


func force_activate() -> void:
	_activated = true


func stop() -> void:
	_running = false
	set_process(false)


func is_completed() -> bool:
	return _completed


func is_activated() -> bool:
	return _activated


func get_active_enemies() -> Array[SecurityConstruct]:
	_synchronize_global_enemy_registry()
	return _active_enemies.duplicate()


func get_global_alive_count() -> int:
	_synchronize_global_enemy_registry()
	return _active_enemies.size()


func set_room_accessible(room_id: StringName, accessible: bool) -> void:
	if room_id.is_empty():
		return
	if accessible:
		_accessible_rooms[room_id] = true
	else:
		_accessible_rooms.erase(room_id)


func is_room_accessible(room_id: StringName) -> bool:
	return bool(_accessible_rooms.get(room_id, false))


func get_accessible_room_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for room_id in _accessible_rooms:
		if bool(_accessible_rooms[room_id]):
			result.append(String(room_id))
	return result


func get_spawn_room_for_marker(marker_path: NodePath) -> StringName:
	var marker_index := spawn_marker_paths.find(marker_path)
	if marker_index < 0 or marker_index >= spawn_marker_room_ids.size():
		return &""
	return StringName(spawn_marker_room_ids[marker_index])


func get_eligible_spawn_room_ids() -> PackedStringArray:
	var result := PackedStringArray()
	for marker_path in spawn_marker_paths:
		var room_id := get_spawn_room_for_marker(marker_path)
		if not room_id.is_empty() and is_room_accessible(room_id) and not result.has(String(room_id)):
			result.append(String(room_id))
	return result


func get_wave_for_spawn(spawn_number: int) -> int:
	return maxi(1, ((maxi(1, spawn_number) - 1) / maxi(1, enemies_per_wave)) + 1)


func get_attack_interval_for_wave(wave: int) -> float:
	return maxf(
		minimum_attack_interval,
		initial_attack_interval - float(maxi(1, wave) - 1) * attack_interval_reduction_per_wave
	)


func sample_spawn_delays(count: int, seed_value: int) -> PackedFloat32Array:
	var sample_rng := RandomNumberGenerator.new()
	sample_rng.seed = seed_value
	var delays := PackedFloat32Array()
	for _index in range(maxi(0, count)):
		delays.append(_random_interval(sample_rng))
	return delays


func try_spawn_now() -> bool:
	if _spawn_in_progress:
		return false
	_spawn_in_progress = true
	var spawned := _try_spawn_now_internal()
	_spawn_in_progress = false
	return spawned


func _try_spawn_now_internal() -> bool:
	if not _running or not enabled:
		return false
	_synchronize_global_enemy_registry()
	if not _completed and total_spawned >= maximum_total_enemies:
		return false
	# The registry is refreshed immediately before construction. Combined with
	# the in-progress guard, this prevents two attempts in the same frame from
	# creating a fifth living guard.
	if _active_enemies.size() >= _effective_alive_cap():
		return false
	if enemy_scene == null:
		return false
	var marker := _choose_spawn_marker()
	if marker == null:
		return false
	var enemy := enemy_scene.instantiate() as SecurityConstruct
	if enemy == null:
		return false
	var spawn_number := total_spawned + 1
	var wave := get_wave_for_spawn(spawn_number)
	enemy.name = "SecurityConstruct_%02d" % spawn_number
	enemy.attack_cooldown = get_attack_interval_for_wave(wave)
	add_child(enemy)
	enemy.global_transform = marker.global_transform
	_last_spawn_room = _get_room_for_marker_node(marker)
	_register_enemy(enemy)
	_schedule_next_spawn()
	enemy_spawned.emit(enemy, wave)
	return true


func _register_enemy(enemy: SecurityConstruct) -> void:
	if _active_enemies.has(enemy):
		return
	total_spawned += 1
	var wave := get_wave_for_spawn(total_spawned)
	enemy.attack_cooldown = get_attack_interval_for_wave(wave)
	_active_enemies.append(enemy)
	enemy.deactivated.connect(_on_enemy_deactivated.bind(enemy), CONNECT_ONE_SHOT)
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy), CONNECT_ONE_SHOT)


func _on_enemy_deactivated(enemy: SecurityConstruct) -> void:
	_active_enemies.erase(enemy)
	total_defeated += 1
	_activated = true
	enemy_defeated.emit(enemy)
	_cleanup_defeated_enemy(enemy)
	if not _completed and _should_complete():
		_complete_encounter()
	else:
		_schedule_next_spawn()


func _on_enemy_tree_exiting(enemy: SecurityConstruct) -> void:
	if not _active_enemies.has(enemy):
		return
	_active_enemies.erase(enemy)
	if _running and not get_tree().paused:
		_schedule_next_spawn()


func _cleanup_defeated_enemy(enemy: SecurityConstruct) -> void:
	await get_tree().create_timer(defeated_cleanup_delay).timeout
	if is_instance_valid(enemy) and enemy.is_deactivated():
		enemy.queue_free()


func _should_complete() -> bool:
	var target_total := maximum_total_enemies if enabled else 1
	return total_spawned >= target_total and _active_enemies.is_empty()


func _complete_encounter() -> void:
	if _completed:
		return
	_completed = true
	if stop_when_objective_complete:
		stop()
	else:
		_schedule_next_spawn()
	encounter_completed.emit()


func _player_reached_activation_zone() -> bool:
	if not is_instance_valid(_player) or not _player.is_physics_processing():
		return false
	var marker := get_node_or_null(activation_marker_path) as Node3D
	if marker == null:
		return true
	return _player.global_position.distance_to(marker.global_position) <= activation_distance


func _get_valid_spawn_markers() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for marker_path in spawn_marker_paths:
		var room_id := get_spawn_room_for_marker(marker_path)
		if room_id.is_empty() or not is_room_accessible(room_id):
			continue
		var marker := get_node_or_null(marker_path) as Node3D
		if marker == null:
			continue
		if is_instance_valid(_player) and marker.global_position.distance_to(_player.global_position) < minimum_spawn_distance_from_player:
			continue
		var occupied := false
		for active_enemy in _active_enemies:
			if is_instance_valid(active_enemy) and active_enemy.global_position.distance_to(marker.global_position) < minimum_enemy_separation:
				occupied = true
				break
		if not occupied:
			result.append(marker)
	return result


func _choose_spawn_marker() -> Node3D:
	var valid_markers := _get_valid_spawn_markers()
	if valid_markers.is_empty():
		return null
	var alternate_room_markers: Array[Node3D] = []
	for marker in valid_markers:
		if _get_room_for_marker_node(marker) != _last_spawn_room:
			alternate_room_markers.append(marker)
	if not alternate_room_markers.is_empty():
		valid_markers = alternate_room_markers
	var hidden_markers: Array[Node3D] = []
	for marker in valid_markers:
		if not _is_marker_in_clear_camera_view(marker):
			hidden_markers.append(marker)
	if not hidden_markers.is_empty():
		valid_markers = hidden_markers
	var nearby_markers: Array[Node3D] = []
	if is_instance_valid(_player):
		for marker in valid_markers:
			if marker.global_position.distance_to(_player.global_position) <= 36.0:
				nearby_markers.append(marker)
	if not nearby_markers.is_empty():
		valid_markers = nearby_markers
	return valid_markers[_rng.randi_range(0, valid_markers.size() - 1)]


func _is_marker_in_clear_camera_view(marker: Node3D) -> bool:
	if not is_instance_valid(_player):
		return false
	var camera := _player.find_child("Camera3D", true, false) as Camera3D
	if camera == null or not camera.is_inside_tree() or camera.is_position_behind(marker.global_position):
		return false
	var screen_position := camera.unproject_position(marker.global_position + Vector3.UP)
	var viewport_size := camera.get_viewport().get_visible_rect().size
	if screen_position.x < 0.0 or screen_position.y < 0.0 or screen_position.x > viewport_size.x or screen_position.y > viewport_size.y:
		return false
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, marker.global_position + Vector3.UP)
	query.exclude = [_player.get_rid()]
	return camera.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _get_room_for_marker_node(marker: Node3D) -> StringName:
	for marker_index in range(spawn_marker_paths.size()):
		if get_node_or_null(spawn_marker_paths[marker_index]) == marker:
			if marker_index < spawn_marker_room_ids.size():
				return StringName(spawn_marker_room_ids[marker_index])
			return &""
	return &""


func _prune_active_enemies() -> void:
	var retained: Array[SecurityConstruct] = []
	for active_enemy in _active_enemies:
		if is_instance_valid(active_enemy) and not active_enemy.is_deactivated():
			retained.append(active_enemy)
	_active_enemies = retained


func _synchronize_global_enemy_registry() -> void:
	_prune_active_enemies()
	var level_root := get_parent()
	if level_root == null:
		return
	for candidate in level_root.find_children("*", "", true, false):
		var enemy := candidate as SecurityConstruct
		if enemy != null and not enemy.is_deactivated() and not _active_enemies.has(enemy):
			_register_enemy(enemy)


func _effective_alive_cap() -> int:
	return mini(MAX_ALIVE_ENEMIES, maximum_simultaneous_enemies)


func _schedule_next_spawn() -> void:
	time_until_spawn = _random_interval(_rng)


func _random_interval(source_rng: RandomNumberGenerator) -> float:
	return source_rng.randf_range(
		minf(minimum_spawn_interval, maximum_spawn_interval),
		maxf(minimum_spawn_interval, maximum_spawn_interval)
	)


func _reset_rng() -> void:
	if reproducible_seed:
		_rng.seed = random_seed
	else:
		_rng.randomize()


func _reset_accessible_rooms() -> void:
	_accessible_rooms.clear()
	for room_id in initially_accessible_rooms:
		set_room_accessible(StringName(room_id), true)
