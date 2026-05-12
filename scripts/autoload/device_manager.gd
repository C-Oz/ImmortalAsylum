extends Node

enum Role { JOYSTICK, DPAD, BUTTONS }

@export var multi_controller_mode: bool = false:
	set(value):
		multi_controller_mode = value
		if is_node_ready():
			for role in role_map.keys():
				_update_input_map(role, role_map[role])

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

var controllers_locked: bool = false
var _base_action_events: Dictionary = {}

const GOD_MODE_RUMBLE_WEAK := 0.08
const GOD_MODE_RUMBLE_STRONG := 0.02

func _ready() -> void:
	_capture_base_action_events()
	
	if not GameManager.god_mode_changed.is_connected(_on_god_mode_changed):
		GameManager.god_mode_changed.connect(_on_god_mode_changed)
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	# Apply initial mappings to InputMap
	_on_god_mode_changed(GameManager.god_mode_enabled)

func _capture_base_action_events() -> void:
	for role in role_map.keys():
		for action in role_actions.get(role, []):
			if not InputMap.has_action(action) or _base_action_events.has(action):
				continue
			
			var events := []
			for event in InputMap.action_get_events(action):
				events.append(event.duplicate())
			_base_action_events[action] = events

func _on_god_mode_changed(enabled: bool) -> void:
	controllers_locked = enabled
	_update_all_input_maps()
	_release_role_actions()
	
	if controllers_locked:
		_start_god_mode_rumble()
	else:
		_stop_god_mode_rumble()

func _update_all_input_maps() -> void:
	for role in role_map.keys():
		_update_input_map(role, role_map[role])

func _release_role_actions() -> void:
	for role in role_actions.keys():
		for action in role_actions[role]:
			if InputMap.has_action(action):
				Input.action_release(action)

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if controllers_locked and connected:
		_start_god_mode_rumble_for_device(device)

func _get_rumble_devices() -> Array:
	var devices := []
	
	for device in Input.get_connected_joypads():
		if device >= 0 and not devices.has(device):
			devices.append(device)
	
	for device in role_map.values():
		if device >= 0 and not devices.has(device):
			devices.append(device)
	
	if devices.is_empty():
		devices.append(0)
	
	return devices

func _start_god_mode_rumble() -> void:
	for device in _get_rumble_devices():
		_start_god_mode_rumble_for_device(device)

func _start_god_mode_rumble_for_device(device: int) -> void:
	if device >= 0:
		Input.start_joy_vibration(device, GOD_MODE_RUMBLE_WEAK, GOD_MODE_RUMBLE_STRONG, 0.0)

func _stop_god_mode_rumble() -> void:
	for device in _get_rumble_devices():
		if device >= 0:
			Input.stop_joy_vibration(device)

func _resume_god_mode_rumble_after(device: int, duration: float) -> void:
	if duration <= 0.0:
		return
	
	await get_tree().create_timer(duration).timeout
	if controllers_locked:
		_start_god_mode_rumble_for_device(device)

func get_device(role: Role) -> int:
	if not multi_controller_mode:
		return 0 # All roles use primary controller
	return role_map.get(role, -1)  # -1 = unassigned

func assign(role: Role, device: int) -> void:
	role_map[role] = device
	_update_input_map(role, device)
	print("Assigned %s to device %d (%s)" % [
		Role.keys()[role], device, Input.get_joy_name(device) if device >= 0 else "Unassigned"
	])

func _update_input_map(role: Role, _device: int) -> void:
	if not role_actions.has(role):
		return
	
	# Use the resolved device ID which respects the toggle
	var target_device = get_device(role)
		
	for action in role_actions[role]:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			
			for base_event in _base_action_events.get(action, []):
				var event = base_event.duplicate()
				
				if controllers_locked and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
					continue
				
				if event is InputEventJoypadButton or event is InputEventJoypadMotion:
					event.device = target_device
				InputMap.action_add_event(action, event)

func is_device_connected(role: Role) -> bool:
	var device = get_device(role)
	return device >= 0 and Input.is_joy_known(device)

func vibrate(role: Role, weak: float, strong: float, duration: float) -> void:
	var device = get_device(role)
	if device >= 0:
		Input.start_joy_vibration(device, weak, strong, duration)
		if controllers_locked:
			_resume_god_mode_rumble_after(device, duration)
	else:
		# Fallback to device 0 if no specific device is assigned to the role
		Input.start_joy_vibration(0, weak, strong, duration)
		if controllers_locked:
			_resume_god_mode_rumble_after(0, duration)

func stop_vibrate(role: Role):
	var device = get_device(role)
	if device >= 0:
		Input.stop_joy_vibration(device)
		if controllers_locked:
			_start_god_mode_rumble_for_device(device)
	else:
		Input.stop_joy_vibration(0)
		if controllers_locked:
			_start_god_mode_rumble_for_device(0)
