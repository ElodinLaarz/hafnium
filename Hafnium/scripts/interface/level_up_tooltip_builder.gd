class_name LevelUpTooltipBuilder
extends Object

const GameConstants = preload("res://scripts/config/game_constants.gd")
const AttributeBonusService = preload("res://scripts/progression/attribute_bonus_service.gd")


static func build(player: PlayerCharacter, attribute: PlayerProgression.Attribute) -> String:
	if player == null or player.player_class == null:
		return PlayerProgression.attribute_display_name(attribute)
	var cn: ClassHandler.ClassName = player.player_class.name
	match attribute:
		PlayerProgression.Attribute.CONSTITUTION:
			return _constitution(cn)
		PlayerProgression.Attribute.DEXTERITY:
			return _dexterity(cn)
		PlayerProgression.Attribute.MAGIC:
			return _magic(player, cn)
		PlayerProgression.Attribute.LUCK:
			return _luck()
		PlayerProgression.Attribute.WILLPOWER:
			return _willpower()
		_:
			return PlayerProgression.attribute_display_name(attribute)


static func _constitution(cn: ClassHandler.ClassName) -> String:
	var lines: Array[String] = []
	lines.append("+2 maximum health per point (from your class baseline).")
	if cn == ClassHandler.ClassName.BARBARIAN:
		lines.append(
			(
				"[b][color=%s]+1 attack damage per point — Barbarian primary stat.[/color][/b]"
				% GameConstants.CLASS_COLOR_BARBARIAN
			)
		)
	return _join_lines(lines)


static func _dexterity(cn: ClassHandler.ClassName) -> String:
	var lines: Array[String] = []
	lines.append("+2 movement speed per point (walk and run).")
	if cn == ClassHandler.ClassName.DRUID:
		lines.append(
			(
				"[b][color=%s]+1 attack damage per point — Druid primary stat.[/color][/b]"
				% GameConstants.CLASS_COLOR_DRUID
			)
		)
	return _join_lines(lines)


static func _magic(player: PlayerCharacter, cn: ClassHandler.ClassName) -> String:
	var lines: Array[String] = []
	var uses_mana: bool = _player_uses_mana(player)
	if uses_mana:
		lines.append("+1 maximum mana per point.")
	else:
		lines.append(
			(
				"Increases maximum mana by 1 per point for classes with a mana pool "
				+ "(your class does not use mana)."
			)
		)
	if cn == ClassHandler.ClassName.WIZARD:
		lines.append(
			(
				"[b][color=%s]+1 attack damage per point — Wizard primary stat.[/color][/b]"
				% GameConstants.CLASS_COLOR_WIZARD
			)
		)
	return _join_lines(lines)


static func _luck() -> String:
	var lines: Array[String] = []
	lines.append("+1.5% additive critical strike chance per point (before global cap).")
	lines.append("Item drop rarity scales with Luck (when loot rules support it).")
	return _join_lines(lines)


static func _willpower() -> String:
	return (
		"Reduces primary attack cooldown by %.2fs per point (minimum cooldown %.2fs)."
		% [
			AttributeBonusService.WILLPOWER_ATTACK_COOLDOWN_PER_POINT,
			AttributeBonusService.MIN_ATTACK_COOLDOWN,
		]
	)


static func _player_uses_mana(player: PlayerCharacter) -> bool:
	if player == null or player.stats == null:
		return false
	return player.stats.resources.has(GameConstants.RESOURCE_MANA)


static func _join_lines(lines: Array[String]) -> String:
	return "\n".join(lines)
