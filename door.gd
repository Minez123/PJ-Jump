extends Node3D

@onready var label_K = $Hints/K
@onready var label_U = $Hints/U
@onready var label_C = $Hints/C
@onready var label_O = $Hints/O
@onready var label_M = $Hints/M
@onready var label_S = $Hints/S
@onready var label_C2 = $Hints/C2
@onready var label_I = $Hints/I
@onready var door_anim = $AnimationPlayer
@onready var door = $AnimatableBody3D
var opened= false
func _ready():
	if not GameData.loaded_save_data:
		opened = false
		door_anim.stop()
		door_anim.play("RESET")

		

func _process(_delta):
	# Update hint lights each frame
	label_K.modulate = Color.GREEN_YELLOW if GameData.collected_keys["K"] else Color(0.2, 0.2, 0.2)
	label_U.modulate = Color.GREEN_YELLOW if GameData.collected_keys["U"] else Color(0.2, 0.2, 0.2)
	label_C.modulate = Color.DARK_BLUE if GameData.collected_keys["C"] else Color(0.2, 0.2, 0.2)
	label_O.modulate = Color.DARK_BLUE if GameData.collected_keys["O"] else Color(0.2, 0.2, 0.2)
	label_M.modulate = Color.DARK_BLUE if GameData.collected_keys["M"] else Color(0.2, 0.2, 0.2)
	label_S.modulate = Color.DARK_BLUE if GameData.collected_keys["S"] else Color(0.2, 0.2, 0.2)
	label_C2.modulate = Color.DARK_BLUE if GameData.collected_keys["C2"] else Color(0.2, 0.2, 0.2)
	label_I.modulate = Color.DARK_BLUE if GameData.collected_keys["I"] else Color(0.2, 0.2, 0.2)



func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if GameData.has_all_keys() and not opened:
			open_door()
			
func open_door():
	opened = true
	if not door_anim.is_playing():
		door_anim.play("open")  
		
