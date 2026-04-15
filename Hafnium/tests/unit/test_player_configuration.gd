extends GutTest

# Tests for Hafnium/scripts/singleplayer/player_configuration.gd (PlayerConfigurationManager)

const PLAYER_CONFIGURATION_MANAGER_SCRIPT = preload(
	"res://scripts/singleplayer/player_configuration.gd"
)


func test_lookup_character_wizard():
	var pcm = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config = pcm.lookup_character("wizard")
	assert_not_null(config, "Should find wizard configuration")
	assert_eq(config.name, "wizard")
	assert_eq(config.player_class.name, ClassHandler.ClassName.WIZARD)


func test_lookup_character_druid():
	var pcm = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config = pcm.lookup_character("druid")
	assert_not_null(config, "Should find druid configuration")
	assert_eq(config.player_class.name, ClassHandler.ClassName.DRUID)


func test_lookup_character_unknown():
	var pcm = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config = pcm.lookup_character("nonexistent")
	assert_null(config, "Should return null for unknown character")


func test_starting_currency():
	var pcm = PLAYER_CONFIGURATION_MANAGER_SCRIPT.new()
	var config = pcm.lookup_character("wizard")
	# Check if currency is initialized (default 0 or specific value)
	assert_eq(config.currency, 0, "Wizard should start with 0 currency")
