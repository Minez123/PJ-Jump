extends Node3D

@onready var area: Area3D = $Area3D

var elapsed_time: float = 0.0
var running := true

func _ready():
	area.body_entered.connect(_on_area_body_entered)

func _process(delta: float) -> void:
	if running:
		elapsed_time += delta

func _on_area_body_entered(body: Node) -> void:
	if body.is_in_group("player") and running:
		running = false  # stop counting

		# Convert to min:sec
		var minutes = int(elapsed_time) / 60
		var seconds = int(elapsed_time) % 60

		print("%d:%02d" % [minutes, seconds])
