extends GutTest


func test_default_preset_values_are_balanced() -> void:
	var profile: FeelTuningProfile = FeelTuningProfile.new()
	assert_eq(profile.get_active_preset(), FeelTuningProfile.PRESET_BALANCED)
	assert_almost_eq(profile.walk_speed, 85.0, 0.001)
	assert_almost_eq(profile.attack_buffer_window, 0.12, 0.001)


func test_apply_preset_changes_values() -> void:
	var profile: FeelTuningProfile = FeelTuningProfile.new()
	profile.apply_preset(FeelTuningProfile.PRESET_SNAPPY)
	assert_eq(profile.get_active_preset(), FeelTuningProfile.PRESET_SNAPPY)
	assert_almost_eq(profile.accel, 16.0, 0.001)
	assert_almost_eq(profile.run_multiplier, 2.0, 0.001)


func test_clamping_protects_out_of_range_values() -> void:
	var profile: FeelTuningProfile = FeelTuningProfile.new()
	profile.set_float_value("hit_stop_time_scale", -5.0)
	profile.set_float_value("walk_speed", 9999.0)
	profile.set_float_value("projectile_life_multiplier", 99.0)
	assert_almost_eq(profile.hit_stop_time_scale, 0.05, 0.001)
	assert_almost_eq(profile.walk_speed, 220.0, 0.001)
	assert_almost_eq(profile.projectile_life_multiplier, 3.0, 0.001)


func test_modified_state_tracks_changes_from_preset() -> void:
	var profile: FeelTuningProfile = FeelTuningProfile.new()
	assert_false(profile.is_modified_from_preset())
	profile.set_float_value("accel", profile.accel + 1.0)
	assert_true(profile.is_modified_from_preset())
