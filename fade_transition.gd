extends ColorRect
func _ready() -> void:
	# Stretch to parent
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	
	# Reset offsets so it truly fills
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
