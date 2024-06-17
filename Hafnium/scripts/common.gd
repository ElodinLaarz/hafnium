extends Node

var bomb_weapon = load("res://scenes/weapons/player_bomb.tscn")

signal start_game_type(object_to_free: Control, game_type: Common.GameType, save_file: String)
const START_GAME_TYPE: String = "start_game_type"
enum GameType {SINGLE_PLAYER, LOAD_GAME, MULTIPLAYER}

var player_character: CharacterBody2D
var player_class: ClassHandler.PlayerClass
var player_heart_containers: Node
var load_player: Callable

func place_bomb():
    if player_class.has_resource("bomb", 1):
        if !player_class.use_resource("bomb", 1):
            # Not enough bombs-- maybe this can happen under a
            # race condition? Do we need the has_resource, then...?
            # Blah blah blah atomic updates
            return false
        var bomb = bomb_weapon.instantiate()        
        bomb.position = player_character.position
        get_parent().add_child(bomb)
        return true