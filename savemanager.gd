extends Node

const SAVE_PATH = "user://savegame.json"

func save_game(player: Node, world: Node) -> void:
	var inventory = get_tree().get_first_node_in_group("inventory_ui")
	var inventory_uids = []
	var coin_positions_to_save = GameData.collected_coin_positions
	var npcs_to_save = GameData.npcs_to_save
	var all_npcs = get_tree().get_nodes_in_group("AI_NPC")
	


		
	for npc in all_npcs:
		if is_instance_valid(npc) and npc.has_method("get_npc_state"):
			npcs_to_save[npc.uid] = npc.get_npc_state()
	
	if inventory:
		for uid in inventory.items.keys():
			inventory_uids.append(uid)

	var save_data = {
		"player": {
			"position": {
				"x": player.global_transform.origin.x,
				"y": player.global_transform.origin.y,
				"z": player.global_transform.origin.z
			},
			"ammo": player.get_ammo(),
		},
		"collected_coin_positions": coin_positions_to_save,
		"collected_keys":GameData.collected_keys, 
		"inventory": inventory_uids,
		"npcs": npcs_to_save,
		"seed": world.custom_seed,
		"elapsed_time": GameData.elapsed_time,   
		"best_time": GameData.best_time, 
		"at_goal": GameData.at_goal
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

		
# SaveManager.gd
func load_game(save_path: String) -> Dictionary:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var save_data = JSON.parse_string(content)
		if save_data is Dictionary:
			if save_data.has("elapsed_time"):
				GameData.elapsed_time = save_data["elapsed_time"]  
			if save_data.has("best_time"):
				GameData.best_time = save_data["best_time"]       
			return save_data
	return {}
	
	
const SETTINGS_PATH := "user://settings.save"

static func save_settings(sensitivity: float, sfx: float, music: float) -> void:
	var data = {
		"mouse_sensitivity": sensitivity,
		"sfx": sfx,
		"music": music,
	}
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_var(data)

static func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return {}
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	return file.get_var()	
