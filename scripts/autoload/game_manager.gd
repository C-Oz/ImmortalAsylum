extends Node

signal scene_changed(scene_name: String)
signal progression_updated
signal reward_granted(reward_id: String)

var unlocked_rewards: Dictionary = {}
var active_skills: Dictionary = {
	"dpad_up": "Box 1",
	"dpad_down": "Box 1",
	"dpad_left": "Box 1",
	"dpad_right": "Box 1"
}

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

var unlocked_skills: Dictionary = {
	"up": true,
	"down": true,
	"left": true,
	"right": true
}

func _ready() -> void:
	# Create a persistent timer node that lives inside the Autoload
	control_timer = Timer.new()
	control_timer.name = "ControlTimer"
	control_timer.one_shot = false
	control_timer.wait_time = 180.0
	add_child(control_timer)
	
	timer_sfx_player = AudioStreamPlayer.new()
	timer_sfx_player.name = "PlayerChangeFx"
	timer_sfx_player.stream = load("res://assets/sfx/SFX player switch v1 [2026-04-01 032029].wav")
	control_timer.add_child(timer_sfx_player)
	
	control_timer.timeout.connect(_on_control_timer_timeout)
	control_timer.start()
	
	player_portrait = load("res://assets/art/p1.PNG")

func _on_control_timer_timeout() -> void:
	if cycling_unlocked:
		timer_sfx_player.play()

func adjust_timer(delta: float) -> void:
	var new_time = max(0.1, control_timer.time_left + delta)
	# start(new_time) sets the duration for the CURRENT run.
	# We then reset wait_time so the NEXT automatic loop uses 180.
	control_timer.start(new_time)
	control_timer.wait_time = 180.0

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

func start_battle(npc_id: String, player_position: Vector2, battle_scene: PackedScene = null) -> void:
	current_npc_id = npc_id
	saved_player_position = player_position
	saved_overworld_scene = get_tree().current_scene.scene_file_path
	returning_from_battle = false
	if battle_scene:
		get_tree().change_scene_to_packed(battle_scene)
	else:
		change_scene("res://scenes/battle/battle.tscn")

func return_to_overworld(victory: bool) -> void:
	battle_victory = victory
	returning_from_battle = true
	
	if victory:
		total_battles_won += 1
		evaluate_progression()
		
	var return_scene = saved_overworld_scene if saved_overworld_scene != "" else "res://scenes/overworld/EastArea2.tscn"
	change_scene(return_scene)

func evaluate_progression() -> void:
	# Flexible progression logic based on battle wins
	if total_battles_won >= 1:
		solo_pitches_unlocked = true
		cycling_unlocked = true
	if total_battles_won >= 2:
		unlocked_skills["right"] = true
	progression_updated.emit()

func get_battle_result() -> Dictionary:
	return {
		"npc_id": current_npc_id,
		"victory": battle_victory,
		"returning": returning_from_battle
	}

func clear_battle_data() -> void:
	current_npc_id = ""
	returning_from_battle = false
	battle_victory = false
	saved_player_position = Vector2.ZERO
	saved_overworld_scene = ""

func set_npc_state(id: String, state: String) -> void:
	npc_states[id] = state
	progression_updated.emit()

func get_npc_state(id: String) -> String:
	return npc_states.get(id, "intro")

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
