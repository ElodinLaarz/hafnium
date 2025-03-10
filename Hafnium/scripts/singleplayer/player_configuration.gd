class_name PlayerConfigurationManager

class PlayerConfiguration:
	var name: String
	var player_class: ClassHandler.PlayerClass
	var currency: int 
	var bomb_count: int
	var bomb_max: int

	func _init(
        p_name: String,
        p_player_class: ClassHandler.PlayerClass,
        p_currency: int,
        p_bomb_count: int,
        p_bomb_max: int):
		self.name = p_name
		self.player_class = p_player_class
		self.currency = p_currency
		self.bomb_count = p_bomb_count
		self.bomb_max = p_bomb_max

var data = {
	"druid": PlayerConfiguration.new("Example Player", ClassHandler.PlayerClass.new(ClassHandler.ClassName.DRUID), 25, 2, 5),
	"wizard": PlayerConfiguration.new("Example Player", ClassHandler.PlayerClass.new(ClassHandler.ClassName.WIZARD), 25, 2, 5),
	"barbarian": PlayerConfiguration.new(
		"Example Player",
		ClassHandler.PlayerClass.new(ClassHandler.ClassName.BARBARIAN),
		25,
		2,
		5,
	),
};

func lookup_character(name: String) -> PlayerConfiguration:
	if name not in data:
		print("Character %s not found" % name)	
		return null
	return data[name]
