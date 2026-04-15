extends Node

const MULTIPLAYER_PLAYER: Resource = preload("res://scenes/multiplayer_player.tscn")

const MAIN_SCENE: String = "MainScene"
const MULTIPLAYER_PLAYERS_NAME: String = "Players"
const SINGLE_PLAYER_NAME: String = "Player"  # To remove single player controller.

const SERVER_PORT: int = 8080
const SERVER_IP: String = "127.0.0.1"

var _main_scene: Node


func become_host() -> void:
	print("Starting to host!")

	_main_scene = _resolve_main_scene()

	var server_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var server_connection_err: Error = server_peer.create_server(SERVER_PORT)
	print_debug(server_connection_err)
	# Handle the error...

	multiplayer.multiplayer_peer = server_peer

	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)

	_remove_single_player()
	_add_player_to_game(1)  # Add the host player


func join_game() -> void:
	print("Joining game...")

	var client_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var client_connection_err: Error = client_peer.create_client(SERVER_IP, SERVER_PORT)
	print(client_connection_err)
	# Handle the error...

	multiplayer.multiplayer_peer = client_peer

	_remove_single_player()


func _add_player_to_game(id: int) -> void:
	print("Player %d joined the game!" % id)

	var player_to_add: Node = MULTIPLAYER_PLAYER.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)

	var player_spawn_node: Node = _main_scene.get_node(MULTIPLAYER_PLAYERS_NAME)
	player_spawn_node.add_child(player_to_add, true)


func _del_player(id: int) -> void:
	print("Player %d left the game :(" % id)
	var player_spawn_node: Node = _main_scene.get_node(MULTIPLAYER_PLAYERS_NAME)
	if not player_spawn_node.has_node(str(id)):
		return
	player_spawn_node.get_node(str(id)).queue_free()


func _remove_single_player() -> void:
	print("Remove single player")
	# This has to be instantiated on clients separate from the server.
	var main_scene: Node = _resolve_main_scene()
	var player_to_remove: Node = main_scene.get_node(SINGLE_PLAYER_NAME)
	player_to_remove.queue_free()


func _resolve_main_scene() -> Node:
	if Common.run_context != null and Common.run_context.world_root != null:
		return Common.run_context.world_root
	return get_tree().get_current_scene().get_node(MAIN_SCENE)
