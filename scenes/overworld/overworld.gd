extends Node2D

# PLACEHOLDER — delete this flag when proper post-battle music system is in place
var _play_drums_on_ready: bool = false

func _enter_tree() -> void:
	# Capture battle state here (top-down) before boss._ready() clears it (bottom-up)
	_play_drums_on_ready = GameManager.returning_from_battle and GameManager.battle_victory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$RhythmNotifier.audio_stream_player.play()
	$RhythmNotifier.beats(1).connect(_on_beat)
	
	# PLACEHOLDER — delete this block when proper post-battle music system is in place
	if _play_drums_on_ready:
		$DrumsPlaceholder.play()
	# END PLACEHOLDER


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_beat(beat: int) -> void:
	get_tree().call_group("destructibles", "on_beat")
