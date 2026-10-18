extends Control

# Skrip untuk menggambar garis penghubung antar-simpul peta
func _draw() -> void:
	var map_scene = get_parent().get_parent()
	if not map_scene or not "map_data" in map_scene:
		return

	var nodes_dict: Dictionary = map_scene.map_data.get("nodes", {})
	var positions: Dictionary = map_scene.node_positions

	for node_id in nodes_dict.keys():
		var node: MapGenerator.MapNode = nodes_dict[node_id]
		if not positions.has(node_id):
			continue

		var start_pos: Vector2 = positions[node_id]

		for target_id in node.connections:
			if positions.has(target_id):
				var end_pos: Vector2 = positions[target_id]
				# Garis redup untuk jalur umum, garis terang untuk jalur yang sedang dilewati
				var line_color = Color(0.4, 0.45, 0.55, 0.5)
				if node_id == GameState.current_node_id:
					line_color = Color(1.0, 0.85, 0.4, 0.9) # Garis emas menuju opsi pilihan
				
				draw_line(start_pos, end_pos, line_color, 3.0, true)
