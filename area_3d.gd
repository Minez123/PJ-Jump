extends Area3D

func _on_ProximityArea_body_entered(body):
	if body.is_in_group("AI_NPC"):
		body.should_move = true  

func _on_ProximityArea_body_exited(body):
	if body.is_in_group("AI_NPC"):
		body.should_move = false
