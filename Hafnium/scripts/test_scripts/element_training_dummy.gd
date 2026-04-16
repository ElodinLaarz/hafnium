class_name ElementTrainingDummy
extends "res://scripts/test_scripts/training_slime_dummy.gd"

## World space; labels use set_as_top_level so dummy scale does not stretch text.
const DPS_Y_BELOW_FEET: float = 14.0
const GAP_BETWEEN_DPS_AND_PROFILE: float = 8.0
const PROFILE_LABEL_WIDTH: float = 200.0

@export_group("Damage multipliers", "dmg_")
@export var dmg_basic: float = 1.0
@export var dmg_fire: float = 1.0
@export var dmg_ice: float = 1.0
@export var dmg_nature: float = 1.0
@export var dmg_physical: float = 1.0

@onready var _profile_hint: Label = $ProfileHint


func _ready() -> void:
	super._ready()
	if _dps_label != null:
		_dps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _profile_hint != null:
		_profile_hint.set_as_top_level(true)
		_profile_hint.scale = Vector2.ONE
		_profile_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_profile_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_profile_hint.custom_minimum_size = Vector2(PROFILE_LABEL_WIDTH, 0.0)
	_update_profile_hint()


func _multiplier_for(t: Damage.DamageType) -> float:
	match t:
		Damage.DamageType.BASIC:
			return dmg_basic
		Damage.DamageType.FIRE:
			return dmg_fire
		Damage.DamageType.ICE:
			return dmg_ice
		Damage.DamageType.NATURE:
			return dmg_nature
		Damage.DamageType.PHYSICAL:
			return dmg_physical
		_:
			return 1.0


func receive_damage(payload: Damage) -> bool:
	if payload == null:
		return false
	var mult: float = _multiplier_for(payload.damage_type)
	var adj: int = maxi(0, int(round(float(payload.amount) * mult)))
	var adjusted: Damage = Damage.typed(
		adj,
		payload.damage_type,
		payload.source,
		payload.source_team,
		payload.metadata.duplicate(true)
	)
	adjusted.metadata["damage_type_multiplier"] = mult
	return super.receive_damage(adjusted)


func _update_profile_hint() -> void:
	if _profile_hint == null:
		return
	_profile_hint.text = _build_profile_description()


func _is_neutral_profile() -> bool:
	return (
		is_equal_approx(dmg_basic, 1.0)
		and is_equal_approx(dmg_fire, 1.0)
		and is_equal_approx(dmg_ice, 1.0)
		and is_equal_approx(dmg_nature, 1.0)
		and is_equal_approx(dmg_physical, 1.0)
	)


func _build_profile_description() -> String:
	if _is_neutral_profile():
		return (
			"This dummy has no elemental modifiers. "
			+ "Every damage type deals the baseline amount (100%)."
		)
	var lines: PackedStringArray = []
	lines.append("Modifiers (100% = baseline):")
	_append_line(lines, Damage.DamageType.BASIC, dmg_basic)
	_append_line(lines, Damage.DamageType.FIRE, dmg_fire)
	_append_line(lines, Damage.DamageType.ICE, dmg_ice)
	_append_line(lines, Damage.DamageType.NATURE, dmg_nature)
	_append_line(lines, Damage.DamageType.PHYSICAL, dmg_physical)
	return "\n".join(lines)


func _append_line(lines: PackedStringArray, t: Damage.DamageType, mult: float) -> void:
	if is_equal_approx(mult, 1.0):
		return
	var name: String = Damage.damage_type_label(t)
	var pct: int = int(round(mult * 100.0))
	var note: String
	if mult <= 0.001:
		note = "immune"
	elif mult > 1.0:
		note = "vulnerable"
	else:
		note = "resistant"
	lines.append("• %s: %d%% — %s" % [name, pct, note])


func _update_label_position() -> void:
	var cursor_y: float = global_position.y + DPS_Y_BELOW_FEET
	if _dps_label != null:
		_dps_label.reset_size()
		_dps_label.global_position = Vector2(global_position.x - _dps_label.size.x * 0.5, cursor_y)
		cursor_y = _dps_label.global_position.y + _dps_label.size.y + GAP_BETWEEN_DPS_AND_PROFILE
	if _profile_hint != null:
		_profile_hint.reset_size()
		_profile_hint.global_position = Vector2(
			global_position.x - _profile_hint.size.x * 0.5, cursor_y
		)
