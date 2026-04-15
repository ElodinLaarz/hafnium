class_name FeelTuningProfile
extends RefCounted

signal changed

const PRESET_BALANCED: String = "balanced"
const PRESET_SNAPPY: String = "snappy"
const PRESET_HEAVY: String = "heavy"

var walk_speed: float = 85.0
var run_multiplier: float = 1.8
var accel: float = 10.0
var decel: float = 24.0
var turn_accel_multiplier: float = 1.25
var run_double_tap_window: float = 0.5

var attack_buffer_window: float = 0.12
var attack_move_slow_multiplier: float = 0.85
var attack_move_slow_time: float = 0.1
var projectile_life_multiplier: float = 1.0

var enable_hit_stop: bool = true
var hit_stop_duration: float = 0.05
var hit_stop_time_scale: float = 0.2
var enable_screen_shake: bool = true
var screen_shake_intensity: float = 2.5
var screen_shake_duration: float = 0.08
var crit_chance: float = 0.5
var crit_damage_multiplier: float = 2.0
var crit_feedback_multiplier: float = 1.75

var _active_preset: String = PRESET_BALANCED
var _suppress_signal: bool = false


func _init() -> void:
	apply_preset(PRESET_BALANCED)


func get_active_preset() -> String:
	return _active_preset


func get_preset_names() -> Array[String]:
	return [PRESET_BALANCED, PRESET_SNAPPY, PRESET_HEAVY]


func is_modified_from_preset() -> bool:
	var preset_values: Dictionary = _get_preset_values(_active_preset)
	return not _matches_values(preset_values)


func reset_defaults() -> void:
	apply_preset(PRESET_BALANCED)


func apply_preset(preset_name: String) -> void:
	var safe_name: String = preset_name
	if not _get_preset_names_dictionary().has(safe_name):
		safe_name = PRESET_BALANCED
	_active_preset = safe_name
	_suppress_signal = true
	_apply_values(_get_preset_values(safe_name))
	_suppress_signal = false
	emit_changed()


func set_float_value(key: String, value: float) -> void:
	match key:
		"walk_speed":
			walk_speed = value
		"run_multiplier":
			run_multiplier = value
		"accel":
			accel = value
		"decel":
			decel = value
		"turn_accel_multiplier":
			turn_accel_multiplier = value
		"run_double_tap_window":
			run_double_tap_window = value
		"attack_buffer_window":
			attack_buffer_window = value
		"attack_move_slow_multiplier":
			attack_move_slow_multiplier = value
		"attack_move_slow_time":
			attack_move_slow_time = value
		"projectile_life_multiplier":
			projectile_life_multiplier = value
		"hit_stop_duration":
			hit_stop_duration = value
		"hit_stop_time_scale":
			hit_stop_time_scale = value
		"screen_shake_intensity":
			screen_shake_intensity = value
		"screen_shake_duration":
			screen_shake_duration = value
		"crit_chance":
			crit_chance = value
		"crit_damage_multiplier":
			crit_damage_multiplier = value
		"crit_feedback_multiplier":
			crit_feedback_multiplier = value
		_:
			return
	clamp_values()
	emit_changed()


func set_bool_value(key: String, value: bool) -> void:
	match key:
		"enable_hit_stop":
			enable_hit_stop = value
		"enable_screen_shake":
			enable_screen_shake = value
		_:
			return
	emit_changed()


func emit_changed() -> void:
	if _suppress_signal:
		return
	changed.emit()


func clamp_values() -> void:
	walk_speed = clampf(walk_speed, 20.0, 220.0)
	run_multiplier = clampf(run_multiplier, 1.0, 3.0)
	accel = clampf(accel, 1.0, 30.0)
	decel = clampf(decel, 1.0, 40.0)
	turn_accel_multiplier = clampf(turn_accel_multiplier, 0.5, 3.0)
	run_double_tap_window = clampf(run_double_tap_window, 0.1, 1.0)
	attack_buffer_window = clampf(attack_buffer_window, 0.0, 0.35)
	attack_move_slow_multiplier = clampf(attack_move_slow_multiplier, 0.2, 1.0)
	attack_move_slow_time = clampf(attack_move_slow_time, 0.0, 0.4)
	projectile_life_multiplier = clampf(projectile_life_multiplier, 0.25, 3.0)
	hit_stop_duration = clampf(hit_stop_duration, 0.0, 0.2)
	hit_stop_time_scale = clampf(hit_stop_time_scale, 0.05, 1.0)
	screen_shake_intensity = clampf(screen_shake_intensity, 0.0, 12.0)
	screen_shake_duration = clampf(screen_shake_duration, 0.0, 0.4)
	crit_chance = clampf(crit_chance, 0.0, 1.0)
	crit_damage_multiplier = clampf(crit_damage_multiplier, 1.0, 5.0)
	crit_feedback_multiplier = clampf(crit_feedback_multiplier, 1.0, 3.0)


func _apply_values(values: Dictionary) -> void:
	for key: String in values.keys():
		var value: Variant = values[key]
		if value is bool:
			set_bool_value(key, value)
		else:
			set_float_value(key, float(value))
	clamp_values()


func _matches_values(values: Dictionary) -> bool:
	for key: String in values.keys():
		var expected: Variant = values[key]
		var actual: Variant = get(key)
		if expected is bool:
			if actual != expected:
				return false
		elif abs(float(actual) - float(expected)) > 0.001:
			return false
	return true


func _get_preset_names_dictionary() -> Dictionary:
	return {
		PRESET_BALANCED: true,
		PRESET_SNAPPY: true,
		PRESET_HEAVY: true,
	}


func _get_preset_values(preset_name: String) -> Dictionary:
	match preset_name:
		PRESET_SNAPPY:
			return {
				"walk_speed": 92.0,
				"run_multiplier": 2.0,
				"accel": 16.0,
				"decel": 28.0,
				"turn_accel_multiplier": 1.7,
				"run_double_tap_window": 0.35,
				"attack_buffer_window": 0.1,
				"attack_move_slow_multiplier": 0.92,
				"attack_move_slow_time": 0.05,
				"projectile_life_multiplier": 0.9,
				"enable_hit_stop": true,
				"hit_stop_duration": 0.04,
				"hit_stop_time_scale": 0.28,
				"enable_screen_shake": true,
				"screen_shake_intensity": 2.0,
				"screen_shake_duration": 0.05,
				"crit_chance": 0.5,
				"crit_damage_multiplier": 1.8,
				"crit_feedback_multiplier": 1.6,
			}
		PRESET_HEAVY:
			return {
				"walk_speed": 76.0,
				"run_multiplier": 1.65,
				"accel": 8.0,
				"decel": 20.0,
				"turn_accel_multiplier": 1.1,
				"run_double_tap_window": 0.6,
				"attack_buffer_window": 0.15,
				"attack_move_slow_multiplier": 0.75,
				"attack_move_slow_time": 0.15,
				"projectile_life_multiplier": 1.2,
				"enable_hit_stop": true,
				"hit_stop_duration": 0.07,
				"hit_stop_time_scale": 0.16,
				"enable_screen_shake": true,
				"screen_shake_intensity": 3.5,
				"screen_shake_duration": 0.1,
				"crit_chance": 0.5,
				"crit_damage_multiplier": 2.2,
				"crit_feedback_multiplier": 2.0,
			}
		_:
			return {
				"walk_speed": 85.0,
				"run_multiplier": 1.8,
				"accel": 10.0,
				"decel": 24.0,
				"turn_accel_multiplier": 1.25,
				"run_double_tap_window": 0.5,
				"attack_buffer_window": 0.12,
				"attack_move_slow_multiplier": 0.85,
				"attack_move_slow_time": 0.1,
				"projectile_life_multiplier": 1.0,
				"enable_hit_stop": true,
				"hit_stop_duration": 0.05,
				"hit_stop_time_scale": 0.2,
				"enable_screen_shake": true,
				"screen_shake_intensity": 2.5,
				"screen_shake_duration": 0.08,
				"crit_chance": 0.5,
				"crit_damage_multiplier": 2.0,
				"crit_feedback_multiplier": 1.75,
			}
