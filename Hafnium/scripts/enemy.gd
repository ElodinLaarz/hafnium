class_name Enemy
extends "res://scripts/base_character.gd"

var movement = EnemyMovement.new()
var rng = RandomNumberGenerator.new()
var chasing_player: bool = false
var player: CharacterBody2D
var definition
var loot_table

# Keys are probability of the reward dropping and the value is the
# packed resource and the quantity. For convenience, the keys
# sum to 100 because I fear floats.
var reward: Dictionary = {}:
	set(value):
		reward = value
		_sorted_reward_keys = value.keys()
		_sorted_reward_keys.sort()
var _sorted_reward_keys: Array = []


func _init():
	rng.randomize()
	team = Team.ENEMY


func _physics_process(delta: float):
	handle_movement(delta)


# A function to identify this as an enemy.
func is_enemy() -> bool:
	return true


func handle_movement(delta: float):
	if chasing_player:
		movement.set_chase_speed()
	else:
		movement.set_idle_speed()
	var direction: Vector2 = movement.get_direction(position, player)
	# Smooth velocity between current and desired velocity.
	velocity = movement.velocity_lerp(delta, velocity, direction)
	move_and_slide()


func apply_definition(enemy_data) -> void:
	definition = enemy_data
	actor_definition_id = enemy_data.id
	if stats == null:
		stats = Stats.new()
	stats.enemy_init(enemy_data.build_stats())
	movement.chase_speed = enemy_data.speed
	loot_table = enemy_data.loot_table


func drop_reward() -> Array:
	if loot_table != null:
		var loot_drop = loot_table.roll_drop(rng)
		if loot_drop == null:
			return []
		return [loot_drop.item_scene, loot_drop.count]

	# Randomly choose a reward based on probabilities of each reward.
	# Select random integer between 0 and 100 and choose the smallest
	# key greater than or equal to the random integer.
	var got_reward: Array = []
	var rand_int = rng.randi_range(0, 100)
	for key in _sorted_reward_keys:
		if key >= rand_int:
			got_reward = reward[key]
			break
	return got_reward
