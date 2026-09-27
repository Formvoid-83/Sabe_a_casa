extends CanvasLayer

# Autoloaded singleton (see project.godot [autoload]).
# Swaps the room shown inside World and places the player on a spawn point:
#   RoomManager.go_to("res://scenes/world/second_floor.tscn", "FromDownstairs")
# Rooms are kept in memory after leaving them, so picked-up items stay gone.
# Every room scene needs a "Spawns" node with Marker2D children to arrive at.

signal room_changed(room: Node)

const FADE_TIME := 0.25

var current_room: Node

var _room_parent: Node
var _player: Player
var _rooms := {} # scene path -> room instance
var _busy := false
var _fade: ColorRect

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

## Called by World once: the room already in the scene becomes the current one.
func setup(room_parent: Node, player: Player, first_room: Node, spawn_name: String) -> void:
	_room_parent = room_parent
	_player = player
	current_room = first_room
	_rooms[first_room.scene_file_path] = first_room
	_place_player(spawn_name)

func is_busy() -> bool:
	return _busy

func go_to(room_path: String, spawn_name: String) -> void:
	if _busy or room_path.is_empty():
		return
	if _player == null:
		push_error("RoomManager: call setup() first (World._ready does it)")
		return
	_busy = true
	_player.set_physics_process(false)
	await _fade_to(1.0)

	_room_parent.remove_child(current_room)
	var room: Node = _rooms.get(room_path)
	if room == null:
		room = load(room_path).instantiate()
		_rooms[room_path] = room
	_room_parent.add_child(room)
	_room_parent.move_child(room, 0) # rooms draw under the player
	current_room = room
	_place_player(spawn_name)
	room_changed.emit(room)

	await get_tree().physics_frame # let the new room's collisions register
	_player.set_physics_process(true)
	await _fade_to(0.0)
	_busy = false

func _place_player(spawn_name: String) -> void:
	var point := _player.global_position
	if not spawn_name.is_empty():
		var spawn := current_room.get_node_or_null("Spawns/" + spawn_name) as Node2D
		if spawn == null:
			push_warning("RoomManager: no Spawns/%s in %s" % [spawn_name, current_room.name])
		else:
			point = spawn.global_position
	_player.teleport_to(point)

func _exit_tree() -> void:
	# Rooms we left are outside the tree, so nothing else would free them.
	for room in _rooms.values():
		if is_instance_valid(room) and not room.is_inside_tree():
			room.free()

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished
