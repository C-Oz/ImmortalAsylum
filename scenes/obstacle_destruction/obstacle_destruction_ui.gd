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

@onready var sequence_container = $SequenceContainer
@onready var needle = $Needle
@onready var countdown_label = $CountdownLabel
@onready var background_panel = $BackgroundPanel

# Button sprite mapping - UPDATE THESE PATHS TO YOUR SPRITES
var button_sprites = {
	"Y": preload("res://assets/art/ui/ABXY/button_xbox_digital_y_1.png"),
	"B": preload("res://assets/art/ui/ABXY/button_xbox_digital_b_1.png"),
	"A": preload("res://assets/art/ui/ABXY/button_xbox_digital_a_1.png")
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

func on_beat():
	print("on_beat called, state: ", State.keys()[state], " beats_remaining: ", beats_remaining)
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
	
	# If we've looped back to start and player hasn't matched anything, reset their progress
	if current_beat_index == 0 and player_input_index > 0:
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
	
	# Player must be on the correct beat AND correct button
	var expected_button = sequence[player_input_index]
	
	if button == expected_button and current_beat_index == player_input_index:
		# Correct!
		player_input_index += 1
		# Visual feedback here (highlight slot, play sound, etc)
		
		if player_input_index >= sequence.size():
			# Sequence completed!
			emit_signal("sequence_completed")
			state = State.INACTIVE
	else:
		# Wrong button or wrong timing - reset
		player_input_index = 0

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
