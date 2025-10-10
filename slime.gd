extends CharacterBody3D

@export var speed := 4.0
@onready var agent := $NavigationAgent3D
@onready var detect_area := $DetectArea 

var should_move: bool = false
var player: Node3D
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
	else:
		var next_position = agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * speed
		look_at(next_position, Vector3.UP)
		move_and_slide()
		
		
func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.call_deferred("trigger_enemy_bounce", global_position)
