extends Node

enum Role { JOYSTICK, DPAD, BUTTONS }

var role_map: Dictionary = {
	Role.JOYSTICK: 0,
	Role.BUTTONS:  1,
	Role.DPAD:     2,
}

var role_actions: Dictionary = {
	Role.JOYSTICK: ["move_left", "move_right", "move_up", "move_down", "interact"],
	Role.DPAD: ["dpad_up", "dpad_down", "dpad_left", "dpad_right"],
	Role.BUTTONS: ["joy_y", "joy_b", "joy_a", "solo_toggle"]
}

func _ready() -> void:
	# Apply initial mappings to InputMap
	for role in role_map.keys():
		_update_input_map(role, role_map[role])

func get_device(role: Role) -> int:
	return role_map.get(role, -1)  # -1 = unassigned

func assign(role: Role, device: int) -> void:
	role_map[role] = device
	_update_input_map(role, device)
	print("Assigned %s to device %d (%s)" % [
		Role.keys()[role], device, Input.get_joy_name(device) if device >= 0 else "Unassigned"
	])

func _update_input_map(role: Role, device: int) -> void:
	if not role_actions.has(role):
		return
		
	for action in role_actions[role]:
		if InputMap.has_action(action):
			var events = InputMap.action_get_events(action)
			InputMap.action_erase_events(action)
			
			for event in events:
				# Update device for joypad events only, leaving keyboard events as -1 (all devices)
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					event.device = device
				InputMap.action_add_event(action, event)

func is_device_connected(role: Role) -> bool:
	var device = get_device(role)
	return device >= 0 and Input.is_joy_known(device)

func vibrate(role: Role, weak: float, strong: float, duration: float) -> void:
	var device = get_device(role)
	if device >= 0:
		Input.start_joy_vibration(device, weak, strong, duration)
	else:
		# Fallback to device 0 if no specific device is assigned to the role
		Input.start_joy_vibration(0, weak, strong, duration)

func stop_vibrate(role: Role):
	var device = get_device(role)
	if device >= 0:
		Input.stop_joy_vibration(device)
	else:
		Input.stop_joy_vibration(0)
