class_name RunContext
extends Node

signal run_started(seed: int)
signal room_entered(room_id: String)
signal player_registered(player)
signal primary_player_changed(player)
signal health_changed(current_health: int, max_health: int)
signal resource_changed(resource_name: String, current_value: int, max_value: int)
signal currency_changed(current_currency: int)
signal enemy_defeated(enemy_id: String)

const CombatDirectorScript = preload("res://scripts/combat/combat_director.gd")
const SpawnDirectorScript = preload("res://scripts/run/spawn_director.gd")
const LootDirectorScript = preload("res://scripts/run/loot_director.gd")
const RoomDirectorScript = preload("res://scripts/rooms/room_director.gd")
const LootDropDataScript = preload("res://scripts/resources/loot_drop_data.gd")
const PLAYER_TEAM := 1

var floor_seed: int = 0
var floor_graph: Array[Dictionary] = []
var world_root: Node2D
var current_room
var active_players: Array = []
var primary_player

var attack_displacement_magnitude: float = 15.0

var combat_director = CombatDirectorScript.new()
var spawn_director = SpawnDirectorScript.new()
var loot_director = LootDirectorScript.new()
var room_director = RoomDirectorScript.new()


func _ready() -> void:
	_attach_director(combat_director)
	_attach_director(spawn_director)
	_attach_director(loot_director)
	_attach_director(room_director)

	combat_director.configure(self)
	spawn_director.configure(self)
	loot_director.configure(self)


func begin_run(seed: int) -> void:
	floor_seed = seed
	floor_graph = room_director.build_floor(seed)
	run_started.emit(seed)


func get_start_room_id() -> String:
	if floor_graph.is_empty():
		return ""
	return floor_graph[0].get("room_id", "")


func instantiate_start_room() -> Node2D:
	var room_id: String = get_start_room_id()
	if room_id.is_empty():
		return null
	return room_director.instantiate_room(room_id)


func attach_world_root(root: Node2D) -> void:
	world_root = root
	var room_id: String = get_start_room_id()
	if not room_id.is_empty():
		current_room = room_director.get_room_data(room_id)
		room_entered.emit(room_id)


func register_player(player) -> void:
	if player == null:
		return

	if active_players.has(player):
		return

	active_players.append(player)
	player.set_run_context(self)
	player.team = PLAYER_TEAM
	player_registered.emit(player)

	if primary_player == null:
		primary_player = player
		primary_player_changed.emit(player)

	if player.player_class != null:
		var stats: Stats = player.player_class.stats
		if not stats.health_changed.is_connected(_on_player_health_changed):
			stats.health_changed.connect(_on_player_health_changed)
		if not stats.resource_changed.is_connected(_on_player_resource_changed):
			stats.resource_changed.connect(_on_player_resource_changed)
		_on_player_health_changed(stats.current_health, stats.max_health)
		emit_resource_state(player)

	emit_currency_state(player)


func perform_primary_attack(angle: float) -> bool:
	return combat_director.fire_attack(primary_player, angle)


func place_primary_bomb() -> bool:
	return combat_director.place_bomb(primary_player)


func resolve_projectile_hit(target, projectile) -> bool:
	return combat_director.resolve_projectile_hit(target, projectile)


func handle_enemy_defeated(enemy) -> void:
	if enemy == null:
		return
	enemy_defeated.emit(enemy.actor_definition_id)
	var reward_details: Array = enemy.drop_reward()
	if reward_details.size() >= 2 and reward_details[0] != null:
		var drop = LootDropDataScript.new()
		drop.item_scene = reward_details[0]
		drop.count = reward_details[1]
		loot_director.spawn_drop(drop, enemy.position)


func emit_resource_state(player) -> void:
	if player == null or player.player_class == null:
		return
	for resource_name in player.player_class.stats.resources.keys():
		var resource: Stats.ResourceStatus = player.player_class.stats.resources[resource_name]
		resource_changed.emit(resource_name, resource.current_resource, resource.max_resource)


func emit_currency_state(player) -> void:
	if player == null:
		return
	currency_changed.emit(player.currency)


func random_offset(max_offset: float) -> Vector2:
	var random_modulus: float = randf_range(0, max_offset)
	return random_modulus * Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()


func spawn_enemy(enemy_id: String, spawn_position: Vector2):
	if world_root == null:
		return null
	return spawn_director.spawn_enemy(enemy_id, world_root, spawn_position)


func _attach_director(director: Node) -> void:
	if director.get_parent() == null:
		add_child(director)


func _on_player_health_changed(new_health: int, max_health: int) -> void:
	health_changed.emit(new_health, max_health)


func _on_player_resource_changed(resource_name: String, current_value: int, max_value: int) -> void:
	resource_changed.emit(resource_name, current_value, max_value)
