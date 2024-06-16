extends Node

signal start_game_type(object_to_free: Control, game_type: Common.GameType, save_file: String)
const START_GAME_TYPE: String = "start_game_type"
enum GameType {SINGLE_PLAYER, LOAD_GAME, MULTIPLAYER}

var player_character: CharacterBody2D
var player_class: ClassHandler.PlayerClass
var player_heart_containers: Node
var load_player: Callable