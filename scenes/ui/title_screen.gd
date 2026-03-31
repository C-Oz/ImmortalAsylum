extends Control

func _ready() -> void:
	$StartButton.pressed.connect(_on_start_pressed)
	$StartButton.grab_focus()
	$VersionNo.text = "Version: %s" % ProjectSettings.get_setting("application/config/version")

func _on_start_pressed() -> void:
	#GameManager.change_scene("res://scenes/overworld/overworld.tscn")
	GameManager.change_scene("res://scenes/overworld/EastArea.tscn")
