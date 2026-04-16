extends Node

signal start_game_type(object_to_free: Control, game_type: GameType, save_file: String)

enum GameType { SINGLE_PLAYER, LOAD_GAME, MULTIPLAYER }

const START_GAME_TYPE: String = "start_game_type"
const GameConstants = preload("res://scripts/config/game_constants.gd")
const FeelTuningProfileScript = preload("res://scripts/config/feel_tuning_profile.gd")

var run_context: RunContext
var player_character: CharacterBody2D
var player_class: ClassHandler.PlayerClass
var player_heart_containers: Node
var load_player: Callable
var feel_tuning: FeelTuningProfile = FeelTuningProfileScript.new()

var attack_spawn_angle: float = 0
var attack_displacement_magnitude: float = GameConstants.ATTACK_SPAWN_DISPLACEMENT
var next_level_scene_path: String = ""
var character_select_after_level_pick: bool = false
var player_screen_shake_enabled: bool = false


func place_bomb() -> bool:
	if run_context == null:
		push_error(
			"Common.place_bomb() requires an active RunContext; bombs are placed via CombatDirector."
		)
		return false
	return run_context.place_primary_bomb()


func attack() -> bool:
	if run_context == null:
		push_error(
			"Common.attack() requires an active RunContext; attacks are fired via CombatDirector."
		)
		return false
	return run_context.perform_primary_attack(attack_spawn_angle)


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


func set_next_level_scene_path(scene_path: String) -> void:
	next_level_scene_path = scene_path


func consume_next_level_scene_path() -> String:
	var selected_path: String = next_level_scene_path
	next_level_scene_path = ""
	return selected_path


func set_player_screen_shake_enabled(enabled: bool) -> void:
	player_screen_shake_enabled = enabled
