extends CharacterBody2D

@export var speed: float = 200.0

func _ready() -> void:
	if GameManager.returning_from_battle and GameManager.saved_player_position != Vector2.ZERO:
		global_position = GameManager.saved_player_position

func _physics_process(_delta: float) -> void:
	if DialogueBox.is_active():
		velocity = Vector2.ZERO
		return
	
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed
	move_and_slide()
