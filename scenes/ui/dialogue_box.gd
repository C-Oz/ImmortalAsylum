extends CanvasLayer

@onready var name_label: Label = $Panel/MarginContainer/VBoxContainer/NameLabel
@onready var dialogue_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DialogueLabel
@onready var continue_icon: Sprite2D = $Panel/ContinueIcon

var current_text: String = ""
var is_displaying: bool = false

signal dialogue_finished
signal advance_requested

func _ready() -> void:
	hide_dialogue()

func show_dialogue(npc_name: String, text: String) -> void:
	name_label.text = npc_name
	current_text = text
	dialogue_label.text = text
	is_displaying = true
	visible = true
	continue_icon.visible = true

func hide_dialogue() -> void:
	visible = false
	is_displaying = false
	current_text = ""

func is_active() -> bool:
	return is_displaying
