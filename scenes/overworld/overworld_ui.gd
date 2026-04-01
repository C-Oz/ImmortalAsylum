extends CanvasLayer

@onready var solo_pitches = $SoloPitches
@onready var solo_instrument = $SoloPitches/SoloInstrument
@onready var skill_up = $DPadSkillWheel/SkillUp
@onready var skill_down = $DPadSkillWheel/SkillDown
@onready var skill_left = $DPadSkillWheel/SkillLeft
@onready var skill_right = $DPadSkillWheel/SkillRight

@onready var timer_label = $TimerLabel
@onready var control_timer = get_node("/root/Overworld/ControlTimer")

var tex_piano = preload("res://assets/art/instruments/piano_big.png")
var tex_clarinet = preload("res://assets/art/instruments/clarinet_big.png")
var tex_cello = preload("res://assets/art/instruments/cello_big.png")
var tex_drums = preload("res://assets/art/instruments/drums_big.png")

@onready var _sfx_player: AudioStreamPlayer = get_node("/root/Overworld/ControlTimer/PlayerChangeFx")

# State machine for the switching instruments
var cycle_state: int = 0

# Maps dpad actions to their corresponding skill slots
var _dpad_slots: Dictionary

func _ready():
	_dpad_slots = {
		"dpad_up": skill_up,
		"dpad_down": skill_down,
		"dpad_left": skill_left,
		"dpad_right": skill_right,
	}
	
	_apply_progression_state()

func _apply_progression_state():
	# Solo pitches: hidden and disabled until unlocked
	solo_pitches.visible = GameManager.solo_pitches_unlocked
	solo_pitches.set_process(GameManager.solo_pitches_unlocked)
	solo_pitches.set_process_input(GameManager.solo_pitches_unlocked)
	
	# Cycling: timer always runs (label visible), but the timeout callback
	# is guarded — instrument switching only happens when unlocked.

func _unhandled_input(event: InputEvent):
	for action in _dpad_slots:
		if event.is_action_pressed(action):
			_dpad_slots[action].activate_color(5.0) # ****** INLINE CONFIG ********

func _process(delta):
	if is_instance_valid(control_timer):
		timer_label.text = str("%.1f" % control_timer.time_left)

func _on_control_timer_timeout():
	if not GameManager.cycling_unlocked:
		return
	
	_sfx_player.play()
	
	# States 0,1,2
	cycle_state = (cycle_state + 1) % 3
	
	match cycle_state:
		0:
			# Starting Position
			solo_instrument.texture = tex_piano
			skill_up.skill_icon = tex_cello
			skill_down.skill_icon = tex_clarinet
			skill_left.skill_icon = tex_drums
			
		1:
			solo_instrument.texture = tex_cello
			skill_up.skill_icon = tex_piano
			skill_down.skill_icon = tex_clarinet
			skill_left.skill_icon = tex_drums
			
		2:
			solo_instrument.texture = tex_clarinet
			skill_up.skill_icon = tex_cello
			skill_down.skill_icon = tex_piano
			skill_left.skill_icon = tex_drums
