extends Node3D

func _on_area_3d_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		if body.has_method("refill_shotgun"):
			body.refill_shotgun()
		$Area3D/collect_sfx.play()
		await get_tree().create_timer(0.2).timeout
		queue_free()
