extends "res://scripts/interactables/obstacle.gd"

@onready var created_layer: Node2D = $CreatedLayer
@onready var destroyed_layer: Node2D = $DestroyedLayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Infer the initial logical state from the editor's visibility setting
@onready var is_built: bool = created_layer.visible

func _on_sequence_completed() -> void:
	# Toggle the state
	is_built = !is_built
	
	# Swap tilemap visibilities
	created_layer.visible = is_built
	destroyed_layer.visible = !is_built
	
	# Toggle the collision shape so the player can walk through the destroyed version
	# (set_deferred is safer when changing physics state during gameplay)
	#if collision_shape:
		#collision_shape.set_deferred("disabled", !is_built)
