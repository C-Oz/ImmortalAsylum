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

const ZONE_PITCH_MAP = {
	"Am9": ["0011", "0012", "0013", "0014", "0015", "0016"],
	"Dm9": ["0017", "0018", "0019", "0020", "0021", "0022"],
	"Dbmaj9": ["0023", "0024", "0025", "0023", "0026", "0027"],
	"Abmaj9": ["0028", "0029", "0030", "0031", "0032", "0033"],
	"F#9#11": ["0035", "0037", "0038", "0037", "0040", "0031"],
	"Fdim": ["0044", "0045", "0046", "0047", "0048", "0049"],
	"Bmaj9": ["0050", "0051", "0052", "0053", "0054", "0055"],
	"Gm9": ["0058", "0059", "0060", "0061", "0065", "0063"],
	"Cmaj9#11": ["0066", "0067", "0068", "0069", "0070", "0071"],
	"C#dim maj7#9": ["0072", "0073", "0074", "0075", "0076", "0077"],
	"Bbm9": ["0078", "0079", "0080", "0081", "0082", "0083"],
	"Ebm maj9": ["0085", "0086", "0087", "0088", "0089", "0090"],
	"F halfdim": ["0091", "0092", "0093", "0094", "0095", "0096"],
	"G halfdim": ["0098", "0099", "0100", "0101", "0102", "0103"],
	"D7b9": ["0105", "0106", "0107", "0108", "0109", "0110"]
}

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

	var is_y_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_Y) or Input.is_physical_key_pressed(KEY_Q)
	if is_y_pressed:
		texture_rect_y.texture = tex_y_2
	else:
		texture_rect_y.texture = tex_y_1
		
	_process_audio(is_y_pressed, sound_y)

	var is_b_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_B) or Input.is_physical_key_pressed(KEY_A)
	if is_b_pressed:
		texture_rect_b.texture = tex_b_2
	else:
		texture_rect_b.texture = tex_b_1
		
	_process_audio(is_b_pressed, sound_b)

	var is_a_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_physical_key_pressed(KEY_Z)
	if is_a_pressed:
		texture_rect_a.texture = tex_a_2
	else:
		texture_rect_a.texture = tex_a_1
		
	_process_audio(is_a_pressed, sound_a)

func _process_audio(is_pressed: bool, player: AudioStreamPlayer):
	if is_pressed:
		if not player.playing:
			player.play()
	else:
		if player.playing:
			player.stop()

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
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
	if sound_y.playing: sound_y.play()
	if sound_b.playing: sound_b.play()
	if sound_a.playing: sound_a.play()

func _build_file_index():
	_file_index.clear()
	var dir = DirAccess.open("res://assets/muzak/solo")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var regex = RegEx.new()
		regex.compile("\\d{4}")
		
		while file_name != "":
			if not dir.current_is_dir():
				var load_path = file_name
				if file_name.ends_with(".import"):
					load_path = file_name.trim_suffix(".import")
				
				if load_path.ends_with(".wav"):
					var result = regex.search(load_path)
					if result:
						var id_str = result.get_string()
						if not _file_index.has(id_str):
							_file_index[id_str] = "res://assets/muzak/solo/" + load_path
			file_name = dir.get_next()
		dir.list_dir_end()
	
	print("SoloPitches: Found ", _file_index.size(), " sound files in index.")

func _load_zone_sounds(zone_name: String):
	_current_zone_name = zone_name
	if not ZONE_PITCH_MAP.has(zone_name):
		return
	
	var ids = ZONE_PITCH_MAP[zone_name]
	
	sound_y_default = _load_sound(ids[0])
	sound_b_default = _load_sound(ids[1])
	sound_a_default = _load_sound(ids[2])
	
	sound_y_alt = _load_sound(ids[3])
	sound_b_alt = _load_sound(ids[4])
	sound_a_alt = _load_sound(ids[5])
	
	_update_audio_streams()

func _load_sound(id_str: String) -> AudioStream:
	if _file_index.has(id_str):
		return load(_file_index[id_str]) as AudioStream
	return null
