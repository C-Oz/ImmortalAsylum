@tool
extends Polygon2D

@export var sequence: Array[String] = ["Y", "B", "A"]
@export var instrument_icon: Texture2D:
	set(value):
		instrument_icon = value
		if is_node_ready() and ui:
			ui.instrument_icon = value
@export var flash_duration: float = 0.5

# We now look for the physics nodes as children
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var collision_polygon: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D
@onready var interaction_zone: Area2D = $InteractionZone
@onready var ui = $DestructionUI

var clearing: bool = false

func _ready() -> void:
	if not is_in_group("destructibles"):
		add_to_group("destructibles")
	
	_sync_physics()

	if Engine.is_editor_hint():
		return
		
	var state = GameManager.get_object_state(self)
	if state is String and state == "cleared":
		queue_free()
		return
		
	ui.sequence = sequence
	ui.instrument_icon = instrument_icon
	ui.setup_sequence()
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	ui.sequence_completed.connect(_on_sequence_completed)

func _process(_delta: float) -> void:
	# In the editor, constantly sync the collision to whatever you draw
	if Engine.is_editor_hint():
		_sync_physics()

func _sync_physics() -> void:
	var cp2d = get_node_or_null("StaticBody2D/CollisionPolygon2D")
	if cp2d:
		# Only update if the points are actually different to save performance
		if cp2d.polygon != self.polygon:
			cp2d.polygon = self.polygon

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not clearing:
		ui.start_sequence()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and not clearing:
		ui.stop_sequence()

func on_beat():
	if clearing: return
	ui.on_beat()

func _input(event):
	if clearing or Engine.is_editor_hint(): return
	var button = null
	if event.is_action_pressed("joy_y", false): button = "Y"
	elif event.is_action_pressed("joy_b", false): button = "B"
	elif event.is_action_pressed("joy_a", false): button = "A"
	if button: ui.check_input(button)

func _on_sequence_completed():
	clearing = true
	GameManager.save_object_state(self, "cleared")
	ui.hide()
	await _white_flash()
	queue_free()

func _white_flash():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	var flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(flash_rect)
	var half_duration = flash_duration / 2.0
	var flash_tween = create_tween()
	flash_tween.tween_property(flash_rect, "color:a", 0.8, half_duration)
	flash_tween.set_trans(Tween.TRANS_SINE)
	flash_tween.tween_property(flash_rect, "color:a", 0.0, half_duration)
	await flash_tween.finished
	canvas_layer.queue_free()
