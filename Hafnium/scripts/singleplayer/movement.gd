class_name PlayerMovement
extends Node

# (ElodinLaarz): Values randomly chosen-- feel free to play around for something more fun.
# Speed in pixels per second. -- The reason for not using consts in some places is so that
# The player's top speeds an be modified, e.g. through equipment, buffs, etc.
@export var walking_speed: int = 85
@export var running_multiplier: float = 1.8
@export var accel: float = 10.0

var running_speed: int = int(walking_speed * running_multiplier)
# Current speed of player
var player_speed: int
# Speed of negatively accelerating player to be considered not running
var run_to_walk_threshold: float = walking_speed * 0.5
var is_running: bool = false

# max_double_click_delta is the largest time between when we consider an action
# done twice. e.g. double-pressing a key.
var max_double_click_delta: float = 0.5  # Units are seconds-- matching delta.
var recently_pressed_action_times: Dictionary = {
	"up": INF,
	"down": INF,
	"left": INF,
	"right": INF,
}  # Can I specify the types here...?
var most_recent_action_name: String


func set_max_speed_walk() -> void:
	player_speed = walking_speed


func set_max_speed_run() -> void:
	player_speed = running_speed


func velocity_lerp(delta: float, v: Vector2, player_direction: Vector2) -> Vector2:
	return lerp(v, player_direction * player_speed, delta * accel)


# Overridable input methods for testing
func get_raw_input() -> Vector2:
	return Vector2(
		get_action_strength("right") - get_action_strength("left"),
		get_action_strength("down") - get_action_strength("up")
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
