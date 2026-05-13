extends CanvasLayer

@onready var solo_pitches = $SoloPitches
@onready var solo_instrument = $SoloPitches/SoloInstrument
@onready var skill_up = $DPadSkillWheel/SkillUp
@onready var skill_down = $DPadSkillWheel/SkillDown
@onready var skill_left = $DPadSkillWheel/SkillLeft
@onready var skill_right = $DPadSkillWheel/SkillRight

@onready var timer_label = $TimerLabel
@onready var timer_adjustment_label = $TimerAdjustmentLabel

const SKILL_TOGGLE_COOLDOWN_SECS := 0.5

var control_timer: Timer

var _sfx_player: AudioStreamPlayer

# Maps dpad actions to their corresponding skill slots
var _dpad_slots: Dictionary
var _skill_toggle_particles: GPUParticles2D
var _skill_toggle_cooldown_remaining := 0.0

func _ready():
	# Use the persistent timer from GameManager
	control_timer = GameManager.control_timer
	_skill_toggle_particles = _get_skill_toggle_particles()
	
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
	var rewards_config = {
		"haniran_box5": ["Haniran's Theme Acquired", "res://assets/art/instruments/cello_big.png"],
		"clarinet_box5": ["Syndra's Theme Acquired", "res://assets/art/instruments/clarinet_big.png"],
		"guitar_box5": ["Onia's Theme Acquired", "res://assets/art/instruments/guitar_big.png"],
		"drums_box5": ["Kunjato's Theme Acquired", "res://assets/art/instruments/drums_big.png"]
	}
	
	if rewards_config.has(reward_id):
		var config = rewards_config[reward_id]
		var reward_scene = load("res://scenes/ui/RewardUI.tscn")
		if reward_scene:
			var reward_inst = reward_scene.instantiate()
			reward_inst.setup(config[0], load(config[1]))
			add_child(reward_inst)

func _refresh_skill_slots() -> void:
	# Base labels for all slots
	var base_labels: Array[String] = ["Box1", "Box2", "Box3", "Box4"]
	
	for action in _dpad_slots:
		var slot = _dpad_slots[action]
		if not is_instance_valid(slot): continue
		
		# Build specific labels for this slot
		var current_labels = base_labels.duplicate()
		
		# Append NPC themes based on unlocked rewards and dpad direction
		if action == "dpad_up" and GameManager.unlocked_rewards.has("haniran_box5"):
			current_labels.append("Haniran")
		elif action == "dpad_down" and GameManager.unlocked_rewards.has("clarinet_box5"):
			current_labels.append("Syndra")
		elif action == "dpad_left" and GameManager.unlocked_rewards.has("guitar_box5"):
			current_labels.append("Onia")
		elif action == "dpad_right" and GameManager.unlocked_rewards.has("drums_box5"):
			current_labels.append("Kunjato")
			
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
			_try_toggle_skill(action)
			return

func _try_toggle_skill(action: String) -> void:
	if _skill_toggle_cooldown_remaining > 0.0:
		return
	
	var slot = _dpad_slots.get(action)
	if not is_instance_valid(slot) or slot.total_options <= 0:
		return
	
	# Toggle to the next pip / label option safely wrapping around at the max
	slot.current_option_index = (slot.current_option_index + 1) % slot.total_options
	# Push state to GameManager so NPCs can read it
	GameManager.set_active_skill(action, slot.option_names[slot.current_option_index])
	_play_skill_toggle_effect(slot)
	_skill_toggle_cooldown_remaining = SKILL_TOGGLE_COOLDOWN_SECS

func _get_skill_toggle_particles() -> GPUParticles2D:
	var particles = get_node_or_null("DPadSkillWheel/SkillToggleParticles") as GPUParticles2D
	if not particles:
		particles = get_node_or_null("DPadSkillWheel/SuccessParticles") as GPUParticles2D
	return particles

func _play_skill_toggle_effect(slot: Control) -> void:
	if not is_instance_valid(_skill_toggle_particles):
		return
	
	var target = slot.find_child("Label", true, false) as Control
	if not is_instance_valid(target):
		target = slot
	
	_skill_toggle_particles.global_position = target.get_global_rect().get_center()
	_skill_toggle_particles.restart()
	_skill_toggle_particles.emitting = true

func _process(delta):
	if _skill_toggle_cooldown_remaining > 0.0:
		_skill_toggle_cooldown_remaining = maxf(0.0, _skill_toggle_cooldown_remaining - delta)
	
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

func _on_dpad_area_body_entered(body: Node2D) -> void:
	print("Dpad Area entered by: ", body.name)
	var wheel = get_node_or_null("DPadSkillWheel")
	if wheel and body.is_in_group("player") and not wheel.visible:
		wheel.modulate.a = 0.0
		wheel.visible = true
		var tween = create_tween()
		tween.tween_property(wheel, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)


func _on_solo_area_body_entered(body: Node2D) -> void:
	push_warning("Solo Area entered by: ", body.name)
	var pitches = get_node_or_null("SoloPitches")
	if pitches and body.is_in_group("player") and not pitches.visible:
		pitches.modulate.a = 0.0
		pitches.visible = true
		var tween = create_tween()
		tween.tween_property(pitches, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
