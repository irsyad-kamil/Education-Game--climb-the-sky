extends Control

var preview_owner: Node = null

func _draw() -> void:
	if not preview_owner or not "node_positions" in preview_owner:
		return

	var positions: Dictionary = preview_owner.node_positions
	var map_data: Dictionary = preview_owner.map_data
	var nodes_dict: Dictionary = map_data.get("nodes", {})

	for node_id in nodes_dict.keys():
		var node: MapGenerator.MapNode = nodes_dict[node_id]
		if not positions.has(node_id):
			continue

		var start_pos: Vector2 = positions[node_id]

		for target_id in node.connections:
			if positions.has(target_id):
				var end_pos: Vector2 = positions[target_id]
				var line_color = Color(0.4, 0.45, 0.55, 0.5)
				if node_id == GameState.current_node_id:
					line_color = Color(1.0, 0.85, 0.4, 0.95)
				draw_line(start_pos, end_pos, line_color, 3.0, true)
