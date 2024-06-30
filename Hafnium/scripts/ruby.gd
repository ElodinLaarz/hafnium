extends CharacterBody2D 

var ttl: float = 1.0 # Seconds to live.
var currency_value: int = 1

func _on_area_2d_body_entered(body:Node2D):
    if body.has_method("is_player"):
        body.add_currency(currency_value)
        queue_free()
