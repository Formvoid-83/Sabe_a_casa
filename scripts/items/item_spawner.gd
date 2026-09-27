extends Node2D
class_name ItemSpawner

# Spawns random pickable items on free floor tiles: never on walls/furniture,
# never on the player, and never on a tile that already holds an item.

@export var item_scene: PackedScene = preload("res://scenes/items/item.tscn")
@export var item_pool: Array[ItemData] = []
@export var spawn_count: int = 5
@export var floor_layer: TileMapLayer
# Used when floor_layer is not set: a local-space rect split into cell_size tiles.
@export var spawn_area: Rect2 = Rect2(0, 0, 160, 160)
@export var cell_size: int = 16
@export_flags_2d_physics var obstacle_mask: int = 1 # same "World" layer the player collides with
@export var player_clearance: float = 16.0

func _ready() -> void:
	# Wait one physics frame so the player has joined its group and
	# furniture colliders are registered for point queries.
	await get_tree().physics_frame
	spawn_items()

func spawn_items() -> void:
	if item_scene == null or item_pool.is_empty():
		push_warning("ItemSpawner: item_scene and item_pool must be set.")
		return

	var candidates := _get_free_positions()
	candidates.shuffle()
	if candidates.size() < spawn_count:
		push_warning("ItemSpawner: only %d free tiles for %d items." % [candidates.size(), spawn_count])

	# Each candidate is a distinct tile, so no two items share a spot.
	for i in mini(spawn_count, candidates.size()):
		var item: Item = item_scene.instantiate()
		item.item_data = item_pool.pick_random()
		add_child(item)
		item.global_position = candidates[i]

func _get_candidate_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	if floor_layer != null:
		for cell in floor_layer.get_used_cells():
			result.append(floor_layer.to_global(floor_layer.map_to_local(cell)))
		return result
	var cols := int(spawn_area.size.x) / cell_size
	var rows := int(spawn_area.size.y) / cell_size
	for x in cols:
		for y in rows:
			var local := spawn_area.position + Vector2(x + 0.5, y + 0.5) * cell_size
			result.append(to_global(local))
	return result

func _get_free_positions() -> Array[Vector2]:
	var half_tile := (floor_layer.tile_set.tile_size.x if floor_layer != null else cell_size) * 0.5
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var existing_items := get_tree().get_nodes_in_group("items")

	var result: Array[Vector2] = []
	for pos in _get_candidate_positions():
		if player != null and pos.distance_to(player.global_position) < player_clearance:
			continue
		if _is_near_item(pos, existing_items, half_tile):
			continue
		if _is_blocked(pos):
			continue
		result.append(pos)
	return result

func _is_near_item(pos: Vector2, items: Array[Node], radius: float) -> bool:
	for item in items:
		if item is Node2D and pos.distance_to(item.global_position) < radius:
			return true
	return false

func _is_blocked(pos: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = obstacle_mask
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()
