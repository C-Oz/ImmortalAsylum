extends Resource
class_name PortraitSet

@export var portraits: Dictionary[String, MoodPortrait] = {}

func get_portrait(mood_key: String) -> Texture2D:
	var mood_data: MoodPortrait = null
	
	if mood_key != "" and portraits.has(mood_key):
		mood_data = portraits[mood_key]
	
	if not mood_data and portraits.has("default"):
		mood_data = portraits["default"]
		
	if not mood_data and portraits.size() > 0:
		mood_data = portraits.values()[0]
	
	return mood_data # This is a Texture2D (AtlasTexture) with the region already built-in!
