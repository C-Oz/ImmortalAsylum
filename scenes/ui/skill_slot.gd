extends Control

@export var skill_icon: Texture2D

@export var max_charge: float = 100.0
@export var drain_rate: float = 1.0

@onready var icon = $Icon
@onready var charge_bar = $ChargeBar

var current_charge: float = 100.0

func _ready():
	if icon:
		icon.texture = skill_icon
	if charge_bar:
		charge_bar.max_value = max_charge
		charge_bar.value = current_charge

func _process(delta):
	if current_charge > 0:
		current_charge -= drain_rate * delta
		current_charge = max(0, current_charge)
		charge_bar.value = current_charge

func refill_charge(amount: float):
	current_charge = min(current_charge + amount, max_charge)
	charge_bar.value = current_charge
