extends CharacterBody3D

@export var speed := 4.0
@export var health := 10
@onready var agent := $NavigationAgent3D
@onready var detect_area := $DetectArea
@onready var anim_tree = $Slime/AnimationTree
@onready var anim_state = $Slime/AnimationTree.get("parameters/playback")
@export var collectible_scene: PackedScene
@export var type_name: String = "Slime"
var uid: String = ""
var should_move: bool = false
var player: Node3D
@export var hit_recover_time: float = 0.5
var hit_timer := 0.0
var is_hit := false
var is_hostile: bool = true
var custom_seed = -1
@export var activation_distance: float = 10.0
var is_active := false
var exist:= true


func _ready():
	add_to_group("AI_NPC")
	agent.debug_enabled = false
	await get_tree().process_frame
	player = get_node("/root/main/Knight")
	detect_area.body_entered.connect(_on_body_entered)
	if GameData.loaded_save_data:
		custom_seed = GameData.loaded_save_data["seed"]
	elif custom_seed == -1:
		custom_seed = Time.get_unix_time_from_system()
	var rng = RandomNumberGenerator.new()
	rng.seed = custom_seed
	rng.randomize()
	var position_hash = str(global_position.x) + "_" + str(global_position.y) + "_" + str(global_position.z)
	uid = "%s_%s" % [type_name, position_hash.md5_text()]
	

var time_passed := 0.0
const UPDATE_INTERVAL := 0.5

func _physics_process(delta):
	if not player:
		return
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0.0:
			is_hit = false
			anim_state.travel("IW")
		return

	time_passed += delta
	var distance = global_position.distance_to(player.global_position)
	if distance < activation_distance:
		is_active = true
	else:
		is_active = false

	if time_passed > UPDATE_INTERVAL and is_active:
		time_passed = 0
		agent.target_position = player.global_position

	if agent.is_navigation_finished():
		velocity = Vector3.ZERO
		anim_tree.set("parameters/IW/blend_position", Vector2(0, 0))
	else:
		var next_position = agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		var movement = direction.normalized()
		anim_tree.set("parameters/IW/blend_position", Vector2(movement.x, -movement.z))
		var new_velocity = direction * speed
		var flat_target = Vector3(next_position.x, global_position.y, next_position.z)
		look_at(flat_target, Vector3.UP)
		velocity = velocity.move_toward(new_velocity, .25)
		move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		if not is_queued_for_deletion():
			drop_collectible()
			set_npc_state()
			GameData.npcs_to_save[uid] = get_npc_state()
			queue_free()

func drop_collectible():
	if collectible_scene:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var num_drops = rng.randi_range(2, 5)

		player = get_tree().get_first_node_in_group("player")
		
		for i in range(num_drops):
			var collectible_instance = collectible_scene.instantiate()
			get_tree().current_scene.add_child(collectible_instance, true)

			# Spawn with random offset
			var random_offset = Vector3(
				rng.randf_range(-1.0, 1.0),
				0,
				rng.randf_range(-1.0, 1.0)
			)
			collectible_instance.global_position = global_position + random_offset

			# Set the player as target for pulling
			if collectible_instance.is_in_group("coins"):
				collectible_instance.target_player = player
				collectible_instance.pulling = true

				# UID setup
				var position_hash = "%s_%s_%s_%s" % [
					str(collectible_instance.global_position.x),
					str(collectible_instance.global_position.y),
					str(collectible_instance.global_position.z),
					str(i)
				]
				uid = "Ammo_%s" % position_hash.md5_text()
				collectible_instance.uid = uid
				GameData.collected_coin_positions[uid] = collectible_instance.get_coin_state()






func _on_body_entered(body):
	var inventory = get_tree().get_first_node_in_group("inventory_ui")
	if inventory and inventory.has_item("slime_jelly"):
		is_hostile = false
	else:
		is_hostile = true
	if body.is_in_group("Player") and not is_hit:
		is_hit = true
		hit_timer = hit_recover_time
		anim_state.travel("HIT")
		if is_hostile:
			body.call_deferred("trigger_enemy_bounce", global_position)

func get_npc_state() -> Dictionary:
	return {
		"position": {
			"x": global_position.x,
			"y": global_position.y,
			"z": global_position.z,
		},
		"health": health,
		"exist": exist,
	}

func set_npc_state():
	exist = false
