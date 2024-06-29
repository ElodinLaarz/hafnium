extends Node

var bomb_weapon = load("res://scenes/weapons/player_bomb.tscn")

# Not totally sure if this will work for melee attacks...
var player_attack_projectile : Resource  # Should be initialized to the player's attack projectile by the player

signal start_game_type(object_to_free: Control, game_type: Common.GameType, save_file: String)
const START_GAME_TYPE: String = "start_game_type"
enum GameType {SINGLE_PLAYER, LOAD_GAME, MULTIPLAYER}

var player_character: CharacterBody2D
var player_class: ClassHandler.PlayerClass
var player_heart_containers: Node
var load_player: Callable

func place_bomb() -> bool:
    if !player_class.use_resource("bomb", 1):
        return false
    var bomb = bomb_weapon.instantiate()        
    bomb.position = player_character.position
    get_parent().add_child(bomb)
    return true

func attack() -> bool:
    if !player_class.attack():
        print("can't attack yet! :O")
        return false
    var projectile = player_attack_projectile.instance()
    projectile.position = player_character.position
    get_parent().add_child(projectile)
    return true
    