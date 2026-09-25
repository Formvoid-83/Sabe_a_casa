extends CharacterBody2D
class_name Player

const TILE_SIZE := 16
const WORLD_LAYER_MASK := 1 # collision_mask bit for the "World"/obstacles layer

const SPRITE_SHEET := preload("res://sprites/AnimationSheet.png")
const FRAME_SIZE := 24
const SHEET_COLUMNS := 8
# AnimationSheet.png only has a front-facing pose (no back/side view), so
# left/right reuse the same frames mirrored via flip_h, and up reuses down.
const IDLE_FRAMES := [0, 1]
const WALK_FRAMES := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 40, 41]

@export var tiles_per_second: float = 6.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _is_moving := false
var _target_position := Vector2.ZERO
var _facing_left := false

func _ready() -> void:
	add_to_group("player")
	_target_position = global_position
	_sprite.sprite_frames = _build_sprite_frames()
	_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if _is_moving:
		_advance_towards_target(delta)
	else:
		var direction := _get_input_direction()
		if direction != Vector2.ZERO:
			_try_move(direction)
		else:
			_sprite.play("idle")

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
	if direction.x != 0.0:
		_facing_left = direction.x < 0.0
		_sprite.flip_h = _facing_left
	_target_position = destination
	_is_moving = true
	_sprite.play("walk")

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

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_animation(frames, "idle", IDLE_FRAMES, 3.0)
	_add_animation(frames, "walk", WALK_FRAMES, 12.0)
	return frames

func _add_animation(frames: SpriteFrames, anim_name: String, indices: Array, fps: float) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, true)
	for index: int in indices:
		var col: int = index % SHEET_COLUMNS
		var row: int = index / SHEET_COLUMNS
		var atlas := AtlasTexture.new()
		atlas.atlas = SPRITE_SHEET
		atlas.region = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(anim_name, atlas)
