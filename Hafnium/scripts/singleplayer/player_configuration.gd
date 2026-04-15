class_name PlayerConfigurationManager

const PLAYER_IDS := {
	"barbarian": "class:barbarian",
	"druid": "class:druid",
	"wizard": "class:wizard",
}


class PlayerConfiguration:
	var name: String
	var definition_id: String
	var player_class: ClassHandler.PlayerClass
	var currency: int
	var bomb_count: int
	var bomb_max: int

	func _init(
		p_name: String,
		p_definition_id: String,
		p_player_class: ClassHandler.PlayerClass,
		p_currency: int,
		p_bomb_count: int,
		p_bomb_max: int
	):
		self.name = p_name
		self.definition_id = p_definition_id
		self.player_class = p_player_class
		self.currency = p_currency
		self.bomb_count = p_bomb_count
		self.bomb_max = p_bomb_max


func lookup_character(name: String) -> PlayerConfiguration:
	if name not in PLAYER_IDS:
		print("Character %s not found" % name)
		return null

	var definition_id: String = PLAYER_IDS[name]
	var definition = ContentRegistry.require_character(definition_id)
	if definition == null:
		return null

	var player_class := ClassHandler.PlayerClass.new(definition.legacy_class_name)
	if player_class.definition == null:
		if not player_class.class_handler.setup_from_data(player_class, definition):
			print("Failed to repair class definition for %s" % name)
			return null
	return PlayerConfiguration.new(
		name,
		definition_id,
		player_class,
		definition.starting_currency,
		definition.bomb_max,
		definition.bomb_max
	)
