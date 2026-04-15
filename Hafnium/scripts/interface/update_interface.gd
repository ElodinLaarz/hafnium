class_name InterfaceUpdater
extends Node


static func update_interface(interface_root: Node, iv: InterfaceValues) -> void:
	if interface_root == null:
		return

	var currency_label: Label = interface_root.get_node_or_null(
		"CounterMargins/Counters/CurrencyCounter/CounterText"
	)
	var bomb_label: Label = interface_root.get_node_or_null(
		"CounterMargins/Counters/BombCounter/CounterText"
	)
	var level_label: Label = interface_root.get_node_or_null("LabelMargins/LevelLabel")

	if currency_label != null:
		currency_label.text = str(iv.currency)
	if bomb_label != null:
		bomb_label.text = "%d/%d" % [iv.bombs, iv.bomb_max]
	if level_label != null:
		level_label.text = "Room: %s" % iv.room_name


func update(iv: InterfaceValues):
	update_interface(get_parent() if get_parent() is Control else null, iv)


class InterfaceValues:
	var health: int = 10
	var max_health: int = 10
	var bombs: int = 0
	var bomb_max: int = 0
	var currency: int = 0
	var room_name: String = "Unknown"
