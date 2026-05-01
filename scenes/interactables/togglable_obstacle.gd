extends "res://scripts/interactables/obstacle.gd"

@onready var created_layer: Node2D = $CreatedLayer
@onready var destroyed_layer: Node2D = $DestroyedLayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var timer_value: float = 10.0 # seconds added/subtracted from timer
@export var state_trigger_npc_id: String = "" # NPC ID to update when built
@export var npc_state_built: String = "" # State to set when built (e.g. "active")
@export var npc_state_destroyed: String = "" # State to set when destroyed (e.g. "default")

# Infer the initial logical state from the editor's visibility setting
@onready var is_built: bool = created_layer.visible


func _ready() -> void:
	var saved_built = GameManager.get_object_state(self)
	if saved_built is bool:
		is_built = saved_built
	
	_apply_state_visuals()
	
	# We must call super._ready() but since we extend "res://scripts/interactables/obstacle.gd"
	# and it's a script-based inheritance, we use super()
	super()

func _apply_state_visuals() -> void:
	# Swap tilemap visibilities
	created_layer.visible = is_built
	destroyed_layer.visible = !is_built

func _on_sequence_completed() -> void:
	# Toggle the state
	is_built = !is_built
	
	# Save the new state
	GameManager.save_object_state(self, is_built)
	
	_apply_state_visuals()
	
	# Adjust the global ControlTimer
	var adjustment = -timer_value if is_built else timer_value
	_adjust_control_timer(adjustment)
	
	# Trigger NPC state change if configured
	if state_trigger_npc_id != "":
		var target_state = npc_state_built if is_built else npc_state_destroyed
		if target_state != "":
			GameManager.set_npc_state(state_trigger_npc_id, target_state)

func _adjust_control_timer(delta: float) -> void:
	# Directly tell the manager to change the time
	GameManager.adjust_timer(delta)
	
	# Show visual feedback on UI if it exists
	var ui_feedback = get_tree().current_scene.get_node_or_null("OverworldUI")
	if ui_feedback and ui_feedback.has_method("show_timer_adjustment"):
		ui_feedback.show_timer_adjustment(delta)
		
