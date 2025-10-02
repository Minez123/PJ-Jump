extends Node2D

var button_type = null
var loaded_save_data = null
@onready var load_button: Button = $"button manager/load"
@onready var hub_music = $AudioStreamPlayer
@onready var seed_input: LineEdit = $"button manager/SeedInput"
@onready var SFX_slider: HSlider = $SFXSlider
@onready var Music_slider: HSlider = $MusicSlider
var custom_seed: int = -1   # default = random
var _previous_caret_position: int = 0

func _on_start_pressed() -> void:
	button_type = "start"
	$"button manager/Fade_transition".show()
	$"button manager/Fade_transition/Faade_Timer".start()
	seed_input.visible = false
	$"button manager/Fade_transition/AnimationPlayer".play("fade_in")


func _ready():
	# Check save file
	var settings = Savemanager.load_settings()

	SFX_slider.value = settings.get("sfx", 1.0)
	Music_slider.value = settings.get("music", 0.7)

	# Apply volumes immediately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(SFX_slider.value))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Music_slider.value))
	seed_input.text_changed.connect(_on_number_line_edit_text_changed)
	seed_input.text_changed.connect(_save_caret_position)
	hub_music.play()
	var save_data = Savemanager.load_game(Savemanager.SAVE_PATH)
	if save_data.has("at_goal") and save_data["at_goal"]:
		load_button.disabled = true
		load_button.modulate = Color(0.5, 0.5, 0.5) 
	else:
		load_button.disabled = false
		load_button.modulate = Color(1, 1, 1) 


func _on_number_line_edit_text_changed(new_text: String) -> void:
	var cleaned_text = ""
	var has_decimal_point = false
	var MAX_LENGTH = 10
	var was_truncated = false
	for char in new_text:
		if char >= "0" and char <= "9": 
			cleaned_text += char
	if cleaned_text.length() > MAX_LENGTH:
		cleaned_text = cleaned_text.substr(0, MAX_LENGTH)
		was_truncated = true
	if seed_input.text != cleaned_text:
		seed_input.text = cleaned_text
		seed_input.caret_column = _previous_caret_position - (new_text.length() - cleaned_text.length())
		
		if was_truncated:
			seed_input.caret_column = MAX_LENGTH
		else:
			var removed_count = new_text.length() - cleaned_text.length()
			seed_input.caret_column = _previous_caret_position - removed_count

func _save_caret_position(new_text: String) -> void:
	_previous_caret_position = seed_input.caret_column
	
func _on_quit_pressed() -> void:
	get_tree().quit()


# Your button manager script
func _on_faade_timer_timeout() -> void:
	if button_type == "start":
		if seed_input.text != "":
			custom_seed = int(seed_input.text)  # convert to int
		else:
			custom_seed = -1  # use random
		GameData.custom_seed = custom_seed
		var save_data = Savemanager.load_game(Savemanager.SAVE_PATH)
		GameData.reset_timer()
		get_tree().change_scene_to_file("res://main.tscn")
	elif button_type == "load":
		var save_data = Savemanager.load_game(Savemanager.SAVE_PATH)
		GameData.loaded_save_data = save_data
		get_tree().change_scene_to_file("res://main.tscn")
	elif button_type == "option":
		get_tree().change_scene_to_file("res://option_menu.tscn")
		

func _on_load_pressed() -> void:
	seed_input.visible = false
	button_type = "load"
	$"button manager/Fade_transition".show()
	$"button manager/Fade_transition/Faade_Timer".start()
	$"button manager/Fade_transition/AnimationPlayer".play("fade_in")

	


	
