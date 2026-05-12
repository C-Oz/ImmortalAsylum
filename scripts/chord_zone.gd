extends Area2D

@export var chord_name: String = ""

const CHORD_ALIASES := {
	"Cmaj9 #11": "Cmaj9",
	"C#dim maj7 #9": "C#dim",
	"Bbm11": "Bbm9",
	"D7": "D7b9",
	"D7r": "D7b9",
	"F7 #11": "F#9#11",
	"F7#9": "F#9",
	"F halfdim": "Fhalfdim",
	"Ebm maj9sssss": "Ebm maj9",
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	call_deferred("_apply_to_overlapping_player")

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	var resolved_chord := _resolve_chord_name()
	if resolved_chord == "":
		return

	if _has_doormat_sounds(resolved_chord):
		GameManager.current_chord_zone = resolved_chord
		return

	push_warning("Chord zone '%s' resolved to '%s', but no matching doormat sounds were loaded." % [name, resolved_chord])

func _apply_to_overlapping_player() -> void:
	await get_tree().physics_frame

	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_body_entered(body)
			return

func _resolve_chord_name() -> String:
	if chord_name.strip_edges() != "":
		return _normalize_chord_name(chord_name)

	var resolved_name := String(name).trim_suffix("(SB)").strip_edges()
	return _normalize_chord_name(resolved_name)

func _normalize_chord_name(raw_chord_name: String) -> String:
	var resolved_name := raw_chord_name.strip_edges()
	var prefix := ""

	if resolved_name.begins_with("Space_"):
		prefix = "Space_"
		resolved_name = resolved_name.trim_prefix("Space_").strip_edges()

	return prefix + String(CHORD_ALIASES.get(resolved_name, resolved_name))

func _has_doormat_sounds(resolved_chord: String) -> bool:
	return AudioManager.doormat_sounds.has(resolved_chord)
