extends CharacterBody2D
class_name PlayerCharacter

# TODO(ElodinLaarz): Add Class Choice.
var player_class: ClassHandler.PlayerClass
var movement = PlayerMovement.new()
var aim = PlayerAim.new()

var enemy_body: CharacterBody2D
var enemy_in_attack_range: bool = false
var is_invincible: bool = false
var invincibility_frame_length: float = 1.5
var invincibility_frame_timer: float = 0.0
@onready var _animated_sprite = $PlayerSprite

# TODO(ElodinLaarz): Add Inventory.
var bomb_count: int = 0
var bomb_max: int = 3

var currency: int = 0

# Function for identifying if the CharacterBody is the player.
func is_player():
	pass

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
		# Allow it to be held down.
		if Input.is_action_pressed("attack"):
				if Common.attack():
						print("attacking!")
		if Input.is_action_just_pressed("secondary_attack"):
				if Common.place_bomb():
						print("bomb placed!")


func handle_stats(delta: float):
	player_class.stats.update(delta)
	if enemy_in_attack_range and enemy_body != null:
		enemy_attack(enemy_body)

func handle_timers(delta: float):
	if is_invincible:
		invincibility_frame_timer += delta
		if invincibility_frame_timer >= invincibility_frame_length:
			is_invincible = false
			invincibility_frame_timer = 0.0
			_animated_sprite.play("idle")

func _ready():
	ready_aim()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	handle_movement(delta)
	handle_attack(delta)
	handle_stats(delta)
	handle_timers(delta)

func _on_hitbox_body_entered(body):
	if body.has_method("is_enemy"):
		enemy_in_attack_range = true
		enemy_body = body
		enemy_attack(body)

func _on_hitbox_body_exited(body):
	if body.has_method("is_enemy"):
		enemy_in_attack_range = false

func take_damage(d: int):
	if is_invincible:
		# You are invincible and don't take damage :)
		return
	_animated_sprite.play("invincibility_frames")
	print("You are taking %d damage!" % d)
	var is_dead: bool = player_class.stats.take_damage(d)
	player_class.draw_hearts(Common.player_heart_containers)
	if is_dead:
		print("You are dead :(")
		# Player is dead.
		pass

func enemy_attack(e: enemy):
	if not e:
		print("uh oh...")
		return
	take_damage(e.stats.damage)
	is_invincible = true

func add_currency(c: int):
	currency += c
	print("You have %d currency!" % currency)
	# TODO(ElodinLaarz): Update currency display.
