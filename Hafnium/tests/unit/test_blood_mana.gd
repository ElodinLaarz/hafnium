extends GutTest

const CLASS_HANDLER_SCRIPT = preload("res://scripts/classes/class_handler.gd")
const GameConstants = preload("res://scripts/config/game_constants.gd")


func test_wizard_mana_max_at_full_health() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	var m: Stats.ResourceStatus = pc.stats.resources[GameConstants.RESOURCE_MANA]
	assert_eq(m.max_resource, 4, "At full HP, max mana should match CharacterData.mana_max")
	assert_eq(m.current_resource, 4)


func test_wizard_blood_mana_raises_max_when_injured() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	pc.stats.current_health = 2
	var m: Stats.ResourceStatus = pc.stats.resources[GameConstants.RESOURCE_MANA]
	assert_eq(m.max_resource, 8, "Half HP missing -> half of bonus_pool (8) added to base (4)")


func test_wizard_blood_mana_clamps_current_when_healing_reduces_cap() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	pc.stats.current_health = 1
	var m: Stats.ResourceStatus = pc.stats.resources[GameConstants.RESOURCE_MANA]
	m.current_resource = 9
	ch.recompute_wizard_blood_mana(pc)
	pc.stats.current_health = pc.stats.max_health
	m = pc.stats.resources[GameConstants.RESOURCE_MANA]
	assert_eq(m.max_resource, 4)
	assert_eq(m.current_resource, 4)


func test_wizard_attack_consumes_mana() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	assert_true(pc.attack())
	assert_eq(pc.stats.resources["mana"].current_resource, 3)
	assert_gt(pc.stats.attack_cooldown, 0.0)


func test_wizard_attack_fails_without_consuming_cooldown_when_oom() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.WIZARD)
	pc.stats.resources["mana"].current_resource = 0
	assert_false(pc.attack())
	assert_eq(pc.stats.attack_cooldown, 0.0)


func test_barbarian_not_affected_by_recompute_wizard_blood_mana() -> void:
	var ch: ClassHandler = CLASS_HANDLER_SCRIPT.new()
	var pc: ClassHandler.PlayerClass = ch.create_class(ClassHandler.ClassName.BARBARIAN)
	ch.recompute_wizard_blood_mana(pc)
	assert_false(pc.stats.resources.has(GameConstants.RESOURCE_MANA))
