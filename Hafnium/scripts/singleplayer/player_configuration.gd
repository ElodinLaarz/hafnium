class_name PlayerConfigurationManager

class PlayerConfiguration:
	var name: String
	var player_class: ClassHandler.PlayerClass
	var stats: Stats
	var currency: int 
	var bomb_count: int
	var bomb_max: int


	func _init(name: String, player_class: ClassHandler.PlayerClass, currency: int, bomb_count: int, bomb_max: int, stats: Stats):
		self.name = name
		self.player_class = player_class
		self.currency = currency
		self.bomb_count = bomb_count
		self.bomb_max = bomb_max
		self.stats = stats

var example_class_name: ClassHandler.ClassName = ClassHandler.ClassName.DRUID 

var data = {
	"player": PlayerConfiguration.new("Example Player", ClassHandler.PlayerClass.new(example_class_name), 25, 2, 5, Stats.new(example_class_name)),
	"wizard": PlayerConfiguration.new("Example Player", ClassHandler.PlayerClass.new(ClassHandler.ClassName.WIZARD), 25, 2, 5, Stats.new(ClassHandler.ClassName.WIZARD)),
	"barbarian": PlayerConfiguration.new("Example Player", ClassHandler.PlayerClass.new(ClassHandler.ClassName.BARBARIAN), 25, 2, 5, Stats.new(ClassHandler.ClassName.BARBARIAN)),
};

func lookup_character(name: String) -> PlayerConfiguration:
	if name not in data:
		return null
	return data[name]
