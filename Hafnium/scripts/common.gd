extends Node

var bomb_weapon: Resource = load("res://scenes/weapons/player_bomb.tscn")

# Not totally sure if this will work for melee attacks...
var player_attack_projectile : Resource  # Should be initialized to the player's attack proj by the player

signal start_game_type(object_to_free: Control, game_type: Common.GameType, save_file: String)
const START_GAME_TYPE: String = "start_game_type"
enum GameType {SINGLE_PLAYER, LOAD_GAME, MULTIPLAYER}

var player_character: CharacterBody2D
var player_class: ClassHandler.PlayerClass
var player_heart_containers: Node
var load_player: Callable

var attack_spawn_angle: float = 0 
var attack_displacement_magnitude: float = 15

func place_bomb() -> bool:
  if !player_class.use_resource("bomb", 1):
    return false
  var bomb = bomb_weapon.instantiate()        
  bomb.position = player_character.position
  get_parent().add_child(bomb)
  return true

func attack() -> bool:
  if !player_class.attack():
    return false
  var stats: Stats = player_class.stats
  var p = player_attack_projectile.instantiate()
  p.rotation = PI+attack_spawn_angle # We should have projectiles point right, actually...
  var aim_dir = Vector2(cos(attack_spawn_angle), sin(attack_spawn_angle))
  p.position = player_character.position + aim_dir * attack_displacement_magnitude 
  # Have the proj have a non-zero velocity in the direction
  # of the aim sight.
  p.velocity = aim_dir * stats.projectile_speed 
  p.damage = stats.damage 
  p.ttl = stats.attack_range / stats.projectile_speed
  get_parent().add_child(p)
  return true

func projectile_resolve(creature: CharacterBody2D, proj: CharacterBody2D):
  if !proj.has_method("is_projectile"):
    print("requested projectile_resolve on a non-projectile!")
    return
  if !creature.has_method("is_enemy"):
    # Only deal damage to enemies.
    return
  proj.call_deferred("queue_free")
  var damage = proj.damage
  var creatureDefeated = creature.stats.take_damage(damage)
  # Get damage value from proj and apply health reduction
  # to creature.
  # Returns true when creature has 0 health.
  if creatureDefeated:
    creature.call_deferred("queue_free")
    var reward_spawn_pos = creature.position
    var reward_details = creature.drop_reward()
    if len(reward_details) > 0:
      var reward = reward_details[0]
      var count = reward_details[1]
      for i in range(count):
        var r = reward.instantiate()
        r.position = reward_spawn_pos + a_little_offset(5)
        get_parent().call_deferred("add_child", r)
    else:
      print("No reward to drop. :(")

func a_little_offset(max_offset: float) -> Vector2:
  var random_modulus: float = randf_range(0, max_offset)
  return random_modulus * Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
