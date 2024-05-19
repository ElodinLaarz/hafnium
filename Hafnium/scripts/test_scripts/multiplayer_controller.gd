extends CharacterBody2D

@export var player_id: int = 1:
	set(id):
		player_id = id

# Update Multiplayer Position using input from network.
