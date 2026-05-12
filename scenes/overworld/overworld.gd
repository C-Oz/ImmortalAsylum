extends Node2D

var rhythm_original_volume_db: float
var volume_tween: Tween
var god_mode_overlay: CanvasLayer
var god_mode_player: Node

func _enter_tree() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	god_mode_overlay = find_child("GodModeOverlay", true, false) as CanvasLayer
	god_mode_player = find_child("Player", true, false)
	
	if not GameManager.god_mode_changed.is_connected(_on_god_mode_changed):
		GameManager.god_mode_changed.connect(_on_god_mode_changed)
	_on_god_mode_changed(GameManager.god_mode_enabled)
	
	rhythm_original_volume_db = $RhythmNotifier.audio_stream_player.volume_db
	
	$RhythmNotifier.audio_stream_player.play()
	$RhythmNotifier.beats(1).connect(_on_beat)
	
	DialogueBox.dialogue_started.connect(_on_dialogue_started)
	DialogueBox.dialogue_finished.connect(_on_dialogue_finished)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("god_mode"):
		GameManager.toggle_god_mode()
		get_viewport().set_input_as_handled()

func _on_god_mode_changed(enabled: bool) -> void:
	if not is_instance_valid(god_mode_overlay):
		god_mode_overlay = find_child("GodModeOverlay", true, false) as CanvasLayer
	if god_mode_overlay:
		god_mode_overlay.visible = enabled
	
	if not is_instance_valid(god_mode_player):
		god_mode_player = find_child("Player", true, false)
	if god_mode_player and god_mode_player.has_method("set_god_mode_enabled"):
		god_mode_player.set_god_mode_enabled(enabled)

func _on_beat(beat: int) -> void:
	get_tree().call_group("destructibles", "on_beat")

func _fade_rhythm_audio(target_db: float) -> void:
	if volume_tween:
		volume_tween.kill()

	volume_tween = create_tween()
	volume_tween.tween_property(
		$RhythmNotifier.audio_stream_player,
		"volume_db",
		target_db,
		0.2
	)

func _on_dialogue_started() -> void:
	_fade_rhythm_audio(-80.0)

func _on_dialogue_finished(_next_state: String = "") -> void:
	_fade_rhythm_audio(rhythm_original_volume_db)
