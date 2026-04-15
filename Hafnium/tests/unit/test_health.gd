extends GutTest

# test_health.gd
# Tests for Hafnium/scripts/stats/health.gd (class_name Health)


func test_bounds_ok_valid_barbarian() -> void:
	var h: Variant = Health.new()
	var s: Variant = Stats.new()
	s.max_health = 12
	s.current_health = 12
	s.health_to_damage_multiplier = 4
	assert_true(h.bounds_ok(s, 3), "Barbarian with 12hp/4mult should be ok with 3 hearts")


func test_bounds_ok_valid_wizard() -> void:
	var h: Variant = Health.new()
	var s: Variant = Stats.new()
	s.max_health = 4
	s.current_health = 4
	s.health_to_damage_multiplier = 2
	assert_true(h.bounds_ok(s, 2), "Wizard with 4hp/2mult should be ok with 2 hearts")


func test_bounds_ok_invalid_heart_count() -> void:
	var h: Variant = Health.new()
	var s: Variant = Stats.new()
	s.max_health = 6
	s.health_to_damage_multiplier = 2  # Expected 3 hearts
	assert_false(h.bounds_ok(s, 5), "Should fail if num_hearts doesn't match expected hearts")


func test_bounds_ok_indivisible_max_health() -> void:
	var h: Variant = Health.new()
	var s: Variant = Stats.new()
	s.max_health = 7
	s.health_to_damage_multiplier = 2
	assert_false(h.bounds_ok(s, 3), "Should fail if max_health is not divisible by multiplier")


func test_bounds_ok_over_max_health() -> void:
	var h: Variant = Health.new()
	var s: Variant = Stats.new()
	s.max_health = 10
	s.current_health = 11
	s.health_to_damage_multiplier = 2
	assert_false(h.bounds_ok(s, 5), "Should fail if current_health > max_health")


func test_current_health_clamps_negative_values_to_zero() -> void:
	var h: Variant = Health.new()
	var s: Variant = Stats.new()
	s.max_health = 10
	s.current_health = -1
	s.health_to_damage_multiplier = 2
	assert_eq(s.current_health, 0, "Setter should clamp current health to zero")
	assert_true(h.bounds_ok(s, 5), "Clamped zero health should still satisfy bounds checks")
