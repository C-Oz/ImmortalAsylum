extends CharacterBody2D

@export var speed: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_tile_pos: Vector2i = Vector2i(-9999, -9999)
var grass_layer: Node = null

var active_stepped_tile: Vector2i = Vector2i(-9999, -9999)
var original_tile_layer: int = 0
var original_tile_source_id: int = -1
var original_tile_atlas_coords: Vector2i = Vector2i(-1, -1)
var original_tile_alt: int = 0

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
	
	_check_doormat_chords()

func _check_doormat_chords() -> void:
	if grass_layer == null:
		var root = get_tree().current_scene
		if root:
			grass_layer = root.find_child("Grass Layer", true, false)
		if grass_layer == null and get_parent():
			grass_layer = get_parent().get_node_or_null("Grass Layer")
			
	if grass_layer != null and GameManager.current_chord_zone != "":
		if grass_layer.has_method("local_to_map"):
			var local_pos = grass_layer.to_local(global_position)
			var current_tile_pos = grass_layer.local_to_map(local_pos)
			
			if current_tile_pos != last_tile_pos:
				last_tile_pos = current_tile_pos
				
				if active_stepped_tile != Vector2i(-9999, -9999):
					if grass_layer.get_class() == "TileMapLayer":
						grass_layer.set_cell(active_stepped_tile, original_tile_source_id, original_tile_atlas_coords, original_tile_alt)
					elif grass_layer.has_method("set_cell"):
						grass_layer.set_cell(original_tile_layer, active_stepped_tile, original_tile_source_id, original_tile_atlas_coords, original_tile_alt)
					active_stepped_tile = Vector2i(-9999, -9999)
				
				var tile_data = null
				var found_layer = -1
				
				if grass_layer.get_class() == "TileMapLayer":
					tile_data = grass_layer.get_cell_tile_data(current_tile_pos)
				elif grass_layer.has_method("get_layers_count"): # Fallback for legacy TileMap
					for layer in range(grass_layer.get_layers_count()):
						var td = grass_layer.get_cell_tile_data(layer, current_tile_pos)
						if td != null and td.get_custom_data("steppable") == true:
							tile_data = td
							found_layer = layer
							break
				
				if tile_data != null and tile_data.get_custom_data("steppable") == true:
					AudioManager.play_doormat_chord(GameManager.current_chord_zone)
					
					if grass_layer.get_class() == "TileMapLayer":
						original_tile_source_id = grass_layer.get_cell_source_id(current_tile_pos)
						original_tile_atlas_coords = grass_layer.get_cell_atlas_coords(current_tile_pos)
						original_tile_alt = grass_layer.get_cell_alternative_tile(current_tile_pos)
						grass_layer.set_cell(current_tile_pos, original_tile_source_id, Vector2i(5, 0), original_tile_alt)
						active_stepped_tile = current_tile_pos
					elif grass_layer.has_method("set_cell") and found_layer != -1:
						original_tile_layer = found_layer
						original_tile_source_id = grass_layer.get_cell_source_id(found_layer, current_tile_pos)
						original_tile_atlas_coords = grass_layer.get_cell_atlas_coords(found_layer, current_tile_pos)
						original_tile_alt = grass_layer.get_cell_alternative_tile(found_layer, current_tile_pos)
						grass_layer.set_cell(found_layer, current_tile_pos, original_tile_source_id, Vector2i(5, 0), original_tile_alt)
						active_stepped_tile = current_tile_pos
