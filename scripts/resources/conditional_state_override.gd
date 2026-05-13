extends Resource
class_name ConditionalStateOverride

@export var required_base_state: String = "intro"
@export var required_skill_slot: String = ""
@export var required_skill_name: String = ""
@export var conditions: Dictionary[String, String] = {}
@export var override_state: String = "active"

func is_met(active_skills: Dictionary) -> bool:
	# Check legacy fields if they are set
	if required_skill_slot != "" and required_skill_name != "":
		if active_skills.get(required_skill_slot) != required_skill_name:
			return false
			
	# Check multiple conditions (AND logic)
	for slot in conditions:
		if active_skills.get(slot) != conditions[slot]:
			return false
			
	return true
