extends CanvasLayer

@onready var mouse_slider: HSlider = $Panel/MouseSlider
@onready var volume_slider: HSlider = $Panel/VolumeSlider
@onready var confirm_button: Button = $Panel/ConfirmButton

var game_script: Node

func _ready():
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	mouse_slider.value = 0.0015  # default or load from settings
	volume_slider.value = 1

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
	var volume = volume_slider.value
	game_script.mouse_sensitivity = sensitivity
	AudioServer.set_bus_volume_db(0, linear_to_db(volume))
	hide_menu()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		hide_menu()
