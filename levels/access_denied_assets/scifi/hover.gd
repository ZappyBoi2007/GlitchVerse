@tool
extends Node3D
@export var amplitude: float = 0.6
@export var speed: float = 0.65
@export var phase: float = 0.0
@export var drift_radius: float = 0.35
@export var spin_speed: float = 0.12
@export var randomize_motion: bool = true
var elapsed: float = 0.0
var base_position: Vector3
var base_rotation: Vector3

func _ready() -> void:
 base_position = $Body.position
 base_rotation = $Body.rotation
 if randomize_motion:
  var random := RandomNumberGenerator.new()
  random.seed = hash(name)
  amplitude *= random.randf_range(0.65, 1.45)
  speed *= random.randf_range(0.7, 1.35)
  drift_radius *= random.randf_range(0.45, 1.4)
  spin_speed *= random.randf_range(-1.25, 1.25)
  phase += random.randf_range(0.0, TAU)

func _process(delta: float) -> void:
 elapsed += delta
 var motion_time := elapsed * speed + phase
 var vertical_wave := sin(motion_time) + sin(motion_time * 1.73 + phase * 0.7) * 0.28
 $Body.position = base_position + Vector3(
  sin(motion_time * 0.37) * drift_radius,
  vertical_wave * amplitude,
  cos(motion_time * 0.29) * drift_radius
 )
 $Body.rotation = base_rotation + Vector3(
  sin(motion_time * 0.23) * 0.08,
  elapsed * spin_speed + phase,
  cos(motion_time * 0.19) * 0.06
 )

