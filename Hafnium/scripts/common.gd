extends Node

signal start_game_type(object_to_free: Control, game_type: GameType, save_file: String)

enum GameType { SINGLE_PLAYER, LOAD_GAME, MULTIPLAYER }

const START_GAME_TYPE: String = "start_game_type"
const GameConstants = preload("res://scripts/config/game_constants.gd")
const FeelTuningProfileScript = preload("res://scripts/config/feel_tuning_profile.gd")
const LEGACY_REWARD_SCATTER_RADIUS: float = 5.0

var bomb_weapon: Resource = load("res://scenes/weapons/player_bomb.tscn")

var run_context: RunContext
var player_character: CharacterBody2D
var player_class: ClassHandler.PlayerClass
var player_heart_containers: Node
var load_player: Callable
var feel_tuning: FeelTuningProfile = FeelTuningProfileScript.new()

var attack_spawn_angle: float = 0
var attack_displacement_magnitude: float = GameConstants.ATTACK_SPAWN_DISPLACEMENT


func place_bomb() -> bool:
	if run_context != null:
		# RunContext owns authoritative combat/resource state in modern flow.
		return run_context.place_primary_bomb()
	if !player_class.use_resource(GameConstants.RESOURCE_BOMB, 1):
		return false
	var bomb: Node2D = bomb_weapon.instantiate()
	bomb.position = player_character.position
	get_parent().add_child(bomb)
	return true


func attack() -> bool:
	if run_context != null:
		# Delegate to the combat pipeline so drops, damage, and UI signals stay unified.
		return run_context.perform_primary_attack(attack_spawn_angle)
	if player_class.attack_projectile_path.is_empty():
		print("No attack projectile defined for class!")
		return false
	if !player_class.attack():
		return false
	var stats: Stats = player_class.stats
	var p: Projectile = player_class.get_attack_scene().instantiate()
	p.rotation = PI + attack_spawn_angle  # We should have projectiles point right, actually...
	var aim_dir: Vector2 = Vector2(cos(attack_spawn_angle), sin(attack_spawn_angle))
	p.position = player_character.position + aim_dir * attack_displacement_magnitude
	# Have the proj have a non-zero velocity in the direction
	# of the aim sight.
	p.velocity = aim_dir * stats.projectile_speed
	p.damage = stats.damage
	p.ttl = stats.attack_range / stats.projectile_speed
	get_parent().add_child(p)
	return true


func projectile_resolve(creature: CharacterBody2D, proj: CharacterBody2D) -> void:
	if (
		run_context != null
		and creature.has_method("receive_damage")
		and proj.has_method("build_damage")
	):
		# Prefer the typed damage path when both actors are on the newer combat API.
		run_context.resolve_projectile_hit(creature, proj)
		return
	if !proj.has_method("is_projectile"):
		print("requested projectile_resolve on a non-projectile!")
		return
	if !creature.has_method("is_enemy"):
		# Only deal damage to enemies.
		return
	# Physics callbacks cannot mutate the tree immediately; defer projectile cleanup.
	proj.call_deferred("queue_free")
	var damage: int = proj.damage
	var creature_defeated: bool = creature.stats.take_damage(damage)
	# Get damage value from proj and apply health reduction
	# to creature.
	# Returns true when creature has 0 health.
	if creature_defeated:
		# Enemy removal and reward spawning are deferred for the same physics-safety reason.
		creature.call_deferred("queue_free")
		var reward_spawn_pos: Vector2 = creature.position
		var reward_details: Array = creature.drop_reward()
		if len(reward_details) > 0:
			var reward: PackedScene = reward_details[0]
			var count: int = reward_details[1]
			for i: int in range(count):
				var r: Node2D = reward.instantiate()
				r.position = reward_spawn_pos + a_little_offset(LEGACY_REWARD_SCATTER_RADIUS)
				get_parent().call_deferred("add_child", r)
		else:
			print("No reward to drop. :(")


func a_little_offset(max_offset: float) -> Vector2:
	if run_context != null:
		return run_context.random_offset(max_offset)
	var random_modulus: float = randf_range(0, max_offset)
	return random_modulus * Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()


func set_run_context(p_run_context: RunContext) -> void:
	run_context = p_run_context


func get_feel_tuning() -> FeelTuningProfile:
	if feel_tuning == null:
		feel_tuning = FeelTuningProfileScript.new()
	return feel_tuning
