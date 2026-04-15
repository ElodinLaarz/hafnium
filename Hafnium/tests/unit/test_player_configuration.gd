extends GutTest

# Tests for Hafnium/scripts/singleplayer/player_configuration.gd (PlayerConfigurationManager)

const PLAYER_CONFIGURATION_MANAGER_SCRIPT = preload(
	"res://scripts/singleplayer/player_configuration.gd"
)


func test_lookup_character_wizard() -> void:
	var pcm: Variant = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config: Variant = pcm.lookup_character("wizard")
	assert_not_null(config, "Should find wizard configuration")
	assert_eq(config.name, "wizard")
	assert_eq(config.player_class.name, ClassHandler.ClassName.WIZARD)
	assert_not_null(
		config.player_class.definition, "Wizard should have a resolved class definition"
	)
	assert_not_null(
		config.player_class.definition.sprite_scene,
		"Wizard definition should provide a sprite scene"
	)


func test_lookup_character_druid() -> void:
	var pcm: Variant = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config: Variant = pcm.lookup_character("druid")
	assert_not_null(config, "Should find druid configuration")
	assert_eq(config.player_class.name, ClassHandler.ClassName.DRUID)
	assert_not_null(config.player_class.definition, "Druid should have a resolved class definition")


func test_lookup_character_unknown() -> void:
	var pcm: Variant = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config: Variant = pcm.lookup_character("nonexistent")
	assert_null(config, "Should return null for unknown character")


func test_starting_currency() -> void:
	var pcm: Variant = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config: Variant = pcm.lookup_character("wizard")
	# Check if currency is initialized (default 0 or specific value)
	assert_eq(config.currency, 0, "Wizard should start with 0 currency")
