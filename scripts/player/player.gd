extends CharacterBody2D
class_name Player

const TILE_SIZE := 32
const WORLD_LAYER_MASK := 1 # collision_mask bit for the "World"/obstacles layer

@export var tiles_per_second: float = 6.0

# Placeholder color since no sprites exist yet.
# Swap this script's visual for a Sprite2D/AnimatedSprite2D once art is available.
@export var color: Color = Color(0.2, 0.6, 1.0)

var _is_moving := false
var _target_position := Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	_target_position = global_position
	queue_redraw()

func _physics_process(delta: float) -> void:
	if _is_moving:
		_advance_towards_target(delta)
	else:
		var direction := _get_input_direction()
		if direction != Vector2.ZERO:
			_try_move(direction)

func _get_input_direction() -> Vector2:
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		return Vector2.UP
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		return Vector2.DOWN
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		return Vector2.LEFT
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		return Vector2.RIGHT
	return Vector2.ZERO

func _try_move(direction: Vector2) -> void:
	var destination := global_position + direction * TILE_SIZE
	if _is_tile_blocked(destination):
		return
	_target_position = destination
	_is_moving = true

func _is_tile_blocked(destination: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = destination
	query.collision_mask = WORLD_LAYER_MASK
	var result := space_state.intersect_point(query, 1)
	return not result.is_empty()

func _advance_towards_target(delta: float) -> void:
	var step := TILE_SIZE * tiles_per_second * delta
	global_position = global_position.move_toward(_target_position, step)
	if global_position.distance_to(_target_position) < 0.5:
		global_position = _target_position
		_is_moving = false

func _draw() -> void:
	var half := TILE_SIZE / 2.0 - 2.0
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), color)
