extends Area2D
class_name Item

@export var item_data: ItemData
@export var quantity: int = 1

# Placeholder color since no sprites exist yet.
# Swap this script's visual for a Sprite2D once art is available.
@export var color: Color = Color(0.9, 0.8, 0.2)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if item_data == null or not body.is_in_group("player"):
		return
	Inventory.add_item(item_data, quantity)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, color)
