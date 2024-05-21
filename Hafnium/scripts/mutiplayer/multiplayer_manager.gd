extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

const MULTIPLAYER_PLAYER = preload("res://scenes/test_scenes/multiplayer_player.tscn")

func become_host():
	print("Starting to host!")
	
	var server_peer = ENetMultiplayerPeer.new()
	var server_connection_err: Error = server_peer.create_server(SERVER_PORT)
	# Handle the error...
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)

func join_game():
	print("Joining game...")
	
	var client_peer = ENetMultiplayerPeer.new()
	var client_connection_err: Error = client_peer.create_client(SERVER_IP, SERVER_PORT)
	# Handle the error...
	
	multiplayer.multiplayer_peer = client_peer

func _add_player_to_game(id: int):
	print("Player %d joined the game!" % id)
	
	var player_to_add = MULTIPLAYER_PLAYER.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)

func _del_player(id: int):
	print("Player %d left the game :(" % id)