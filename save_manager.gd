extends Node

const SAVE_PATH := "user://savegame.json"

func save_game(player: Node, world: Node) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory_ui")

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
		"inventory": [],
		"seed": world.custom_seed  # ✅ store your world seed
	}

	if inventory:
		for item_id in inventory.items.keys():
			var item = inventory.get_item(item_id)
			save_data["inventory"].append({
				"id": item["id"],
				"desc": item["desc"]
			})

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
