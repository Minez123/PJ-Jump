extends Control

@onready var icon_rect: TextureRect = $PanelContainer/HBoxContainer/icon
@onready var name_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/name
@onready var desc_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/description

func _ready() -> void:
	add_to_group("item_popup")
	visible = false

func show_item(item_resource: Resource, duration: float) -> void:
	# Cast the generic Resource to your specific ItemResource class.
	var item_data: ItemResource = item_resource as ItemResource

	# Check if the cast was successful before accessing properties.
	if not item_data:
		printerr("Error: Expected an ItemResource, but received a different type.")
		return
	
	icon_rect.texture = item_data.texture
	name_label.text = item_data.item_name
	desc_label.text = item_data.description
	
	icon_rect.expand = true
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(64, 64)

	visible = true
	modulate.a = 1.0

	await get_tree().create_timer(duration).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(self.hide)
