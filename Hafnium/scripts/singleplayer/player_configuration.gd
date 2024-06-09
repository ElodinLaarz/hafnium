class_name PlayerConfigurationManager

class PlayerConfiguration:
    var name: String
    var player_class: ClassHandler.PlayerClass
    var currency: int 
    var bomb_count: int
    var bomb_max: int


    func _init(name: String, player_class: ClassHandler.PlayerClass, currency: int, bomb_count: int, bomb_max: int):
        self.name = name
        self.player_class = player_class
        self.currency = currency
        self.bomb_count = bomb_count
        self.bomb_max = bomb_max

var data = {
    "player": PlayerConfiguration.new("Example Player", ClassHandler.PlayerClass.new(ClassHandler.ClassName.DRUID), 25, 2, 5),
};

func lookup_character(name: String) -> PlayerConfiguration:
    if name not in data:
        return null
    return data[name]