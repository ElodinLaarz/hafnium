extends GutTest

const INFINITE_ROOM_SCRIPT = preload("res://scripts/levels/infinite_room.gd")

var _previous_run_context: RunContext


class MockFailedRunContext:
	extends RefCounted

	var spawn_calls: Array[Vector2] = []

	func spawn_enemy(_enemy_id: String, spawn_position: Vector2) -> Enemy:
		spawn_calls.append(spawn_position)
		return null


func before_each() -> void:
	_previous_run_context = Common.run_context


func after_each() -> void:
	Common.run_context = _previous_run_context


func test_room_size_scales_with_room_index() -> void:
	var room = INFINITE_ROOM_SCRIPT.new()
	room.room_scale_tiles = 10
	room.tile_size = 16

	assert_eq(room.get_room_size_tiles(3), Vector2i(30, 30))
	assert_eq(room.get_room_half_extents(3), Vector2(240, 240))


func test_spawn_positions_match_room_index_and_stay_inside_room() -> void:
	var room = INFINITE_ROOM_SCRIPT.new()
	room.room_scale_tiles = 12
	room.tile_size = 16
	room.spawn_margin = 48.0

	var positions: Array[Vector2] = room.build_spawn_positions(9)
	var max_spawn_radius: float = (
		min(room.get_room_half_extents(9).x, room.get_room_half_extents(9).y) - room.spawn_margin
	)

	assert_eq(positions.size(), 9)
	for position: Vector2 in positions:
		assert_gt(position.length(), 0.0, "Spawn points should not overlap the player spawn")
		assert_lte(position.length(), max_spawn_radius + 0.001)


func test_spawn_positions_stay_inside_small_rooms_with_large_spawn_margin() -> void:
	var room = INFINITE_ROOM_SCRIPT.new()
	room.room_scale_tiles = 1
	room.tile_size = 16
	room.spawn_margin = 20.0

	var room_index: int = 1
	var positions: Array[Vector2] = room.build_spawn_positions(room_index)
	var half_extents: Vector2 = room.get_room_half_extents(room_index)

	assert_lt(
		min(half_extents.x, half_extents.y) - room.spawn_margin,
		0.0,
		"Test setup should exercise the clamped spawn-radius edge case"
	)
	assert_eq(positions.size(), room_index)
	for position: Vector2 in positions:
		assert_lte(absf(position.x), half_extents.x + 0.001)
		assert_lte(absf(position.y), half_extents.y + 0.001)


func test_failed_enemy_spawns_schedule_room_advance() -> void:
	var room = INFINITE_ROOM_SCRIPT.new()
	var mock_run_context: MockFailedRunContext = MockFailedRunContext.new()
	Common.run_context = mock_run_context

	room._spawn_wave(3)

	assert_eq(mock_run_context.spawn_calls.size(), 3)
	assert_eq(room.remaining_enemies, 0)
	assert_true(
		room._advance_scheduled, "Room progression should auto-advance when every enemy spawn fails"
	)


func test_enemy_defeated_only_counts_active_wave_members() -> void:
	var room = INFINITE_ROOM_SCRIPT.new()
	var tracked_enemy: Enemy = Enemy.new()
	var stale_enemy: Enemy = Enemy.new()

	room.current_room_index = 2
	room.remaining_enemies = 1
	room._active_wave_enemy_ids[tracked_enemy.get_instance_id()] = true

	room._on_enemy_defeated(stale_enemy)

	assert_eq(room.remaining_enemies, 1, "Untracked enemies should not affect wave progress")
	assert_false(room._advance_scheduled)

	room._on_enemy_defeated(tracked_enemy)

	assert_eq(room.remaining_enemies, 0)
	assert_true(room._advance_scheduled)
