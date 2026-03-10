extends Control

signal sequence_completed

enum State { INACTIVE, COUNTDOWN, ACTIVE }

@export var sequence: Array[String] = [] # passed from parent
@export var countdown_beats: int = 4
@export var slot_spacing: float = 20.0  # Adjust this to space buttons
@export var button_scale: float = 0.06  # Scale down 480x480 button sprites

var state = State.INACTIVE
var current_beat_index = 0
var beats_remaining = 0
var player_input_index = 0
const HIT_WINDOW_SECS := 0.2
var pressed_slots := []

@onready var sequence_container = $SequenceContainer
@onready var needle = $Needle
@onready var countdown_label = $CountdownLabel
@onready var background_panel = $BackgroundPanel

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
	setup_sequence()
	hide_countdown()
	reset_needle()

func setup_sequence():
	print("setup_sequence called with: ", sequence)
	# Clear existing slots
	for child in sequence_container.get_children():
		child.queue_free()
	
	resize_container()
	print("Container size after resize: ", sequence_container.size)
	
	# Calculate layout
	var button_width = 480 * button_scale
	var total_width = (sequence.size() * button_width) + ((sequence.size() - 1) * slot_spacing)
	var start_x = (sequence_container.size.x / 2.0) - (total_width / 2.0)
	print("Total width: ", total_width)
	print("Start X: ", start_x)
	
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
		slot.position.x = start_x + (i * (button_width + slot_spacing))
		slot.position.y = (sequence_container.size.y / 2.0) - (button_width / 2.0)
		slot.name = "Slot_" + str(i)
		print("Button ", i, " created at position: ", slot.position, " size: ", slot.size)
		
		sequence_container.add_child(slot)
	
	print("Created ", sequence_container.get_child_count(), " button slots")
	reset_needle()

func start_sequence():
	if state != State.INACTIVE:
		print("Already active, returning")
		return
	
	print("Starting countdown from ", countdown_beats)
	state = State.COUNTDOWN
	beats_remaining = countdown_beats
	current_beat_index = 0
	player_input_index = 0
	show_countdown()

func stop_sequence():
	state = State.INACTIVE
	reset_needle()
	hide_countdown()
	player_input_index = 0
	current_beat_index = 0
	reset_buttons()

func on_beat():
	#print("on_beat called, state: ", State.keys()[state], " beats_remaining: ", beats_remaining)
	match state:
		State.COUNTDOWN:
			beats_remaining -= 1
			print("Countdown: ", beats_remaining)
			update_countdown_display()
			
			if beats_remaining <= 0:
				print("Countdown finished, going ACTIVE")
				state = State.ACTIVE
				hide_countdown()
		
		State.ACTIVE:
			advance_needle()

func resize_container():
	# Calculate needed width for all buttons + spacing
	var button_width = 480 * button_scale  # Width of one button
	var total_width = (button_width * sequence.size()) + (slot_spacing * (sequence.size() - 1))
	
	var padding = 10
	
	# Resize the sequence container and the background panel
	sequence_container.custom_minimum_size.x = total_width
	sequence_container.size.x = total_width
	background_panel.custom_minimum_size.x = total_width + (padding * 2)
	background_panel.size.x = total_width + (padding * 2)
	# Also resize the parent Control if needed
	custom_minimum_size.x = total_width
	size.x = total_width
	# Center the UI horizontally by offsetting position
	position.x = -total_width / 2.0  # Shift left by half the width
	background_panel.position.x = -padding # Shift left by padding amount

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
	if sequence_container.get_child_count() == 0:
		return
	
	var target_slot = sequence_container.get_child(current_beat_index)
	var button_width = 480 * button_scale
	needle.position.x = target_slot.position.x + (button_width / 2.0) - (needle.size.x / 2.0)
	needle.position.y = target_slot.position.y - button_width

func check_input(button: String):
	if state != State.ACTIVE:
		return
	
	var rhythm_notifier = get_node("/root/Overworld/RhythmNotifier")
	
	# Calculate timing difference (same as battle system)
	var beat_time : float = floor(rhythm_notifier.current_beat) * rhythm_notifier.beat_length
	var next_beat_time : float = beat_time + rhythm_notifier.beat_length
	var diff_current : float = rhythm_notifier.current_position - beat_time
	var diff_next : float = next_beat_time - rhythm_notifier.current_position
	var diff : float = min(diff_current, diff_next)
	
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
