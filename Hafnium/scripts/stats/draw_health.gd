extends Node

const PLAYER_HEART = preload("res://scenes/interface/lifebar/heart.tscn")

func create_child()

func create_heart_child():
	var heart = PLAYER_HEART.instance()
	add_child(heart)
	return heart

func update_health(player_character: PlayerCharacter):
	var stats: Stats = player_character.player_stats
	var pc: ClassHandler.PlayerClass = player_character.player_class
	# Make sure you have the right number of child components with 
	# hearts.
	# Update the icon for each heart based on the current status.
	# TODO(ElodinLaarz): Could probably ask each class for a map
	# to draw their health...
