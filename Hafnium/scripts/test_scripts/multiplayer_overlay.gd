extends Control

@onready var multiplayer_overlay = $"."

func become_host():
	print("Become host pressed!")
	multiplayer_overlay.hide()
	MultiplayerManager.become_host()

func join_game_pressed():
	print("Join game pressed!")
	multiplayer_overlay.hide()
	MultiplayerManager.join_game()
