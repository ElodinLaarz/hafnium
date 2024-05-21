extends Node

const MULTIPLAYER_PLAYER = preload("res://scenes/multiplayer_player.tscn")

const MAIN_SCENE: String = "MainScene"
const MULTIPLAYER_PLAYERS_NAME: String = "Players"
const SINGLE_PLAYER_NAME: String = "Player" # To remove single player controller.

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var _main_scene

func become_host():
	print("Starting to host!")
	
	var scene_switcher = get_tree().get_current_scene()
	_main_scene = scene_switcher.get_node(MAIN_SCENE) 
	
	var server_peer = ENetMultiplayerPeer.new()
	var server_connection_err: Error = server_peer.create_server(SERVER_PORT)
	# Handle the error...
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)

	_remove_single_player()
	_add_player_to_game(1) # Add the host player

func join_game():
	print("Joining game...")

	var client_peer = ENetMultiplayerPeer.new()
	var client_connection_err: Error = client_peer.create_client(SERVER_IP, SERVER_PORT)
	print(client_connection_err)
	# Handle the error...
	
	multiplayer.multiplayer_peer = client_peer

	_remove_single_player()

func _add_player_to_game(id: int):
	print("Player %d joined the game!" % id)
	
	var player_to_add = MULTIPLAYER_PLAYER.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	var player_spawn_node = _main_scene.get_node(MULTIPLAYER_PLAYERS_NAME)
	player_spawn_node.add_child(player_to_add, true)

func _del_player(id: int):
	print("Player %d left the game :(" % id)
	var player_spawn_node = _main_scene.get_node(MULTIPLAYER_PLAYERS_NAME)
	if not player_spawn_node.has_node(str(id)):
		return
	player_spawn_node.get_node(str(id)).queue_free()
	
func _remove_single_player():
	print("Remove single player")
	# This has to be instantiated on clients separate from the server.
	var main_scene = get_tree().get_current_scene().get_node(MAIN_SCENE)
	var player_to_remove = main_scene.get_node(SINGLE_PLAYER_NAME)
	player_to_remove.queue_free()
