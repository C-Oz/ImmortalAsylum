extends Control

func _ready() -> void:
	$StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	GameManager.change_scene("res://scenes/overworld/overworld.tscn")
