extends "res://scenes/overworld/overworld.gd"

@export var world_width: float = 1280.0
@export var world_height: float = 720.0

@onready var world_content = $WorldContent
@onready var player = $Player

@onready var parallax_layers: Array = [%Parallax2D, %Parallax2D2, %Parallax2D3]

func _ready():
	# Automatically set repeat_size for parallax layers based on their textures
	# This prevents 'gaps' from appearing when the world wraps or autoscrolls
	for layer in parallax_layers:
		if is_instance_valid(layer) and layer is Parallax2D:
			for child in layer.get_children():
				if child is Sprite2D and child.texture:
					# Set repeat_size to texture size (accounting for sprite scale)
					layer.repeat_size = child.texture.get_size() * child.scale
					break

	# Tile the world in a 3x3 grid around the origin
	# IMPORTANT: WorldContent must be a Node2D in the scene for this to work!
	var offsets = [
		Vector2(-world_width, -world_height), Vector2(0, -world_height), Vector2(world_width, -world_height),
		Vector2(-world_width,  0),                                      Vector2(world_width,  0),
		Vector2(-world_width,  world_height), Vector2(0,  world_height), Vector2(world_width,  world_height),
	]

	if not world_content is Node2D:
		push_error("SpaceArea: WorldContent must be a Node2D to support tiling. Change the type in the editor.")
		return

	for offset in offsets:
		var copy = world_content.duplicate()
		copy.position = offset
		add_child(copy)

func _process(_delta):
	if is_instance_valid(player):
		var old_pos = player.global_position

		# Wrap player position within the bounds of the central tile
		# We do this in _process to sync perfectly with Camera2D smoothing and Parallax2D rendering
		player.global_position.x = fposmod(player.global_position.x, world_width)
		player.global_position.y = fposmod(player.global_position.y, world_height)

		var wrap_vector = player.global_position - old_pos

		# Detect wrap (significant jump)
		if wrap_vector.length() > min(world_width,world_height) * 0.5:
			# 1. Reset Camera Smoothing to prevent the 'snap' motion
			var camera = player.get_node_or_null("Camera2D")
			if camera and camera.has_method("reset_smoothing"):
				camera.reset_smoothing()

			# 2. Compensate Parallax Layers to prevent background jitter
			for layer in parallax_layers:
				if is_instance_valid(layer) and layer is Parallax2D:
					layer.scroll_offset += wrap_vector * layer.scroll_scale
