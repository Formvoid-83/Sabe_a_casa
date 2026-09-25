extends Area2D
class_name Item

@export var item_data: ItemData
@export var quantity: int = 1

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if item_data != null:
		_sprite.texture = item_data.icon

func _on_body_entered(body: Node2D) -> void:
	if item_data == null or not body.is_in_group("player"):
		return
	Inventory.add_item(item_data, quantity)
	queue_free()
