extends Control

@onready var background_color = $BackgroundColor

@export var activate_sfx: AudioStreamPlayer
@export var deactivate_sfx: AudioStreamPlayer


@export var skill_icon: Texture2D:
	set(value):
		skill_icon = value
		if is_node_ready() and icon:
			icon.texture = skill_icon
@export var max_charge: float = 100.0
@export var drain_rate: float = 1.0

@onready var icon = $Icon
@onready var charge_bar = $ChargeBar

const COLOR_RED := Color(1.0, 0.2, 0.2, 0.6)

var current_charge: float = 100.0
var _style: StyleBoxFlat
var _color_blue: Color
var _is_red: bool = false
var _color_timer: float = 0.0

func _ready():
	if icon:
		icon.texture = skill_icon
		# Inset the icon so the colored panel border is always visible
		icon.offset_left = -20
		icon.offset_right = 20
		icon.offset_top = 4
		icon.offset_bottom = 44
	if charge_bar:
		charge_bar.max_value = max_charge
		charge_bar.value = current_charge
	# Duplicate the editor-set StyleBoxFlat so each slot has its own copy
	var base_style = background_color.get_theme_stylebox("panel") as StyleBoxFlat
	_style = base_style.duplicate()
	_color_blue = _style.bg_color
	background_color.add_theme_stylebox_override("panel", _style)

func activate_color(duration: float = 1.0):
	_is_red = true
	_style.bg_color = COLOR_RED
	_color_timer = duration
	if activate_sfx:
		activate_sfx.play()

func _process(delta):
	if _color_timer > 0:
		_color_timer -= delta
		if _color_timer <= 0:
			_is_red = false
			_style.bg_color = _color_blue
			if deactivate_sfx:
				deactivate_sfx.play()
			
	if current_charge > 0:
		current_charge -= drain_rate * delta
		current_charge = max(0, current_charge)
		charge_bar.value = current_charge

func refill_charge(amount: float):
	current_charge = min(current_charge + amount, max_charge)
	charge_bar.value = current_charge
