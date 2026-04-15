class_name PlayerCharacter
extends "res://scripts/base_character.gd"

const GameConstants = preload("res://scripts/config/game_constants.gd")
const PLAYER_INVINCIBILITY_DURATION: float = 1.5
const RUN_TO_WALK_THRESHOLD_FACTOR: float = 0.5

# TODO(ElodinLaarz): Add Class Choice.
var player_class: ClassHandler.PlayerClass
var movement: PlayerMovement = PlayerMovement.new()
var aim: PlayerAim = PlayerAim.new()

var enemy_body: CharacterBody2D
var enemy_in_attack_range: bool = false

# TODO(ElodinLaarz): Add Inventory.
var bomb_count: int = 0
var bomb_max: int = 3
var currency: int = 0


func _init() -> void:
	invincibility_frame_length = PLAYER_INVINCIBILITY_DURATION
	Common.player_character = self
	Common.load_player = load_player_data


func _ready() -> void:
	_animated_sprite = $PlayerSprite
	ready_aim()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	handle_movement(delta)
	handle_attack(delta)
	handle_stats(delta)
	handle_timers(delta)


# Function for identifying if the CharacterBody is the player.
func is_player() -> bool:
	return true


func load_player_data(player_name: String) -> bool:
	var player_data: PlayerConfigurationManager.PlayerConfiguration = (
		PlayerConfigurationManager.new().lookup_character(player_name)
	)
	if player_data:
		player_class = player_data.player_class
		if player_class == null or player_class.definition == null:
			print("Player class definition missing for %s" % player_name)
			return false
		stats = player_class.stats
		Common.player_class = player_data.player_class
		currency = player_data.currency
		bomb_count = player_data.bomb_count
		bomb_max = player_data.bomb_max
		if player_class.definition != null:
			movement.walking_speed = player_class.definition.speed
			movement.running_speed = int(movement.walking_speed * movement.running_multiplier)
			movement.run_to_walk_threshold = movement.walking_speed * RUN_TO_WALK_THRESHOLD_FACTOR
		return true
	return false


func ready_aim() -> void:
	aim.aim_sight = get_node("Main Camera/PlayerPivot/Aim Sight")
	aim.camera = get_node("Main Camera")
	aim.pivot = get_node("Main Camera/PlayerPivot")


func handle_movement(delta: float) -> void:
	movement.set_max_speed_walk()  # Default to walking, unless running.
	if movement.check_is_running(delta, velocity.length()):
		movement.set_max_speed_run()

	# Could pass along the body here, if ambiguous.
	var player_direction: Vector2 = movement.unit_direction()
	# Smooth velocity between current and desired velocity.
	velocity = movement.velocity_lerp(delta, velocity, player_direction)

	move_and_slide()


func handle_attack(_delta: float) -> void:
	aim.update_pivot(_delta)
	# Allow it to be held down.
	if Input.is_action_pressed(GameConstants.INPUT_ACTION_ATTACK):
		if Common.attack():
			print("attacking!")
	if Input.is_action_just_pressed(GameConstants.INPUT_ACTION_SECONDARY_ATTACK):
		if Common.place_bomb():
			print("bomb placed!")


func handle_stats(delta: float) -> void:
	player_class.stats.update(delta)
	if enemy_in_attack_range and enemy_body != null:
		enemy_attack(enemy_body)


func _on_hitbox_body_entered(body: Node) -> void:
	if body.has_method("is_enemy"):
		enemy_in_attack_range = true
		enemy_body = body
		enemy_attack(body)


func _on_hitbox_body_exited(body: Node) -> void:
	if body.has_method("is_enemy"):
		enemy_in_attack_range = false


func take_damage(d: int) -> bool:
	print("You are taking %d damage!" % d)
	var is_dead: bool = super.take_damage(d)
	if is_dead:
		print("You are dead :(")
	return is_dead


func enemy_attack(e: Enemy) -> void:
	if not e:
		print("uh oh...")
		return
	take_damage(e.stats.damage)


func add_currency(c: int) -> void:
	currency += c
	if run_context != null:
		run_context.emit_currency_state(self)
	print("You have %d currency!" % currency)
	# TODO(ElodinLaarz): Update currency display.
