extends Control

@onready var _message_label: Label = $CenterContainer/VBoxContainer/MessageLabel


func _ready() -> void:
	_message_label.text = GameOver.pending_message

func _on_menu_button_pressed() -> void:
	FadeTransition.go_to("res://scenes/menu/main_menu.tscn")
