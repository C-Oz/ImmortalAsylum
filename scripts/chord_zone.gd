extends Area2D

@export var chord_name: String = ""
@export var zone_music: AudioStream
@export var zone_ambience: AudioStream
@export var crossfade_time: float = 1.5

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if chord_name != "":
			GameManager.current_chord_zone = chord_name
		AudioManager.transition_to(zone_music, zone_ambience, crossfade_time)

func _on_body_exited(body: Node2D) -> void:
	pass # AudioManager handles overlap priority
