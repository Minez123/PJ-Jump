extends Node3D
var custom_seed = -1
var uid: String = ""
@export var type_name: String = "Ammo"
@export var spin_speed: float = 90.0  # degrees per second
@export var pull_speed: float = 15.0  # units per second
var target_player: Node = null
var pulling: bool = false
var collected = false
func _ready() -> void:
	add_to_group("coins")

	if GameData.loaded_save_data:
		return

	if custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()
	var rng = RandomNumberGenerator.new()
	rng.seed = custom_seed
	rng.randomize()
	if uid == "":
		uid = str(randi()) + "_" + type_name



func _process(delta: float) -> void:
	rotate_y(deg_to_rad(spin_speed * delta))
	if pulling and target_player and is_instance_valid(target_player):
		var dir = (target_player.global_position - global_position).normalized()
		global_position += dir * pull_speed * delta

func _on_area_3d_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		if body.has_method("refill_shotgun"):
			body.refill_shotgun()
			set_coin_state()
			GameData.collected_coin_positions[uid] = get_coin_state()
			$Area3D/collect_sfx.play()
			await get_tree().create_timer(0.2).timeout
			queue_free()

func get_coin_state() -> Dictionary:
	return {
		"collected": collected,
		"position": {
			"x": global_position.x,
			"y": global_position.y,
			"z": global_position.z,
		},
		
	}

func set_coin_state()->void:
	collected=true
