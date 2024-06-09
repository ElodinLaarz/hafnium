class_name PlayerConfiguration

var data = {
    "player": {
        "name": "Player 1",
        "class": ClassHandler.ClassName.DRUID,
        "currency": 25,
    }
};

func LoadPlayerFromData(data: Dictionary) -> PlayerCharacter:
    var player = PlayerCharacter.new()
    player.name = data["player"]["name"]
    player.class = ClassHandler.GetClass(data["player"]["class"])
    player.currency = data["player"]["currency"]
    return player