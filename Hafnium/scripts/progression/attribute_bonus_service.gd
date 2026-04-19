class_name AttributeBonusService
extends Object

const GameConstants = preload("res://scripts/config/game_constants.gd")

const HP_PER_CONSTITUTION: int = 2
const MOVE_SPEED_PER_DEXTERITY: int = 2
const DAMAGE_PER_PRIMARY_ATTRIBUTE: int = 1
const MANA_PER_MAGIC: int = 1
const MIN_ATTACK_COOLDOWN: float = 0.12
const WILLPOWER_ATTACK_COOLDOWN_PER_POINT: float = 0.03


static func apply(player: PlayerCharacter) -> void:
	if player == null or player.player_class == null or player.player_class.definition == null:
		return
	if player.stats == null:
		return
	var prog: PlayerProgression = player.progression
	if prog == null:
		return

	var con: int = prog.get_attribute(PlayerProgression.Attribute.CONSTITUTION)
	var dex: int = prog.get_attribute(PlayerProgression.Attribute.DEXTERITY)
	var mag: int = prog.get_attribute(PlayerProgression.Attribute.MAGIC)
	var will: int = prog.get_attribute(PlayerProgression.Attribute.WILLPOWER)

	var bonus_hp: int = con * HP_PER_CONSTITUTION
	var mult: int = player.stats.health_to_damage_multiplier
	var raw_max: int = player._baseline_max_health + bonus_hp
	var new_max: int = _snap_max_health_to_heart_grid(raw_max, mult)
	var old_max: int = player.stats.max_health
	player.stats.max_health = new_max
	if new_max > old_max:
		player.stats.current_health += new_max - old_max

	var primary_bonus: int = _primary_attribute_bonus(player.player_class.name, con, dex, mag)
	player.stats.damage = player._baseline_damage + primary_bonus

	var base_speed: int = player._baseline_speed + dex * MOVE_SPEED_PER_DEXTERITY
	player.movement.walking_speed = base_speed
	player.movement.running_speed = int(base_speed * player.movement.running_multiplier)
	player.movement.run_to_walk_threshold = (
		player.movement.walking_speed * PlayerCharacter.RUN_TO_WALK_THRESHOLD_FACTOR
	)

	var base_cooldown: float = player._baseline_attack_speed
	var adjusted: float = maxf(
		MIN_ATTACK_COOLDOWN, base_cooldown - float(will) * WILLPOWER_ATTACK_COOLDOWN_PER_POINT
	)
	player.stats.attack_speed = adjusted

	if player.player_class.name == ClassHandler.ClassName.WIZARD:
		player.player_class.class_handler.recompute_wizard_blood_mana(
			player.player_class, mag * MANA_PER_MAGIC
		)
	else:
		var mana_res: Stats.ResourceStatus = player.stats.resources.get(GameConstants.RESOURCE_MANA)
		if mana_res is Stats.ResourceStatus:
			var mana_bonus: int = mag * MANA_PER_MAGIC
			var target_max: int = maxi(0, player._baseline_mana_max + mana_bonus)
			mana_res.max_resource = target_max
			if mana_res.current_resource > mana_res.max_resource:
				mana_res.current_resource = mana_res.max_resource
			player.player_class.stats.resource_changed.emit(
				GameConstants.RESOURCE_MANA, mana_res.current_resource, mana_res.max_resource
			)


static func _snap_max_health_to_heart_grid(value: int, mult: int) -> int:
	if mult <= 0:
		return value
	var rem: int = value % mult
	if rem == 0:
		return value
	return value + (mult - rem)


static func _primary_attribute_bonus(
	class_name_enum: ClassHandler.ClassName, con: int, dex: int, mag: int
) -> int:
	match class_name_enum:
		ClassHandler.ClassName.BARBARIAN:
			return con * DAMAGE_PER_PRIMARY_ATTRIBUTE
		ClassHandler.ClassName.DRUID:
			return dex * DAMAGE_PER_PRIMARY_ATTRIBUTE
		ClassHandler.ClassName.WIZARD:
			return mag * DAMAGE_PER_PRIMARY_ATTRIBUTE
		_:
			return 0
