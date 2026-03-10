extends CanvasLayer

@onready var solo_instrument = $SoloPitches/SoloInstrument
@onready var skill_up = $DPadSkillWheel/SkillUp
@onready var skill_down = $DPadSkillWheel/SkillDown

@onready var timer_label = $TimerLabel
@onready var control_timer = get_node("/root/Overworld/ControlTimer")

var tex_piano = preload("res://assets/art/instruments/piano_big.png")
var tex_clarinet = preload("res://assets/art/instruments/clarinet_big.png")
var tex_cello = preload("res://assets/art/instruments/cello_big.png")

# State machine for the switching instruments
var cycle_state: int = 0  

func _process(delta):
	if is_instance_valid(control_timer):
		timer_label.text = str("%.1f" % control_timer.time_left)

func _on_control_timer_timeout():
	# States 1,2,3
	cycle_state = (cycle_state + 1) % 3
	
	match cycle_state:
		0:
			# Starting Position
			solo_instrument.texture = tex_piano
			skill_up.skill_icon = tex_cello
			skill_down.skill_icon = tex_clarinet
			
		1:
			solo_instrument.texture = tex_cello
			skill_up.skill_icon = tex_piano
			skill_down.skill_icon = tex_clarinet
			
		2:
			solo_instrument.texture = tex_clarinet
			skill_up.skill_icon = tex_cello
			skill_down.skill_icon = tex_piano
