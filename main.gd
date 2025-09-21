extends Node3D
@export var player: Node3D
var saved_seed: int = -1

var sky_material: ShaderMaterial



func _ready() -> void:


	var world = get_tree().get_first_node_in_group("world")
	if world:
		world.connect("world_generation_finished", _on_world_generation_finished)

	# The loading logic now moves into a separate function.

func _on_world_generation_finished() -> void:
	$Fade_transition/AnimationPlayer.play("fade_out")
	$Fade_transition/Fade_Timer.start()
	if not GameData.loaded_save_data:
		return

	var save_data = GameData.loaded_save_data

	# Load Player Data
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var saved_pos = save_data["player"]["position"]
		player.global_position = Vector3(saved_pos.x, saved_pos.y, saved_pos.z)
		player.shotgun_shots_remaining = save_data["player"]["ammo"]
		var inventory = get_tree().get_first_node_in_group("inventory_ui")
		# Load Inventory Data
		if inventory:
			var loaded_uids = save_data["inventory"]
			for uid in loaded_uids:
				var item_resource_path = "res://items/" + uid + ".tres"
				var item_resource = load(item_resource_path)
				if item_resource:
					inventory.add_item(item_resource)
			
			var all_items = get_tree().get_nodes_in_group("items")
			for item in all_items:
				if loaded_uids.has(item.uid):
					item.queue_free()

		# Remove collected coins from the world
		var collected_coin_positions = save_data.get("collected_coin_positions", [])
		if not collected_coin_positions.is_empty():
			var all_coins = get_tree().get_nodes_in_group("coins")
			print("Found coins to process:", all_coins.size())
			for coin in all_coins:
				for saved_pos_dict in collected_coin_positions:
					var saved_vec = Vector3(saved_pos_dict.x, saved_pos_dict.y, saved_pos_dict.z)
					if coin.global_position.is_equal_approx(saved_vec):
						coin.queue_free()
						break

		GameData.loaded_save_data = null


func _process(delta) -> void:
	if not player:
		return
	var h = player.global_position.y
	sky_material = $WorldEnvironment.environment.sky.sky_material
	if sky_material :
		sky_material.set("shader_parameter/player_height", h)



func _on_fade_timer_timeout() -> void:
	$Fade_transition.hide()
