extends Node3D

@export var spin_speed: float = 90.0  # degrees per second
@export var respawn_time: float = 300.0  # seconds until it comes back

var collected := false

func _process(delta: float) -> void:
	if not collected:
		rotate_y(deg_to_rad(spin_speed * delta))

func _on_area_3d_body_entered(body: Node) -> void:
	if collected:
		return
	
	if body is CharacterBody3D and body.has_method("refill_shotgun"):
		body.refill_shotgun()
		$Area3D/collect_sfx.play()
		_hide_pickup()
		await get_tree().create_timer(respawn_time).timeout
		_show_pickup()

# === Hide the pickup ===
func _hide_pickup() -> void:
	collected = true
	$MeshInstance3D.visible = false


# === Show the pickup again ===
func _show_pickup() -> void:
	collected = false
	$MeshInstance3D.visible = true
