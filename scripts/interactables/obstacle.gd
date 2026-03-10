# Obstacles destructable with the rhythm minigame
extends StaticBody2D

@export var sequence: Array[String] = ["Y", "B", "A"]

@onready var ui = $DestructionUI
@onready var interaction_zone: Area2D = $InteractionZone

var player_in_range: bool = false

func _ready() -> void:
	# Pass sequence to UI
	ui.sequence = sequence
	ui.setup_sequence()
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	ui.sequence_completed.connect(_on_sequence_completed)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player detected, starting sequence")
		ui.start_sequence()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		ui.stop_sequence()

func on_beat():
	#print("Obstacle.gd on_beat called")
	ui.on_beat()

func _input(event):
	# Only process input if UI is active
	var button = null
	
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_Y:
			button = "Y"
		elif event.button_index == JOY_BUTTON_B:
			button = "B"
		elif event.button_index == JOY_BUTTON_A:
			button = "A"
	# Keyboard fallback for debugging
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			button = "Y"
		elif event.keycode == KEY_A:
			button = "B"
		elif event.keycode == KEY_Z:
			button = "A"
	
	if button:
		ui.check_input(button)

func _on_sequence_completed():
	# Play destruction animation/sound
	queue_free()
