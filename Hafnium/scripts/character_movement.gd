extends CharacterBody2D

# (ElodinLaarz): Values randomly chosen-- feel free to play around for something more fun. 
# Speed in pixels per second. -- The reason for not using consts in some places is so that
# The player's top speeds an be modified, e.g. through equipment, buffs, etc.
@export var WALKING_SPEED: int = 85
@export var RUNNING_MULTIPLIER: float = 1.2
@export var ACCEL: float = 10.0
var RUNNING_SPEED: int = int(WALKING_SPEED * RUNNING_MULTIPLIER)
# Current speed of player
var player_speed: int
# Speed of negatively accelerating player to be considered not running
var STOP_RUNNING_THRESHOLD: float = WALKING_SPEED * 0.5 
var is_running: bool = false

# Create unit vector in direction determined by currently pressed keys.
func unit_direction() -> Vector2:
	var input: Vector2
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up") # Yo, down is up?
	return input.normalized() # Do we need to handle 0 vector?

# max_double_click_delta is the largest time between when we consider an action
# done twice. e.g. double-pressing a key.
var max_double_click_delta: float = 1 # Units?
var recently_pressed_action_times: Dictionary = {
	"up": INF,
	"down": INF,
	"left": INF,
	"right": INF,
} # Can I specify the types here...?
var most_recent_action_name: string

# still_running checks if a movement key is being held and
# updates recently_pressed_action_times.
# It should be called only when is_running == true.
func still_running(delta: float) -> bool:
	if !is_running:
		print("OH NO! WE ARE NOT SUPPOSED TO BE HERE!")
		print("still_running called when not running.")
	is_running = player_speed >  # Unless we're holding a key
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

func check_is_running(delta: float) -> bool:
	if is_running:
		# Running and any direction is still down, then keep running.
		return still_running()
	# Was not running but direction double-clicked, then run.
	# Update 
	var new_most_recent_action: string
	

	if is_running:
		return true

	for action in recently_pressed_actions:
		# If running and any (movement) key held, then keep running.

		# If not running, then run when movement action is a repeat of
		# the most recent action. e.g. double-pressing "up".

		match Input.is_action_just_pressed(action):
			true when action_recently_pressed:
				is_running = true
				return true
			true when recently_pressed_actions[action] == false:
				
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	player_speed = WALKING_SPEED # Default to walking, unless running.

	# If direction double-clicked, use running speed.
	is_running = check_is_running(delta)
	if is_running:
		player_speed = RUNNING_SPEED

	var playerDirection: Vector2 = unit_direction() # Could pass along the body here, if ambiguous.	
	# Smooth veolcity between current and desired velocity.
	velocity = lerp(velocity, playerDirection * player_speed, delta * ACCEL)
	
	move_and_slide()
