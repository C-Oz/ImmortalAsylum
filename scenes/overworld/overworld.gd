extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$RhythmNotifier.audio_stream_player.play()
	$RhythmNotifier.beats(1).connect(_on_beat)
	
	# PLACEHOLDER — delete this block when proper post-battle music system is in place
	if GameManager.returning_from_battle and GameManager.battle_victory:
		$DrumsPlaceholder.play()
	# END PLACEHOLDER


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_beat(beat: int) -> void:
	get_tree().call_group("destructibles", "on_beat")
