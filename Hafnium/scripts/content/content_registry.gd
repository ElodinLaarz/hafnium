extends Node

const CHARACTER_RESOURCE_PATHS := [
	"res://resources/characters/barbarian.tres",
	"res://resources/characters/druid.tres",
	"res://resources/characters/wizard.tres",
]
const ENEMY_RESOURCE_PATHS := [
	"res://resources/enemies/slime_basic.tres",
]
const PROJECTILE_RESOURCE_PATHS := [
	"res://resources/projectiles/fireball.tres",
]
const LOOT_RESOURCE_PATHS := [
	"res://resources/loot/slime_basic_loot.tres",
]
const ENCOUNTER_RESOURCE_PATHS := [
	"res://resources/encounters/slime_loop.tres",
]
const ROOM_RESOURCE_PATHS := [
	"res://resources/rooms/start_room.tres",
]

var character_defs: Dictionary = {}
var legacy_character_lookup: Dictionary = {}
var enemy_defs: Dictionary = {}
var projectile_defs: Dictionary = {}
var loot_defs: Dictionary = {}
var encounter_defs: Dictionary = {}
var room_defs: Dictionary = {}


func _init():
	reload_defaults()


func reload_defaults() -> void:
	character_defs.clear()
	legacy_character_lookup.clear()
	enemy_defs.clear()
	projectile_defs.clear()
	loot_defs.clear()
	encounter_defs.clear()
	room_defs.clear()

	_register_all(CHARACTER_RESOURCE_PATHS, character_defs, "character")
	_register_all(ENEMY_RESOURCE_PATHS, enemy_defs, "enemy")
	_register_all(PROJECTILE_RESOURCE_PATHS, projectile_defs, "projectile")
	_register_all(LOOT_RESOURCE_PATHS, loot_defs, "loot")
	_register_all(ENCOUNTER_RESOURCE_PATHS, encounter_defs, "encounter")
	_register_all(ROOM_RESOURCE_PATHS, room_defs, "room")


func require_character(id: String):
	return _require_from(character_defs, id, "character")


func require_legacy_character(legacy_name: int):
	if not legacy_character_lookup.has(legacy_name):
		push_error("Unknown legacy class name: %s" % legacy_name)
		return null
	return legacy_character_lookup[legacy_name]


func require_enemy(id: String):
	return _require_from(enemy_defs, id, "enemy")


func require_projectile(id: String):
	return _require_from(projectile_defs, id, "projectile")


func require_loot(id: String):
	return _require_from(loot_defs, id, "loot")


func require_encounter(id: String):
	return _require_from(encounter_defs, id, "encounter")


func require_room(id: String):
	return _require_from(room_defs, id, "room")


func get_rooms_by_kind(room_kind: String) -> Array:
	var rooms: Array = []
	for room in room_defs.values():
		if room.room_kind == room_kind:
			rooms.append(room)
	return rooms


func choose_weighted_room(room_kind: String, rng: RandomNumberGenerator):
	var rooms := get_rooms_by_kind(room_kind)
	if rooms.is_empty():
		return null

	var total_weight := 0
	for room in rooms:
		total_weight += max(room.weight, 0)

	if total_weight <= 0:
		return rooms[0]

	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for room in rooms:
		cumulative += max(room.weight, 0)
		if roll <= cumulative:
			return room
	return rooms[0]


func _register_all(paths: Array, target: Dictionary, label: String) -> void:
	for path in paths:
		var resource = load(path)
		if resource == null:
			push_error("Failed to load %s definition at %s" % [label, path])
			continue
		_register_resource(resource, target, label)


func _register_resource(resource: Resource, target: Dictionary, label: String) -> void:
	var resource_id = resource.get("id")
	if resource_id == null or String(resource_id).is_empty():
		push_error("Cannot register %s with empty id" % label)
		return
	if target.has(resource_id):
		push_error("Duplicate %s id detected: %s" % [label, resource_id])
		return
	target[resource_id] = resource
	if resource.get("legacy_class_name") != null and resource.legacy_class_name >= 0:
		legacy_character_lookup[resource.legacy_class_name] = resource


func _require_from(source: Dictionary, id: String, label: String):
	if source.has(id):
		return source[id]
	push_error("Missing %s definition: %s" % [label, id])
	return null
