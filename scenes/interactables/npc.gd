extends StaticBody2D

@export var npc_id: String = "npc_1"
@export var npc_portrait: Texture2D
@export var dialogue_map: Dictionary[String, DialogueSequence] = {}
@export var state_overrides: Array[ConditionalStateOverride] = []

@onready var interaction_zone: Area2D = $InteractionZone
@onready var interaction_prompt: Sprite2D = $InteractionPrompt

var player_in_range: bool = false

func _ready() -> void:
	interaction_prompt.visible = false
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)

func _process(_delta: float) -> void:
	interaction_prompt.visible = player_in_range

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if not DialogueBox.is_active():
			_start_interaction()

func _start_interaction() -> void:
	var current_state = GameManager.get_npc_state(npc_id)
	
	# Evaluate dynamic overrides
	for override in state_overrides:
		if override == null: continue
		
		# Skip override if the NPC is not in the required base state
		if override.required_base_state != "" and override.required_base_state != current_state:
			continue
			
		if GameManager.active_skills.get(override.required_skill_slot) == override.required_skill_name:
			current_state = override.override_state
			break
	
	if dialogue_map.has(current_state):
		DialogueBox.start_sequence(dialogue_map[current_state], npc_id, npc_portrait)
	elif dialogue_map.has("default"):
		DialogueBox.start_sequence(dialogue_map["default"], npc_id, npc_portrait)


func _on_dialogue_finished(next_state_id: String) -> void:
	# Only update state if this was the NPC the player was talking to
	if next_state_id != "" and player_in_range:
		GameManager.set_npc_state(npc_id, next_state_id)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		DialogueBox.hide_dialogue()
