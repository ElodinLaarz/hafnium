extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player_character.tscn")
const RUN_CONTEXT_SCRIPT = preload("res://scripts/run/run_context.gd")
const UI_SCENE: PackedScene = preload("res://scenes/interface/ui.tscn")
const ELEMENT_DUMMY_SCENE: PackedScene = preload("res://scenes/npcs/element_training_dummy.tscn")
const PICKUP_SCENE: PackedScene = preload(
	"res://scenes/test_scenes/damage_type_training_pickup.tscn"
)

@export var player_name: String = "wizard"
@export var player_spawn_position: Vector2 = Vector2(-200, 0)

var _run_context: RunContext

@onready var _dynamic_entities: Node2D = $DynamicEntities
@onready var _pickups: Node2D = $Pickups
@onready var _element_hud: Label = $CanvasLayer/ElementHud


func _ready() -> void:
	_boot_run_context()
	_spawn_player()
	_spawn_dummies()
	_spawn_pickups()
	_connect_hud()
	_refresh_hud()


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
		push_error("Element training room failed to instantiate PlayerCharacter.")
		return
	var player: PlayerCharacter = player_node
	if not player.load_player_data(player_name):
		push_error("Element training room failed to load player '%s'." % player_name)
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


func _spawn_dummies() -> void:
	var configs: Array[Dictionary] = [
		{
			"pos": Vector2(-40, -100),
			"scale": Vector2(2.5, 2.5),
			"dmg_fire": 0.5,
			"dmg_ice": 1.5,
			"mod": Color(0.35, 0.75, 1.0),
		},
		{
			"pos": Vector2(120, -100),
			"scale": Vector2(2.5, 2.5),
			"dmg_fire": 1.5,
			"dmg_ice": 0.5,
			"mod": Color(1.0, 0.45, 0.25),
		},
		{
			"pos": Vector2(-40, 100),
			"scale": Vector2(2.5, 2.5),
			"dmg_physical": 1.5,
			"dmg_nature": 0.5,
			"mod": Color(0.45, 0.85, 0.4),
		},
		{
			"pos": Vector2(120, 100),
			"scale": Vector2(2.5, 2.5),
			"dmg_nature": 1.5,
			"dmg_physical": 0.5,
			"mod": Color(0.75, 0.45, 1.0),
		},
		{
			"pos": Vector2(200, 0),
			"scale": Vector2(2.2, 2.2),
			"dmg_basic": 1.0,
			"dmg_fire": 1.0,
			"dmg_ice": 1.0,
			"dmg_nature": 1.0,
			"dmg_physical": 1.0,
			"mod": Color(0.85, 0.85, 0.85),
		},
	]
	for cfg: Dictionary in configs:
		var node: Node = ELEMENT_DUMMY_SCENE.instantiate()
		if not (node is ElementTrainingDummy):
			push_error("Expected ElementTrainingDummy scene.")
			continue
		var dummy: ElementTrainingDummy = node
		dummy.position = cfg.get("pos", Vector2.ZERO)
		dummy.scale = cfg.get("scale", Vector2.ONE)
		dummy.dmg_basic = float(cfg.get("dmg_basic", dummy.dmg_basic))
		dummy.dmg_fire = float(cfg.get("dmg_fire", dummy.dmg_fire))
		dummy.dmg_ice = float(cfg.get("dmg_ice", dummy.dmg_ice))
		dummy.dmg_nature = float(cfg.get("dmg_nature", dummy.dmg_nature))
		dummy.dmg_physical = float(cfg.get("dmg_physical", dummy.dmg_physical))
		var sprite: Node = dummy.get_node_or_null("SlimeSprite")
		if sprite is CanvasItem:
			(sprite as CanvasItem).modulate = cfg.get("mod", Color.WHITE)
		_dynamic_entities.add_child(dummy)


func _spawn_pickups() -> void:
	var token_specs: Array[Dictionary] = [
		{"pos": Vector2(-120, -40), "element": Damage.DamageType.BASIC},
		{"pos": Vector2(-120, 0), "element": Damage.DamageType.FIRE},
		{"pos": Vector2(-120, 40), "element": Damage.DamageType.ICE},
		{"pos": Vector2(-120, 80), "element": Damage.DamageType.NATURE},
		{"pos": Vector2(-120, 120), "element": Damage.DamageType.PHYSICAL},
		{"pos": Vector2(-160, 80), "clear": true},
	]
	for spec: Dictionary in token_specs:
		var pickup: DamageTypeTrainingPickup = (
			PICKUP_SCENE.instantiate() as DamageTypeTrainingPickup
		)
		if pickup == null:
			continue
		pickup.position = spec.get("pos", Vector2.ZERO)
		if spec.get("clear", false):
			pickup.clears_override = true
		else:
			pickup.clears_override = false
			pickup.grant_element = spec.get("element", Damage.DamageType.BASIC)
		_pickups.add_child(pickup)


func _connect_hud() -> void:
	if _run_context == null:
		return
	if not _run_context.training_damage_type_override_changed.is_connected(
		_on_training_element_changed
	):
		_run_context.training_damage_type_override_changed.connect(_on_training_element_changed)


func _on_training_element_changed(_active: bool, _element: Damage.DamageType) -> void:
	_refresh_hud()


func _refresh_hud() -> void:
	if _element_hud == null or _run_context == null:
		return
	if _run_context.use_training_damage_type_override:
		var label: String = Damage.damage_type_label(_run_context.training_damage_type_override)
		_element_hud.text = (
			"Attack damage type: %s (set by the last token you walked over). "
			+ "Your projectiles use this element until you touch another token or "
			+ 'the "Class default" token.' % label
		)
	else:
		_element_hud.text = (
			"Attack damage type: follow your class and weapon (no token override). "
			+ "Walk over a colored token on the left to force Fire, Ice, Nature, and so on."
		)
