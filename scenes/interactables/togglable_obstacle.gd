extends "res://scripts/interactables/obstacle.gd"

@onready var created_layer: Node2D = $CreatedLayer
@onready var destroyed_layer: Node2D = $DestroyedLayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var timer_value: float = 10.0 # seconds added/subtracted from timer
@export var state_trigger_npc_id: String = "" # NPC ID to update when built
@export var trigger_alt_dialogue: bool = true # Whether to enable alt dialogue

# Infer the initial logical state from the editor's visibility setting
@onready var is_built: bool = created_layer.visible

func _on_sequence_completed() -> void:
	# Toggle the state
	is_built = !is_built
	
	# Swap tilemap visibilities
	created_layer.visible = is_built
	destroyed_layer.visible = !is_built
	
	# Adjust the global ControlTimer
	var adjustment = -timer_value if is_built else timer_value
	_adjust_control_timer(adjustment)
	
	# Trigger NPC state change if configured
	if is_built and state_trigger_npc_id != "":
		GameManager.set_npc_alt(state_trigger_npc_id, trigger_alt_dialogue)

func _adjust_control_timer(delta: float) -> void:
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
		
	var timer = scene_root.get_node_or_null("ControlTimer")
	if timer and timer is Timer:
		var current_time = timer.time_left
		# Calculate the new remaining time
		var new_time_left = max(0.1, current_time + delta)
		
		# Restart the timer with the new remaining time for immediate effect
		timer.start(new_time_left)
		
		# Show visual feedback on UI
		var ui = get_tree().current_scene.get_node_or_null("OverworldUI")
		if ui and ui.has_method("show_timer_adjustment"):
			ui.show_timer_adjustment(delta)
		
