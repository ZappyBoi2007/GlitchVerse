class_name PlayerHealth
extends Node

signal health_changed(current_health: int, maximum_health: int)
signal damaged(amount: int)
signal player_defeated

@export_range(1, 10, 1) var maximum_health := 3
@export_range(0.0, 3.0, 0.05) var invulnerability_seconds := 0.65

var current_health := 3
var _invulnerability_remaining := 0.0
var _defeated := false


func _ready() -> void:
	current_health = maximum_health
	add_to_group("player_health")
	call_deferred("_emit_initial_state")


func _process(delta: float) -> void:
	_invulnerability_remaining = maxf(0.0, _invulnerability_remaining - delta)


func take_damage(amount: int, _source: Node = null) -> bool:
	if amount <= 0 or _defeated or _invulnerability_remaining > 0.0:
		return false
	current_health = maxi(0, current_health - amount)
	_invulnerability_remaining = invulnerability_seconds
	damaged.emit(amount)
	health_changed.emit(current_health, maximum_health)
	_play_hurt_audio()
	if current_health == 0:
		_defeated = true
		player_defeated.emit()
	return true


func is_defeated() -> bool:
	return _defeated


func reset_health() -> void:
	current_health = maximum_health
	_invulnerability_remaining = 0.0
	_defeated = false
	health_changed.emit(current_health, maximum_health)


func _emit_initial_state() -> void:
	health_changed.emit(current_health, maximum_health)


func _play_hurt_audio() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_sfx(&"player_hurt", -4.0)
