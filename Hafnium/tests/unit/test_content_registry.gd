extends GutTest


func before_each() -> void:
	ContentRegistry.reload_defaults()


func test_require_character_returns_wizard_definition() -> void:
	var wizard: CharacterData = ContentRegistry.require_character("class:wizard")
	assert_not_null(wizard, "Wizard definition should exist")
	assert_eq(wizard.display_name, "Wizard")
	assert_eq(wizard.attack_projectile_id, "weapon:fireball")


func test_legacy_class_lookup_uses_resource_registry() -> void:
	var wizard: CharacterData = ContentRegistry.require_legacy_character(
		ClassHandler.ClassName.WIZARD
	)
	assert_not_null(wizard, "Legacy enum lookup should resolve through registry")
	assert_eq(wizard.id, "class:wizard")


func test_require_enemy_returns_loot_enabled_definition() -> void:
	var slime: EnemyData = ContentRegistry.require_enemy("enemy:slime_basic")
	assert_not_null(slime, "Slime definition should exist")
	assert_not_null(slime.loot_table, "Slime should use a loot table")
