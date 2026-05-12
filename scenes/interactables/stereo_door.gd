extends StaticBody2D

@onready var interaction_zone: Area2D = $InteractionZone
@onready var door_collision: CollisionShape2D = $DoorCollision
@onready var door_tile: TileMapLayer = $DoorTile
@onready var success_particles := get_node_or_null("SuccessParticles") as GPUParticles2D

var player_in_zone: bool = false
var is_open: bool = false

func _ready() -> void:
	interaction_zone.body_entered.connect(_on_interaction_zone_body_entered)
	interaction_zone.body_exited.connect(_on_interaction_zone_body_exited)

func _on_interaction_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = true

func _on_interaction_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = false

func _input(event: InputEvent) -> void:
	if is_open:
		return

	if event.is_action_pressed("open_stereo") and player_in_zone:
		open_door()

func open_door() -> void:
	is_open = true
	door_tile.visible = false
	door_collision.set_deferred("disabled", true)
	_play_open_particles()

func _play_open_particles() -> void:
	if not is_instance_valid(success_particles):
		return
	
	success_particles.restart()
	success_particles.emitting = true
