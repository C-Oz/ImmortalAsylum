extends CanvasLayer

@onready var solo_pitches = $SoloPitches
@onready var solo_instrument = $SoloPitches/SoloInstrument
@onready var skill_up = $DPadSkillWheel/SkillUp
@onready var skill_down = $DPadSkillWheel/SkillDown
@onready var skill_left = $DPadSkillWheel/SkillLeft
@onready var skill_right = $DPadSkillWheel/SkillRight

@onready var timer_label = $TimerLabel

var control_timer: Timer

var _sfx_player: AudioStreamPlayer

# Maps dpad actions to their corresponding skill slots
var _dpad_slots: Dictionary

func _ready():
	# Attempt to find ControlTimer globally or locally, allowing any map node root
	if get_tree().current_scene:
		control_timer = get_tree().current_scene.get_node_or_null("ControlTimer")
	if not control_timer:
		# Fallback if OverworldUI is a sibling
		control_timer = get_node_or_null("../ControlTimer")
		
	if control_timer:
		_sfx_player = control_timer.get_node_or_null("PlayerChangeFx")
		# Connect timeout signal safely
		if not control_timer.timeout.is_connected(_on_control_timer_timeout):
			control_timer.timeout.connect(_on_control_timer_timeout)

	_dpad_slots = {
		"dpad_up": skill_up,
		"dpad_down": skill_down,
		"dpad_left": skill_left,
		"dpad_right": skill_right,
	}

	# Initialize the pip options
	var initial_labels: Array[String] = ["Off ", "Solo", "Box1", "Box2", "Box3", "Box4"]
	for slot in _dpad_slots.values():
		if is_instance_valid(slot):
			slot.option_names = initial_labels
			slot.total_options = initial_labels.size()
			# Children _ready happens before parent _ready, so we rebuild the dynamic pips here
			if slot.has_method("_setup_pips"):
				slot._setup_pips()
				slot._update_pips()

func _unhandled_input(event: InputEvent):
	for action in _dpad_slots:
		if event.is_action_pressed(action):
			var slot = _dpad_slots[action]
			if is_instance_valid(slot):
				# Toggle to the next pip / label option safely wrapping around at the max
				slot.current_option_index = (slot.current_option_index + 1) % slot.total_options

func _process(delta):
	if is_instance_valid(control_timer):
		timer_label.text = str("%.1f" % control_timer.time_left)

func _on_control_timer_timeout():
	if not GameManager.cycling_unlocked:
		return
	
	if is_instance_valid(_sfx_player):
		_sfx_player.play()
