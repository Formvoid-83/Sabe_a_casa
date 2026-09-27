extends StaticBody2D

## Empties the inventory into this pot, tossing each item's icon through a
## small arc from `from_position` and freeing it on arrival.

const FLIGHT_DURATION := 0.5
const ARC_HEIGHT := 24.0
const STAGGER_DELAY := 0.12
# The sprite isn't centered on this node's origin (see Sprite2D/CollisionShape2D
# offsets in the scene), so aim the landing point at its visual middle instead.
const VISUAL_CENTER_OFFSET := Vector2(7, 6.5)

const BOILING_SOUND := preload("res://sounds/Boiling.wav")

func _ready() -> void:
	add_to_group("cooking_pot")

func receive_items(from_position: Vector2) -> void:
	var snapshot: Array = Inventory.slots.duplicate(true)
	if snapshot.is_empty():
		return
	Inventory.clear()
	Sfx.play(BOILING_SOUND)
	for slot in snapshot:
		var item: ItemData = slot["item"]
		Recipe.deliver(item, slot["quantity"])
		_spawn_flying_item(item.icon, from_position)
		await get_tree().create_timer(STAGGER_DELAY).timeout

func _spawn_flying_item(icon: Texture2D, from_position: Vector2) -> void:
	if icon == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = icon
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.global_position = from_position
	get_tree().current_scene.add_child(sprite)

	var target := global_position + VISUAL_CENTER_OFFSET
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(t: float) -> void:
		var pos := from_position.lerp(target, t)
		pos.y -= sin(t * PI) * ARC_HEIGHT
		sprite.global_position = pos
	, 0.0, 1.0, FLIGHT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", Vector2(0.4, 0.4), FLIGHT_DURATION)
	tween.chain().tween_callback(sprite.queue_free)
