class_name NullSpindleFragments
extends Node

## NULL SPINDLE-local collection objective. The reusable pickup has no knowledge
## of puzzle completion, scoring, or exits.

signal fragment_progress_changed(collected: int, required: int, total: int)
signal fragment_requirement_met

@export_range(1, 99, 1) var required_fragments := 2
@export var fragment_paths: Array[NodePath] = []

var _collected_ids: Dictionary = {}
var _fragments: Array[RealityFragment] = []
var _requirement_reported := false


func _ready() -> void:
	for fragment_path in fragment_paths:
		var fragment := get_node_or_null(fragment_path) as RealityFragment
		if fragment == null:
			push_error("NULL SPINDLE fragment path is invalid: %s" % fragment_path)
			continue
		_fragments.append(fragment)
		fragment.fragment_collected.connect(_on_fragment_collected)
	call_deferred("_emit_progress")


func get_collected_count() -> int:
	return _collected_ids.size()


func get_required_count() -> int:
	return required_fragments


func get_total_count() -> int:
	return _fragments.size()


func has_required_fragments() -> bool:
	return get_collected_count() >= required_fragments


func get_snapshot() -> Dictionary:
	return {
		"collected": get_collected_count(),
		"required": required_fragments,
		"total": get_total_count(),
		"requirement_met": has_required_fragments(),
	}


func _on_fragment_collected(fragment_id: StringName) -> void:
	if fragment_id in _collected_ids:
		return
	_collected_ids[fragment_id] = true
	_emit_progress()
	if has_required_fragments() and not _requirement_reported:
		_requirement_reported = true
		fragment_requirement_met.emit()
		var audio := get_node_or_null("/root/AudioManager")
		if audio != null:
			audio.play_sfx(&"fragment_requirement", -5.0, 1.0)


func _emit_progress() -> void:
	fragment_progress_changed.emit(get_collected_count(), required_fragments, get_total_count())
