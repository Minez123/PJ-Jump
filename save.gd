extends Node

const SAVE_PATH := "user://savegame.json"

func save_game(player: Node) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory_ui")

	var save_data = {
		"player": {
			"position": player.global_transform.origin,
			"ammo": player.get_ammo(),
		},
		"inventory": [],
		"seed": ProjectSettings.get_setting("application/run/seed", -1)
	}

	# Save inventory items
	if inventory:
		for item_id in inventory.items.keys():
			var item = inventory.get_item(item_id)
			save_data["inventory"].append({
				"id": item["id"],
				"desc": item["desc"]
				# icon not saved (resource), you reload it by item_id
			})

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved to:", SAVE_PATH)


func load_game(player: Node) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found!")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data := JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		print("Invalid save file")
		return

	# Load player data
	var player_data = data.get("player", {})
	if player_data.has("position"):
		player.global_transform.origin = player_data["position"]
	if player_data.has("ammo"):
		player.shotgun_shots_remaining = player_data["ammo"]

	# Load inventory
	var inventory = get_tree().get_first_node_in_group("inventory_ui")
	if inventory:
		inventory.items.clear()
		for item in data.get("inventory", []):
			# Rebuild inventory (lookup icons by id if needed)
			var icon = preload("res://icons/%s.png" % item["id"]) if ResourceLoader.exists("res://icons/%s.png" % item["id"]) else null
			inventory.add_item(icon, item["id"], item["desc"])

	print("Game loaded!")
