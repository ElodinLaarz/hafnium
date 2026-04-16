class_name DamageTypeTrainingPickup
extends Area2D

## Forces attack element while active (see [member RunContext.use_training_damage_type_override]).

const TOKEN_FILL: Dictionary = {
	Damage.DamageType.BASIC: Color(0.7, 0.68, 0.62),
	Damage.DamageType.FIRE: Color(0.96, 0.22, 0.08),
	Damage.DamageType.ICE: Color(0.12, 0.62, 0.95),
	Damage.DamageType.NATURE: Color(0.16, 0.78, 0.32),
	Damage.DamageType.PHYSICAL: Color(0.78, 0.5, 0.28),
}
const CLEAR_FILL_COLOR: Color = Color(0.38, 0.42, 0.52)

@export var grant_element: Damage.DamageType = Damage.DamageType.FIRE
@export var clears_override: bool = false
@export var respawn_seconds: float = 1.5

@onready var _visual: Node2D = $Visual
@onready var _diamond: Polygon2D = $Visual/Diamond
@onready var _token_label: Label = $Visual/TokenLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 3
	monitoring = true
	monitorable = false
	_style_token_label()
	_apply_token_appearance()


func _style_token_label() -> void:
	if _token_label == null:
		return
	_token_label.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0, 1.0))
	_token_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.82))
	_token_label.add_theme_constant_override("shadow_offset_x", 1)
	_token_label.add_theme_constant_override("shadow_offset_y", 1)


func _apply_token_appearance() -> void:
	if _token_label == null:
		return
	if clears_override:
		_token_label.text = "Class default"
		_set_diamond_colors(CLEAR_FILL_COLOR)
	else:
		_token_label.text = Damage.damage_type_label(grant_element)
		var fill: Color = TOKEN_FILL.get(grant_element, Color(0.75, 0.75, 0.75))
		_set_diamond_colors(fill)


func _set_diamond_colors(fill: Color) -> void:
	if _diamond != null:
		_diamond.color = fill


func _on_body_entered(body: Node2D) -> void:
	if not body is PlayerCharacter:
		return
	var rc: RunContext = Common.run_context
	if rc == null:
		return
	if clears_override:
		rc.set_training_damage_type_override(false, Damage.DamageType.BASIC)
	else:
		rc.set_training_damage_type_override(true, grant_element)
	_begin_respawn()


func _begin_respawn() -> void:
	set_deferred("monitoring", false)
	if _visual != null:
		_visual.visible = false
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	await tree.create_timer(respawn_seconds).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if _visual != null:
		_visual.visible = true
	set_deferred("monitoring", true)
