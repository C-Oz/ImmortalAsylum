# SubmergeSect - destructible with rhythm minigame + cinematic destruction sequence
extends StaticBody2D

@export var sequence: Array[String] = ["Y", "B", "A"]

# --- Tunable destruction parameters ---
@export_group("Destruction Sequence")
@export var shake_intensity: float = 3.0
@export var translucent_alpha: float = 0.7
@export var translucent_duration: float = 02.0
@export var flash_duration: float = 0.5
@export var row_delay: float = 0.1

@onready var ui = $DestructionUI
@onready var interaction_zone: Area2D = $InteractionZone
@onready var water_carpet: TileMapLayer = $WaterCarpet
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var collider: CollisionShape2D = $Collider

var player_in_range: bool = false
var destroying: bool = false
var _shake_tween: Tween
var _shake_camera: Camera2D
var _shake_original_offset: Vector2

func _ready() -> void:
	# Pass sequence to UI
	ui.sequence = sequence
	ui.setup_sequence()
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	ui.sequence_completed.connect(_on_sequence_completed)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not destroying:
		print("Player detected, starting sequence")
		ui.start_sequence()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and not destroying:
		ui.stop_sequence()

func on_beat():
	if destroying:
		return
	ui.on_beat()

func _input(event):
	if destroying:
		return
	
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
	destroying = true
	
	# Step 1: Remove the DestructionUI
	ui.queue_free()
	
	# Step 2: Start screen shake (runs throughout all steps)
	_start_shake()
	
	# Step 3: Fade WaterCarpet to translucent
	await _fade_water_carpet()
	
	# Step 4: Brief white flash
	await _white_flash()
	
	# Step 5: Row-by-row tile destruction with particles
	await _destroy_rows()
	
	# Step 6: Stop shake and cleanup
	_stop_shake()
	collider.set_deferred("disabled", true)
	queue_free()

func _start_shake():
	_shake_camera = _get_camera()
	if not _shake_camera:
		return
	
	_shake_original_offset = _shake_camera.offset
	_shake_tween = create_tween()
	_shake_tween.set_loops()  # Loop indefinitely
	
	for i in 10:
		var random_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		_shake_tween.tween_property(_shake_camera, "offset", _shake_original_offset + random_offset, 0.05)

func _stop_shake():
	if _shake_tween:
		_shake_tween.kill()
		_shake_tween = null
	if _shake_camera:
		_shake_camera.offset = _shake_original_offset
		_shake_camera = null

func _fade_water_carpet():
	var fade_tween = create_tween()
	fade_tween.tween_property(water_carpet, "modulate:a", translucent_alpha, translucent_duration)
	await fade_tween.finished


func _white_flash():
	# Create a CanvasLayer + ColorRect dynamically
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	var flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.anchors_preset = Control.PRESET_FULL_RECT
	# Cover the full viewport
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(flash_rect)
	
	var half_duration = flash_duration / 2.0
	var flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "color:a", 0.8, half_duration)
	flash_tween.tween_property(flash_rect, "color:a", 0.0, half_duration)
	await flash_tween.finished
	
	canvas_layer.queue_free()


func _destroy_rows():
	var cells = water_carpet.get_used_cells()
	if cells.is_empty():
		return
	
	# Group cells by Y coordinate (row)
	var rows: Dictionary = {}
	for cell in cells:
		var y = cell.y
		if not rows.has(y):
			rows[y] = []
		rows[y].append(cell)
	
	# Sort row keys top-to-bottom (smallest Y first)
	var sorted_y = rows.keys()
	sorted_y.sort()
	
	# Get the tile size for positioning particles in world space
	var tile_size = water_carpet.tile_set.tile_size if water_carpet.tile_set else Vector2i(16, 16)
	
	# Allow particles to re-emit by disabling one_shot temporarily
	particles.one_shot = false
	
	# Get the process material so we can set emission shape per row
	var proc_mat = particles.process_material as ParticleProcessMaterial
	
	for y in sorted_y:
		var row_cells = rows[y]
		
		# Calculate the center X of this row in local coords
		var min_x = row_cells[0].x
		var max_x = row_cells[0].x
		for cell in row_cells:
			min_x = min(min_x, cell.x)
			max_x = max(max_x, cell.x)
		
		var row_width_px = (max_x - min_x + 1) * tile_size.x
		var center_x = (min_x + max_x) / 2.0 * tile_size.x + tile_size.x / 2.0
		var center_y = y * tile_size.y + tile_size.y / 2.0
		
		# Spread particles across the row width using a box emission shape
		if proc_mat:
			proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			proc_mat.emission_box_extents = Vector3(row_width_px / 2.0, 2.0, 0.0)
		
		# Position particles at this row (local to SubmergeSect, same as WaterCarpet)
		particles.position = water_carpet.position + Vector2(center_x, center_y)
		particles.emitting = true
		
		# Erase all cells in this row
		for cell in row_cells:
			water_carpet.erase_cell(cell)
		
		# Wait before next row
		await get_tree().create_timer(row_delay).timeout
	
	# Restore one_shot
	particles.one_shot = true
	particles.emitting = false


# --- Helpers ---
func _get_camera() -> Camera2D:
	# Find the player's Camera2D in the scene tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			return camera
	return null
