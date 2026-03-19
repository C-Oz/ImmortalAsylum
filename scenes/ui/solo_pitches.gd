extends Control

@onready var texture_rect_y = $Pitches/TextureRectY
@onready var texture_rect_b = $Pitches/TextureRectB
@onready var texture_rect_a = $Pitches/TextureRectA

@onready var sound_y = $SoundY
@onready var sound_b = $SoundB
@onready var sound_a = $SoundA

var tex_y_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_y_1.png")
var tex_y_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_y_2.png")

var tex_b_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_b_1.png")
var tex_b_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_b_2.png")

var tex_a_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_a_1.png")
var tex_a_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_a_2.png")

var fade_in_speed: float = 0.5
var fade_out_speed: float = 0.5
var max_volume_linear: float = 1.0
var min_volume_db: float = -80.0

var vol_y_linear: float = 0.0
var vol_b_linear: float = 0.0
var vol_a_linear: float = 0.0

func _ready():
	sound_y.volume_db = min_volume_db
	sound_b.volume_db = min_volume_db
	sound_a.volume_db = min_volume_db
	
	sound_y.stop()
	sound_b.stop()
	sound_a.stop()

func _process(delta):

	var is_y_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_Y) or Input.is_physical_key_pressed(KEY_Q)
	if is_y_pressed:
		texture_rect_y.texture = tex_y_2
	else:
		texture_rect_y.texture = tex_y_1
		
	vol_y_linear = _update_linear_vol(is_y_pressed, vol_y_linear, delta)
	_process_audio(is_y_pressed, sound_y, vol_y_linear)

	var is_b_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_B) or Input.is_physical_key_pressed(KEY_A)
	if is_b_pressed:
		texture_rect_b.texture = tex_b_2
	else:
		texture_rect_b.texture = tex_b_1
		
	vol_b_linear = _update_linear_vol(is_b_pressed, vol_b_linear, delta)
	_process_audio(is_b_pressed, sound_b, vol_b_linear)

	var is_a_pressed = Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_physical_key_pressed(KEY_Z)
	if is_a_pressed:
		texture_rect_a.texture = tex_a_2
	else:
		texture_rect_a.texture = tex_a_1
		
	vol_a_linear = _update_linear_vol(is_a_pressed, vol_a_linear, delta)
	_process_audio(is_a_pressed, sound_a, vol_a_linear)

func _update_linear_vol(is_pressed: bool, current_linear: float, delta: float) -> float:
	if is_pressed:
		return move_toward(current_linear, max_volume_linear, fade_in_speed * delta)
	else:
		return move_toward(current_linear, 0.0, fade_out_speed * delta)

func _process_audio(is_pressed: bool, player: AudioStreamPlayer, current_linear: float):
	if is_pressed:
		if not player.playing:
			player.play()
	else:
		if current_linear <= 0.0 and player.playing:
			player.stop()
			
	if current_linear <= 0.0:
		player.volume_db = min_volume_db
	else:
		player.volume_db = max(min_volume_db, linear_to_db(current_linear))
