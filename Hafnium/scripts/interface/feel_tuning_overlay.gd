extends Control

const GameConstants = preload("res://scripts/config/game_constants.gd")

var _profile: FeelTuningProfile
var _is_refreshing: bool = false
var _status_label: Label
var _value_labels: Dictionary = {}
var _slider_map: Dictionary = {}
var _toggle_map: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_profile = Common.get_feel_tuning()
	if _profile == null:
		return
	if not _profile.changed.is_connected(_on_profile_changed):
		_profile.changed.connect(_on_profile_changed)
	_bind_controls()
	_refresh_from_profile()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(GameConstants.INPUT_ACTION_TOGGLE_FEEL_TUNING):
		visible = not visible
		accept_event()


func _bind_controls() -> void:
	_status_label = get_node("Panel/Container/Header/Status")
	_bind_preset_button(
		"Panel/Container/Header/PresetButtons/Balanced", FeelTuningProfile.PRESET_BALANCED
	)
	_bind_preset_button(
		"Panel/Container/Header/PresetButtons/Snappy", FeelTuningProfile.PRESET_SNAPPY
	)
	_bind_preset_button(
		"Panel/Container/Header/PresetButtons/Heavy", FeelTuningProfile.PRESET_HEAVY
	)
	var reset_button: Button = get_node("Panel/Container/Header/PresetButtons/Reset")
	reset_button.pressed.connect(func() -> void: _profile.reset_defaults())

	_register_slider("Panel/Container/Scroll/Margin/Rows/WalkSpeed", "walk_speed")
	_register_slider("Panel/Container/Scroll/Margin/Rows/RunMultiplier", "run_multiplier")
	_register_slider("Panel/Container/Scroll/Margin/Rows/Accel", "accel")
	_register_slider("Panel/Container/Scroll/Margin/Rows/Decel", "decel")
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/TurnAccelMultiplier", "turn_accel_multiplier"
	)
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/RunDoubleTapWindow", "run_double_tap_window"
	)
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/AttackBufferWindow", "attack_buffer_window"
	)
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/AttackMoveSlowMultiplier", "attack_move_slow_multiplier"
	)
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/AttackMoveSlowTime", "attack_move_slow_time"
	)
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/ProjectileLifeMultiplier", "projectile_life_multiplier"
	)
	_register_slider("Panel/Container/Scroll/Margin/Rows/HitStopDuration", "hit_stop_duration")
	_register_slider("Panel/Container/Scroll/Margin/Rows/HitStopTimeScale", "hit_stop_time_scale")
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/ScreenShakeIntensity", "screen_shake_intensity"
	)
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/ScreenShakeDuration", "screen_shake_duration"
	)
	_register_slider("Panel/Container/Scroll/Margin/Rows/CritChance", "crit_chance")
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/CritDamageMultiplier", "crit_damage_multiplier"
	)
	_register_slider(
		"Panel/Container/Scroll/Margin/Rows/CritFeedbackMultiplier", "crit_feedback_multiplier"
	)

	_register_toggle("Panel/Container/Scroll/Margin/Rows/EnableHitStop", "enable_hit_stop")
	_register_toggle("Panel/Container/Scroll/Margin/Rows/EnableScreenShake", "enable_screen_shake")


func _register_slider(path: String, key: String) -> void:
	var row: HBoxContainer = get_node(path)
	var label: Label = row.get_node("Label")
	var slider: HSlider = row.get_node("Slider")
	var value_label: Label = row.get_node("Value")
	label.custom_minimum_size.x = 120.0
	value_label.custom_minimum_size.x = 52.0
	_slider_map[key] = slider
	_value_labels[key] = value_label
	slider.value_changed.connect(
		func(new_value: float) -> void:
			if _is_refreshing:
				return
			_profile.set_float_value(key, new_value)
	)


func _register_toggle(path: String, key: String) -> void:
	var row: HBoxContainer = get_node(path)
	var check_button: CheckButton = row.get_node("Toggle")
	_toggle_map[key] = check_button
	check_button.toggled.connect(
		func(enabled: bool) -> void:
			if _is_refreshing:
				return
			_profile.set_bool_value(key, enabled)
	)


func _bind_preset_button(path: String, preset_name: String) -> void:
	var preset_button: Button = get_node(path)
	preset_button.pressed.connect(func() -> void: _profile.apply_preset(preset_name))


func _on_profile_changed() -> void:
	_refresh_from_profile()


func _refresh_from_profile() -> void:
	if _profile == null:
		return
	_is_refreshing = true
	for key: String in _slider_map.keys():
		var slider: HSlider = _slider_map[key]
		var value: float = float(_profile.get(key))
		slider.value = value
		var value_label: Label = _value_labels[key]
		value_label.text = "%.2f" % value
	for key: String in _toggle_map.keys():
		var check_button: CheckButton = _toggle_map[key]
		check_button.button_pressed = bool(_profile.get(key))
	if _status_label != null:
		var modified_suffix: String = " (modified)" if _profile.is_modified_from_preset() else ""
		_status_label.text = (
			"Preset: %s%s" % [_profile.get_active_preset().capitalize(), modified_suffix]
		)
	_is_refreshing = false
