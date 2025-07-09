extends Node3D

func _on_area_3d_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		$Area3D/collect_sfx.play()  # Optional: play sound before disappearing
		await get_tree().create_timer(0.2).timeout  # wait for sound to play
		queue_free()
