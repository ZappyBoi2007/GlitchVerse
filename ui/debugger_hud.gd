extends CanvasLayer

## Replaceable prototype HUD adapter. The debugger itself has no UI dependency.

@onready var ability_label: Label = $DebuggerPanel/Ability
@onready var target_label: Label = $DebuggerPanel/Target
@onready var feedback_label: Label = $DebuggerPanel/Feedback
@onready var crosshair_horizontal: ColorRect = $Crosshair/Horizontal
@onready var crosshair_vertical: ColorRect = $Crosshair/Vertical

var _debugger: RealityDebugger
var _ability_color := Color("25ecff")


func _ready() -> void:
	call_deferred("_connect_debugger")


func _connect_debugger() -> void:
	_debugger = get_tree().get_first_node_in_group("reality_debugger") as RealityDebugger
	if _debugger == null:
		ability_label.text = "REALITY DEBUGGER // OFFLINE"
		feedback_label.text = "Debugger component not found."
		return
	_debugger.ability_changed.connect(_on_ability_changed)
	_debugger.target_changed.connect(_on_target_changed)
	_debugger.feedback_changed.connect(_on_feedback_changed)
	_on_ability_changed(_debugger.get_selected_ability_label(), _debugger.get_selected_ability_color())


func _on_ability_changed(ability_name: String, color: Color) -> void:
	_ability_color = color
	ability_label.text = "REALITY DEBUGGER // %s" % ability_name
	ability_label.modulate = color
	_set_crosshair_color(color)


func _on_target_changed(target_name: String, compatible: bool, has_target: bool) -> void:
	target_label.text = "TARGET // %s" % target_name
	if not has_target:
		target_label.modulate = Color("8190a8")
		_set_crosshair_color(_ability_color)
	elif compatible:
		target_label.modulate = Color("69ff9f")
		_set_crosshair_color(Color("69ff9f"))
	else:
		target_label.modulate = Color("ff596d")
		_set_crosshair_color(Color("ff596d"))


func _on_feedback_changed(message: String, is_error: bool) -> void:
	feedback_label.text = message
	feedback_label.modulate = Color("ff7183") if is_error else Color("c7e9ff")


func _set_crosshair_color(color: Color) -> void:
	crosshair_horizontal.color = color
	crosshair_vertical.color = color
