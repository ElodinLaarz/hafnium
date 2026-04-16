extends Node2D

const NORMAL_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const CRIT_COLOR: Color = Color(1.0, 0.88, 0.3, 1.0)

var _pending_value: int = 0
var _pending_is_crit: bool = false
var _has_pending_setup: bool = false
@onready var _label: Label = $Label


func _ready() -> void:
	_apply_setup_if_ready()
	var travel: Vector2 = Vector2(randf_range(-8.0, 8.0), randf_range(-32.0, -48.0))
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + travel, 0.45)
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.finished.connect(queue_free)


func setup(value: int, is_crit: bool) -> void:
	_pending_value = value
	_pending_is_crit = is_crit
	_has_pending_setup = true
	_apply_setup_if_ready()


func _apply_setup_if_ready() -> void:
	if _label == null or not _has_pending_setup:
		return
	_label.text = str(_pending_value)
	if _pending_is_crit:
		_label.modulate = CRIT_COLOR
		_label.scale = Vector2(1.4, 1.4)
	else:
		_label.modulate = NORMAL_COLOR
		_label.scale = Vector2.ONE
	_has_pending_setup = false
