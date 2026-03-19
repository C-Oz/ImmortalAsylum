extends CharacterBody2D

@export var speed: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if GameManager.returning_from_battle and GameManager.saved_player_position != Vector2.ZERO:
		global_position = GameManager.saved_player_position

func _physics_process(_delta: float) -> void:
	if DialogueBox.is_active():
		velocity = Vector2.ZERO
		sprite.play("idle")
		return
	
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed
	
	if input_vector != Vector2.ZERO:
		sprite.play("run")
		if input_vector.x != 0:
			sprite.flip_h = input_vector.x < 0
	else:
		sprite.play("idle")
		
	move_and_slide()
