@tool
extends Area2D
class_name Item

# Setter refreshes the icon so the item is visible while editing the scene.
@export var item_data: ItemData:
	set(value):
		item_data = value
		if is_node_ready():
			_update_icon()
@export var quantity: int = 1

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_update_icon()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)

func _update_icon() -> void:
	_sprite.texture = item_data.icon if item_data != null else null

func _on_body_entered(body: Node2D) -> void:
	if item_data == null or not body.is_in_group("player"):
		return
	Inventory.add_item(item_data, quantity)
	queue_free()
