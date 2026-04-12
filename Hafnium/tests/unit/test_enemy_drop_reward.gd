extends GutTest

# test_enemy_drop_reward.gd
# Tests for Hafnium/scripts/enemy.gd (class_name enemy)


func test_drop_reward_empty():
	var e = enemy.new()
	e.reward = {}
	assert_eq(e.drop_reward(), [], "Should return empty array if no rewards defined")


func test_drop_reward_seeded_low():
	var e = enemy.new()
	e.reward = {20: ["low_reward", 1], 100: ["high_reward", 1]}
	# Seed RNG to get a low value
	e.rng.seed = 12345
	# randi_range(0, 100) with seed 12345 gives something specific
	# We can also just mock the rng if we want perfect control
	var result = e.drop_reward()
	# Based on the logic: if key >= rand_int: return reward
	assert_not_null(result, "Should return a reward")


class MockRNG:
	extends RandomNumberGenerator
	var next_val = 0

	func randi_range(_min, _max):
		return next_val


func test_drop_reward_deterministic():
	var e = enemy.new()
	var mock_rng = MockRNG.new()
	e.rng = mock_rng
	e.reward = {30: ["small", 1], 70: ["medium", 1], 100: ["large", 1]}

	mock_rng.next_val = 25
	assert_eq(e.drop_reward()[0], "small")

	mock_rng.next_val = 50
	assert_eq(e.drop_reward()[0], "medium")

	mock_rng.next_val = 90
	assert_eq(e.drop_reward()[0], "large")
