extends Node2D

const ROOM_DATA_SCRIPT = preload("res://scripts/resources/room_data.gd")

const ENEMY_ID := "enemy:slime_basic"
const FLOOR_COLOR := Color(0.117647, 0.129412, 0.156863, 1.0)
const BORDER_COLOR := Color(0.345098, 0.392157, 0.470588, 1.0)

@export var room_scale_tiles: int = 12
@export var tile_size: int = 16
@export var wall_thickness: float = 24.0
@export var spawn_margin: float = 56.0
@export var ring_capacity: int = 8

var current_room_index: int = 0
var remaining_enemies: int = 0
var _advance_scheduled: bool = false

@onready var generated_room: Node2D = $GeneratedRoom


func _ready() -> void:
	if (
		Common.run_context != null
		and not Common.run_context.enemy_defeated.is_connected(_on_enemy_defeated)
	):
		Common.run_context.enemy_defeated.connect(_on_enemy_defeated)
	call_deferred("_start_initial_room")


func get_room_size_tiles(room_index: int) -> Vector2i:
	var safe_room_index: int = max(room_index, 1)
	var safe_room_scale_tiles: int = max(room_scale_tiles, 1)
	var side_length: int = safe_room_index * safe_room_scale_tiles
	return Vector2i(side_length, side_length)


func get_room_half_extents(room_index: int) -> Vector2:
	var room_size_tiles := get_room_size_tiles(room_index)
	return Vector2(room_size_tiles.x * tile_size, room_size_tiles.y * tile_size) * 0.5


func build_spawn_positions(room_index: int) -> Array[Vector2]:
	var spawn_positions: Array[Vector2] = []
	var count: int = max(room_index, 1)
	var half_extents := get_room_half_extents(room_index)
	var max_radius: float = min(half_extents.x, half_extents.y) - spawn_margin
	max_radius = max(max_radius, 48.0)
	var safe_ring_capacity: int = max(ring_capacity, 1)
	var estimated_ring_count: float = max(ceil(float(count) / float(safe_ring_capacity)), 1.0)
	var radius_step: float = max(max_radius / estimated_ring_count, 48.0)

	for i in range(count):
		var ring_index: int = i / safe_ring_capacity
		var slot_index: int = i % safe_ring_capacity
		var slots_in_ring: int = mini(count - ring_index * safe_ring_capacity, safe_ring_capacity)
		var radius: float = min(radius_step * float(ring_index + 1), max_radius)
		var angle_offset: float = float(ring_index) * PI / 8.0
		var angle: float = angle_offset + TAU * float(slot_index) / float(max(slots_in_ring, 1))
		spawn_positions.append(Vector2.RIGHT.rotated(angle) * radius)

	return spawn_positions


func _start_initial_room() -> void:
	_load_room(1)


func _load_room(room_index: int) -> void:
	current_room_index = max(room_index, 1)
	remaining_enemies = 0
	_advance_scheduled = false

	_clear_dynamic_children()
	_rebuild_room_geometry(current_room_index)
	_center_primary_player()
	_emit_room_state(current_room_index)
	_spawn_wave(current_room_index)


func _spawn_wave(room_index: int) -> void:
	if Common.run_context == null:
		return

	var attempted_spawn_count: int = 0
	var successful_spawn_count: int = 0
	for spawn_position in build_spawn_positions(room_index):
		attempted_spawn_count += 1
		var enemy = Common.run_context.spawn_enemy(ENEMY_ID, spawn_position)
		if enemy != null:
			successful_spawn_count += 1
			remaining_enemies += 1

	if attempted_spawn_count > 0 and successful_spawn_count <= 0:
		push_warning("Failed to spawn enemies for room %d" % room_index)
		return

	if remaining_enemies <= 0 and not _advance_scheduled:
		_advance_scheduled = true
		call_deferred("_advance_to_next_room")


func _advance_to_next_room() -> void:
	_load_room(current_room_index + 1)


func _clear_dynamic_children() -> void:
	for child in get_children():
		if child == generated_room:
			continue
		if child is CanvasLayer:
			continue
		if child.has_method("is_player"):
			continue
		child.queue_free()

	for child in generated_room.get_children():
		child.queue_free()


func _rebuild_room_geometry(room_index: int) -> void:
	var half_extents := get_room_half_extents(room_index)
	var floor_points := PackedVector2Array(
		[
			Vector2(-half_extents.x, -half_extents.y),
			Vector2(half_extents.x, -half_extents.y),
			Vector2(half_extents.x, half_extents.y),
			Vector2(-half_extents.x, half_extents.y),
		]
	)

	var floor := Polygon2D.new()
	floor.polygon = floor_points
	floor.color = FLOOR_COLOR
	generated_room.add_child(floor)

	var border := Line2D.new()
	border.width = 6.0
	border.closed = true
	border.default_color = BORDER_COLOR
	border.points = floor_points
	generated_room.add_child(border)

	var walls := StaticBody2D.new()
	generated_room.add_child(walls)

	_add_wall(
		walls,
		Vector2(0, -half_extents.y - wall_thickness * 0.5),
		Vector2(half_extents.x * 2.0 + wall_thickness * 2.0, wall_thickness)
	)
	_add_wall(
		walls,
		Vector2(0, half_extents.y + wall_thickness * 0.5),
		Vector2(half_extents.x * 2.0 + wall_thickness * 2.0, wall_thickness)
	)
	_add_wall(
		walls,
		Vector2(-half_extents.x - wall_thickness * 0.5, 0),
		Vector2(wall_thickness, half_extents.y * 2.0)
	)
	_add_wall(
		walls,
		Vector2(half_extents.x + wall_thickness * 0.5, 0),
		Vector2(wall_thickness, half_extents.y * 2.0)
	)


func _add_wall(parent: Node, wall_position: Vector2, wall_size: Vector2) -> void:
	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = wall_size
	collision_shape.shape = rectangle
	collision_shape.position = wall_position
	parent.add_child(collision_shape)


func _center_primary_player() -> void:
	if Common.run_context == null or Common.run_context.primary_player == null:
		return
	Common.run_context.primary_player.position = Vector2.ZERO


func _emit_room_state(room_index: int) -> void:
	if Common.run_context == null:
		return

	var room_data = ROOM_DATA_SCRIPT.new()
	room_data.id = "Room %d" % room_index
	room_data.room_kind = "combat"
	Common.run_context.current_room = room_data
	Common.run_context.room_entered.emit(room_data.id)


func _on_enemy_defeated(_enemy_id: String) -> void:
	if current_room_index <= 0 or remaining_enemies <= 0:
		return

	remaining_enemies -= 1
	if remaining_enemies <= 0 and not _advance_scheduled:
		_advance_scheduled = true
		call_deferred("_advance_to_next_room")
