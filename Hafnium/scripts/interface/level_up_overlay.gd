class_name LevelUpOverlay
extends CanvasLayer

var _run_context: RunContext
var _choices_box: VBoxContainer


func configure(run_context: RunContext) -> void:
	_run_context = run_context
	if not run_context.level_up_choice_required.is_connected(_on_level_up_choice_required):
		run_context.level_up_choice_required.connect(_on_level_up_choice_required)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_choices_box = get_node("CenterContainer/VBoxContainer/Choices") as VBoxContainer


func _on_level_up_choice_required(player: PlayerCharacter, choices: Array[int]) -> void:
	visible = true
	for child: Node in _choices_box.get_children():
		child.queue_free()
	for attr_int: int in choices:
		var attribute: PlayerProgression.Attribute = attr_int as PlayerProgression.Attribute
		var button: Button = Button.new()
		button.text = "+%s" % PlayerProgression.attribute_display_name(attribute)
		button.pressed.connect(_on_stat_button_pressed.bind(player, attribute))
		_choices_box.add_child(button)


func _on_stat_button_pressed(
	player: PlayerCharacter, attribute: PlayerProgression.Attribute
) -> void:
	visible = false
	if _run_context != null:
		_run_context.resolve_level_up_choice(player, attribute)
