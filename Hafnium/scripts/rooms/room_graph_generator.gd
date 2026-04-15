class_name RoomGraphGenerator
extends RefCounted


func generate_floor(seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var floor: Array[Dictionary] = []
	floor.append(_make_room_node(0, "entrance", _choose_room_id("entrance", rng)))
	floor.append(_make_room_node(1, "combat", _choose_room_id("combat", rng)))
	floor.append(_make_room_node(2, "boss", _choose_room_id("boss", rng)))
	return floor


func _make_room_node(index: int, room_kind: String, room_id: String) -> Dictionary:
	return {
		"index": index,
		"room_kind": room_kind,
		"room_id": room_id,
	}


func _choose_room_id(room_kind: String, rng: RandomNumberGenerator) -> String:
	var room_data = ContentRegistry.choose_weighted_room(room_kind, rng)
	if room_data != null:
		return room_data.id

	var fallback = ContentRegistry.choose_weighted_room("combat", rng)
	if fallback != null:
		return fallback.id

	return ""
