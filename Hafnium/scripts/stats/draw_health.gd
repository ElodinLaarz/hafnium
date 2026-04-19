class_name PlayerHealth
extends Node

const PLAYER_HEART: PackedScene = preload("res://scenes/interface/lifebar/heart.tscn")
const INTERFACE_UPDATER: GDScript = preload("res://scripts/interface/update_interface.gd")
const GameConstants = preload("res://scripts/config/game_constants.gd")

var run_context: RunContext
var tracked_player: PlayerCharacter
var interface_values: INTERFACE_UPDATER.InterfaceValues = INTERFACE_UPDATER.InterfaceValues.new()


func _ready() -> void:
	call_deferred("_bind_run_context")


func dequeue_children(parent: Node) -> void:
	while parent.get_child_count() > 0:
		parent.get_child(0).queue_free()


func set_num_hearts(heart_container: Node, num_hearts: int) -> void:
	if heart_container.get_child_count() != num_hearts:
		dequeue_children(heart_container)
		for i: int in range(num_hearts):
			var heart: Node = PLAYER_HEART.instantiate()
			heart_container.add_child(heart)


func check_and_create_hearts(player: PlayerCharacter) -> void:
	if player == null or player.player_class == null:
		print("Error: Player class not set.")
		return
	var stats: Stats = player.player_class.stats
	var max_health: int = stats.max_health
	var mult: int = stats.health_to_damage_multiplier
	if mult <= 0:
		print("Error: health_to_damage_multiplier must be positive for heart UI.")
		return
	if max_health % mult != 0:
		print(
			(
				"Warning: Max health %d is not a multiple of the health to damage multiplier %d."
				% [max_health, mult]
			)
		)
		print("Warning: Value will be truncated.")
	var heart_counter: int = max_health / mult
	var heart_container: Node = self.get_node("HeartContainer")
	Common.player_heart_containers = heart_container
	# TODO(ElodinLaarz): Need to add error handling at some point...
	set_num_hearts(heart_container, heart_counter)

	# Draw appropriate hearts based on the current health.
	player.player_class.draw_hearts(heart_container)


func _bind_run_context() -> void:
	run_context = Common.run_context
	if run_context == null:
		return

	if not run_context.primary_player_changed.is_connected(_on_primary_player_changed):
		run_context.primary_player_changed.connect(_on_primary_player_changed)
	if not run_context.health_changed.is_connected(_on_health_changed):
		run_context.health_changed.connect(_on_health_changed)
	if not run_context.resource_changed.is_connected(_on_resource_changed):
		run_context.resource_changed.connect(_on_resource_changed)
	if not run_context.currency_changed.is_connected(_on_currency_changed):
		run_context.currency_changed.connect(_on_currency_changed)
	if not run_context.room_entered.is_connected(_on_room_entered):
		run_context.room_entered.connect(_on_room_entered)

	if run_context.primary_player != null:
		_on_primary_player_changed(run_context.primary_player)


func _on_primary_player_changed(player: PlayerCharacter) -> void:
	tracked_player = player
	check_and_create_hearts(player)
	_render_player_state()


func _on_health_changed(_current_health: int, _max_health: int) -> void:
	if tracked_player == null or tracked_player.player_class == null:
		return
	check_and_create_hearts(tracked_player)
	_render_player_state()


func _on_resource_changed(resource_name: String, current_value: int, max_value: int) -> void:
	if resource_name == GameConstants.RESOURCE_BOMB:
		interface_values.bombs = current_value
		interface_values.bomb_max = max_value
		INTERFACE_UPDATER.update_interface(_get_interface_root(), interface_values)
	elif resource_name == GameConstants.RESOURCE_MANA:
		interface_values.mana_current = current_value
		interface_values.mana_max = max_value
		INTERFACE_UPDATER.update_interface(_get_interface_root(), interface_values)


func _on_currency_changed(current_currency: int) -> void:
	interface_values.currency = current_currency
	INTERFACE_UPDATER.update_interface(_get_interface_root(), interface_values)


func _on_room_entered(room_id: String) -> void:
	interface_values.room_name = room_id
	INTERFACE_UPDATER.update_interface(_get_interface_root(), interface_values)


func _render_player_state() -> void:
	if tracked_player == null or tracked_player.player_class == null:
		return
	var pc: ClassHandler.PlayerClass = tracked_player.player_class
	interface_values.health = pc.stats.current_health
	interface_values.max_health = pc.stats.max_health
	interface_values.currency = tracked_player.currency
	interface_values.bomb_max = tracked_player.bomb_max
	var bomb_status: Stats.ResourceStatus = pc.stats.resources.get(GameConstants.RESOURCE_BOMB)
	interface_values.bombs = bomb_status.current_resource if bomb_status != null else 0
	interface_values.show_mana_bar = pc.name == ClassHandler.ClassName.WIZARD
	var mana_status: Stats.ResourceStatus = pc.stats.resources.get(GameConstants.RESOURCE_MANA)
	if mana_status != null:
		interface_values.mana_current = mana_status.current_resource
		interface_values.mana_max = mana_status.max_resource
	else:
		interface_values.mana_current = 0
		interface_values.mana_max = 0
	interface_values.room_name = (
		run_context.current_room.id
		if run_context != null and run_context.current_room != null
		else "Unknown"
	)
	INTERFACE_UPDATER.update_interface(_get_interface_root(), interface_values)


func _get_interface_root() -> Node:
	if get_node_or_null("CounterMargins") != null:
		return self
	var parent: Node = get_parent()
	if parent != null and parent.get_node_or_null("CounterMargins") != null:
		return parent
	return self
