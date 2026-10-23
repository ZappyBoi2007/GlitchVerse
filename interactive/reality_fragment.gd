class_name RealityFragment
extends Area3D

## Reusable, one-shot collectible. Level-specific controllers decide what a
## fragment contributes to; the collectible only validates and reports pickup.

signal fragment_collected(fragment_id: StringName)

@export var fragment_id: StringName = &"fragment"
@export_range(0.0, 0.5, 0.01) var float_height := 0.14
@export_range(0.1, 4.0, 0.05) var float_speed := 1.25
@export_range(0.0, 180.0, 1.0) var rotation_speed_degrees := 38.0

@onready var visual_root: Node3D = $VisualRoot
@onready var pickup_collision: CollisionShape3D = $PickupCollision

var _collected := false
var _animation_time := 0.0
var _visual_start_y := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_visual_start_y = visual_root.position.y


func _process(delta: float) -> void:
	if _collected:
		return
	_animation_time += delta
	visual_root.position.y = _visual_start_y + sin(_animation_time * TAU * float_speed) * float_height
	visual_root.rotate_y(deg_to_rad(rotation_speed_degrees) * delta)


func is_collected() -> bool:
	return _collected


func try_collect(body: Node3D) -> bool:
	if _collected or body == null:
		return false
	if not body is CharacterBody3D or not body.is_in_group("player"):
		return false

	_collected = true
	monitoring = false
	pickup_collision.set_deferred("disabled", true)
	fragment_collected.emit(fragment_id)
	_play_pickup_feedback()
	return true


func _on_body_entered(body: Node3D) -> void:
	try_collect(body)


func _play_pickup_feedback() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_3d(&"fragment_pickup", global_position, -5.0, 1.0, 18.0)

	set_process(false)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "scale", Vector3.ONE * 1.45, 0.12)
	tween.tween_property(visual_root, "position:y", visual_root.position.y + 0.42, 0.24)
	tween.chain().tween_property(visual_root, "scale", Vector3.ZERO, 0.16)
	tween.finished.connect(queue_free, CONNECT_ONE_SHOT)
