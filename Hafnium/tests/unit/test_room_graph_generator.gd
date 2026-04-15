extends GutTest

const ROOM_GRAPH_GENERATOR_SCRIPT = preload("res://scripts/rooms/room_graph_generator.gd")


func test_generate_floor_returns_seeded_three_room_path():
	var generator = ROOM_GRAPH_GENERATOR_SCRIPT.new()
	var floor = generator.generate_floor(12345)

	assert_eq(floor.size(), 3, "Default floor graph should have entrance, combat, and boss nodes")
	assert_eq(floor[0]["room_kind"], "entrance")
	assert_eq(floor[1]["room_kind"], "combat")
	assert_eq(floor[2]["room_kind"], "boss")


func test_generated_rooms_use_registered_room_ids():
	ContentRegistry.reload_defaults()
	var generator = ROOM_GRAPH_GENERATOR_SCRIPT.new()
	var floor = generator.generate_floor(9876)

	for room in floor:
		assert_true(room.has("room_id"), "Every generated node should contain a room id")
		assert_ne(room["room_id"], "", "Room id should not be empty")
