extends CanvasLayer

@onready var timer_label: Label = $TimerLabel

func _process(delta: float) -> void:
	if GameData.timing_active:
		GameData.elapsed_time += delta

	var minutes = int(GameData.elapsed_time) / 60
	var seconds = int(GameData.elapsed_time) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
