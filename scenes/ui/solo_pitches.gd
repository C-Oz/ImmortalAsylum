extends Control

@onready var texture_rect_y = $Pitches/TextureRectY
@onready var texture_rect_b = $Pitches/TextureRectB
@onready var texture_rect_a = $Pitches/TextureRectA

@onready var sound_y = $SoundY
@onready var sound_b = $SoundB
@onready var sound_a = $SoundA

@onready var solo_instrument = $SoloInstrument

var tex_y_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_y_1.png")
var tex_y_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_y_2.png")

var tex_b_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_b_1.png")
var tex_b_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_b_2.png")

var tex_a_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_a_1.png")
var tex_a_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_a_2.png")



var _file_index: Dictionary = {}
var _current_zone_name: String = ""

var sound_y_default: AudioStream
var sound_b_default: AudioStream
var sound_a_default: AudioStream
var sound_y_alt: AudioStream
var sound_b_alt: AudioStream
var sound_a_alt: AudioStream

var is_alt_map: bool = false



func _ready():
	_build_file_index()
	
	sound_y.volume_db = 0.0
	sound_b.volume_db = 0.0
	sound_a.volume_db = 0.0
	
	sound_y.stop()
	sound_b.stop()
	sound_a.stop()

func _process(delta):

	if GameManager.current_chord_zone != _current_zone_name:
		_load_zone_sounds(GameManager.current_chord_zone)

	# var is_y_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_Y) or Input.is_physical_key_pressed(KEY_Q)
	var is_y_pressed = Input.is_action_pressed("joy_y")
	if is_y_pressed:
		texture_rect_y.texture = tex_y_2
	else:
		texture_rect_y.texture = tex_y_1
		
	# _process_audio(is_y_pressed, sound_y)
	if Input.is_action_just_pressed("joy_y"):
		_process_audio(true, sound_y)

	# var is_b_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_B) or Input.is_physical_key_pressed(KEY_A)
	var is_b_pressed = Input.is_action_pressed("joy_b")
	if is_b_pressed:
		texture_rect_b.texture = tex_b_2
	else:
		texture_rect_b.texture = tex_b_1
		
	# _process_audio(is_b_pressed, sound_b)
	if Input.is_action_just_pressed("joy_b"):
		_process_audio(true, sound_b)

	# var is_a_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_physical_key_pressed(KEY_Z)
	var is_a_pressed = Input.is_action_pressed("joy_a")
	if is_a_pressed:
		texture_rect_a.texture = tex_a_2
	else:
		texture_rect_a.texture = tex_a_1
		
	# _process_audio(is_a_pressed, sound_a)
	if Input.is_action_just_pressed("joy_a"):
		_process_audio(true, sound_a)

func _process_audio(is_pressed: bool, player: AudioStreamPlayer):
	if is_pressed:
		if not player.playing:
			# Determine volume reduction based on current scene
			var scene_name = get_tree().current_scene.name
			if scene_name == "EastArea2":
				player.volume_db = -12.0
			else:
				player.volume_db = 2.0
				
			player.play()
	#else:
		#if player.playing:
			#player.stop()

func _unhandled_input(event):
	if event.is_action_pressed("solo_toggle"):
		is_alt_map = !is_alt_map
		_update_audio_streams()

func _update_audio_streams():
	if is_alt_map:
		sound_y.stream = sound_y_alt
		sound_b.stream = sound_b_alt
		sound_a.stream = sound_a_alt
		if is_instance_valid(solo_instrument):
			solo_instrument.flip_v = true
	else:
		sound_y.stream = sound_y_default
		sound_b.stream = sound_b_default
		sound_a.stream = sound_a_default
		if is_instance_valid(solo_instrument):
			solo_instrument.flip_v = false
			
	# Restart sounds if they were already playing
	#if sound_y.playing: sound_y.play()
	#if sound_b.playing: sound_b.play()
	#if sound_a.playing: sound_a.play()

func _build_file_index():
	_file_index.clear()
	var base_path = "res://assets/muzak/solo"
	var dir = DirAccess.open(base_path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				var chord_dict = {"set1": [], "set2": []}
				
				var set1_path = base_path + "/" + folder_name + "/Pitch set 1"
				_get_files_to_array(set1_path, chord_dict["set1"])
				
				var set2_path = base_path + "/" + folder_name + "/Pitch set 2"
				_get_files_to_array(set2_path, chord_dict["set2"])
				
				_file_index[folder_name] = chord_dict
			folder_name = dir.get_next()
		dir.list_dir_end()
	
	print("SoloPitches: Built folder index for ", _file_index.size(), " zones.")

func _get_files_to_array(folder_path: String, arr: Array):
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var clean_name = file_name.trim_suffix(".import")
				if clean_name.ends_with(".wav") or clean_name.ends_with(".mp3"):
					var full_path = folder_path + "/" + clean_name
					if not arr.has(full_path):
						arr.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()

func _load_zone_sounds(zone_name: String):
	_current_zone_name = zone_name
	
	if not _file_index.has(zone_name):
		print("SoloPitches Warning: Could not find folder matching chord_name '", zone_name, "'. Check EastArea2.tscn or folder name.")
		return
		
	var chord_dict = _file_index[zone_name]
	
	var set1 = chord_dict["set1"]
	var set2 = chord_dict["set2"]
	
	sound_y_default = load(set1[0]) as AudioStream if set1.size() > 0 else null
	sound_b_default = load(set1[1]) as AudioStream if set1.size() > 1 else null
	sound_a_default = load(set1[2]) as AudioStream if set1.size() > 2 else null
	
	sound_y_alt = load(set2[0]) as AudioStream if set2.size() > 0 else null
	sound_b_alt = load(set2[1]) as AudioStream if set2.size() > 1 else null
	sound_a_alt = load(set2[2]) as AudioStream if set2.size() > 2 else null
	
	_update_audio_streams()
