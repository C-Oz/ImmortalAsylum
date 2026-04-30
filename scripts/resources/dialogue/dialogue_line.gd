extends Resource
class_name DialogueLine

enum Speaker {
	NPC,
	PLAYER
}

@export var speaker: Speaker = Speaker.NPC
@export var display_name_override: String = ""
@export var portrait_override: Texture2D
@export_multiline var text: String = ""
