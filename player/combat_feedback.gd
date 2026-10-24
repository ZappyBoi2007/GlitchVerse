class_name CombatFeedback
extends CanvasLayer

@export_range(0.01, 0.3, 0.01) var hit_impact_duration := 0.08
@export_range(0.01, 0.4, 0.01) var damage_impact_duration := 0.14
@export_range(0.0, 0.15, 0.005) var hit_camera_offset := 0.028
@export_range(0.0, 0.2, 0.005) var damage_camera_offset := 0.055

var _camera: Camera3D
var _hit_flash: ColorRect
var _damage_flash: ColorRect
var _impact_remaining := 0.0
var _impact_duration := 0.0
var _impact_strength := 0.0
var _hit_flash_alpha := 0.0
var _damage_flash_alpha := 0.0
var _base_h_offset := 0.0
var _base_v_offset := 0.0


func _ready() -> void:
	layer = 85
	_camera = get_parent().get_node_or_null("Head/Camera3D") as Camera3D
	if _camera != null:
		_base_h_offset = _camera.h_offset
		_base_v_offset = _camera.v_offset
	_hit_flash = _make_flash(Color(0.78, 0.96, 1.0, 0.0))
	_damage_flash = _make_flash(Color(1.0, 0.08, 0.12, 0.0))
	var health := get_parent().find_child("PlayerHealth", true, false) as PlayerHealth
	if health != null:
		health.damaged.connect(_on_player_damaged)
		health.health_changed.connect(_on_health_changed)
	var sword := get_parent().find_child("SwordController", true, false) as SwordController
	if sword != null:
		sword.hit_confirmed.connect(_on_hit_confirmed)


func _process(delta: float) -> void:
	_hit_flash_alpha = move_toward(_hit_flash_alpha, 0.0, delta * 7.5)
	_damage_flash_alpha = move_toward(_damage_flash_alpha, 0.0, delta * 4.5)
	_set_flash_alpha(_hit_flash, _hit_flash_alpha)
	_set_flash_alpha(_damage_flash, _damage_flash_alpha)
	if _camera == null:
		return
	_impact_remaining = maxf(0.0, _impact_remaining - delta)
	if _impact_remaining > 0.0:
		var falloff := _impact_remaining / maxf(_impact_duration, 0.001)
		var phase := Time.get_ticks_msec() * 0.095
		_camera.h_offset = _base_h_offset + sin(phase) * _impact_strength * falloff
		_camera.v_offset = _base_v_offset + cos(phase * 1.37) * _impact_strength * falloff
	else:
		_camera.h_offset = move_toward(_camera.h_offset, _base_h_offset, delta * 0.8)
		_camera.v_offset = move_toward(_camera.v_offset, _base_v_offset, delta * 0.8)


func _exit_tree() -> void:
	if _camera != null:
		_camera.h_offset = _base_h_offset
		_camera.v_offset = _base_v_offset


func _make_flash(color: Color) -> ColorRect:
	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = color
	add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return flash


func _set_flash_alpha(flash: ColorRect, alpha: float) -> void:
	if flash == null:
		return
	var color := flash.color
	color.a = alpha
	flash.color = color


func _begin_impact(duration: float, strength: float) -> void:
	_impact_duration = duration
	_impact_remaining = duration
	_impact_strength = strength


func _on_hit_confirmed(_target: Node, _damage: int) -> void:
	_hit_flash_alpha = 0.16
	_begin_impact(hit_impact_duration, hit_camera_offset)


func _on_player_damaged(_amount: int) -> void:
	_damage_flash_alpha = 0.28
	_begin_impact(damage_impact_duration, damage_camera_offset)


func _on_health_changed(current: int, maximum: int) -> void:
	if current < maximum:
		return
	_hit_flash_alpha = 0.0
	_damage_flash_alpha = 0.0
	_impact_remaining = 0.0
	if _camera != null:
		_camera.h_offset = _base_h_offset
		_camera.v_offset = _base_v_offset
