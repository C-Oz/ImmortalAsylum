extends Node

var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var tween: Tween

var doormat_sounds: Dictionary = {}
var doormat_player: AudioStreamPlayer
var last_doormat_time: int = -15000
var doormat_cooldown_ms: int = 15000

func _ready() -> void:
	# Two players for seamless crossfading (no gap/click)
	music_player_a = AudioStreamPlayer.new()
	music_player_b = AudioStreamPlayer.new()
	add_child(music_player_a)
	add_child(music_player_b)
	music_player_a.bus = "Music"
	music_player_b.bus = "Music"
	active_player = music_player_a
	
	doormat_player = AudioStreamPlayer.new()
	add_child(doormat_player)
	doormat_player.bus = "Music"
	
	_load_doormat_sounds()

func _load_doormat_sounds() -> void:
	var path = "res://assets/muzak/Doormat Chords"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				var folder_path = path + "/" + folder_name
				var folder_dir = DirAccess.open(folder_path)
				if folder_dir:
					var sounds: Array[AudioStream] = []
					folder_dir.list_dir_begin()
					var file_name = folder_dir.get_next()
					while file_name != "":
						if not folder_dir.current_is_dir() and (file_name.ends_with(".wav") or file_name.ends_with(".ogg")):
							var stream = load(folder_path + "/" + file_name)
							if stream is AudioStream:
								sounds.append(stream)
						file_name = folder_dir.get_next()
					if sounds.size() > 0:
						doormat_sounds[folder_name] = sounds
			folder_name = dir.get_next()

func play_doormat_chord(chord_name: String) -> void:
	var current_time = Time.get_ticks_msec()
	if current_time - last_doormat_time < doormat_cooldown_ms:
		return
		
	if doormat_sounds.has(chord_name):
		var sounds = doormat_sounds[chord_name]
		if sounds.size() > 0:
			var random_sound = sounds.pick_random()
			doormat_player.stream = random_sound
			doormat_player.play()
			last_doormat_time = current_time

func transition_to(music: AudioStream, ambience: AudioStream, duration: float) -> void:
	var incoming := _get_inactive_player()

	# Don't restart if same track is already playing
	if active_player.stream == music and active_player.playing:
		return

	incoming.stream = music
	incoming.volume_db = -80.0
	incoming.play()

	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(active_player, "volume_db", -80.0, duration)
	tween.tween_property(incoming, "volume_db", 0.0, duration)

	await tween.finished
	active_player.stop()
	active_player = incoming

func _get_inactive_player() -> AudioStreamPlayer:
	return music_player_b if active_player == music_player_a else music_player_a
