class_name RunContext
extends Node

signal run_started(seed: int)
signal room_entered(room_id: String)
signal player_registered(player: PlayerCharacter)
signal primary_player_changed(player: PlayerCharacter)
signal health_changed(current_health: int, max_health: int)
signal resource_changed(resource_name: String, current_value: int, max_value: int)
signal currency_changed(current_currency: int)
signal enemy_defeated(enemy: Enemy)
signal level_up_choice_required(player: PlayerCharacter, choices: Array[int])
signal camera_shake_requested(intensity: float, duration: float)
signal training_damage_type_override_changed(active: bool, element: Damage.DamageType)

const CombatDirectorScript = preload("res://scripts/combat/combat_director.gd")
const SpawnDirectorScript = preload("res://scripts/run/spawn_director.gd")
const LootDirectorScript = preload("res://scripts/run/loot_director.gd")
const RoomDirectorScript = preload("res://scripts/rooms/room_director.gd")
const LootDropDataScript = preload("res://scripts/resources/loot_drop_data.gd")
const AttributeBonusService = preload("res://scripts/progression/attribute_bonus_service.gd")
const GameConstants = preload("res://scripts/config/game_constants.gd")
const LevelUpOverlayScene: PackedScene = preload("res://scenes/interface/level_up_overlay.tscn")
const FloatingDamageNumberScene: PackedScene = preload(
	"res://scenes/combat/floating_damage_number.tscn"
)

var floor_seed: int = 0
var floor_graph: Array[Dictionary] = []
var world_root: Node2D
var current_room: RoomData
var active_players: Array[PlayerCharacter] = []
var primary_player: PlayerCharacter

var attack_displacement_magnitude: float = GameConstants.ATTACK_SPAWN_DISPLACEMENT

## When true, use [member training_damage_type_override] instead of resolving from weapon/class.
var use_training_damage_type_override: bool = false
var training_damage_type_override: Damage.DamageType = Damage.DamageType.BASIC

var combat_director: CombatDirector = CombatDirectorScript.new()
var spawn_director: SpawnDirector = SpawnDirectorScript.new()
var loot_director: LootDirector = LootDirectorScript.new()
var room_director: RoomDirector = RoomDirectorScript.new()
var _hit_stop_remaining: float = 0.0
var _level_up_choice_queue: Array[PlayerCharacter] = []


func _ready() -> void:
	# Directors are plain Nodes so tests can swap/spy them without scene dependencies.
	_attach_director(combat_director)
	_attach_director(spawn_director)
	_attach_director(loot_director)
	_attach_director(room_director)

	combat_director.configure(self)
	spawn_director.configure(self)
	loot_director.configure(self)

	# LevelUpOverlayScene is preloaded, so any failure is a parse/load error rather
	# than a runtime nil — no null-guard is meaningful here.
	var level_overlay: Node = LevelUpOverlayScene.instantiate()
	add_child(level_overlay)
	if level_overlay.has_method(&"configure"):
		level_overlay.configure(self)


func _process(delta: float) -> void:
	if _hit_stop_remaining > 0:
		var unscaled_delta: float = delta / max(Engine.time_scale, 0.001)
		_hit_stop_remaining = max(_hit_stop_remaining - unscaled_delta, 0.0)
		if _hit_stop_remaining <= 0:
			_clear_hit_stop()


func _exit_tree() -> void:
	_clear_hit_stop()


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


func set_training_damage_type_override(active: bool, element: Damage.DamageType) -> void:
	use_training_damage_type_override = active
	training_damage_type_override = element
	training_damage_type_override_changed.emit(active, element)


func register_player(player: PlayerCharacter) -> void:
	if player == null:
		return

	if active_players.has(player):
		return

	active_players.append(player)
	player.set_run_context(self)
	player.team = GameConstants.PLAYER_TEAM
	player_registered.emit(player)

	if primary_player == null:
		# Input currently targets one player; first registration defines HUD/combat source.
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


func resolve_projectile_hit(target: BaseCharacter, projectile: Projectile) -> bool:
	return combat_director.resolve_projectile_hit(target, projectile)


func request_hit_feedback(is_crit: bool = false) -> void:
	var feel_tuning: FeelTuningProfile = Common.get_feel_tuning()
	if feel_tuning == null:
		return
	var feedback_multiplier: float = 1.0
	if is_crit:
		feedback_multiplier = feel_tuning.crit_feedback_multiplier
	if feel_tuning.enable_hit_stop and feel_tuning.hit_stop_duration > 0:
		var crit_adjusted_time_scale: float = feel_tuning.hit_stop_time_scale / feedback_multiplier
		apply_hit_stop(
			feel_tuning.hit_stop_duration * feedback_multiplier, crit_adjusted_time_scale
		)
	if (
		Common.player_screen_shake_enabled
		and feel_tuning.enable_screen_shake
		and feel_tuning.screen_shake_duration > 0
	):
		camera_shake_requested.emit(
			feel_tuning.screen_shake_intensity * feedback_multiplier,
			feel_tuning.screen_shake_duration * feedback_multiplier
		)


func spawn_damage_number(world_position: Vector2, amount: int, is_crit: bool) -> void:
	var entity_root: Node = get_world_entity_root()
	if entity_root == null or FloatingDamageNumberScene == null:
		return
	var number_node: Node = FloatingDamageNumberScene.instantiate()
	if number_node == null:
		return
	entity_root.add_child(number_node)
	if number_node is Node2D:
		number_node.global_position = world_position
	if number_node.has_method("setup"):
		number_node.setup(amount, is_crit)


func apply_hit_stop(duration: float, time_scale: float) -> void:
	var clamped_duration: float = clampf(duration, 0.0, 0.2)
	if clamped_duration <= 0:
		return
	var clamped_time_scale: float = clampf(time_scale, 0.05, 1.0)
	_hit_stop_remaining = max(_hit_stop_remaining, clamped_duration)
	Engine.time_scale = min(Engine.time_scale, clamped_time_scale)


func enqueue_level_up_choice(player: PlayerCharacter) -> void:
	if player == null or not is_instance_valid(player):
		return
	_level_up_choice_queue.append(player)
	if _level_up_choice_queue.size() == 1:
		_set_level_up_choice_paused(true)
		_emit_next_level_up_choice()


func resolve_level_up_choice(
	player: PlayerCharacter, attribute: PlayerProgression.Attribute
) -> void:
	_prune_invalid_level_up_choice_queue_head()
	if player == null or not is_instance_valid(player) or player.progression == null:
		if _level_up_choice_queue.is_empty():
			_set_level_up_choice_paused(false)
		else:
			_emit_next_level_up_choice()
		return
	if _level_up_choice_queue.is_empty() or _level_up_choice_queue[0] != player:
		return
	player.progression.increment_attribute(attribute)
	AttributeBonusService.apply(player)
	_level_up_choice_queue.pop_front()
	_prune_invalid_level_up_choice_queue_head()
	if _level_up_choice_queue.is_empty():
		_set_level_up_choice_paused(false)
	else:
		_emit_next_level_up_choice()


func _emit_next_level_up_choice() -> void:
	while not _level_up_choice_queue.is_empty():
		var player: PlayerCharacter = _level_up_choice_queue[0]
		if player == null or not is_instance_valid(player):
			_level_up_choice_queue.pop_front()
			continue
		var choices: Array[int] = PlayerProgression.pick_random_attributes(
			GameConstants.LEVEL_UP_CHOICE_COUNT
		)
		level_up_choice_required.emit(player, choices)
		return
	# Queue was drained of invalid entries without emitting; unpause so gameplay
	# does not stay frozen waiting on a choice that can never be made.
	_set_level_up_choice_paused(false)


func _prune_invalid_level_up_choice_queue_head() -> void:
	while not _level_up_choice_queue.is_empty():
		var queued_player: PlayerCharacter = _level_up_choice_queue[0]
		if queued_player != null and is_instance_valid(queued_player):
			return
		_level_up_choice_queue.pop_front()


func _set_level_up_choice_paused(paused: bool) -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.paused = paused


func handle_enemy_defeated(enemy: Enemy) -> void:
	if enemy == null:
		return
	enemy_defeated.emit(enemy)
	var xp_amount: int = 0
	if enemy.definition != null:
		xp_amount = enemy.definition.experience_reward
	# Iterate in reverse so removing freed players does not skip entries.
	for i: int in range(active_players.size() - 1, -1, -1):
		var p: PlayerCharacter = active_players[i]
		if p == null or not is_instance_valid(p):
			active_players.remove_at(i)
			continue
		p.grant_experience(xp_amount)
	var reward_details: Array = enemy.drop_reward()
	if reward_details.size() >= 2 and reward_details[0] != null:
		var drop: LootDropData = LootDropDataScript.new()
		drop.item_scene = reward_details[0]
		drop.count = reward_details[1]
		loot_director.spawn_drop(drop, enemy.position)


func emit_resource_state(player: PlayerCharacter) -> void:
	if player == null or player.player_class == null:
		return
	for resource_name: String in player.player_class.stats.resources.keys():
		var resource: Stats.ResourceStatus = player.player_class.stats.resources[resource_name]
		resource_changed.emit(resource_name, resource.current_resource, resource.max_resource)


func emit_currency_state(player: PlayerCharacter) -> void:
	if player == null:
		return
	currency_changed.emit(player.currency)


func random_offset(max_offset: float) -> Vector2:
	var random_modulus: float = randf_range(0, max_offset)
	return random_modulus * Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()


func spawn_enemy(enemy_id: String, spawn_position: Vector2) -> Enemy:
	var entity_root: Node = get_world_entity_root()
	if entity_root == null:
		return null
	return spawn_director.spawn_enemy(enemy_id, entity_root, spawn_position)


func get_world_entity_root() -> Node:
	if world_root == null:
		return null
	if world_root.has_method("get_dynamic_entity_root"):
		# Level scripts can expose a dedicated transient container for spawned entities.
		var entity_root: Node = world_root.get_dynamic_entity_root()
		if entity_root != null:
			return entity_root
	return world_root


func _attach_director(director: Node) -> void:
	if director.get_parent() == null:
		add_child(director)


func _on_player_health_changed(new_health: int, max_health: int) -> void:
	health_changed.emit(new_health, max_health)


func _on_player_resource_changed(resource_name: String, current_value: int, max_value: int) -> void:
	resource_changed.emit(resource_name, current_value, max_value)


func _clear_hit_stop() -> void:
	_hit_stop_remaining = 0.0
	Engine.time_scale = 1.0
