extends Node3D


@export var spin_speed: float = 90.0  # degrees per second

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(spin_speed * delta))


func _on_area_3d_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		if body.has_method("refill_shotgun"):
			body.refill_shotgun()
		$Area3D/collect_sfx.play()
		await get_tree().create_timer(0.2).timeout
		queue_free()
