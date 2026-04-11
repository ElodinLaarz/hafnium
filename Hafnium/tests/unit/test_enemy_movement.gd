extends GutTest

# test_enemy_movement.gd
# Tests for Hafnium/scripts/enemy_movement.gd (class_name EnemyMovement)

func test_get_direction_no_player():
	var em = EnemyMovement.new()
	var dir = em.get_direction(Vector2(10, 10), null)
	assert_eq(dir, Vector2.ZERO, "Direction should be zero if player is null")

func test_get_direction_to_player():
	var em = EnemyMovement.new()
	# Player is at (20, 10), Enemy is at (10, 10)
	# Direction is (1, 0)
	var dir = em.get_direction(Vector2(10, 10), { "position": Vector2(20, 10) })
	assert_eq(dir, Vector2(1, 0), "Direction should be normalized vector pointing to player")

func test_velocity_lerp():
	var em = EnemyMovement.new()
	em.set_idle_speed() # 30 by default
	var start_v = Vector2.ZERO
	var dir = Vector2(1, 0)
	var next_v = em.velocity_lerp(0.1, start_v, dir)
	# lerp(0, 30, 0.1 * 5.0) -> lerp(0, 30, 0.5) = 15
	assert_eq(next_v, Vector2(15, 0), "Velocity should lerp toward target speed")
