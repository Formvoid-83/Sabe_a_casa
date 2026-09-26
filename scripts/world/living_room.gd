extends Node2D

# Builds the living room (floor, walls, door, window, furniture) at runtime
# from the raw sprite sheets, since hand-authoring a TileSet/TileMap resource
# by hand is far more error-prone than composing it in code.

const TILE_SIZE := 16

const ROOM_WIDTH := 14   # columns: 0..13
const ROOM_HEIGHT := 12  # rows: 0..11
const WALL_ROWS := 3     # top wall is 3 tiles tall, matching the door art's height
const DOOR_COLS := Vector2i(6, 7)   # inclusive column range in the top wall
const WINDOW_COLS := Vector2i(2, 3) # inclusive column range in the top wall

const FLOORS_WALLS_PNG := preload("res://sprites/TopDownHouse_FloorsAndWalls.png")
const DOORS_WINDOWS_PNG := preload("res://sprites/TopDownHouse_DoorsAndWindows.png")
const FURNITURE1_PNG := preload("res://sprites/TopDownHouse_FurnitureState1.png")
const FURNITURE2_PNG := preload("res://sprites/TopDownHouse_FurnitureState2.png")

# --- TopDownHouse_FloorsAndWalls.png tile coords (col, row), tan room set ---
const WALL_PLAIN := Vector2i(9, 1)
const WALL_BASE := Vector2i(9, 4)
const FLOOR_TILE := Vector2i(10, 6)

# --- TopDownHouse_DoorsAndWindows.png tile coords, tan frame set ---
# Open doorway frame: 2 cols x 3 rows, walkable (no collision) -> leads to the kitchen later.
const DOOR_FRAME := [
	[Vector2i(12, 5), Vector2i(13, 5)],
	[Vector2i(12, 6), Vector2i(13, 6)],
	[Vector2i(12, 7), Vector2i(13, 7)],
]
# 4-pane window: 2 cols x 2 rows, blocks movement like the rest of the wall.
const WINDOW_TILES := [
	[Vector2i(12, 8), Vector2i(13, 8)],
	[Vector2i(12, 9), Vector2i(13, 9)],
]

# --- Furniture pieces as [dx, dy, atlas_col, atlas_row] lists ---
const FIREPLACE_TILES := [[0,0,9,7],[1,0,10,7],[0,1,9,8],[1,1,10,8],[0,2,9,9],[1,2,10,9]]
const BOOKSHELF_TILES := [[0,0,2,6],[1,0,3,6],[2,0,4,6],[0,1,2,7],[1,1,3,7],[2,1,4,7]]
const COFFEE_TABLE_TILES := [[0,0,5,2],[1,0,6,2],[0,1,5,3],[1,1,6,3]]
const ARMCHAIR_TILES := [[0,0,11,8],[1,0,12,8],[0,1,11,9],[1,1,12,9]]
const FLOOR_LAMP_TILES := [[0,0,6,7],[0,1,6,8],[0,2,6,9]]
const SOFA_TILES := [[0,0,2,10],[1,0,3,10],[2,0,4,10],[0,1,2,11],[1,1,3,11],[2,1,4,11]]
const PLANT_TILES := [[0,0,0,10],[0,1,0,11]]
const RUG_TILES := [[0,0,10,2],[1,0,11,2],[2,0,12,2],[0,1,10,3],[1,1,11,3],[2,1,12,3]]

var _fw_source_id: int
var _dw_source_id: int
var _f1_source_id: int
var _f2_source_id: int

var _tile_set: TileSet
var _floor_layer: TileMapLayer
var _wall_layer: TileMapLayer
var _furniture_layer: TileMapLayer

func _ready() -> void:
	_build_tile_set()
	_floor_layer = _make_layer()
	_wall_layer = _make_layer()
	_furniture_layer = _make_layer()

	_paint_floor()
	_paint_walls()
	_paint_furniture()

func _make_layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = _tile_set
	add_child(layer)
	return layer

func _build_tile_set() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	_tile_set.add_physics_layer()
	_tile_set.set_physics_layer_collision_layer(0, 1) # matches Player.WORLD_LAYER_MASK

	_fw_source_id = _add_source(FLOORS_WALLS_PNG)
	_dw_source_id = _add_source(DOORS_WINDOWS_PNG)
	_f1_source_id = _add_source(FURNITURE1_PNG)
	_f2_source_id = _add_source(FURNITURE2_PNG)

	_register_tile(_fw_source_id, WALL_PLAIN, true)
	_register_tile(_fw_source_id, WALL_BASE, true)
	_register_tile(_fw_source_id, FLOOR_TILE, false)

	for row in DOOR_FRAME:
		for coords in row:
			_register_tile(_dw_source_id, coords, false)
	for row in WINDOW_TILES:
		for coords in row:
			_register_tile(_dw_source_id, coords, true)

	for tiles in [FIREPLACE_TILES, ARMCHAIR_TILES, FLOOR_LAMP_TILES, SOFA_TILES, PLANT_TILES, COFFEE_TABLE_TILES]:
		for cell in tiles:
			_register_tile(_f1_source_id, Vector2i(cell[2], cell[3]), true)
	for cell in RUG_TILES:
		_register_tile(_f1_source_id, Vector2i(cell[2], cell[3]), false)
	for cell in BOOKSHELF_TILES:
		_register_tile(_f2_source_id, Vector2i(cell[2], cell[3]), true)

func _add_source(texture: Texture2D) -> int:
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	return _tile_set.add_source(source)

func _register_tile(source_id: int, coords: Vector2i, collidable: bool) -> void:
	var source := _tile_set.get_source(source_id) as TileSetAtlasSource
	if not source.has_tile(coords):
		source.create_tile(coords)
	if not collidable:
		return
	var data := source.get_tile_data(coords, 0)
	if data.get_collision_polygons_count(0) == 0:
		data.add_collision_polygon(0)
		var half := TILE_SIZE / 2.0
		data.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-half, -half), Vector2(half, -half),
			Vector2(half, half), Vector2(-half, half),
		]))

func _paint_floor() -> void:
	for row in range(WALL_ROWS, ROOM_HEIGHT - 1):
		for col in range(1, ROOM_WIDTH - 1):
			_floor_layer.set_cell(Vector2i(col, row), _fw_source_id, FLOOR_TILE)
	_stamp(_floor_layer, RUG_TILES, _f1_source_id, Vector2i(4, 6))

func _paint_walls() -> void:
	for col in range(0, ROOM_WIDTH):
		for row in range(0, WALL_ROWS):
			if col >= DOOR_COLS.x and col <= DOOR_COLS.y:
				_wall_layer.set_cell(Vector2i(col, row), _dw_source_id, DOOR_FRAME[row][col - DOOR_COLS.x])
				continue
			if col >= WINDOW_COLS.x and col <= WINDOW_COLS.y and row > 0:
				_wall_layer.set_cell(Vector2i(col, row), _dw_source_id, WINDOW_TILES[row - 1][col - WINDOW_COLS.x])
				continue
			var tile := WALL_BASE if row == WALL_ROWS - 1 else WALL_PLAIN
			_wall_layer.set_cell(Vector2i(col, row), _fw_source_id, tile)

	for row in range(WALL_ROWS, ROOM_HEIGHT):
		_wall_layer.set_cell(Vector2i(0, row), _fw_source_id, WALL_BASE)
		_wall_layer.set_cell(Vector2i(ROOM_WIDTH - 1, row), _fw_source_id, WALL_BASE)
	for col in range(0, ROOM_WIDTH):
		_wall_layer.set_cell(Vector2i(col, ROOM_HEIGHT - 1), _fw_source_id, WALL_BASE)

func _paint_furniture() -> void:
	_stamp(_furniture_layer, FIREPLACE_TILES, _f1_source_id, Vector2i(1, 3))
	_stamp(_furniture_layer, BOOKSHELF_TILES, _f2_source_id, Vector2i(10, 3))
	_stamp(_furniture_layer, COFFEE_TABLE_TILES, _f1_source_id, Vector2i(5, 7))
	_stamp(_furniture_layer, ARMCHAIR_TILES, _f1_source_id, Vector2i(8, 7))
	_stamp(_furniture_layer, FLOOR_LAMP_TILES, _f1_source_id, Vector2i(10, 7))
	_stamp(_furniture_layer, SOFA_TILES, _f1_source_id, Vector2i(5, 9))
	_stamp(_furniture_layer, PLANT_TILES, _f1_source_id, Vector2i(12, 9))

func _stamp(layer: TileMapLayer, piece: Array, source_id: int, origin: Vector2i) -> void:
	for cell in piece:
		layer.set_cell(origin + Vector2i(cell[0], cell[1]), source_id, Vector2i(cell[2], cell[3]))
