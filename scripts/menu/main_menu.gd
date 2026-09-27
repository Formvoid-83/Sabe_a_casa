extends Control

const KITCHEN_SCENE := "res://scenes/world/kitchen_world.tscn"

func _ready() -> void:
	Music.play_menu_theme()

func _on_play_pressed() -> void:
	FadeTransition.go_to(KITCHEN_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
