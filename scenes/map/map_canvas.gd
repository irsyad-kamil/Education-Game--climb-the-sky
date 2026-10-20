extends Control

# MapCanvas v1.0 (GDD v1.0 Architecture)
# Menggambar garis jalur vertikal linear menghubungkan titik-titik pendakian langit

func _draw() -> void:
	var map_scene = get_parent().get_parent()
	if not map_scene:
		return

	var positions: Dictionary = map_scene.get("point_positions") if "point_positions" in map_scene else {}
	var total_points: int = map_scene.get("total_points") if "total_points" in map_scene else 0
	var current_point: int = map_scene.get("current_point") if "current_point" in map_scene else 1

	if total_points <= 1 or positions.is_empty():
		return

	for p in range(1, total_points):
		if not positions.has(p) or not positions.has(p + 1):
			continue

		var start_pos: Vector2 = positions[p]
		var end_pos: Vector2 = positions[p + 1]

		# 1. Garis dasar / latar belakang jalur
		draw_line(start_pos, end_pos, Color(0.12, 0.15, 0.22, 0.9), 10.0, true)

		# 2. Garis status warna
		if (p + 1) < current_point:
			# Jalur yang sudah selesai sepenuhnya
			draw_line(start_pos, end_pos, Color(0.3, 0.85, 0.5, 0.9), 4.0, true)
		elif (p + 1) == current_point:
			# Jalur menuju titik yang sedang aktif
			draw_line(start_pos, end_pos, Color(1.0, 0.85, 0.3, 0.95), 5.0, true)
		else:
			# Jalur yang masih terkunci ke atas
			draw_line(start_pos, end_pos, Color(0.3, 0.35, 0.45, 0.6), 3.0, true)
