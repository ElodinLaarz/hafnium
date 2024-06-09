extends CharacterBody2D
class_name PlayerCharacter

# TODO(ElodinLaarz): Add Class Choice.
var player_class: ClassHandler.PlayerClass 
var movement = PlayerMovement.new()
var aim = PlayerAim.new() 

# TODO(ElodinLaarz): Add Inventory.
var bomb_count: int = 0
var bomb_max: int = 3

var currency: int = 0

func _init():
	Common.player_character = self
	Common.load_player = load_player_data

func load_player_data(player_name: String) -> bool:
	var player_data: PlayerConfigurationManager.PlayerConfiguration = PlayerConfigurationManager.new().lookup_character(player_name)
	if player_data:
		player_class = player_data.player_class
		Common.player_class = player_data.player_class
		currency = player_data.currency
		bomb_count = player_data.bomb_count
		bomb_max = player_data.bomb_max
		return true
	return false

func ready_aim():
	aim.aim_sight = get_node("Main Camera/PlayerPivot/Aim Sight")
	aim.camera = get_node("Main Camera")
	aim.pivot = get_node("Main Camera/PlayerPivot")

func handle_movement(delta: float):
	movement.set_max_speed_walk() # Default to walking, unless running.
	if movement.check_is_running(delta, velocity.length()):
		movement.set_max_speed_run()

	var player_direction: Vector2 = movement.unit_direction() # Could pass along the body here, if ambiguous.	
	# Smooth veolcity between current and desired velocity.
	velocity = movement.velocity_lerp(delta, velocity, player_direction)
	
	move_and_slide()

func handle_attack(delta: float):
	aim.update_pivot(delta)
	if Input.is_action_just_pressed("attack"):
		print("attack!")

func handle_stats(delta: float):
	pass

func _ready():
	ready_aim()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	handle_movement(delta)
	handle_attack(delta)
	handle_stats(delta)
