extends Node

var multiplayer_enabled: bool = false

func _on_tree_entered():
	if multiplayer_enabled:
		%MultiplayerOverlay.visibile = true
	else:
		%MultiplayerOverlay.visibile = true
