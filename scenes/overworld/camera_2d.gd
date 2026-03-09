extends Camera2D

@export var smoothing_enabled := true
@export var smoothing_speed := 5.0
@export var look_ahead_distance := 50.0
@export var use_bounds := false
@export var bounds_rect := Rect2(0, 0, 1000, 1000)

func _ready():
	enabled = true
	position_smoothing_enabled = smoothing_enabled
	position_smoothing_speed = smoothing_speed
	
	if use_bounds:
		limit_left = int(bounds_rect.position.x)
		limit_top = int(bounds_rect.position.y)
		limit_right = int(bounds_rect.position.x + bounds_rect.size.x)
		limit_bottom = int(bounds_rect.position.y + bounds_rect.size.y)

func _process(delta):
	# Optional: camera looks ahead in movement direction
	if look_ahead_distance > 0:
		var parent = get_parent()
		if parent and parent.has_method("get_velocity"):
			var vel = parent.get_velocity()
			offset = vel.normalized() * look_ahead_distance * delta
