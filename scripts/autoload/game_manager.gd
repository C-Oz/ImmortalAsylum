extends Node

signal scene_changed(scene_name: String)
signal battle_completed(npc_id: String, victory: bool)
signal progression_updated

var current_npc_id: String = ""
var returning_from_battle: bool = false
var battle_victory: bool = false
var saved_player_position: Vector2 = Vector2.ZERO
var saved_overworld_scene: String = ""

var total_battles_won: int = 0
var solo_pitches_unlocked: bool = false
var cycling_unlocked: bool = false

var unlocked_skills: Dictionary = {
	"up": true,
	"down": true,
	"left": true,
	"right": false
}

func change_scene(scene_path: String) -> void:
	scene_changed.emit(scene_path)
	get_tree().change_scene_to_file(scene_path)

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
		
	var return_scene = saved_overworld_scene if saved_overworld_scene != "" else "res://scenes/overworld/EastArea.tscn"
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
