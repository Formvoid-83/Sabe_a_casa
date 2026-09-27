extends Node

# Autoloaded singleton (see project.godot [autoload]).
# One-shot sound effects. Each call gets its own temporary AudioStreamPlayer
# parented to this persistent autoload, so the sound finishes playing even if
# whatever triggered it (an Item, the Pot, ...) is freed immediately after.

func play(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
