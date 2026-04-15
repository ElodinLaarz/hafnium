extends GutTest

# test_player_movement.gd
# Tests for Hafnium/scripts/singleplayer/movement.gd (class_name PlayerMovement)


# Mock class to override input
class MockPlayerMovement:
	extends PlayerMovement
	var mock_raw_input: Vector2 = Vector2.ZERO
	var mock_just_pressed: Dictionary = {}
	var mock_strength: Dictionary = {}

	func get_raw_input() -> Vector2:
		return mock_raw_input

	func is_action_just_pressed(action: String) -> bool:
		return mock_just_pressed.get(action, false)

	func get_action_strength(action: String) -> float:
		return mock_strength.get(action, 0.0)


func test_unit_direction_normalization() -> void:
	var pm: MockPlayerMovement = MockPlayerMovement.new()
	pm.mock_raw_input = Vector2(1, 1)  # Diagonal
	var dir: Vector2 = pm.unit_direction()
	assert_almost_eq(dir.length(), 1.0, 0.001, "Unit direction should be normalized")
	assert_almost_eq(dir.x, 0.707, 0.001)


func test_check_is_running_double_tap() -> void:
	var pm: MockPlayerMovement = MockPlayerMovement.new()
	# First tap
	pm.mock_just_pressed["up"] = true
	pm.check_is_running(0.1, 0.0)
	pm.mock_just_pressed["up"] = false

	# Wait a bit
	pm.check_is_running(0.1, 0.0)

	# Second tap within threshold (0.5)
	pm.mock_just_pressed["up"] = true
	var running: bool = pm.check_is_running(0.1, 0.0)
	assert_true(running, "Should start running after double tap")


func test_check_is_running_stop_threshold() -> void:
	var pm: MockPlayerMovement = MockPlayerMovement.new()
	pm.is_running = true
	# No keys pressed, speed drops below threshold (85 * 0.5 = 42.5)
	var running: bool = pm.check_is_running(0.1, 10.0)
	assert_false(running, "Should stop running when speed is below threshold and no keys pressed")


func test_velocity_lerp_walking() -> void:
	var pm: MockPlayerMovement = MockPlayerMovement.new()
	pm.set_max_speed_walk()  # 85
	var next_v: Vector2 = pm.velocity_lerp(0.1, Vector2.ZERO, Vector2(1, 0))
	# Blend factor is clamped, so with delta * accel = 1.0 velocity reaches target.
	assert_eq(next_v, Vector2(85, 0), "Velocity should reach target speed at delta * ACCEL = 1.0")


func test_velocity_lerp_decelerates_when_no_input() -> void:
	var pm: MockPlayerMovement = MockPlayerMovement.new()
	var next_v: Vector2 = pm.velocity_lerp(0.1, Vector2(40, 0), Vector2.ZERO)
	assert_lt(next_v.length(), 40.0, "Velocity should decay when no movement input is active")
