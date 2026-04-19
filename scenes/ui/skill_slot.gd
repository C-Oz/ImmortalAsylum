extends Control

@export var activate_sfx: AudioStreamPlayer
@export var deactivate_sfx: AudioStreamPlayer

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

# You can use find_child to reliably locate these nodes even if you restructure the scene slightly.
@onready var icon = find_child("Icon", true, false) as TextureRect
@onready var charge_bar = find_child("ChargeBar", true, false) as TextureProgressBar
@onready var grid_container = find_child("GridContainer", true, false) as GridContainer
@onready var title_label = find_child("Label", true, false) as Label

const PIP_OPEN = preload("res://assets/art/ui/pipopen16.png")
const PIP_FULL = preload("res://assets/art/ui/pipfull16.png")

var current_charge: float = 100.0
var _pips: Array[TextureRect] = []

func _ready():
	if icon:
		icon.texture = skill_icon
	if charge_bar:
		charge_bar.max_value = max_charge
		charge_bar.value = current_charge
	
	_setup_pips()
	_update_pips()

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
