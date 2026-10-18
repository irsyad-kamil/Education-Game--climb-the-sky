extends Control

# Skrip untuk menggambar garis konektor pada soal Menjodohkan
func _draw() -> void:
	var quiz_scene = get_parent().get_parent().get_parent().get_parent()
	if not quiz_scene or not "connected_pairs" in quiz_scene:
		return

	var pairs: Dictionary = quiz_scene.connected_pairs
	var buttons: Dictionary = quiz_scene.socket_buttons

	for left_id in pairs.keys():
		var right_id = pairs[left_id]
		var btn_left: Button = buttons.get("L_" + left_id)
		var btn_right: Button = buttons.get("R_" + right_id)

		if btn_left and btn_right and btn_left.is_inside_tree() and btn_right.is_inside_tree():
			var start_pos = btn_left.global_position - global_position + (btn_left.size * 0.5)
			var end_pos = btn_right.global_position - global_position + (btn_right.size * 0.5)
			draw_line(start_pos, end_pos, Color(0.2, 0.85, 0.95, 0.85), 3.0, true)
