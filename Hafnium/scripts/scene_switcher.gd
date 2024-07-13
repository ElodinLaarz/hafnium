extends Node

const MULTIPLAYER_OVERLAY: String = "MultiplayerOverlay"

const PLAYER_SPRITE_NAME: String = "PlayerSprite"

var main_scene = load("res://scenes/main_scene.tscn")
var level_one = load("res://scenes/levels/level_1.tscn")
var character_select = load("res://scenes/character_select.tscn")

var curret_game_type: Common.GameType = Common.GameType.SINGLE_PLAYER

func _ready():
  Common.start_game_type.connect(handle_game_start)

func main_scene_start(menu_caller: Control, game_type: Common.GameType, player_name: String):
  if game_type == Common.GameType.LOAD_GAME:
    var menu_to_load: Control = character_select.instantiate()
    menu_caller.queue_free()
    add_child(menu_to_load)
    return
  if player_name == "":
    print("Player name is empty, defaulting to wizard")
    player_name = "wizard"
  # var level_to_load: Node2D = main_scene.instantiate()
  var level_to_load: Node2D = level_one.instantiate()
  # Load the main scene and attach the player character.
  var ui: CanvasLayer = level_to_load.get_node("UI")
  var multiplayer_overlay: Control = ui.get_node(MULTIPLAYER_OVERLAY)
  match game_type:
    Common.GameType.SINGLE_PLAYER:
      multiplayer_overlay.visible = false
    Common.GameType.MULTIPLAYER:
      multiplayer_overlay.visible = true
  var player_character: Node2D = load("res://scenes/player_character.tscn").instantiate()
  if !Common.load_player.call(player_name):
    print("Unable to load player character: %s" % player_name)
    return
  var player_class: ClassHandler.PlayerClass = Common.player_class
  var ch: ClassHandler = ClassHandler.new()
  var player_sprite: AnimatedSprite2D = load(ch.Class_sprite_lookup[player_class.name]).instantiate()
  player_sprite.name = PLAYER_SPRITE_NAME # For reference by other scripts.
  player_character.add_child(player_sprite)
  level_to_load.add_child(player_character)
  # Load data about player.
  # Draw UI and attach.
  var interface_to_draw: Control = load("res://scenes/interface/interface.tscn").instantiate()
  ui.add_child(interface_to_draw)    
  add_child(level_to_load)
  menu_caller.queue_free()

func update_menu_options(main_menu: Control, new_options: Dictionary):
  # This does not work yet...
  var buttons: Array = main_menu.get_node("Buttons").get_children()
  for i in range(buttons.size()):
    buttons[i].text = new_options[new_options.keys()[i]]
    buttons[i].text = new_options[new_options.values()[i]]

func handle_game_start(main_menu: Control, game_type: Common.GameType, player_name: String):
  print("Game start: %s" % game_type)
  main_scene_start(main_menu, game_type, player_name)
