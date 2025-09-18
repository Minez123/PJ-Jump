extends Control

@onready var icon_rect: TextureRect = $PanelContainer/HBoxContainer/icon 
@onready var name_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/name
@onready var desc_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/description

func _ready() -> void:
	add_to_group("item_popup")
	visible = false

func show_item(item_icon: Texture2D, item_id: String, item_desc: String, duration: float) -> void:
	# ✅ Apply texture to existing TextureRect
	icon_rect.texture = item_icon  
	icon_rect.expand = true
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(64, 64)  # 🔹 fixed size

	name_label.text = item_id
	desc_label.text = item_desc
	visible = true
	modulate.a = 1.0

	# Fade out after duration
	await get_tree().create_timer(duration).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(self.hide)
