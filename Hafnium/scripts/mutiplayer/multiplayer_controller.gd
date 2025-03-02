extends CharacterBody2D

@export var player_id: int = 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

# (ElodinLaarz): Values randomly chosen-- feel free to play around for something more fun. 
# Speed in pixels per second. -- The reason for not using consts in some places is so that
# The player's top speeds an be modified, e.g. through equipment, buffs, etc.
@export var WALKING_SPEED: int = 85
@export var RUNNING_MULTIPLIER: float = 1.8
@export var ACCEL: float = 10.0
var RUNNING_SPEED: int = int(WALKING_SPEED * RUNNING_MULTIPLIER)
# Current speed of player
var player_speed: int
# Speed of negatively accelerating player to be considered not running
var RUN_TO_WALK_THRESHOLD: float = WALKING_SPEED * 0.5 
var is_running: bool = false

# Create unit vector in direction determined by currently pressed keys.
func unit_direction() -> Vector2:
	var input: Vector2 = Vector2(0,0)
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up") # Yo, down is up?
	return input.normalized() # Do we need to handle 0 vector?

# max_double_click_delta is the largest time between when we consider an action
# done twice. e.g. double-pressing a key.
var max_double_click_delta: float = 0.5 # Units are seconds-- matching delta.
var recently_pressed_action_times: Dictionary = {
	"up": INF,
	"down": INF,
	"left": INF,
	"right": INF,
} # Can I specify the types here...?
var most_recent_action_name: String

# still_running checks if a movement key is being held and
# updates recently_pressed_action_times.
# assumes (and checks) is_running = true
func still_running(delta: float, player_current_speed: float) -> bool:
	if !is_running:
		print("OH NO! WE ARE NOT SUPPOSED TO BE HERE!")
		print("still_running called when not running.")
		#TODO(ElodinLaarz): How do errors work in Godot...?
	is_running = player_current_speed > RUN_TO_WALK_THRESHOLD # Unless we're still pressing a key
	for action in recently_pressed_action_times:
		# A little worried about ordering and what happens if more than
		# one action is recently pressed...

		# Increment time since last pressed actions
		recently_pressed_action_times[action] += delta
		if Input.get_action_strength(action) > 0:
			is_running = true
		if Input.is_action_just_pressed(action):
			recently_pressed_action_times[action] = 0
			most_recent_action_name = action
	return is_running

# Was not running but direction double-clicked, then run.
# assumes (and checks) is_running = false
func started_running(delta: float) -> bool:
	if is_running:
		print("OH NO! WE ARE NOT SUPPOSED TO BE HERE!")
		print("started_running called when already running.")
	for action in recently_pressed_action_times:
		recently_pressed_action_times[action] += delta
		# If not running, then run when movement action is a repeat of
		# the most recent action. e.g. double-pressing "up".
		var action_just_pressed: bool = Input.is_action_just_pressed(action)
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

func _apply_movement_from_input(delta: float):
	player_speed = WALKING_SPEED # Default to walking, unless running.
	if check_is_running(delta, velocity.length()):
		player_speed = RUNNING_SPEED

	var playerDirection: Vector2 = %InputSynchronizer.input_direction
	# Smooth veolcity between current and desired velocity.
	velocity = lerp(velocity, playerDirection * player_speed, delta * ACCEL)
	
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float): # Should this be _process?
	if multiplayer.is_server():
		_apply_movement_from_input(delta)

func _ready():
	var multiplayer_camera: Camera2D = $MultiplayerCamera
	if multiplayer.get_unique_id() == player_id:
		multiplayer_camera.make_current()
	else:
		multiplayer_camera.enabled = false

# func _apply_animation(delta: float):
# 	#TODO(ElodinLaarz): Implement animations.
# 	pass

