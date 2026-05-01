extends Node

var canvas: CanvasLayer
var rect: ColorRect

func _ready() -> void:
	canvas = CanvasLayer.new()
	canvas.layer = 128 # High layer to be above everything
	add_child(canvas)
	
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.anchor_right = 0 # Start hidden (width 0)
	canvas.add_child(rect)

func wipe_out(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(rect, "anchor_right", 1.0, duration)
	await tween.finished

func wipe_in(duration: float = 0.5) -> void:
	rect.anchor_left = 0
	rect.anchor_right = 1.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	# Move anchor_left to 1 to "open" the curtain from the left
	tween.tween_property(rect, "anchor_left", 1.0, duration)
	await tween.finished

func reset_wipe() -> void:
	rect.anchor_left = 0
	rect.anchor_right = 0

func transition_to_scene(scene_path: String, portal_name: StringName) -> void:
	await wipe_out(1.0)
	GameManager.travel_through_portal(scene_path, portal_name)
	# Wait for the new scene to fully load
	await get_tree().process_frame
	await wipe_in(0.6)
	reset_wipe()
