extends CharacterBody3D

@export var mouse_sensitivity := 0.0015

@export var min_jump_power := 5.0
@export var max_jump_power := 10.0
@export var jump_charge_rate := 10.0 

@export var move_speed := 8.0
@export var bounce_speed := 8.0

@export var respawn_position: Vector3 = Vector3(0, 15, 0)
@export var fall_limit: float = -50.0  # Y-position considered "fell out"

#Cam
@export var min_zoom := -20.0
@export var max_zoom := 0.0
@export var zoom_speed := 1.0
@export var zoom_hide_threshold:= 0  # Distance at which the mesh disappears

@onready var anim_tree = $AnimationTree
@onready var anim_state = $AnimationTree.get("parameters/playback")
@onready var model = $Rig

@onready var character_mesh = $Rig/Skeleton3D
@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var camera := $TwistPivot/PitchPivot/Camera3D

#UI
@onready var pause_menu: Node = $PauseMenu  
@onready var jump_bar := $"../CanvasLayer/JumpPowerBar" 

#sfx
@onready var jump_sfx: AudioStreamPlayer2D = $jump_sfx
@onready var landing_sfx: AudioStreamPlayer3D = $Landing_sfx
@onready var full_charge_sfx: AudioStreamPlayer2D = $Full_Charge_sfx

var current_zoom := -10.0  # initial zoom distance

var charging_jump := false
var was_on_floor := false
var full_charge_sfx_played := false
var jump_power := 0.0
var jump_direction := 0 
var jump_hight := 2
var landed_timer := 0.0


var GRAVITY = 9.8 * jump_hight 
var original_gravity: float  # Store the original gravity value


var last_dash_time := -1.0
const DASH_COOLDOWN := 1.0  # seconds

# Mouse input
var twist_input := 0.0
var pitch_input := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_gravity = GRAVITY  # Store the original gravity value
	


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twist_input = -event.relative.x * mouse_sensitivity
		pitch_input = -event.relative.y * mouse_sensitivity

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			current_zoom = max(min_zoom, current_zoom - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			current_zoom = min(max_zoom, current_zoom + zoom_speed)
	if event.is_action_pressed("ui_cancel") and not pause_menu.visible:
		pause_menu.game_script = self
		pause_menu.show_menu()


func _physics_process(delta: float) -> void:
	if global_transform.origin.y < fall_limit:
		respawn()

	
	# Camera rotation
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	twist_input = 0.0
	pitch_input = 0.0
	camera.transform.origin.z = -current_zoom
	# Visibility toggle based on zoom
	character_mesh.visible = current_zoom < zoom_hide_threshold
	if landed_timer > 0.0:
		landed_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		# Movement input
	else:
		var input_dir = Vector3.ZERO
		input_dir.x = Input.get_axis("move_left", "move_right")
		input_dir.z = Input.get_axis("move_forward", "move_back")
		
		input_dir = input_dir.normalized()
		var direction = twist_pivot.basis * input_dir
		direction.y = 0
		direction = direction.normalized()
		var speed := move_speed
		# Turn character to match camera's horizontal rotation (TwistPivot)
		var camera_yaw = twist_pivot.global_rotation.y
		$Rig.rotation.y = twist_pivot.global_rotation.y
		#Animetion
		var model_var = velocity * model.transform.basis
		anim_tree.set("parameters/IWR/blend_position",Vector2(model_var.x,-model_var.z)/speed)




		if landed_timer > 0.0:
			landed_timer -= delta

		
		# Only allow movement input on ground
		if is_on_floor():
			anim_tree.set("parameters/conditions/grounded",true)
			var move_input := Input.get_axis("move_left", "move_right")
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			if move_input != 0:
				jump_direction = sign(move_input)
			
			# Start charging
			if Input.is_action_pressed("move_up"): 
				velocity.x = 0
				velocity.z = 0
				charging_jump = true
				jump_power = min(jump_power + jump_charge_rate * delta, max_jump_power)

				# Show jump charge
				if charging_jump:
					jump_bar.visible = true
					jump_bar.value = jump_power
					if jump_power >= jump_bar.max_value  and not full_charge_sfx_played:
						full_charge_sfx.play()
						full_charge_sfx_played = true

				else:
					jump_bar.visible = false

			elif Input.is_action_just_released("move_up") and charging_jump:
				anim_tree.set("parameters/conditions/jumping",true)
				anim_tree.set("parameters/conditions/grounded",false)
				charging_jump = false
				full_charge_sfx_played = false  
				velocity.y = jump_power * jump_hight
				# Get camera's forward direction (ignoring vertical tilt)
				var forward = -twist_pivot.global_transform.basis.z
				forward.y = 0
				forward = forward.normalized()
				jump_sfx.play()
				velocity.x = forward.x * jump_power 
				velocity.z = forward.z * jump_power 

				jump_power = 0.0

		# Gravity
		if not is_on_floor():
			anim_state.travel("Jump_Idle")
			anim_tree.set("parameters/conditions/grounded",false)
			# Check if character is falling down (negative y velocity)
			if velocity.y < 0:

				# Increase gravity when falling to make character fall faster
				GRAVITY = original_gravity + (2.5 * original_gravity)
			else:
				# Reset gravity to original when not falling (jumping up)
				GRAVITY = original_gravity
			
			velocity.y -= GRAVITY * delta
		else:
			# Reset gravity to original when on floor
			GRAVITY = original_gravity	
			
		var velocity_before_slide := velocity
		
		
		
		move_and_slide()
	
		#wall bouncing
		
		var collision_count = get_slide_collision_count()
		if collision_count > 0:
			for i in range(collision_count):
				var collision = get_slide_collision(i)
				if abs(collision.get_normal().y) < 0.1:
					var wall_normal := collision.get_normal()
					#R=L−2(N⋅L)N
					var reflection := velocity_before_slide - 2*(wall_normal.dot(velocity_before_slide))*wall_normal
					
					velocity = reflection
					
					
					

		if not was_on_floor and is_on_floor():
			landing_sfx.play()
			landed_timer = 0.5 
			anim_tree.set("parameters/conditions/grounded",true)
			anim_tree.set("parameters/conditions/jumping",false)
		was_on_floor = is_on_floor()


func respawn():
	global_transform.origin = respawn_position
	velocity = Vector3.ZERO 
