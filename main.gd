extends Node3D
@export var player: Node3D
var saved_seed: int = -1
@onready var music_low: AudioStreamPlayer = $WorldEnvironment/Music/MusicLow
@onready var music_mid: AudioStreamPlayer = $WorldEnvironment/Music/MusicMid
@onready var music_high: AudioStreamPlayer = $WorldEnvironment/Music/MusicHigh
@onready var music_high2: AudioStreamPlayer = $WorldEnvironment/Music/MusicVeryHigh
var sky_material: ShaderMaterial
var current_music: AudioStreamPlayer = null


func _ready() -> void:

	
	var world = get_tree().get_first_node_in_group("world")
	if world:
		world.connect("world_generation_finished", _on_world_generation_finished)




func _on_world_generation_finished() -> void:

	if not GameData.loaded_save_data:
		$Fade_transition/AnimationPlayer.play("fade_out")
		$Fade_transition/Fade_Timer.start()
		return

	var save_data = GameData.loaded_save_data
	GameData.collected_keys = save_data["collected_keys"]
	# Load Player Data
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
						
			var loaded_coins = save_data["collected_coin_positions"]
			var all_coins = get_tree().get_nodes_in_group("coins")

			for coin in all_coins: 
				if loaded_coins.has(coin.uid): 
					var coin_state = loaded_coins[coin.uid] 
					if not coin_state.collected:
						saved_pos = coin_state.position 
						coin.global_position = Vector3(saved_pos.x, saved_pos.y, saved_pos.z)
					else: 
						coin.set_coin_state()
						GameData.collected_coin_positions[coin.uid] = coin.get_coin_state()
						coin.queue_free()



						
		# Load NPC data
		var loaded_npcs = save_data["npcs"]
		var all_npcs = get_tree().get_nodes_in_group("AI_NPC")
		for npc in all_npcs:
			if loaded_npcs.has(npc.uid):
				var npc_state = loaded_npcs[npc.uid]
				if npc_state.exist:
					saved_pos = npc_state.position
					npc.global_position = Vector3(saved_pos.x, saved_pos.y, saved_pos.z)
					npc.health = npc_state.health
				else:
					npc.set_npc_state()
					GameData.npcs_to_save[npc.uid] = npc.get_npc_state()
					npc.queue_free()
		$Fade_transition/AnimationPlayer.play("fade_out")
		$Fade_transition/Fade_Timer.start()
		GameData.loaded_save_data = null
		


func _process(_delta) -> void:
	if not player:
		return
	var h = player.global_position.y
	sky_material = $WorldEnvironment.environment.sky.sky_material
	if sky_material :
		sky_material.set("shader_parameter/player_height", h)
	var target_music: AudioStreamPlayer = null
	if h > 6000:
		target_music = music_high
	elif h > 450.0:
		target_music = music_high
	elif h > 250.0:
		target_music = music_mid
	else:
		target_music = music_low

	# 🎶 Switch music if needed
	if target_music != current_music:
		if current_music and current_music.playing:
			current_music.stop()
		if not target_music.playing:
			target_music.play()
		current_music = target_music



func _on_fade_timer_timeout() -> void:
	$Fade_transition.hide()
