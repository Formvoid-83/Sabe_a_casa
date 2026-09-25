extends Node2D

const TILE_SIZE := 16
const GRID_EXTENT := 20 # tiles drawn in each direction from the origin

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var half := GRID_EXTENT * TILE_SIZE
	var color := Color(1, 1, 1, 0.12)
	var x := -half
	while x <= half:
		draw_line(Vector2(x, -half), Vector2(x, half), color)
		x += TILE_SIZE
	var y := -half
	while y <= half:
		draw_line(Vector2(-half, y), Vector2(half, y), color)
		y += TILE_SIZE
