extends CanvasLayer

@onready var solo_pitches = $SoloPitches
@onready var solo_instrument = $SoloPitches/SoloInstrument
@onready var skill_up = $DPadSkillWheel/SkillUp
@onready var skill_down = $DPadSkillWheel/SkillDown
@onready var skill_left = $DPadSkillWheel/SkillLeft
@onready var skill_right = $DPadSkillWheel/SkillRight

@onready var timer_label = $TimerLabel
@onready var timer_adjustment_label = $TimerAdjustmentLabel

var control_timer: Timer

var _sfx_player: AudioStreamPlayer

# Maps dpad actions to their corresponding skill slots
var _dpad_slots: Dictionary

func _ready():
	# Use the persistent timer from GameManager
	control_timer = GameManager.control_timer
	
	if control_timer:
		_sfx_player = GameManager.timer_sfx_player
		# The timeout signal is now handled in GameManager for the SFX, 
		# but if the UI needs to do something else, it can connect here too.
		# For now, the existing _on_control_timer_timeout logic in this script 
		# is just playing the sfx which GameManager already does.
		# If there are other UI-specific timeout needs, we can add them.
		pass

	_dpad_slots = {
		"dpad_up": skill_up,
		"dpad_down": skill_down,
		"dpad_left": skill_left,
		"dpad_right": skill_right,
	}

	_refresh_skill_slots()
	GameManager.progression_updated.connect(_refresh_skill_slots)
	GameManager.reward_granted.connect(_on_reward_granted)
	
	DialogueBox.dialogue_started.connect(_on_dialogue_started)
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)

func _on_reward_granted(reward_id: String) -> void:
	if reward_id == "haniran_box5":
		var reward_scene = load("res://scenes/ui/RewardUI.tscn")
		if reward_scene:
			var reward_inst = reward_scene.instantiate()
			reward_inst.setup("Haniran's Theme Acquired", load("res://assets/art/instruments/cello_big.png"))
			add_child(reward_inst)

func _refresh_skill_slots() -> void:
	# Base labels for all slots
	var base_labels: Array[String] = ["Box1", "Box2", "Box3", "Box4"]
	
	for action in _dpad_slots:
		var slot = _dpad_slots[action]
		if not is_instance_valid(slot): continue
		
		# Build specific labels for this slot
		var current_labels = base_labels.duplicate()
		
		# If this is the skill_up slot and haniran box 5 is unlocked
		if action == "dpad_up" and GameManager.unlocked_rewards.has("haniran_box5"):
			current_labels.append("Haniran")
			
		# Apply the labels to the slot
		slot.option_names = current_labels
		slot.total_options = current_labels.size()
		
		if slot.has_method("_setup_pips"):
			slot._setup_pips()
			slot._update_pips()
			
		# Sync the initial state to GameManager
		GameManager.set_active_skill(action, slot.option_names[slot.current_option_index])

func _unhandled_input(event: InputEvent):
	for action in _dpad_slots:
		if event.is_action_pressed(action):
			var slot = _dpad_slots[action]
			if is_instance_valid(slot):
				# Toggle to the next pip / label option safely wrapping around at the max
				slot.current_option_index = (slot.current_option_index + 1) % slot.total_options
				# Push state to GameManager so NPCs can read it
				GameManager.set_active_skill(action, slot.option_names[slot.current_option_index])

func _process(delta):
	if is_instance_valid(control_timer):
		timer_label.text = str("%.1f" % control_timer.time_left)

func _on_control_timer_timeout():
	if not GameManager.cycling_unlocked:
		return
	
	if is_instance_valid(_sfx_player):
		_sfx_player.play()

func _on_dialogue_started():
	visible = false

func _on_dialogue_finished(_next_state: String = ""):
	visible = true

func show_timer_adjustment(delta: float) -> void:
	if not timer_adjustment_label:
		return
	
	# Set text and color based on adjustment
	var prefix = "+" if delta > 0 else ""
	timer_adjustment_label.text = prefix + str("%.1f" % delta)
	timer_adjustment_label.modulate = Color.GREEN if delta > 0 else Color.RED
	
	# Reset alpha to full for the start of the animation
	timer_adjustment_label.modulate.a = 1.0
	
	# Reset position (relative to its original place)
	var base_y = timer_label.position.y + 40 
	timer_adjustment_label.position.y = base_y
	
	# Animate: Float up slightly and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(timer_adjustment_label, "position:y", base_y - 20, 1.2)
	tween.tween_property(timer_adjustment_label, "modulate:a", 0.0, 1.2)
