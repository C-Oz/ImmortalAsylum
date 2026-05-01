extends Control

@onready var label: Label = %RewardLabel
@onready var icon_rect: TextureRect = %RewardIcon

# Configuration
var display_text: String = ""
var display_icon: Texture2D = null

func setup(text: String, icon: Texture2D = null) -> void:
	display_text = text
	display_icon = icon

func _ready() -> void:
	if label: 
		label.text = display_text
	
	if icon_rect:
		if display_icon:
			icon_rect.texture = display_icon
			# Enforce a reasonable icon size dynamically so big icons don't break the UI
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.custom_minimum_size = Vector2(128, 128)
		else:
			icon_rect.hide()
	
	# Start invisible
	modulate.a = 0.0 
	
	await get_tree().process_frame
	
	# Create animation tween
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in and float up slightly over 2 seconds
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.tween_property(self, "position:y", position.y - 100, 2.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Wait a bit, then fade back out
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(1.5)
	
	# Delete node when the entire animation finishes
	tween.chain().tween_callback(queue_free)
