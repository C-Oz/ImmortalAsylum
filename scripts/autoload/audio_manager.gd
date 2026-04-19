extends Node

var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var tween: Tween

func _ready() -> void:
	# Two players for seamless crossfading (no gap/click)
	music_player_a = AudioStreamPlayer.new()
	music_player_b = AudioStreamPlayer.new()
	add_child(music_player_a)
	add_child(music_player_b)
	music_player_a.bus = "Music"
	music_player_b.bus = "Music"
	active_player = music_player_a

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
