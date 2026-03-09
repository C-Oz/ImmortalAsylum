extends Area2D
class_name Interactable

signal interacted

@export var interaction_prompt: String = "Press E to interact"

var player_nearby: bool = false
var _prompt_label: Label = null

func _ready() -> void:
	# Proximity is tracked by the player's interaction Area2D (see `player.gd`).
	# This avoids relying on `body_entered`, which won't fire when the player uses an Area2D.
	hide_prompt()

func set_player_nearby(is_nearby: bool) -> void:
	if player_nearby == is_nearby:
		return
	player_nearby = is_nearby
	if player_nearby:
		show_prompt()
	else:
		hide_prompt()

func interact() -> void:
	# Only allow interaction while the player is in range.
	if not player_nearby:
		return
	interacted.emit()
	_on_interact()

# Override this in child classes
func _on_interact() -> void:
	pass

func show_prompt() -> void:
	# If the scene already provides its own prompt node, prefer that.
	# Otherwise, create a simple in-world Label once.
	if _prompt_label == null:
		var existing = get_node_or_null("InteractionPrompt")
		if existing is Label:
			_prompt_label = existing
		else:
			_prompt_label = Label.new()
			_prompt_label.name = "InteractionPrompt"
			_prompt_label.text = interaction_prompt
			_prompt_label.z_index = 1000
			_prompt_label.position = Vector2(-60, -40)
			add_child(_prompt_label)

	_prompt_label.text = interaction_prompt
	_prompt_label.visible = true

func hide_prompt() -> void:
	if _prompt_label == null:
		var existing = get_node_or_null("InteractionPrompt")
		if existing is Label:
			_prompt_label = existing
		else:
			return
	_prompt_label.visible = false
