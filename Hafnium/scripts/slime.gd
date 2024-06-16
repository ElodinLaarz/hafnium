extends enemy 

func _on_detection_body_entered(body: CharacterBody2D):
	self.player = body
	self.chasing_player = true


func _on_detection_body_exited(body):
	self.player = null
	self.chasing_player = false
