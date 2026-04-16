extends Node

const DEFAULT_RESOURCE_INDEX: int = 0
const NON_POSITIVE_WEIGHT: int = 0
const WEIGHTED_ROLL_MIN: int = 1

const CHARACTER_RESOURCE_PATHS: Array[String] = [
	"res://resources/characters/barbarian.tres",
	"res://resources/characters/druid.tres",
	"res://resources/characters/wizard.tres",
]
const ENEMY_RESOURCE_PATHS: Array[String] = [
	"res://resources/enemies/slime_basic.tres",
]
const PROJECTILE_RESOURCE_PATHS: Array[String] = [
	"res://resources/projectiles/barbarian_swing.tres",
	"res://resources/projectiles/fireball.tres",
]
const LOOT_RESOURCE_PATHS: Array[String] = [
	"res://resources/loot/slime_basic_loot.tres",
]
const ENCOUNTER_RESOURCE_PATHS: Array[String] = [
	"res://resources/encounters/slime_loop.tres",
]
const ROOM_RESOURCE_PATHS: Array[String] = [
	"res://resources/rooms/start_room.tres",
]

var character_defs: Dictionary = {}
var legacy_character_lookup: Dictionary = {}
var enemy_defs: Dictionary = {}
var projectile_defs: Dictionary = {}
var loot_defs: Dictionary = {}
var encounter_defs: Dictionary = {}
var room_defs: Dictionary = {}


func _init() -> void:
	reload_defaults()


func reload_defaults() -> void:
	# Rebuilding all registries in one pass keeps tests deterministic across reloads.
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


func require_character(id: String) -> CharacterData:
	return _require_from(character_defs, id, "character")


func require_legacy_character(legacy_name: int) -> CharacterData:
	if not legacy_character_lookup.has(legacy_name):
		push_error("Unknown legacy class name: %s" % legacy_name)
		return null
	return legacy_character_lookup[legacy_name]


func require_enemy(id: String) -> EnemyData:
	return _require_from(enemy_defs, id, "enemy")


func require_projectile(id: String) -> ProjectileData:
	return _require_from(projectile_defs, id, "projectile")


func require_loot(id: String) -> LootTable:
	return _require_from(loot_defs, id, "loot")


func require_encounter(id: String) -> EncounterData:
	return _require_from(encounter_defs, id, "encounter")


func require_room(id: String) -> RoomData:
	return _require_from(room_defs, id, "room")


func get_rooms_by_kind(room_kind: String) -> Array:
	var rooms: Array = []
	for room: RoomData in room_defs.values():
		if room.room_kind == room_kind:
			rooms.append(room)
	return rooms


func choose_weighted_room(room_kind: String, rng: RandomNumberGenerator) -> RoomData:
	var rooms: Array = get_rooms_by_kind(room_kind)
	if rooms.is_empty():
		return null

	var total_weight: int = 0
	for room: RoomData in rooms:
		total_weight += max(room.weight, NON_POSITIVE_WEIGHT)

	if total_weight <= NON_POSITIVE_WEIGHT:
		# Fallback keeps generation running even if all weights are accidentally zeroed.
		return rooms[DEFAULT_RESOURCE_INDEX]

	var roll: int = rng.randi_range(WEIGHTED_ROLL_MIN, total_weight)
	var cumulative: int = 0
	for room: RoomData in rooms:
		cumulative += max(room.weight, NON_POSITIVE_WEIGHT)
		if roll <= cumulative:
			return room
	return rooms[DEFAULT_RESOURCE_INDEX]


func _register_all(paths: Array, target: Dictionary, label: String) -> void:
	for path: String in paths:
		var resource: Resource = load(path)
		if resource == null:
			push_error("Failed to load %s definition at %s" % [label, path])
			continue
		_register_resource(resource, target, label)


func _register_resource(resource: Resource, target: Dictionary, label: String) -> void:
	var resource_id: String = String(resource.get("id"))
	if resource_id == null or String(resource_id).is_empty():
		push_error("Cannot register %s with empty id" % label)
		return
	if target.has(resource_id):
		push_error("Duplicate %s id detected: %s" % [label, resource_id])
		return
	target[resource_id] = resource
	if resource.get("legacy_class_name") != null and resource.legacy_class_name >= 0:
		# Legacy enum lookups still power old call sites; keep both registries in sync.
		legacy_character_lookup[resource.legacy_class_name] = resource


func _require_from(source: Dictionary, id: String, label: String) -> Resource:
	if source.has(id):
		return source[id]
	push_error("Missing %s definition: %s" % [label, id])
	return null
