extends Node2D

const WORLD_LAYER := 1 # physics layer "World" — what the player's movement checks against

# The three item types that can appear in the garden.
@export var garden_items: Array[ItemData] = [
	preload("res://resources/items/cilantro.tres"),
	preload("res://resources/items/perejil.tres"),
]
@export var item_count: int = 17
@export var spawn_area: Rect2 = Rect2(10, 10, 200, 170)

func _ready() -> void:
	_build_boundaries()
	
	var spawner := ItemSpawner.new()
	spawner.name = "ItemSpawner"
	spawner.item_pool = garden_items
	spawner.spawn_count = item_count
	spawner.spawn_area = spawn_area
	add_child(spawner)
	Bubbles.say("cilantro... que?, pere... que?" , 3 )
	# Wait until the first bubble has fully closed, then show the next one.
	await Bubbles.closed
	Bubbles.say("cual sera cual????? :(", 3)


# Surrounds the painted area of every TileMapLayer with solid cells, so the
# player can't step onto any cell that has no tile in any layer.
func _build_boundaries() -> void:
	var layers: Array[TileMapLayer] = []
	for child in get_children():
		if child is TileMapLayer:
			layers.append(child)
	if layers.is_empty():
		return

	# Use the first layer's grid as reference and merge the used cells of all layers into it.
	var grid: TileMapLayer = layers[0]
	var used := {}
	for layer in layers:
		for cell in layer.get_used_cells():
			var world_pos := layer.to_global(layer.map_to_local(cell))
			used[grid.local_to_map(grid.to_local(world_pos))] = true

	var tile_size := Vector2(grid.tile_set.tile_size)
	var body := StaticBody2D.new()
	body.name = "Boundaries"
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	grid.add_child(body)

	var blocked := {}
	for cell in used:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var neighbour: Vector2i = cell + Vector2i(dx, dy)
				if used.has(neighbour) or blocked.has(neighbour):
					continue
				blocked[neighbour] = true
				var shape := RectangleShape2D.new()
				shape.size = tile_size
				var collider := CollisionShape2D.new()
				collider.shape = shape
				collider.position = grid.map_to_local(neighbour)
				body.add_child(collider)
