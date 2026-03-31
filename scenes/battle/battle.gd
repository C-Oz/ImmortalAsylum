extends CanvasLayer

enum Phase { DEMO, PLAYER }
enum Direction { Y, B, A }
enum BattleMode { RANDOM_LEGACY, SCRIPTED }

@onready var r: RhythmNotifier = $RhythmNotifier
@onready var demo_lane_container: Control = $DemoLaneContainer
@onready var lane_visual: TextureRect = $DemoLaneContainer/LaneVisual
@onready var lane_y: Control = $DemoLaneContainer/LaneY
@onready var lane_b: Control = $DemoLaneContainer/LaneB
@onready var lane_a: Control = $DemoLaneContainer/LaneA
@onready var button_vbox: VBoxContainer = $VBoxContainer
@onready var player_lane_container: Control = $PlayerLaneContainer
@onready var player_lane_y: Control = $PlayerLaneContainer/LaneY
@onready var player_lane_b: Control = $PlayerLaneContainer/LaneB
@onready var player_lane_a: Control = $PlayerLaneContainer/LaneA
@onready var player_button_vbox: VBoxContainer = $VBoxContainer2

@export var sequence_length: int = 4
@export var battle_length: int = 2 # number of total sequnces
var sequence_no: int = -1

@export var mode: BattleMode = BattleMode.RANDOM_LEGACY
@export_multiline var battle_script: String = ""

var absolute_beat_count: int = -1
var scripted_timeline_actions := {}
var current_sequence_start_beat: int = 0

@export var audio_offset_ms: float = 0.0
@export var button_prompt_scene: PackedScene
@export var button_y_texture: Texture2D
@export var button_b_texture: Texture2D
@export var button_a_texture: Texture2D

var phase := Phase.DEMO
var button_sequence := []
var active_buttons := []
var player_input_index := 0

const HIT_WINDOW_SECS := 0.2

@export var debug_mode: bool = false

func _ready() -> void:
	if mode == BattleMode.SCRIPTED:
		build_timeline()
	r.audio_stream_player.play()
	r.beats(1).connect(_on_beat)

func _process(_delta: float) -> void:
	pass

func _on_beat(_beat: int) -> void:
	absolute_beat_count += 1
	if mode == BattleMode.RANDOM_LEGACY:
		_on_beat_legacy(absolute_beat_count)
	elif mode == BattleMode.SCRIPTED:
		_on_beat_scripted(absolute_beat_count)

func _on_beat_legacy(beat: int) -> void:
	var b := beat % (sequence_length * 4)
	
	if debug_mode:
		print ("beat: %d" % b)
	
	# Reset cycle every sequence_length beats
	if b == 0:
		clear_buttons()
		button_sequence.clear()
		player_input_index = 0
		phase = Phase.DEMO
		sequence_no += 1
		current_sequence_start_beat = beat + (3 * sequence_length)
		if sequence_no >= battle_length:
			_on_battle_end()
		
	elif b == (( 3 * sequence_length) - 1):
		phase = Phase.PLAYER
	
	if b >= 0 and b < sequence_length:
		spawn_button_legacy(b)
	elif b >= ( 2 * sequence_length) and b < ( 3 * sequence_length):
		spawn_player_button(b - (2 * sequence_length))
	elif b > ( 3 * sequence_length) and b < ( 4 * sequence_length):
		player_input_index += 1

func _on_beat_scripted(beat: int) -> void:
	if debug_mode:
		print ("scripted beat: %d" % beat)
		
	if scripted_timeline_actions.has(beat):
		var actions = scripted_timeline_actions[beat]
		for action in actions:
			if action.type == "spawn_button":
				spawn_button_scripted(action.direction)
			elif action.type == "prepare_inputs":
				button_sequence = action.sequence
				player_input_index = 0
				current_sequence_start_beat = action.start_beat
				phase = Phase.PLAYER
			elif action.type == "spawn_player_button":
				spawn_player_button_scripted(action.direction)
			elif action.type == "inc_player_input":
				player_input_index += 1
			elif action.type == "end_inputs":
				phase = Phase.DEMO
			elif action.type == "clear_feedback":
				if phase != Phase.PLAYER:
					$Feedback.text = ""
			elif action.type == "battle_end":
				_on_battle_end()

func add_action(beat: int, type: String, data: Dictionary = {}):
	if not scripted_timeline_actions.has(beat):
		scripted_timeline_actions[beat] = []
	var action = {"type": type}
	action.merge(data)
	scripted_timeline_actions[beat].append(action)

func build_timeline():
	scripted_timeline_actions.clear()
	var align_beat = 0
	var lines = battle_script.split("\n", false)
	for line in lines:
		line = line.strip_edges()
		if line == "" or line.begins_with("#"):
			continue
			
		if line.begins_with("WAIT "):
			var beats = line.substr(5).strip_edges().to_int()
			align_beat += beats
			
		elif line.begins_with("PLAY "):
			var seq_str = line.substr(5).strip_edges()
			var seq = []
			var raw_chars = seq_str.replace(" ", "")
			for i in range(raw_chars.length()):
				var c = raw_chars.substr(i, 1).to_upper()
				if c == "Y": seq.append(Direction.Y)
				elif c == "B": seq.append(Direction.B)
				elif c == "A": seq.append(Direction.A)
				elif c == ".": seq.append(-1)
			
			var sl = seq.size()
			var demo_spawn_start = align_beat - sequence_length
			
			if demo_spawn_start < 0:
				demo_spawn_start = max(0, demo_spawn_start)
			
			add_action(demo_spawn_start, "clear_feedback")
			
			for i in range(sl):
				add_action(demo_spawn_start + i, "spawn_button", {"direction": seq[i]})
			
			var player_hit_start = align_beat + sl
			var player_spawn_start = player_hit_start - sequence_length
			
			if player_spawn_start < 0:
				player_spawn_start = max(0, player_spawn_start)
			
			var prepare_beat = player_hit_start - 2
			if prepare_beat < 0:
				prepare_beat = max(0, prepare_beat)
			
			add_action(prepare_beat, "prepare_inputs", {"sequence": seq, "start_beat": player_hit_start})
			
			for i in range(sl):
				add_action(player_spawn_start + i, "spawn_player_button", {"direction": seq[i]})
			
			for i in range(1, sl):
				add_action(player_hit_start + i, "inc_player_input")
			
			add_action(player_hit_start + sl, "end_inputs")
			
			# Advance align_beat so the NEXT sequence's demo spawns immediately after this sequence's player inputs finish
			align_beat += (2 * sl)
			
	# Append enough rests at the end to allow for the final animations before shutting down
	add_action(align_beat + 4, "battle_end")

func spawn_button_legacy(spawn_beat: int):
	var direction = randi() % 3
	button_sequence.append(direction)
	_spawn_demo_button_visual(direction, spawn_beat)

func spawn_button_scripted(direction: int):
	if direction == -1:
		return
	_spawn_demo_button_visual(direction, 0)

func _spawn_demo_button_visual(direction: int, spawn_beat: int):
	var button := button_prompt_scene.instantiate()
	
	if debug_mode:
		print ("add: %d" % [direction])
	
	match direction:
		Direction.Y:
			button.texture = button_y_texture
		Direction.B:
			button.texture = button_b_texture
		Direction.A:
			button.texture = button_a_texture
	
	var target_lane: Control
	match direction:
		Direction.Y:
			target_lane = lane_y
		Direction.B:
			target_lane = lane_b
		Direction.A:
			target_lane = lane_a
	
	target_lane.add_child(button)
	
	# Position button at left edge of lane
	var button_size = button.custom_minimum_size
	button.position = Vector2(-button_size.x, (target_lane.size.y - button_size.y) / 2)
	
	# Store button data for tracking
	var button_data = {
		"button": button,
		"direction": direction,
		"lane": target_lane,
		"spawn_beat": spawn_beat
	}
	active_buttons.append(button_data)
	
	animate_button_slide(button, target_lane, direction, button_vbox)

func spawn_player_button(sequence_index: int):
	if sequence_index >= button_sequence.size():
		return
	
	var direction = button_sequence[sequence_index]
	if direction == -1:
		return
	_spawn_player_button_visual(direction)

func spawn_player_button_scripted(direction: int):
	if direction == -1:
		return
	_spawn_player_button_visual(direction)

func _spawn_player_button_visual(direction: int):
	var button := button_prompt_scene.instantiate()
	
	match direction:
		Direction.Y:
			button.texture = button_y_texture
		Direction.B:
			button.texture = button_b_texture
		Direction.A:
			button.texture = button_a_texture
	
	var target_lane: Control
	match direction:
		Direction.Y:
			target_lane = player_lane_y
		Direction.B:
			target_lane = player_lane_b
		Direction.A:
			target_lane = player_lane_a
	
	target_lane.add_child(button)
	
	# Position button at RIGHT edge of lane (mirrored)
	var button_size = button.custom_minimum_size
	button.position = Vector2(target_lane.size.x, (target_lane.size.y - button_size.y) / 2)
	
	animate_button_slide(button, target_lane, direction, player_button_vbox)


func clear_buttons():
	for button_data in active_buttons:
		if is_instance_valid(button_data.button):
			button_data.button.queue_free()
	active_buttons.clear()
	
	for lane in [lane_y, lane_b, lane_a]:
		for child in lane.get_children():
			child.queue_free()

func _input(event: InputEvent) -> void:
	if debug_mode:
		print("Input event received, phase: %s" % Phase.keys()[phase])
		
	if phase != Phase.PLAYER:
		return
	
	var pressed_direction = -1
	
	# Map joypad and keyboard input to directions
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_Y and event.pressed:
		pressed_direction = Direction.Y
	elif event is InputEventKey and event.keycode == KEY_Q and event.pressed and not event.echo:
		pressed_direction = Direction.Y
	elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_B and event.pressed:
		pressed_direction = Direction.B
	elif event is InputEventKey and event.keycode == KEY_A and event.pressed and not event.echo:
		pressed_direction = Direction.B
	elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and event.pressed:
		pressed_direction = Direction.A
	elif event is InputEventKey and event.keycode == KEY_Z and event.pressed and not event.echo:
		pressed_direction = Direction.A
	
	if pressed_direction != -1:
		check_player_input(pressed_direction)

func check_player_input(pressed_direction: int):
	if debug_mode:
		print("=== CHECK INPUT CALLED ===")
	
	if player_input_index >= button_sequence.size():
		return
		
	var target_beat_1 = current_sequence_start_beat + player_input_index
	var target_time_1 = target_beat_1 * r.beat_length
	
	var current_time = r.current_position + (audio_offset_ms / 1000.0)
	var diff_1 = abs(current_time - target_time_1)
	
	var expected_direction = button_sequence[player_input_index]
	var min_diff = diff_1
	
	if player_input_index + 1 < button_sequence.size():
		var target_beat_2 = target_beat_1 + 1
		var target_time_2 = target_beat_2 * r.beat_length
		var diff_2 = abs(current_time - target_time_2)
		
		if diff_2 < diff_1:
			expected_direction = button_sequence[player_input_index + 1]
			min_diff = diff_2
	
	if min_diff > HIT_WINDOW_SECS:
		show_feedback("Off beat!")
		return
	
	if pressed_direction != expected_direction:
		show_feedback("Wrong direction!")
		return
	
	show_feedback(min_diff)
	
	if player_input_index + 1 >= button_sequence.size():
		await get_tree().create_timer(0.3).timeout
		$Feedback.text = "Sequence complete!"
		await get_tree().create_timer(1.5).timeout
		if $Feedback.text == "Sequence complete!":
			$Feedback.text = ""

func show_feedback(diff):
	if typeof(diff) == TYPE_STRING:
		$Feedback.text = diff
	elif diff < 0.05:
		$Feedback.text = "Perfect!"
	elif diff < 0.10:
		$Feedback.text = "Good"
	elif diff < 0.15:
		$Feedback.text = "OK"
	else:
		$Feedback.text = "Meh"

func animate_button_slide(button_prompt: Control, lane: Control, direction: int, target_vbox: VBoxContainer):
	# Calculate target position where button prompt should align with target button
	var target_buttons = target_vbox.get_children()
	var target_button = target_buttons[direction] if direction < target_buttons.size() else target_buttons[0]
	
	var target_button_global_pos = target_button.get_global_position()
	var lane_global_pos = lane.get_global_position()
	var target_x_global = target_button_global_pos.x
	var target_x_local = target_x_global - lane_global_pos.x
	
	# Center button prompt on target button
	var prompt_size = button_prompt.custom_minimum_size
	var target_button_size = target_button.size
	var target_x = target_x_local + (target_button_size.x / 2) - (prompt_size.x / 2)
	
	# Animation duration scales with sequence length, can be made constant
	# Ex. always 4 beats: var slide_duration = r.beat_length * 4
	var slide_duration = r.beat_length * sequence_length
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(button_prompt, "position:x", target_x, slide_duration)
	tween.tween_callback(button_prompt.queue_free)

func _on_battle_end() -> void:
	GameManager.return_to_overworld(true)
