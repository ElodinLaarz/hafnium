extends Control

@onready var multiplayer_overlay: Control = %MultiplayerOverlay


func become_host() -> void:
	print("Become host pressed!")
	multiplayer_overlay.hide()
	MultiplayerManager.become_host()


func join_game_pressed() -> void:
	print("Join game pressed!")
	multiplayer_overlay.hide()
	MultiplayerManager.join_game()
