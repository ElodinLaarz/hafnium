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
var battle_hardened_counter: int = 0
var bomb_count: int = 0
var bomb_max: int = 3
var currency: int = 0
var feel_tuning: FeelTuningProfile
var _attack_buffer_timer: float = 0.0
var _attack_move_slow_timer: float = 0.0


func _init() -> void:
	invincibility_frame_length = PLAYER_INVINCIBILITY_DURATION
	Common.player_character = self
	Common.load_player = load_player_data


func _ready() -> void:
	_animated_sprite = $PlayerSprite
	feel_tuning = Common.get_feel_tuning()
	if feel_tuning != null and not feel_tuning.changed.is_connected(_on_feel_tuning_changed):
		feel_tuning.changed.connect(_on_feel_tuning_changed)
	_apply_feel_tuning()
	ready_aim()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_attack_windows(delta)
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
		_apply_feel_tuning()
		return true
	return false


func ready_aim() -> void:
	aim.aim_sight = get_node("Main Camera/PlayerPivot/Aim Sight")
	aim.camera = get_node("Main Camera")
	aim.pivot = get_node("Main Camera/PlayerPivot")


func handle_movement(delta: float) -> void:
	if Input.is_action_just_pressed(GameConstants.INPUT_ACTION_TOGGLE_AUTORUN):
		movement.toggle_autorun()
	var walk_modifier_held: bool = Input.is_action_pressed(GameConstants.INPUT_ACTION_WALK_MODIFIER)
	var movement_scale: float = _get_attack_movement_scale()
	movement.set_speed_scale(movement_scale)
	movement.set_max_speed_walk()  # Default to walking, unless running.
	if movement.should_run(delta, velocity.length(), walk_modifier_held):
		movement.set_max_speed_run()

	# Could pass along the body here, if ambiguous.
	var player_direction: Vector2 = movement.unit_direction()
	# Smooth velocity between current and desired velocity.
	velocity = movement.velocity_lerp(delta, velocity, player_direction)

	move_and_slide()


func handle_attack(delta: float) -> void:
	aim.update_pivot(delta)
	var attack_held: bool = Input.is_action_pressed(GameConstants.INPUT_ACTION_ATTACK)
	if Input.is_action_just_pressed(GameConstants.INPUT_ACTION_ATTACK):
		_attack_buffer_timer = _get_attack_buffer_window()
	var attack_requested: bool = attack_held or _attack_buffer_timer > 0
	if attack_requested and Common.attack():
		_attack_buffer_timer = 0.0
		_attack_move_slow_timer = _get_attack_move_slow_time()
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
	var applied_damage: int = apply_battle_hardened(d)
	print("You are taking %d damage!" % applied_damage)
	var is_dead: bool = super.take_damage(applied_damage)
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


func set_run_context(p_run_context: RunContext) -> void:
	super.set_run_context(p_run_context)
	if run_context == null:
		return
	var camera: Camera2D = get_node_or_null("Main Camera")
	if (
		camera != null
		and camera.has_method("trigger_shake")
		and not run_context.camera_shake_requested.is_connected(camera.trigger_shake)
	):
		run_context.camera_shake_requested.connect(camera.trigger_shake)


func apply_battle_hardened(incoming_damage: int) -> int:
	if not _is_barbarian():
		return incoming_damage
	if incoming_damage <= 0:
		return incoming_damage
	if is_invincible or stats == null or stats.current_health <= 0:
		return incoming_damage
	var reduced_damage: int = maxi(0, incoming_damage - battle_hardened_counter)
	if reduced_damage <= 0:
		battle_hardened_counter = 0
		return 0
	battle_hardened_counter += 1
	return reduced_damage


func _is_barbarian() -> bool:
	return player_class != null and player_class.name == ClassHandler.ClassName.BARBARIAN


func _update_attack_windows(delta: float) -> void:
	if _attack_buffer_timer > 0:
		_attack_buffer_timer = max(_attack_buffer_timer - delta, 0.0)
	if _attack_move_slow_timer > 0:
		_attack_move_slow_timer = max(_attack_move_slow_timer - delta, 0.0)


func _get_attack_movement_scale() -> float:
	if _attack_move_slow_timer <= 0:
		return 1.0
	if feel_tuning == null:
		return 1.0
	return feel_tuning.attack_move_slow_multiplier


func _get_attack_move_slow_time() -> float:
	if feel_tuning == null:
		return 0.0
	return feel_tuning.attack_move_slow_time


func _get_attack_buffer_window() -> float:
	if feel_tuning == null:
		return 0.0
	return feel_tuning.attack_buffer_window


func _on_feel_tuning_changed() -> void:
	_apply_feel_tuning()


func _apply_feel_tuning() -> void:
	if feel_tuning == null:
		return
	movement.apply_tuning(feel_tuning)
