class_name PlayerMovement
extends Node

const GameConstants = preload("res://scripts/config/game_constants.gd")

const RUN_TO_WALK_THRESHOLD_FACTOR: float = 0.5
const MAX_DOUBLE_CLICK_DELTA: float = 0.5

# (ElodinLaarz): Values randomly chosen-- feel free to play around for something more fun.
# Speed in pixels per second. -- The reason for not using consts in some places is so that
# The player's top speeds an be modified, e.g. through equipment, buffs, etc.
@export var walking_speed: int = 85
@export var running_multiplier: float = 1.8
@export var accel: float = 10.0
@export var decel: float = 14.0
@export var turn_accel_multiplier: float = 1.25

var running_speed: int = int(walking_speed * running_multiplier)
# Current speed of player
var player_speed: int
# Speed of negatively accelerating player to be considered not running
var run_to_walk_threshold: float = walking_speed * RUN_TO_WALK_THRESHOLD_FACTOR
var is_running: bool = false
var autorun_enabled: bool = false

# max_double_click_delta is the largest time between when we consider an action
# done twice. e.g. double-pressing a key.
var max_double_click_delta: float = MAX_DOUBLE_CLICK_DELTA  # Units are seconds-- matching delta.
var speed_scale: float = 1.0
var recently_pressed_action_times: Dictionary = {
	GameConstants.INPUT_ACTION_UP: INF,
	GameConstants.INPUT_ACTION_DOWN: INF,
	GameConstants.INPUT_ACTION_LEFT: INF,
	GameConstants.INPUT_ACTION_RIGHT: INF,
}  # Can I specify the types here...?
var most_recent_action_name: String


func set_max_speed_walk() -> void:
	player_speed = int(round(walking_speed * speed_scale))


func set_max_speed_run() -> void:
	player_speed = int(round(running_speed * speed_scale))


func set_speed_scale(multiplier: float) -> void:
	speed_scale = clampf(multiplier, 0.2, 1.0)


func toggle_autorun() -> void:
	autorun_enabled = not autorun_enabled


func should_run(delta: float, player_current_speed: float, walk_modifier_held: bool) -> bool:
	if autorun_enabled:
		is_running = not walk_modifier_held
		return is_running
	if walk_modifier_held:
		is_running = false
		return false
	return check_is_running(delta, player_current_speed)


func apply_tuning(tuning: FeelTuningProfile) -> void:
	if tuning == null:
		return
	walking_speed = int(round(tuning.walk_speed))
	running_multiplier = tuning.run_multiplier
	accel = tuning.accel
	decel = tuning.decel
	turn_accel_multiplier = tuning.turn_accel_multiplier
	max_double_click_delta = tuning.run_double_tap_window
	update_derived_stats()


## Recomputes running_speed and run_to_walk_threshold from walking_speed and
## running_multiplier. Call after mutating either input so callers do not have
## to duplicate the derivation formula.
func update_derived_stats() -> void:
	running_speed = int(round(walking_speed * running_multiplier))
	run_to_walk_threshold = walking_speed * RUN_TO_WALK_THRESHOLD_FACTOR


func velocity_lerp(delta: float, v: Vector2, player_direction: Vector2) -> Vector2:
	var target_velocity: Vector2 = player_direction * player_speed
	if player_direction == Vector2.ZERO:
		return _blend_velocity(v, Vector2.ZERO, delta, decel)
	var blend_rate: float = accel
	if v.length() > 0.001 and v.dot(target_velocity) < 0:
		blend_rate *= turn_accel_multiplier
	return _blend_velocity(v, target_velocity, delta, blend_rate)


func _blend_velocity(
	current_velocity: Vector2, target_velocity: Vector2, delta: float, rate: float
) -> Vector2:
	var blend_weight: float = clampf(delta * rate, 0.0, 1.0)
	return current_velocity.lerp(target_velocity, blend_weight)


# Overridable input methods for testing
func get_raw_input() -> Vector2:
	return Vector2(
		(
			get_action_strength(GameConstants.INPUT_ACTION_RIGHT)
			- get_action_strength(GameConstants.INPUT_ACTION_LEFT)
		),
		(
			get_action_strength(GameConstants.INPUT_ACTION_DOWN)
			- get_action_strength(GameConstants.INPUT_ACTION_UP)
		)
	)


func is_action_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)


func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)


func get_action_strength(action: String) -> float:
	return Input.get_action_strength(action)


# Create unit vector in direction determined by currently pressed keys.
func unit_direction() -> Vector2:
	return get_raw_input().normalized()


# still_running checks if a movement key is being held and
# updates recently_pressed_action_times.
# assumes (and checks) is_running = true
func still_running(delta: float, player_current_speed: float) -> bool:
	if !is_running:
		print("OH NO! WE ARE NOT SUPPOSED TO BE HERE!")
		print("still_running called when not running.")
		#TODO(ElodinLaarz): How do errors work in Godot...?
	is_running = player_current_speed > run_to_walk_threshold  # Unless we're still pressing a key
	for action: String in recently_pressed_action_times:
		# A little worried about ordering and what happens if more than
		# one action is recently pressed...

		# Increment time since last pressed actions
		recently_pressed_action_times[action] += delta
		if get_action_strength(action) > 0:
			is_running = true
		if is_action_just_pressed(action):
			recently_pressed_action_times[action] = 0
			most_recent_action_name = action
	return is_running


# Was not running but direction double-clicked, then run.
# assumes (and checks) is_running = false
func started_running(delta: float) -> bool:
	if is_running:
		print("OH NO! WE ARE NOT SUPPOSED TO BE HERE!")
		print("started_running called when already running.")
	for action: String in recently_pressed_action_times:
		recently_pressed_action_times[action] += delta
		# If not running, then run when movement action is a repeat of
		# the most recent action. e.g. double-pressing "up".
		var action_just_pressed: bool = is_action_just_pressed(action)
		var action_is_most_recent: bool = most_recent_action_name == action
		var action_recent: bool = recently_pressed_action_times[action] < max_double_click_delta
		if action_just_pressed and action_is_most_recent and action_recent:
			is_running = true
		if action_just_pressed:
			recently_pressed_action_times[action] = 0
			most_recent_action_name = action
	return is_running


func check_is_running(delta: float, player_current_speed: float) -> bool:
	if is_running:
		# If running and any direction is still down, then keep running.
		return still_running(delta, player_current_speed)
	return started_running(delta)
