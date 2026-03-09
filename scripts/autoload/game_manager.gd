extends Node

signal scene_changed(scene_name: String)
signal battle_completed(npc_id: String, victory: bool)

var current_npc_id: String = ""
var returning_from_battle: bool = false
var battle_victory: bool = false
var saved_player_position: Vector2 = Vector2.ZERO

func change_scene(scene_path: String) -> void:
	scene_changed.emit(scene_path)
	get_tree().change_scene_to_file(scene_path)

func start_battle(npc_id: String, player_position: Vector2) -> void:
	current_npc_id = npc_id
	saved_player_position = player_position
	returning_from_battle = false
	change_scene("res://scenes/battle/battle.tscn")

func return_to_overworld(victory: bool) -> void:
	battle_victory = victory
	returning_from_battle = true
	change_scene("res://scenes/overworld/overworld.tscn")

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
