extends Node2D

# World holds whatever room is active (first child), the Player and the UI.
# RoomManager swaps the room. The player starts where it is placed in this scene,
# or on start_room's Spawns/<start_spawn> if set.

@export var start_room: Node
## Leave empty to start where the Player node is placed in the editor.
@export var start_spawn: String = ""

@onready var _player: Player = $Player
@onready var _floor: TileMapLayer = $LivingRoom/Floor
@onready var _walls: TileMapLayer = $LivingRoom/Walls

func _ready() -> void:
	Music.play_main_theme()
	RoomManager.setup(self, _player, start_room, start_spawn)
	Bubbles.say("guille puto",3.0)
	if SceneTransition.arrived_by_transition:
		SceneTransition.arrived_by_transition = false
		_place_player_bottom_left()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Puts the player on the bottom-left floor tile of the living room (skipping wall tiles).
func _place_player_bottom_left() -> void:
	var walls := {}
	for cell in _walls.get_used_cells():
		walls[cell] = true

	var best := Vector2i.ZERO
	var found := false
	for cell in _floor.get_used_cells():
		if walls.has(cell):
			continue
		if not found or cell.y > best.y or (cell.y == best.y and cell.x < best.x):
			best = cell
			found = true
	if not found:
		return

	_player.teleport_to(_floor.to_global(_floor.map_to_local(best)))
