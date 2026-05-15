extends Area2D

@onready var sprite = $Sprite2D
@onready var particles = $SuccessParticles

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect():
	# 1. Disable collision immediately so it can't be picked up twice
	set_deferred("monitoring", false)
	
	# 2. Tell the game we won
	GameManager.collect_win_item()
	
	# 3. Hide the crown visuals
	sprite.visible = false
	
	# 4. Fire the particles (ensure 'One Shot' is ON in inspector)
	particles.restart()
	particles.emitting = true
	
	# 5. Wait for the particles to finish (lifetime) before freeing the node
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
