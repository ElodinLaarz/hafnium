extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player_character.tscn")
const RUN_CONTEXT_SCRIPT = preload("res://scripts/run/run_context.gd")
const UI_SCENE: PackedScene = preload("res://scenes/interface/ui.tscn")
const DUMMY_SCENE: PackedScene = preload("res://scenes/npcs/training_slime_dummy.tscn")

@export var player_name: String = "wizard"
@export var player_spawn_position: Vector2 = Vector2(-120, 0)
@export var dummy_spawn_position: Vector2 = Vector2(130, 0)
@export var dummy_scale: Vector2 = Vector2(3, 3)

var _run_context: RunContext

@onready var _dynamic_entities: Node2D = $DynamicEntities


func _ready() -> void:
	_boot_run_context()
	_spawn_player()
	_spawn_dummy()


func get_dynamic_entity_root() -> Node:
	return _dynamic_entities


func _boot_run_context() -> void:
	_run_context = RUN_CONTEXT_SCRIPT.new()
	add_child(_run_context)
	Common.set_run_context(_run_context)
	_run_context.begin_run(Time.get_unix_time_from_system())
	_run_context.attach_world_root(self)


func _spawn_player() -> void:
	var player_node: Node = PLAYER_SCENE.instantiate()
	if not (player_node is PlayerCharacter):
		push_error("DPS training room failed to instantiate PlayerCharacter.")
		return
	var player: PlayerCharacter = player_node
	if not player.load_player_data(player_name):
		push_error("DPS training room failed to load player '%s'." % player_name)
		return

	var player_class: ClassHandler.PlayerClass = player.player_class
	if (
		player_class != null
		and player_class.definition != null
		and player_class.definition.sprite_scene != null
	):
		var player_sprite: AnimatedSprite2D = player_class.definition.sprite_scene.instantiate()
		player_sprite.name = "PlayerSprite"
		player.add_child(player_sprite)

	player.position = player_spawn_position
	add_child(player)
	_run_context.register_player(player)

	var ui_instance: Node = UI_SCENE.instantiate()
	add_child(ui_instance)


func _spawn_dummy() -> void:
	if DUMMY_SCENE == null:
		return
	var dummy_node: Node = DUMMY_SCENE.instantiate()
	if not (dummy_node is BaseCharacter):
		push_error("Training dummy scene must inherit BaseCharacter.")
		return
	var dummy: BaseCharacter = dummy_node
	dummy.position = dummy_spawn_position
	dummy.scale = dummy_scale
	_dynamic_entities.add_child(dummy)
