class_name LevelUpOverlay
extends CanvasLayer

const LevelUpTooltipBuilder = preload("res://scripts/interface/level_up_tooltip_builder.gd")

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
		_choices_box.remove_child(child)
		child.queue_free()
	for attr_int: int in choices:
		var attribute: PlayerProgression.Attribute = PlayerProgression.attribute_from_int(attr_int)
		var button: StatChoiceButton = StatChoiceButton.new()
		button.text = "+%s" % PlayerProgression.attribute_display_name(attribute)
		button.tooltip_text = LevelUpTooltipBuilder.build(player, attribute)
		button.pressed.connect(_on_stat_button_pressed.bind(player, attribute))
		_choices_box.add_child(button)


func _on_stat_button_pressed(
	player: PlayerCharacter, attribute: PlayerProgression.Attribute
) -> void:
	visible = false
	if _run_context != null:
		_run_context.resolve_level_up_choice(player, attribute)


class StatChoiceButton:
	extends Button

	func _make_custom_tooltip(for_text: String) -> Control:
		var rtl: RichTextLabel = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rtl.scroll_active = false
		rtl.custom_minimum_size = Vector2(280, 0)
		rtl.text = for_text
		return rtl
