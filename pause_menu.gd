extends CanvasLayer

@onready var mouse_slider: HSlider = $Panel/MouseSlider
@onready var SFX_slider: HSlider = $Panel/SFXSlider
@onready var Music_slider: HSlider = $Panel/MusicSlider
@onready var confirm_button: Button = $Panel/ConfirmButton
@onready var save_confirm_dialog: ConfirmationDialog = $SaveConfirmDialog
var game_script: Node

func _ready():
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)

	var settings = Savemanager.load_settings()
	mouse_slider.value = settings.get("mouse_sensitivity", 0.0015)
	SFX_slider.value = settings.get("sfx", 1.0)
	Music_slider.value = settings.get("music", 0.7)

	# Apply volumes immediately
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(SFX_slider.value))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Music_slider.value))

func show_menu():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

func hide_menu():
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_confirm_pressed():
	var sensitivity = mouse_slider.value
	var SFX = SFX_slider.value
	var Music = Music_slider.value

	game_script.mouse_sensitivity = sensitivity
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(SFX))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Music))
	Savemanager.save_settings(sensitivity, SFX, Music)

	hide_menu()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			hide_menu()
		else:
			game_script = get_tree().get_first_node_in_group("player") # or pass reference
			show_menu()


			



func _on_save_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var world = get_tree().get_first_node_in_group("world")
	GameData.at_goal = false
	Savemanager.save_game(player, world)
	save_confirm_dialog.popup_centered()

func _on_save_confirm_dialog_confirmed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
	



func _on_save_confirm_dialog_canceled() -> void:
	_on_confirm_pressed()
	
