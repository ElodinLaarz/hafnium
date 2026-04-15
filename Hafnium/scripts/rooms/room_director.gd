class_name RoomDirector
extends Node

const ROOM_GRAPH_GENERATOR_SCRIPT = preload("res://scripts/rooms/room_graph_generator.gd")

var graph_generator = ROOM_GRAPH_GENERATOR_SCRIPT.new()


func build_floor(seed: int) -> Array[Dictionary]:
	return graph_generator.generate_floor(seed)


func instantiate_room(room_id: String) -> Node2D:
	var room_data = ContentRegistry.require_room(room_id)
	if room_data == null or room_data.scene == null:
		return null

	var room_root = room_data.scene.instantiate()
	if room_root is Node2D:
		_apply_room_definition(room_root, room_data)
		return room_root
	return null


func get_room_data(room_id: String):
	return ContentRegistry.require_room(room_id)


func _apply_room_definition(room_root: Node, room_data) -> void:
	var room_nodes: Array = [room_root]
	room_nodes.append_array(room_root.find_children("*", "Node", true, false))
	for node in room_nodes:
		if (
			node != null
			and node.get("encounter_definition_id") != null
			and room_data.encounter_id != ""
		):
			node.encounter_definition_id = room_data.encounter_id
