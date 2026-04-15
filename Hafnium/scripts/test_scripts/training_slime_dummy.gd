extends "res://scripts/slime.gd"

const INFINITE_HEALTH: int = 1000000000
const DPS_WINDOW_SECONDS: float = 3.0
const LABEL_VERTICAL_OFFSET: Vector2 = Vector2(0, -60)

var _damage_events: Array[Dictionary] = []
@onready var _detection_area: Area2D = $Detection
@onready var _dps_label: Label = $DpsLabel


func _ready() -> void:
	super._ready()
	chasing_player = false
	player = null
	movement.chase_speed = 0
	movement.idle_speed = 0
	if stats != null:
		stats.max_health = INFINITE_HEALTH
		stats.current_health = INFINITE_HEALTH
	if _detection_area != null:
		_detection_area.monitoring = false
		_detection_area.monitorable = false
	if _dps_label != null:
		_dps_label.set_as_top_level(true)
	_update_dps_label()
	if not damage_received.is_connected(_on_damage_received):
		damage_received.connect(_on_damage_received)


func _process(delta: float) -> void:
	super._process(delta)
	_prune_old_events()
	_update_dps_label()
	_update_label_position()


func _physics_process(_delta: float) -> void:
	# Training dummy intentionally stays fixed.
	pass


func take_damage(_d: int) -> bool:
	# Never dies; RunContext still receives damage via damage_received signal.
	if stats != null:
		stats.current_health = INFINITE_HEALTH
	return false


func drop_reward() -> Array:
	return []


func _on_damage_received(payload: Damage, _remaining_health: int) -> void:
	if payload == null:
		return
	_damage_events.append({"time": _now_seconds(), "damage": max(payload.amount, 0)})
	_prune_old_events()
	_update_dps_label()


func _prune_old_events() -> void:
	var cutoff: float = _now_seconds() - DPS_WINDOW_SECONDS
	while not _damage_events.is_empty() and float(_damage_events[0].get("time", 0.0)) < cutoff:
		_damage_events.remove_at(0)


func _update_dps_label() -> void:
	if _dps_label == null:
		return
	var total_damage: int = 0
	for event: Dictionary in _damage_events:
		total_damage += int(event.get("damage", 0))
	var dps: float = float(total_damage) / DPS_WINDOW_SECONDS
	_dps_label.text = "DPS: %.1f" % dps


func _update_label_position() -> void:
	if _dps_label == null:
		return
	_dps_label.global_position = global_position + LABEL_VERTICAL_OFFSET


func _now_seconds() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
