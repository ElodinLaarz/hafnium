extends GutTest

# test_stats.gd
# Tests for Hafnium/scripts/stats/stats_handler.gd (class_name Stats)


func test_take_damage_reduces_health() -> void:
	var s: Variant = Stats.new()
	s.max_health = 10
	s.current_health = 10
	s.take_damage(3)
	assert_eq(s.current_health, 7, "Health should be 7 after 3 damage")


func test_take_damage_returns_true_on_death() -> void:
	var s: Variant = Stats.new()
	s.max_health = 10
	s.current_health = 5
	var killed: Variant = s.take_damage(5)
	assert_true(killed, "take_damage should return true on lethal damage")
	assert_eq(s.current_health, 0, "Health should be 0 on death")


func test_take_damage_clamps_at_zero() -> void:
	var s: Variant = Stats.new()
	s.current_health = 2
	s.take_damage(10)
	assert_eq(s.current_health, 0, "Health should not go below 0")


func test_health_setters_clamp_and_emit_only_on_change() -> void:
	var s: Variant = Stats.new()
	var emissions: Array = []
	s.health_changed.connect(
		func(new_health: int, max_health: int) -> void: emissions.append([new_health, max_health])
	)

	s.max_health = 10
	s.max_health = 10
	s.current_health = 5
	s.current_health = -3
	s.current_health = -3

	assert_eq(s.max_health, 10, "Max health should be stored")
	assert_eq(s.current_health, 0, "Current health should clamp at zero")
	assert_eq(emissions.size(), 3, "Health should emit once per actual stored-value change")


func test_max_health_clamps_current_health_when_lowered() -> void:
	var s: Variant = Stats.new()
	s.max_health = 10
	s.current_health = 8
	s.max_health = 4

	assert_eq(s.max_health, 4, "Max health should update")
	assert_eq(s.current_health, 4, "Current health should clamp when max health is lowered")


func test_resource_status_update_rate() -> void:
	# ResourceStatus is an inner class of Stats
	var rs: Variant = Stats.ResourceStatus.new(Stats.ClassResource.BOMB, 3, 0.5)  # 0.5 recovery/sec
	rs.current_resource = 0
	rs.update(1.0)  # 1 second passed
	assert_eq(rs.recovery_progress, 0.5, "Recovery progress should be 0.5")
	rs.update(1.0)  # another second passed
	assert_eq(rs.current_resource, 1, "Resource should have incremented")
	assert_eq(rs.recovery_progress, 0.0, "Recovery progress should reset")


func test_resource_status_max_clamp() -> void:
	var rs: Variant = Stats.ResourceStatus.new(Stats.ClassResource.BOMB, 1, 10.0)
	rs.current_resource = 1
	rs.update(1.0)
	assert_eq(rs.current_resource, 1, "Should not exceed max_resource")


func test_attack_cooldown_update() -> void:
	var s: Variant = Stats.new()
	s.attack_cooldown = 1.0
	s.update(0.4)
	assert_almost_eq(s.attack_cooldown, 0.6, 0.001, "Cooldown should decrement by delta")
