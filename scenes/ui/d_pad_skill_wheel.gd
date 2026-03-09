extends Control

@onready var skill_up = $SkillUp
@onready var skill_down = $SkillDown
@onready var skill_left = $SkillLeft
@onready var skill_right = $SkillRight

func _ready():
	skill_up.visible = true
	skill_down.visible = true
	skill_left.visible = false
	skill_right.visible = false

func unlock_skill(direction: String):
	match direction:
		"up": skill_up.visible = true
		"down": skill_down.visible = true
		"left": skill_left.visible = true
		"right": skill_right.visible = true
