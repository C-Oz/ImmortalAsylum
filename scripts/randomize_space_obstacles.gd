@tool
extends EditorScript

# Paths to the 4 strictly requested instrument icons
const INSTRUMENTS = [
	"res://assets/art/instruments/drums_big.png",
	"res://assets/art/instruments/guitar_big.png",
	"res://assets/art/instruments/cello_big.png",
	"res://assets/art/instruments/clarinet_big.png"
]

const BUTTONS = ["Y", "B", "A"]

func _run():
	var root = get_scene()
	if not root:
		push_error("Obstacle Randomizer: No scene open in the editor.")
		return
		
	# Verification that we are in SpaceArea or a scene containing WorldContent
	var world_content = root.get_node_or_null("WorldContent")
	if not world_content:
		# If SpaceArea is the root itself or we are inside WorldContent
		if root.name == "WorldContent":
			world_content = root
		else:
			push_error("Obstacle Randomizer: Could not find 'WorldContent' node in the current scene. Please open SpaceArea.tscn.")
			return

	print("Obstacle Randomizer: Starting randomization in '", root.name, "'...")
	
	var obstacles = []
	_find_obstacles(world_content, obstacles)
	
	if obstacles.is_empty():
		print("Obstacle Randomizer: No obstacles with 'DestructionUI' found.")
		return
		
	print("Obstacle Randomizer: Found ", obstacles.size(), " obstacles.")
	
	# Load textures
	var textures = []
	for path in INSTRUMENTS:
		var tex = load(path)
		if tex:
			textures.append(tex)
		else:
			push_error("Obstacle Randomizer: Failed to load instrument texture at: " + path)
	
	if textures.is_empty():
		push_error("Obstacle Randomizer: No instrument textures could be loaded. Aborting.")
		return

	var instrument_count = textures.size()
	var processed_count = 0
	
	for i in range(obstacles.size()):
		var obstacle = obstacles[i]
		
		# 1. Deterministic Random Sequence (3-5 buttons)
		# We seed using the node's name so it's consistent across runs
		var rng = RandomNumberGenerator.new()
		rng.seed = hash(obstacle.name)
		
		var seq_length = rng.randi_range(3, 5)
		var sequence: Array[String] = []
		for j in range(seq_length):
			var btn = BUTTONS[rng.randi_range(0, BUTTONS.size() - 1)]
			sequence.append(btn)
		
		# Apply sequence to the obstacle node
		if "sequence" in obstacle:
			obstacle.set("sequence", sequence)
		
		# 2. Equal Instrument Distribution (Round-Robin)
		var ui = obstacle.get_node_or_null("DestructionUI")
		if ui and "instrument_icon" in ui:
			var tex = textures[i % instrument_count]
			ui.set("instrument_icon", tex)
		
		print("  - Randomized '", obstacle.name, "': Seq=", sequence, " Icon=", textures[i % instrument_count].resource_path.get_file())
		processed_count += 1

	print("Obstacle Randomizer: Successfully processed ", processed_count, " obstacles.")
	print("IMPORTANT: Changes are made to the scene tree. PLEASE SAVE THE SCENE (Ctrl+S) to hardcode them into the .tscn file.")

func _find_obstacles(node: Node, list: Array):
	# An obstacle is defined by having a DestructionUI child
	if node.has_node("DestructionUI"):
		list.append(node)
	
	# Recursively search children
	for child in node.get_children():
		_find_obstacles(child, list)
