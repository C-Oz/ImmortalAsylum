extends StaticBody2D

@export var npc_id: String = "npc_1"
@export_multiline var npc_dialogue: Array[String] = [
	"Herp",
	"Derp"
]

@onready var interaction_zone: Area2D = $InteractionZone
@onready var interaction_prompt: Sprite2D = $InteractionPrompt

# State tracking
var player_in_range: bool = false
var current_dialogue_index: int = 0

func _ready() -> void:
	interaction_prompt.visible = false
	
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_range:
		interaction_prompt.visible = true
	else:
		interaction_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if DialogueBox.is_active():
			_advance_dialogue()
		else:
			current_dialogue_index = 0
			_show_dialogue()


func _show_dialogue() -> void:
	if npc_dialogue.is_empty():
		return
	var dialogue_text: String = npc_dialogue[current_dialogue_index]
	DialogueBox.show_dialogue(npc_id, dialogue_text)

func _advance_dialogue() -> void:
	current_dialogue_index += 1
	
	if current_dialogue_index < npc_dialogue.size():
		_show_dialogue()
	else:
		_finish_dialogue_sequence()

func _finish_dialogue_sequence() -> void:
	DialogueBox.hide_dialogue()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		DialogueBox.hide_dialogue()
