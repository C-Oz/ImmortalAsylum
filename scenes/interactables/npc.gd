extends StaticBody2D

@export var npc_id: String = "npc_1"
@export var npc_map_sprite: Texture2D
@export var portrait_set: Resource # PortraitSet
@export var dialogue_map: Dictionary[String, DialogueSequence] = {}
@export var state_overrides: Array[ConditionalStateOverride] = []

@onready var interaction_zone: Area2D = $InteractionZone
@onready var interaction_prompt: Sprite2D = $InteractionPrompt
@onready var map_sprite: Sprite2D = $MapSprite

var player_in_range: bool = false

func _ready() -> void:
	interaction_prompt.visible = false
	if npc_map_sprite:
		map_sprite.texture = npc_map_sprite
	
	_setup_floating_animation()
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)

func _setup_floating_animation() -> void:
	var float_dist = 6.0
	var duration = 2.0 + randf_range(-0.3, 0.3)
	var base_y = map_sprite.position.y
	
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(map_sprite, "position:y", base_y - float_dist, duration)
	tween.tween_property(map_sprite, "position:y", base_y, duration)
	
	# Jump to a random point in the animation so NPCs aren't synchronized
	tween.custom_step(randf_range(0.0, duration * 2.0))

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
		DialogueBox.start_sequence(dialogue_map[current_state], npc_id, portrait_set)
	elif dialogue_map.has("default"):
		DialogueBox.start_sequence(dialogue_map["default"], npc_id, portrait_set)


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
