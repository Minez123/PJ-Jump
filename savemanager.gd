extends Node

const SAVE_PATH := "user://savegame.json"

func save_game(player: Node, world: Node) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory_ui")
	var inventory_uids = []
	var coin_positions_to_save = []
	for pos in GameData.collected_coin_positions:
		coin_positions_to_save.append({
			"x": pos.x,
			"y": pos.y,
			"z": pos.z
		})
	
	if inventory:
		for uid in inventory.items.keys():
			inventory_uids.append(uid)

	var save_data = {
		"player": {
		"position": {
			"x": player.global_transform.origin.x,
			"y": player.global_transform.origin.y,
			"z": player.global_transform.origin.z
		}
,
			"ammo": player.get_ammo(),
		},
		"collected_coin_positions": coin_positions_to_save,
		"inventory": inventory_uids,
		"seed": world.custom_seed  # ✅ store your world seed
	}


	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved with seed:", world.custom_seed)
		
# SaveManager.gd
func load_game(save_path: String) -> Dictionary:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var save_data = JSON.parse_string(content)
		if save_data is Dictionary:
			print("Game loaded successfully.")
			return save_data
		else:
			print("Error parsing save data.")
			return {}
	else:
		print("Save file not found.")
		return {}
