extends Node

signal scene_changed(scene_name: String)
signal progression_updated
signal reward_granted(reward_id: String)
signal god_mode_changed(enabled: bool)

var unlocked_rewards: Dictionary = {}
var god_mode_enabled: bool = false
var god_mode_speed_multiplier: float = 3.0
var active_skills: Dictionary = {
	"dpad_up": "Box 1",
	"dpad_down": "Box 1",
	"dpad_left": "Box 1",
	"dpad_right": "Box 1"
}

func set_god_mode_enabled(enabled: bool) -> void:
	if god_mode_enabled == enabled:
		return
	
	god_mode_enabled = enabled
	god_mode_changed.emit(god_mode_enabled)

func toggle_god_mode() -> void:
	set_god_mode_enabled(not god_mode_enabled)

func set_active_skill(action: String, skill_name: String) -> void:
	active_skills[action] = skill_name
	
var current_npc_id: String = ""
var returning_from_battle: bool = false
var battle_victory: bool = false
var saved_player_position: Vector2 = Vector2.ZERO
var saved_overworld_scene: String = ""

var total_battles_won: int = 0
var solo_pitches_unlocked: bool = true
var cycling_unlocked: bool = false
var current_chord_zone: String = "Am9"

var pending_portal_name: StringName = &""
var scene_object_states: Dictionary = {} # Stores states indexed by [scene_path][node_path]

var control_timer: Timer
var timer_sfx_player: AudioStreamPlayer

var npc_states: Dictionary = {} # Stores String states indexed by NPC ID (e.g. "intro", "active", "perma")

var player_name: String = "Giratran"
var player_portrait: Texture2D
var player_portrait_set: Resource # PortraitSet

var unlocked_skills: Dictionary = {
	"up": true,
	"down": true,
	"left": true,
	"right": true
}

var game_over_overlay_scene = preload("res://scenes/ui/GameOverOverlay.tscn")
var game_over_overlay: CanvasLayer
var timer_has_started: bool = false
var has_win_collectible: bool = false

func _ready() -> void:
	# Create a persistent timer node that lives inside the Autoload
	control_timer = Timer.new()
	control_timer.name = "ControlTimer"
	control_timer.one_shot = true
	control_timer.wait_time = 2520.0 # 45 minutes 2700
	add_child(control_timer)
	
	timer_sfx_player = AudioStreamPlayer.new()
	timer_sfx_player.name = "PlayerChangeFx"
	timer_sfx_player.stream = load("res://assets/sfx/SFX player switch v1 [2026-04-01 032029].wav")
	control_timer.add_child(timer_sfx_player)
	
	control_timer.timeout.connect(_on_control_timer_timeout)
	
	player_portrait_set = load("res://scripts/resources/dialogue/player_portraits.tres")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("god_mode"):
		toggle_god_mode()
	
	if not god_mode_enabled:
		return
	
	if event.is_action_pressed("start_tutorial"):
		change_scene("res://scenes/overworld/Tutorial.tscn")
	elif event.is_action_pressed("start_east"):
		change_scene("res://scenes/overworld/EastArea2.tscn")
	elif event.is_action_pressed("start_space"):
		change_scene("res://scenes/overworld/SpaceArea.tscn")
	
	if event.is_action_pressed("debug_add_timer"):
		_debug_adjust_timer(60.0)
	elif event.is_action_pressed("debug_sub_timer"):
		_debug_adjust_timer(-60.0)

func _debug_adjust_timer(delta: float) -> void:
	if not timer_has_started: return
	var new_time = max(0.1, control_timer.time_left + delta)
	control_timer.start(new_time)

func _process(_delta: float) -> void:
	_update_glitch_apocalypse()

func collect_win_item() -> void:
	has_win_collectible = true
	progression_updated.emit()

func _update_glitch_apocalypse() -> void:
	if not timer_has_started:
		if is_instance_valid(game_over_overlay):
			game_over_overlay.visible = false
		return
		
	if not control_timer.is_stopped() and control_timer.time_left > 300.0:
		if is_instance_valid(game_over_overlay):
			game_over_overlay.visible = false
		return
	
	if not is_instance_valid(game_over_overlay):
		game_over_overlay = game_over_overlay_scene.instantiate()
		add_child(game_over_overlay)
	
	game_over_overlay.visible = true
	var time_left = control_timer.time_left
	var urgency = 1.0
	if not control_timer.is_stopped():
		urgency = (300.0 - time_left) / 300.0 # 0.0 to 1.0
	
	var color_rect = game_over_overlay.get_node("ColorRect")
	var white_screen = game_over_overlay.get_node_or_null("WhiteScreen")
	
	if has_win_collectible:
		color_rect.visible = false
		if white_screen:
			white_screen.visible = true
			white_screen.modulate.a = urgency
	else:
		color_rect.visible = true
		var material = color_rect.material as ShaderMaterial
		if material:
			material.set_shader_parameter("glitch_intensity", lerp(0.0, 0.05, urgency))
			material.set_shader_parameter("static_amount", lerp(0.0, 1.0, urgency))
			material.set_shader_parameter("speed", lerp(2.0, 10.0, urgency))
		if white_screen:
			white_screen.visible = false

func start_global_game_timer() -> void:
	if control_timer.is_stopped():
		control_timer.start()
		timer_has_started = true

func get_formatted_game_time() -> String:
	var total_seconds = int(control_timer.time_left)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _on_control_timer_timeout() -> void:
	if is_instance_valid(game_over_overlay):
		if has_win_collectible:
			var white_screen = game_over_overlay.get_node_or_null("WhiteScreen")
			if white_screen:
				white_screen.visible = true
				white_screen.modulate.a = 1.0
		else:
			var black_screen = game_over_overlay.get_node_or_null("BlackScreen")
			if black_screen:
				black_screen.visible = true
	
	if cycling_unlocked:
		timer_sfx_player.play()

func adjust_timer(delta: float) -> void:
	if delta <= 0: return # Only additions now
	
	var new_time = control_timer.time_left + delta
	control_timer.start(new_time)

func change_scene(scene_path: String) -> void:
	scene_changed.emit(scene_path)
	get_tree().change_scene_to_file(scene_path)

func save_object_state(node: Node, value: Variant) -> void:
	var scene_root = get_tree().current_scene
	if not scene_root or scene_root.scene_file_path == "":
		return
	
	var scene_path = scene_root.scene_file_path
	var node_path = String(scene_root.get_path_to(node))
	
	if not scene_object_states.has(scene_path):
		scene_object_states[scene_path] = {}
	
	scene_object_states[scene_path][node_path] = value

func get_object_state(node: Node, default: Variant = null) -> Variant:
	var scene_root = get_tree().current_scene
	if not scene_root or scene_root.scene_file_path == "":
		return default
	
	var scene_path = scene_root.scene_file_path
	var node_path = String(scene_root.get_path_to(node))
	
	if scene_object_states.has(scene_path):
		return scene_object_states[scene_path].get(node_path, default)
	
	return default

#func start_battle(npc_id: String, player_position: Vector2, battle_scene: PackedScene = null) -> void:
	#current_npc_id = npc_id
	#saved_player_position = player_position
	#saved_overworld_scene = get_tree().current_scene.scene_file_path
	#returning_from_battle = false
	#if battle_scene:
		#get_tree().change_scene_to_packed(battle_scene)
	#else:
		#change_scene("res://scenes/battle/battle.tscn")

func return_to_overworld(victory: bool) -> void:
	#battle_victory = victory
	#returning_from_battle = true
	#
	#if victory:
		#total_battles_won += 1
		#evaluate_progression()
		
	var return_scene = saved_overworld_scene if saved_overworld_scene != "" else "res://scenes/overworld/EastArea2.tscn"
	change_scene(return_scene)

#func evaluate_progression() -> void:
	## Flexible progression logic based on battle wins
	#if total_battles_won >= 1:
		#solo_pitches_unlocked = true
		#cycling_unlocked = true
	#if total_battles_won >= 2:
		#unlocked_skills["right"] = true
	#progression_updated.emit()

#func get_battle_result() -> Dictionary:
	#return {
		#"npc_id": current_npc_id,
		#"victory": battle_victory,
		#"returning": returning_from_battle
	#}

#func clear_battle_data() -> void:
	#current_npc_id = ""
	#returning_from_battle = false
	#battle_victory = false
	#saved_player_position = Vector2.ZERO
	#saved_overworld_scene = ""

func set_npc_state(id: String, state: String) -> void:
	npc_states[id] = state
	progression_updated.emit()

func get_npc_state(id: String) -> String:
	return npc_states.get(id, "first")

func grant_reward(reward_id: String) -> void:
	if reward_id == "" or unlocked_rewards.has(reward_id):
		return
	unlocked_rewards[reward_id] = true
	reward_granted.emit(reward_id)
	progression_updated.emit()

func travel_through_portal(scene_path: String, destination_portal_name: StringName) -> void:
	pending_portal_name = destination_portal_name
	returning_from_battle = false
	saved_player_position = Vector2.ZERO
	saved_overworld_scene = ""
	change_scene(scene_path)

func has_pending_portal_spawn() -> bool:
	return pending_portal_name != &""

func consume_pending_portal_name() -> StringName:
	var portal_name := pending_portal_name
	pending_portal_name = &""
	return portal_name
