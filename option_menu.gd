extends CanvasLayer

@onready var mouse_slider: HSlider = $Panel/MouseSlider
@onready var SFX_slider: HSlider = $Panel/SFXSlider
@onready var Music_slider: HSlider = $Panel/MusicSlider
@onready var confirm_button: Button = $Panel/ConfirmButton

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
