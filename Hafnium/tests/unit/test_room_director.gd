extends GutTest

const ROOM_DIRECTOR_SCRIPT = preload("res://scripts/rooms/room_director.gd")


func test_instantiate_room_applies_encounter_definition_to_room_root() -> void:
	var room_director: RoomDirector = ROOM_DIRECTOR_SCRIPT.new()
	var room_root: Node2D = room_director.instantiate_room("room:start")

	assert_ne(room_root, null, "Expected start room to instantiate")
	assert_eq(
		room_root.get("encounter_definition_id"),
		"encounter:slime_loop",
		"Room root should receive the configured encounter id"
	)

	if room_root != null:
		room_root.free()
