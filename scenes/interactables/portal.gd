extends AnimatedSprite2D

@export_file("*.tscn") var destination_scene_path: String = ""
@export var destination_portal_name: StringName = &"Portal"
@export var fallback_exit_offset: Vector2 = Vector2(0, 64)

@onready var interaction_area := get_node_or_null("InteractionArea") as Area2D
@onready var interaction_prompt := get_node_or_null("InteractionPrompt") as CanvasItem

var player_in_range := false
var transition_started := false

func _ready() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false

	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	else:
		push_warning("%s is missing InteractionArea." % name)

	if sprite_frames:
		play()

func _unhandled_input(event: InputEvent) -> void:
	if transition_started or not player_in_range:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_travel()

func get_arrival_position() -> Vector2:
	var exit_point := get_node_or_null("ExitPoint")
	if exit_point is Node2D:
		return exit_point.global_position

	return to_global(fallback_exit_offset)

func _travel() -> void:
	if destination_scene_path.is_empty():
		push_warning("%s has no destination_scene_path set." % name)
		return

	transition_started = true

	if interaction_prompt:
		interaction_prompt.visible = false

	# 1. Find player and lock them
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("flash_and_hide"):
		await player.flash_and_hide()

	# 2. Trigger the curtain wipe and scene change via the persistent Autoload
	if SceneTransition:
		SceneTransition.transition_to_scene(destination_scene_path, destination_portal_name)
	else:
		GameManager.travel_through_portal(destination_scene_path, destination_portal_name)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if interaction_prompt:
			interaction_prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if interaction_prompt:
			interaction_prompt.visible = false
