@tool
extends Control

signal sequence_completed

enum State { INACTIVE, COUNTDOWN, ACTIVE }

@export var sequence: Array[String] = []: # passed from parent
	set(value):
		sequence = value
		if Engine.is_editor_hint():
			setup_sequence()

@export var countdown_beats: int = 4
@export var slot_spacing: float = 20.0  # Adjust this to space buttons
@export var button_scale: float = 0.06  # Scale down 480x480 button sprites

@export var instrument_icon: Texture2D:
	set(value):
		instrument_icon = value
		_update_icon_visuals()
		if Engine.is_editor_hint():
			setup_sequence() # Resize needed when icon changes

@export var auto_center_x: bool = true

var state = State.INACTIVE
var current_beat_index = 0
var beats_remaining = 0
var player_input_index = 0
const HIT_WINDOW_SECS := 0.3
var pressed_slots := []

@onready var sequence_container = $SequenceContainer
@onready var needle = $Needle
@onready var countdown_label = $CountdownLabel
@onready var background_panel = $BackgroundPanel
@onready var success_particles = $SuccessParticles
@onready var instrument_icon_rect = $InstrumentIcon

var button_sprites = {
	"Y": preload("res://assets/art/ui/ABXY/button_xbox_digital_y_1.png"),
	"B": preload("res://assets/art/ui/ABXY/button_xbox_digital_b_1.png"),
	"A": preload("res://assets/art/ui/ABXY/button_xbox_digital_a_1.png")
}

var button_sprites_pressed = {
	"Y": preload("res://assets/art/ui/ABXY/button_xbox_digital_y_2.png"),
	"B": preload("res://assets/art/ui/ABXY/button_xbox_digital_b_2.png"),
	"A": preload("res://assets/art/ui/ABXY/button_xbox_digital_a_2.png")
}

func _ready():
	# Reset root modulation so it doesn't multiply with children
	modulate = Color(1, 1, 1, 1)
	
	_update_icon_visuals()
	setup_sequence()
	
	if not Engine.is_editor_hint():
		hide_countdown()
		reset_needle()
		stop_sequence() # Ensure initial state is greyed out correctly

func _update_icon_visuals():
	if not is_node_ready(): await ready
	if instrument_icon_rect:
		if instrument_icon:
			instrument_icon_rect.texture = instrument_icon
			instrument_icon_rect.visible = true
		else:
			instrument_icon_rect.visible = false

func setup_sequence():
	if not is_node_ready(): await ready
	if not sequence_container: return
	
	# Clear existing slots
	for child in sequence_container.get_children():
		child.queue_free()
	
	resize_container()
	
	# Calculate layout
	var button_width = 480 * button_scale
	
	# Create button slots
	for i in sequence.size():
		var slot = TextureRect.new()
		
		# Set sprite
		if sequence[i] in button_sprites:
			slot.texture = button_sprites[sequence[i]]
		else:
			push_warning("No sprite for button: ", sequence[i])
		
		# Just scale it down instead of resizing
		slot.scale = Vector2(button_scale, button_scale)
		# Position (top-left corner positioning for Control nodes)
		slot.position.x = i * (button_width + slot_spacing)
		slot.position.y = (sequence_container.size.y / 2.0) - (button_width / 2.0)
		slot.name = "Slot_" + str(i)
		
		sequence_container.add_child(slot)
	
	if not Engine.is_editor_hint():
		reset_needle()

func start_sequence():
	if state != State.INACTIVE:
		return
	
	DeviceManager.vibrate(DeviceManager.Role.BUTTONS, 0.1, 0.1, 0)
	
	state = State.COUNTDOWN
	beats_remaining = countdown_beats
	current_beat_index = 0
	player_input_index = 0
	show_countdown()

func stop_sequence():
	DeviceManager.stop_vibrate(DeviceManager.Role.BUTTONS)
	state = State.INACTIVE
	reset_needle()
	hide_countdown()
	player_input_index = 0
	current_beat_index = 0
	reset_buttons()
	# Grey out everything
	var grey = Color(0.5, 0.5, 0.5, 1.0)
	background_panel.modulate = grey
	sequence_container.modulate = grey
	needle.modulate = grey
	if instrument_icon_rect:
		instrument_icon_rect.modulate = grey
	visible = true # Reappear when resetting

func on_beat():
	match state:
		State.COUNTDOWN:
			beats_remaining -= 1
			update_countdown_display()
			
			if beats_remaining <= 0:
				state = State.ACTIVE
				_activate_visuals()
				# Reset current_beat_index to 0 to ensure we start on the first slot
				current_beat_index = 0
				reset_needle()
		
		State.ACTIVE:
			advance_needle()

func _activate_visuals():
	hide_countdown()
	# Full brightness for everything
	var white = Color(1.0, 1.0, 1.0, 1.0)
	background_panel.modulate = white
	sequence_container.modulate = white
	needle.modulate = white
	if instrument_icon_rect:
		instrument_icon_rect.modulate = white

func resize_container():
	if not is_node_ready(): await ready
	if not sequence_container or not background_panel: return
	
	# Calculate needed width for all buttons + spacing
	var button_width = 480 * button_scale  # Width of one button
	var icon_width = 0.0
	if instrument_icon:
		icon_width = button_width + slot_spacing
		
	var total_width = (button_width * sequence.size()) + (slot_spacing * (sequence.size() - 1)) + icon_width
	
	var padding = 10
	
	# Resize the sequence container and the background panel
	sequence_container.custom_minimum_size.x = total_width - icon_width
	sequence_container.size.x = total_width - icon_width
	background_panel.custom_minimum_size.x = total_width + (padding * 2)
	background_panel.size.x = total_width + (padding * 2)
	
	# Also resize the parent Control if needed
	custom_minimum_size.x = total_width
	size.x = total_width
	
	# Center the UI horizontally by offsetting position
	if auto_center_x:
		position.x = -total_width / 2.0  # Shift left by half the width
	
	background_panel.position.x = -padding # Shift left by padding amount
	
	# Position the icon and container
	if instrument_icon:
		instrument_icon_rect.size = Vector2(button_width, button_width)
		instrument_icon_rect.position = Vector2(0, (size.y / 2.0) - (button_width / 2.0))
		sequence_container.position.x = icon_width
	else:
		sequence_container.position.x = 0

func advance_needle():
	current_beat_index = (current_beat_index + 1) % sequence.size()
	update_needle_position()
	
	# Always reset visuals at start of loop
	if current_beat_index == 0:
		reset_buttons()
		# Also reset player progress if incomplete
		if player_input_index > 0 and player_input_index < sequence.size():
			player_input_index = 0

func update_needle_position():
	if not sequence_container or sequence_container.get_child_count() == 0:
		return
	
	var target_slot = sequence_container.get_child(current_beat_index)
	if not target_slot: return
	
	var button_width = 480 * button_scale
	# Needle is sibling of SequenceContainer, so add its offset
	# Set Y higher to avoid overlapping sprites
	needle.position.x = sequence_container.position.x + target_slot.position.x + (button_width / 2.0) - (needle.size.x / 2.0)
	needle.position.y = target_slot.position.y - button_width

func check_input(button: String):
	if state == State.INACTIVE:
		return
	
	var rhythm_notifier = get_tree().current_scene.get_node("RhythmNotifier")
	
	# Calculate timing difference (same as battle system)
	var beat_time : float = floor(rhythm_notifier.current_beat) * rhythm_notifier.beat_length
	var next_beat_time : float = beat_time + rhythm_notifier.beat_length
	var diff_current : float = rhythm_notifier.current_position - beat_time
	var diff_next : float = next_beat_time - rhythm_notifier.current_position
	var diff : float = min(diff_current, diff_next)
	
	# Handle early hit on the very first button during countdown
	if state == State.COUNTDOWN:
		# If on last beat of countdown and hitting closer to the "GO" beat
		if beats_remaining == 1 and diff_current > diff_next and diff <= HIT_WINDOW_SECS:
			if button == sequence[0]:
				state = State.ACTIVE
				# We don't advance the beat index here, just activate visuals
				# The upcoming on_beat will handle the first "natural" beat transition
				_activate_visuals()
				show_pressed_feedback(0)
				player_input_index = 1
				print("Early hit on first button registered!")
				return
		return # Ignore other countdown inputs
	
	# Check timing window
	if diff > HIT_WINDOW_SECS:
		player_input_index = 0
		print("Off beat!")
		return
	
	# Determine which beat to check
	var check_index = current_beat_index
	# If closer to next beat, check next button
	if diff_current > diff_next and current_beat_index + 1 < sequence.size():
		check_index = current_beat_index + 1
	
	var expected_button = sequence[check_index]
	
	# Check if correct button for THIS beat (not sequence position)
	if button == expected_button:
		# Always show visual feedback for correct button
		show_pressed_feedback(check_index)
		print("Correct button at position: ", check_index)
		
		# Only advance sequence if it's the NEXT expected button
		if check_index == player_input_index:
			player_input_index += 1
			print("Sequence progress: ", player_input_index, "/", sequence.size())
			
			if player_input_index >= sequence.size():
				# Sequence completed!
				print("Sequence completed!")
				emit_signal("sequence_completed")
				state = State.INACTIVE
				visible = false # Hide until player leaves zone
		else:
			# Correct button but wrong order - reset sequence tracking
			print("Correct button but broke sequence. Resetting progress.")
			player_input_index = 0
	else:
		# Wrong button entirely
		print("Wrong button! Expected: ", expected_button, " Got: ", button)
		player_input_index = 0

func show_pressed_feedback(slot_index: int):
	if slot_index >= sequence_container.get_child_count():
		return
	
	var slot = sequence_container.get_child(slot_index)
	var button_key = sequence[slot_index]
	
	# Change to pressed sprite
	if button_key in button_sprites_pressed:
		slot.texture = button_sprites_pressed[button_key]
	
	# Track that this slot was pressed
	if not pressed_slots.has(slot_index):
		pressed_slots.append(slot_index)
	
	if sequence_container and slot:
		var button_width = 480 * button_scale
		# Correct for container offset
		var particle_pos = sequence_container.position + slot.position + Vector2(button_width / 2.0, button_width / 2.0)
		spawn_success_particles(particle_pos)
		
	trigger_vibration()

func reset_buttons():
	# Reset all buttons to unpressed state
	for i in range(sequence_container.get_child_count()):
		var slot = sequence_container.get_child(i)
		var button_key = sequence[i]
		
		if button_key in button_sprites:
			slot.texture = button_sprites[button_key]
	
	pressed_slots.clear()

func reset_needle():
	current_beat_index = 0
	update_needle_position()

func show_countdown():
	countdown_label.visible = true

func hide_countdown():
	countdown_label.visible = false

func update_countdown_display():
	print("Updating countdown label to: ", beats_remaining)
	countdown_label.text = str(beats_remaining)

func spawn_success_particles(pos: Vector2):
	if success_particles:
		success_particles.position = pos
		success_particles.restart()
		success_particles.emitting = true

func trigger_vibration():
	# Vibrate for 0.1 seconds, medium strength
	DeviceManager.vibrate(DeviceManager.Role.BUTTONS, 0.5, 0.5, 0.1)
