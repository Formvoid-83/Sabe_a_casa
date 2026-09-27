extends Node

# Autoloaded singleton (see project.godot [autoload]).
# Persists across scene changes, so calling play() with the track that's
# already playing is a no-op instead of restarting it - that's what lets the
# soundtrack keep going as the player walks between the living room and the
# kitchen (two separate top-level scenes swapped via change_scene_to_file).

const MAIN_THEME := preload("res://sounds/main.ogg")

var _player: AudioStreamPlayer
var _current_stream: AudioStream

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

## Starts playing `stream` on loop, unless it's already the one playing.
func play(stream: AudioStream) -> void:
	if stream == null or stream == _current_stream:
		return
	_current_stream = stream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_player.stream = stream
	_player.play()

func play_main_theme() -> void:
	play(MAIN_THEME)

func stop() -> void:
	_current_stream = null
	_player.stop()
