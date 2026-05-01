extends CanvasLayer

@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var dialogue_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DialogueLabel
@onready var continue_icon: Sprite2D = $Panel/ContinueIcon
@onready var portrait_left: TextureRect = $Panel/PlayerPortrait
@onready var portrait_right: TextureRect = $Panel/NPCPortrait

var current_sequence: DialogueSequence
var current_line_index: int = 0
var is_displaying: bool = false

# Temporary storage for the current conversation's NPC data
var active_npc_name: String = ""
var active_npc_portrait: Texture2D

signal dialogue_started
signal dialogue_finished(next_state_id: String)

func _ready() -> void:
	hide_dialogue()

func _input(event: InputEvent) -> void:
	if not is_displaying:
		return
		
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		advance_dialogue()

func start_sequence(sequence: DialogueSequence, npc_name: String = "???", npc_portrait: Texture2D = null) -> void:
	if not sequence or sequence.get_parsed_lines().is_empty():
		return
		
	current_sequence = sequence
	active_npc_name = npc_name
	active_npc_portrait = npc_portrait
	
	current_line_index = 0
	is_displaying = true
	visible = true
	dialogue_started.emit()
	_display_current_line()

func advance_dialogue() -> void:
	current_line_index += 1
	if current_line_index < current_sequence.get_parsed_lines().size():
		_display_current_line()
	else:
		var next_state_id = current_sequence.next_state
		var reward_id = current_sequence.reward_id
		hide_dialogue()
		dialogue_finished.emit(next_state_id)
		
		if reward_id != "":
			GameManager.grant_reward(reward_id)

func _display_current_line() -> void:
	var line: DialogueSequence.ParsedLine = current_sequence.get_parsed_lines()[current_line_index]
	
	dialogue_label.text = line.text
	
	# Handle Name and Portrait Logic
	if line.speaker.to_upper() == "PLAYER":
		# Name: Override > Global Default
		name_label.text = line.display_name_override if line.display_name_override != "" else GameManager.player_name
		
		# Portrait: Override > Global Default
		var p = null
		if line.portrait_override_key != "" and current_sequence.portrait_overrides.has(line.portrait_override_key):
			p = current_sequence.portrait_overrides[line.portrait_override_key]
		if not p:
			p = GameManager.player_portrait
			
		if p:
			portrait_left.texture = p
			portrait_left.show()
		else:
			portrait_left.hide()
		portrait_right.hide()
		
	else: # NPC
		# Name: Override > Active NPC Name
		name_label.text = line.display_name_override if line.display_name_override != "" else active_npc_name
		
		# Portrait: Override > Active NPC Default
		var p = null
		if line.portrait_override_key != "" and current_sequence.portrait_overrides.has(line.portrait_override_key):
			p = current_sequence.portrait_overrides[line.portrait_override_key]
		if not p:
			p = active_npc_portrait
			
		if p:
			portrait_right.texture = p
			portrait_right.show()
		else:
			portrait_right.hide()
		portrait_left.hide()
	
	continue_icon.visible = true

func hide_dialogue() -> void:
	visible = false
	is_displaying = false
	current_sequence = null
	current_line_index = 0
	active_npc_name = ""
	active_npc_portrait = null

func is_active() -> bool:
	return is_displaying
