extends Node

## Distance-driven first-person movement audio. It observes the existing controller
## without owning movement, input, or collision behavior.

@export_range(0.5, 4.0, 0.05) var walk_step_distance := 1.85
@export_range(0.5, 4.0, 0.05) var sprint_step_distance := 2.15
@export_range(0.1, 2.0, 0.05) var minimum_movement_speed := 0.75
@export_range(1.0, 20.0, 0.5) var minimum_landing_speed := 3.0

@onready var player := get_parent() as CharacterBody3D

var _previous_position := Vector3.ZERO
var _distance_since_step := 0.0
var _was_grounded := false
var _previous_vertical_velocity := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_previous_position = player.global_position
	_was_grounded = player.is_on_floor()
	_previous_vertical_velocity = player.velocity.y


func _physics_process(_delta: float) -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio == null:
		return
	var grounded := player.is_on_floor()
	var movement_delta := player.global_position - _previous_position
	movement_delta.y = 0.0
	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()

	if grounded and not _was_grounded:
		var impact_speed := maxf(0.0, -_previous_vertical_velocity)
		if impact_speed >= minimum_landing_speed:
			var landing_volume := clampf(remap(impact_speed, minimum_landing_speed, 18.0, -10.0, -2.0), -10.0, -2.0)
			audio.call("play_sfx", &"land", landing_volume, _rng.randf_range(0.95, 1.03))
	elif not grounded and _was_grounded and player.velocity.y > 1.0:
		audio.call("play_sfx", &"jump", -8.0, _rng.randf_range(0.97, 1.04))

	if grounded and horizontal_speed >= minimum_movement_speed:
		_distance_since_step += movement_delta.length()
		var step_distance := sprint_step_distance if horizontal_speed > player.walk_speed + 0.8 else walk_step_distance
		if _distance_since_step >= step_distance:
			_distance_since_step = fmod(_distance_since_step, step_distance)
			var volume := -7.0 if horizontal_speed > player.walk_speed + 0.8 else -9.0
			audio.call("play_sfx", &"footstep", volume, _rng.randf_range(0.92, 1.08))
	else:
		_distance_since_step = 0.0

	_previous_position = player.global_position
	_previous_vertical_velocity = player.velocity.y
	_was_grounded = grounded
