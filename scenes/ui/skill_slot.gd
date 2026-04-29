extends Control

@export var sounds_folder: String
var _toggle_sfx: Array[AudioStream] = []
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer


@export var skill_icon: Texture2D:
	set(value):
		skill_icon = value
		if is_node_ready() and icon:
			icon.texture = skill_icon

@export var max_charge: float = 100.0
@export var drain_rate: float = 1.0

# Pip Configuration
@export var total_options: int = 6
@export var option_names: Array[String] = []
@export var current_option_index: int = 0:
	set(value):
		current_option_index = clamp(value, 0, total_options - 1)
		if is_node_ready():
			_update_pips()
			_play_toggle_sound()


# find_child for restructure-proof locating nodes
@onready var icon = %Icon
@onready var charge_bar = find_child("ChargeBar", true, false) as TextureProgressBar
@onready var grid_container = find_child("GridContainer", true, false) as GridContainer
@onready var title_label = find_child("Label", true, false) as Label

const PIP_OPEN = preload("res://assets/art/ui/empty_bubble.tres")
const PIP_FULL = preload("res://assets/art/ui/full_bubble.tres")

var current_charge: float = max_charge
var _pips: Array[TextureRect] = []

func _ready():
	if icon:
		icon.texture = skill_icon
	if charge_bar:
		charge_bar.max_value = max_charge
		charge_bar.value = current_charge
	
	_setup_pips()
	_update_pips()
	_load_sfx()

func _load_sfx():
	if sounds_folder == "": return
	_toggle_sfx.clear()
	for i in range(1, 7):
		var path = "res://assets/sfx/%s/%s %d.wav" % [sounds_folder, sounds_folder, i]
		if ResourceLoader.exists(path):
			_toggle_sfx.append(load(path))
		else:
			_toggle_sfx.append(null)

func _play_toggle_sound():
	if audio_player and current_option_index < _toggle_sfx.size():
		var stream = _toggle_sfx[current_option_index]
		if stream:
			audio_player.stream = stream
			audio_player.play()


func _setup_pips():
	if not grid_container: return
	
	# Clear out any existing placeholder pips
	for child in grid_container.get_children():
		child.queue_free()
	_pips.clear()
	
	# Instantiate our dynamic pips
	for i in range(total_options):
		var pip = TextureRect.new()
		pip.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		grid_container.add_child(pip)
		_pips.append(pip)

func _update_pips():
	for i in range(_pips.size()):
		if i == current_option_index:
			_pips[i].texture = PIP_FULL
		else:
			_pips[i].texture = PIP_OPEN
	
	if title_label:
		if current_option_index < option_names.size():
			title_label.text = option_names[current_option_index]
		else:
			title_label.text = "Option " + str(current_option_index + 1)

func _process(delta):
	if current_charge > 0:
		current_charge -= drain_rate * delta
		current_charge = max(0, current_charge)
		if charge_bar:
			charge_bar.value = current_charge

func refill_charge(amount: float):
	current_charge = min(current_charge + amount, max_charge)
	if charge_bar:
		charge_bar.value = current_charge
