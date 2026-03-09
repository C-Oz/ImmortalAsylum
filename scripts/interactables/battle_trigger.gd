extends Interactable

@export var one_time_only: bool = true
var has_been_used: bool = false

func _ready() -> void:
	var collision := get_node_or_null("CollisionShape2D")
	if collision is CollisionShape2D and collision.shape == null:
		var shape := CircleShape2D.new()
		shape.radius = 24.0
		collision.shape = shape

func _on_interact() -> void:
	if one_time_only and has_been_used:
		return
	
	has_been_used = true
	#GameManager.start_battle(npc_id: String)
