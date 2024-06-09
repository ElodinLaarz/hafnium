extends Node

enum GameType {SINGLE_PLAYER, MULTIPLAYER}

var player_character: CharacterBody2D
var player_class: ClassHandler.PlayerClass
var load_player: Callable