extends Node2D

# World holds whatever room is active (first child), the Player and the UI.
# RoomManager swaps the room. The player starts where it is placed in this scene,
# or on start_room's Spawns/<start_spawn> if set.

@export var start_room: Node
## Leave empty to start where the Player node is placed in the editor.
@export var start_spawn: String = ""

@onready var _player: Player = $Player

func _ready() -> void:
	RoomManager.setup(self, _player, start_room, start_spawn)
	Bubbles.say("guille puto",3.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
