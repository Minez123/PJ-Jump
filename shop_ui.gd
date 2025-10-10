extends CanvasLayer
@onready var icon_rect: TextureRect = $Panel/Icon
@onready var name_label: Label = $Panel/Name
@onready var price_label: Label = $Panel/Price
@onready var description_label: Label = $Panel/Description


func _ready() -> void:
	visible=false
	add_to_group("shop_ui")

func show_item( price: int, player_ammo: int):
	price_label.text = str(price) + " Ammo Press E to buy"
	if player_ammo >= price:
		price_label.modulate = Color(0,1,0) # green
	else:
		price_label.modulate = Color(1,0,0) # red
	visible = true

func hide_item():
	visible = false

func reject():
	price_label.modulate = Color(1,0,0) # red
	price_label.text =  "Not Enough Ammo"
	visible = true
