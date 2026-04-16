class_name MainCamera
extends Camera2D

var _base_offset: Vector2
var _shake_time_remaining: float = 0.0
var _shake_duration: float = 0.0
var _shake_intensity: float = 0.0


func _ready() -> void:
	_base_offset = offset


func _process(delta: float) -> void:
	if _shake_time_remaining <= 0:
		offset = _base_offset
		_shake_intensity = 0.0
		return
	_shake_time_remaining = max(_shake_time_remaining - delta, 0.0)
	var normalized_time: float = _shake_time_remaining / max(_shake_duration, 0.001)
	var magnitude: float = _shake_intensity * normalized_time
	offset = (
		_base_offset
		+ Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude))
	)


func trigger_shake(intensity: float, duration: float) -> void:
	_shake_duration = max(_shake_duration, clampf(duration, 0.0, 0.4))
	_shake_time_remaining = max(_shake_time_remaining, _shake_duration)
	_shake_intensity = max(_shake_intensity, clampf(intensity, 0.0, 12.0))
