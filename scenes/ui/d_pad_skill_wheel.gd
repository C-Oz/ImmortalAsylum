extends Control

@onready var skill_up = $SkillUp
@onready var skill_down = $SkillDown
@onready var skill_left = $SkillLeft
@onready var skill_right = $SkillRight

func _ready():
	update_visuals()

func update_visuals():
	skill_up.visible = GameManager.unlocked_skills["up"]
	skill_down.visible = GameManager.unlocked_skills["down"]
	skill_left.visible = GameManager.unlocked_skills["left"]
	skill_right.visible = GameManager.unlocked_skills["right"]

func unlock_skill(direction: String):
	match direction:
		"up": skill_up.visible = true
		"down": skill_down.visible = true
		"left": skill_left.visible = true
		"right": skill_right.visible = true
