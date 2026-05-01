extends Resource
class_name DialogueSequence

class ParsedLine:
	var speaker: String
	var display_name_override: String
	var portrait_override_key: String
	var text: String

@export_file("*.txt") var dialogue_file: String
@export_multiline var raw_dialogue: String
@export var portrait_overrides: Dictionary[String, Texture2D] = {}
@export var next_state: String = ""
@export var reward_id: String = ""

var _parsed_lines: Array[ParsedLine] = []

func get_parsed_lines() -> Array[ParsedLine]:
	if not _parsed_lines.is_empty():
		return _parsed_lines
		
	var text_to_parse = ""
	
	if dialogue_file != "" and FileAccess.file_exists(dialogue_file):
		var file = FileAccess.open(dialogue_file, FileAccess.READ)
		if file:
			text_to_parse = file.get_as_text()
			file.close()
	else:
		text_to_parse = raw_dialogue
		
	if text_to_parse == "":
		return []
		
	var lines_str = text_to_parse.split("\n", false)
	for line_str in lines_str:
		var line_str_stripped = line_str.strip_edges()
		if line_str_stripped == "":
			continue
			
		var parsed = ParsedLine.new()
		
		# Find the first colon
		var colon_pos = line_str_stripped.find(":")
		if colon_pos != -1:
			var prefix = line_str_stripped.substr(0, colon_pos).strip_edges()
			parsed.text = line_str_stripped.substr(colon_pos + 1).strip_edges()
			
			# Parse prefix for speaker, display name, portrait
			# Format: Speaker(DisplayName)[Portrait]
			
			# Extract portrait
			var bracket_start = prefix.find("[")
			var bracket_end = prefix.find("]")
			if bracket_start != -1 and bracket_end != -1 and bracket_start < bracket_end:
				parsed.portrait_override_key = prefix.substr(bracket_start + 1, bracket_end - bracket_start - 1)
				prefix = prefix.substr(0, bracket_start) + prefix.substr(bracket_end + 1)
			
			# Extract display name
			var paren_start = prefix.find("(")
			var paren_end = prefix.find(")")
			if paren_start != -1 and paren_end != -1 and paren_start < paren_end:
				parsed.display_name_override = prefix.substr(paren_start + 1, paren_end - paren_start - 1)
				prefix = prefix.substr(0, paren_start) + prefix.substr(paren_end + 1)
			
			parsed.speaker = prefix.strip_edges()
		else:
			# Default if no colon
			parsed.speaker = "NPC"
			parsed.text = line_str_stripped
			
		_parsed_lines.append(parsed)
		
	return _parsed_lines
