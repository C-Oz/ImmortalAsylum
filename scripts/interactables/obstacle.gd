# Obstacles destructable with the rhythm minigame
extends StaticBody2D

@export var sequence: Array[String] = ["Y", "B", "A"]

@onready var ui = $DestructionUI
@onready var interaction_zone: Area2D = $InteractionZone

var player_in_range: bool = false

func _ready() -> void:
	var state = GameManager.get_object_state(self)
	if state is String and state == "destroyed":
		queue_free()
		return
		
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
	
	if event.is_action_pressed("joy_y", false):
		button = "Y"
	elif event.is_action_pressed("joy_b", false):
		button = "B"
	elif event.is_action_pressed("joy_a", false):
		button = "A"
	
	if button:
		ui.check_input(button)

func _on_sequence_completed():
	# Save state as destroyed
	GameManager.save_object_state(self, "destroyed")
	# Play destruction animation/sound
	queue_free()
