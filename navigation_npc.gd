extends CharacterBody3D

@export var speed := 4.0
@export var health := 50
@onready var agent := $NavigationAgent3D
@onready var detect_area := $DetectArea 
@onready var anim_tree = $Slime/AnimationTree
@onready var anim_state = $Slime/AnimationTree.get("parameters/playback")
@export var collectible_scene: PackedScene
var should_move: bool = false
var player: Node3D
@export var hit_recover_time: float = 0.5
var hit_timer := 0.0
var is_hit := false

@export var activation_distance: float = 10.0
var is_active := false
func _ready():
	add_to_group("AI_NPC")
	agent.debug_enabled = false # draw line
	await get_tree().process_frame  # Let everything enter the scene tree
	player = get_node("/root/main/Knight") 
	detect_area.body_entered.connect(_on_body_entered)

	

var time_passed := 0.0
const UPDATE_INTERVAL := 0.5

func _physics_process(delta):
	if not player:
		return
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0.0:
			is_hit = false
			anim_state.travel("IW")  # return to BlendSpace2D
		return  # Skip movement while hit anim plays

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
		velocity = direction * speed
		var flat_target = Vector3(next_position.x, global_position.y, next_position.z)
		look_at(flat_target, Vector3.UP)
		
		move_and_slide()

		



func take_damage(amount: int):
	if collectible_scene:
		var collectible_instance = collectible_scene.instantiate()

		# Add it to the same top-level (nav_level) before positioning
		var nav_level = get_tree().get_root().get_node(".")
		nav_level.add_child(collectible_instance)

		# Now set position in world space
		collectible_instance.global_position = global_position 
	queue_free()


func drop_collectible():
	if collectible_scene:
		var collectible_instance = collectible_scene.instantiate()
		# Set collectible position to slime position
		collectible_instance.global_position = global_position + Vector3(0, 0.5, 0)
		get_parent().add_child(collectible_instance)

	
func _on_body_entered(body):

	if body.is_in_group("Player") and not is_hit:
		is_hit = true
		hit_timer = hit_recover_time
		anim_state.travel("HIT")
		body.call_deferred("trigger_enemy_bounce", global_position)
		

		
		
