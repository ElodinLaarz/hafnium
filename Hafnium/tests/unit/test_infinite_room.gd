extends GutTest

const INFINITE_ROOM_SCRIPT = preload("res://scripts/levels/infinite_room.gd")


func test_room_size_scales_with_room_index():
	var room = INFINITE_ROOM_SCRIPT.new()
	room.room_scale_tiles = 10
	room.tile_size = 16

	assert_eq(room.get_room_size_tiles(3), Vector2i(30, 30))
	assert_eq(room.get_room_half_extents(3), Vector2(240, 240))


func test_spawn_positions_match_room_index_and_stay_inside_room():
	var room = INFINITE_ROOM_SCRIPT.new()
	room.room_scale_tiles = 12
	room.tile_size = 16
	room.spawn_margin = 48.0

	var positions: Array[Vector2] = room.build_spawn_positions(9)
	var max_spawn_radius: float = (
		min(room.get_room_half_extents(9).x, room.get_room_half_extents(9).y) - room.spawn_margin
	)

	assert_eq(positions.size(), 9)
	for position in positions:
		assert_gt(position.length(), 0.0, "Spawn points should not overlap the player spawn")
		assert_lte(position.length(), max_spawn_radius + 0.001)
