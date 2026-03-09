extends StaticBody2D

@export var npc_id: String = "boss_1"  # Unique ID for each boss
@export_multiline var pre_battle_dialogue: Array[String] = [
	"You dare challenge me?",
	"Prepare for battle!"
]
@export_multiline var post_battle_dialogue: Array[String] = [
	"You... defeated me...",
	"Take this as your reward."
]

@onready var interaction_zone: Area2D = $InteractionZone
@onready var interaction_prompt: Sprite2D = $InteractionPrompt

# State tracking
enum State { IDLE, PRE_BATTLE, BATTLING, POST_BATTLE, COMPLETED }
var current_state: State = State.IDLE
var player_in_range: bool = false
var current_dialogue_index: int = 0
var has_been_defeated: bool = false

func _ready() -> void:
	interaction_prompt.visible = false
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	
	# Check if returning from battle with this NPC
	if GameManager.returning_from_battle and GameManager.current_npc_id == npc_id:
		var result = GameManager.get_battle_result()
		if result.victory:
			has_been_defeated = true
			current_state = State.POST_BATTLE
			current_dialogue_index = 0
			_show_dialogue()
		GameManager.clear_battle_data()

func _process(_delta: float) -> void:
	if player_in_range and current_state == State.IDLE and not has_been_defeated:
		interaction_prompt.visible = true
	else:
		interaction_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_handle_interaction()

func _handle_interaction() -> void:
	match current_state:
		State.IDLE:
			if not has_been_defeated:
				current_state = State.PRE_BATTLE
				current_dialogue_index = 0
				_show_dialogue()
		
		State.PRE_BATTLE:
			_advance_dialogue(pre_battle_dialogue)
		
		State.POST_BATTLE:
			_advance_dialogue(post_battle_dialogue)

func _show_dialogue() -> void:
	var dialogue_text: String
	
	if current_state == State.PRE_BATTLE:
		dialogue_text = pre_battle_dialogue[current_dialogue_index]
	elif current_state == State.POST_BATTLE:
		dialogue_text = post_battle_dialogue[current_dialogue_index]
	
	DialogueBox.show_dialogue(npc_id, dialogue_text)

func _advance_dialogue(dialogue_array: Array[String]) -> void:
	current_dialogue_index += 1
	
	if current_dialogue_index < dialogue_array.size():
		_show_dialogue()
	else:
		_finish_dialogue_sequence()

func _finish_dialogue_sequence() -> void:
	DialogueBox.hide_dialogue()
	
	if current_state == State.PRE_BATTLE:
		current_state = State.BATTLING
		var player = get_tree().get_first_node_in_group("player")
		GameManager.start_battle(npc_id, player.global_position)
	elif current_state == State.POST_BATTLE:
		current_state = State.COMPLETED
		_play_completion_animation()

func _play_completion_animation() -> void:
	# TODO: Play your animation here
	print("Playing completion animation for: ", npc_id)
	# Example: $AnimationPlayer.play("completion")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
