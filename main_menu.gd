extends Node2D

var button_type = null
var loaded_save_data = null

func _on_start_pressed() -> void:
	button_type = "start"
	$"button manager/Fade_transition".show()
	$"button manager/Fade_transition/Faade_Timer".start()
	$"button manager/Fade_transition/AnimationPlayer".play("fade_in")






func _on_quit_pressed() -> void:
	get_tree().quit()


# Your button manager script
func _on_faade_timer_timeout() -> void:
	if button_type == "start":
		get_tree().change_scene_to_file("res://main.tscn")
	elif button_type == "load":
		var data = Savemanager.load_game("user://savegame.json")
		GameData.loaded_save_data = data
		get_tree().change_scene_to_file("res://main.tscn")
		

func _on_load_pressed() -> void:
	button_type = "load"
	$"button manager/Fade_transition".show()
	$"button manager/Fade_transition/Faade_Timer".start()
	$"button manager/Fade_transition/AnimationPlayer".play("fade_in")

	
