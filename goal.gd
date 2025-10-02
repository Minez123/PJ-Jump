extends Node3D

@onready var area: Area3D = $Area3D
@onready var ending_screen: CanvasLayer = $EndingScreen   # CanvasLayer UI
@onready var time_label: Label = $EndingScreen/Panel/VBoxContainer/TimeLabel
@onready var best_label: Label = $EndingScreen/Panel/VBoxContainer/BestLabel

var elapsed_time: float = 0.0
var running := true

func _ready():
	area.body_entered.connect(_on_area_body_entered)
	ending_screen.visible = false

func _process(delta: float) -> void:
	pass

func _on_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and GameData.timing_active:
		GameData.timing_active = false  # stop counting
		var Finish_time = GameData.elapsed_time
		# Convert to min:sec
		var minutes = int(Finish_time) / 60
		var seconds = int(Finish_time) % 60

		var formatted = "%d:%02d" % [minutes, seconds]


		var save_data = Savemanager.load_game(Savemanager.SAVE_PATH)
		var old_best := -1.0
		if save_data.has("best_time"):
			old_best = GameData.best_time
		GameData.elapsed_time = Finish_time

		var new_best := old_best
		if old_best < 0 or Finish_time  < old_best:
			new_best = Finish_time 
			GameData.best_time = new_best
			print("new high")
		else:
			GameData.best_time = old_best
			print("old high")

		# Format PB

		var best_formatted = "N/A"
		if new_best >= 0:
			var bmin = int(new_best) / 60
			var bsec = int(new_best) % 60
			best_formatted = "%d:%02d" % [bmin, bsec]

		time_label.text = "Your Time: %s" % formatted
		best_label.text = "Best Time: %s" % best_formatted
		ending_screen.visible = true

		var world = get_tree().get_first_node_in_group("world")
		GameData.at_goal = true
		GameData.reset_keys()
		Savemanager.save_game(body, world)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func _on_confirm_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
