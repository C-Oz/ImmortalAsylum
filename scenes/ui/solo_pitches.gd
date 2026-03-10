extends Control

@onready var texture_rect_y = $Pitches/TextureRectY
@onready var texture_rect_b = $Pitches/TextureRectB
@onready var texture_rect_a = $Pitches/TextureRectA

var tex_y_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_y_1.png")
var tex_y_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_y_2.png")

var tex_b_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_b_1.png")
var tex_b_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_b_2.png")

var tex_a_1 = preload("res://assets/art/ui/ABXY/button_xbox_digital_a_1.png")
var tex_a_2 = preload("res://assets/art/ui/ABXY/button_xbox_digital_a_2.png")

func _process(_delta):
	# Check Y button (Xbox Y) or Q key
	if Input.is_joy_button_pressed(0, JOY_BUTTON_Y) or Input.is_physical_key_pressed(KEY_Q):
		texture_rect_y.texture = tex_y_2
	else:
		texture_rect_y.texture = tex_y_1

	# Check B button (Xbox B) or A key
	if Input.is_joy_button_pressed(0, JOY_BUTTON_B) or Input.is_physical_key_pressed(KEY_A):
		texture_rect_b.texture = tex_b_2
	else:
		texture_rect_b.texture = tex_b_1

	# Check A button (Xbox A) or Z key
	if Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.is_physical_key_pressed(KEY_Z):
		texture_rect_a.texture = tex_a_2
	else:
		texture_rect_a.texture = tex_a_1
