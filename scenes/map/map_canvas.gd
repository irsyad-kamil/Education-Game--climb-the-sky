extends Control

# MapCanvas v2.0 (Modern Light Palette desain.md)
# Menggambar garis jalur vertikal linear naik ke atas dari Titik 1 ke Titik N

func _draw() -> void:
	var map_scene = get_parent().get_parent()
	if not map_scene:
		return

	var positions: Dictionary = map_scene.get("point_positions") if "point_positions" in map_scene else {}
	var total_points: int = map_scene.get("total_points") if "total_points" in map_scene else 0
	var current_point: int = map_scene.get("current_point") if "current_point" in map_scene else 1

	if total_points <= 1 or positions.is_empty():
		return

	var gs = map_scene.call("_get_gs") if map_scene.has_method("_get_gs") else null
	var tm = map_scene.call("_get_tm") if map_scene.has_method("_get_tm") else null
	var lvl = gs.current_level if gs else 1
	var lvl_color = tm.get_level_color(lvl) if tm else Color("#FF8A3D")

	for p in range(1, total_points):
		if not positions.has(p) or not positions.has(p + 1):
			continue

		var start_pos: Vector2 = positions[p]
		var end_pos: Vector2 = positions[p + 1]

		# 1. Jalur dasar (Track border lembut)
		draw_line(start_pos, end_pos, Color(0.82, 0.87, 0.93, 1.0), 14.0, true)
		draw_line(start_pos, end_pos, Color(1.0, 1.0, 1.0, 0.95), 8.0, true)

		# 2. Jalur progres warna
		if (p + 1) < current_point:
			# Segmen selesai sepenuhnya: Hijau #3DDC97
			draw_line(start_pos, end_pos, tm.COLOR_CORRECT_GREEN if tm else Color("#3DDC97"), 6.0, true)
		elif (p + 1) == current_point:
			# Segmen aktif menuju current_point: Warna aksen level aktif
			draw_line(start_pos, end_pos, lvl_color, 6.0, true)
		else:
			# Segmen terkunci ke atas: Abu-abu redup
			draw_line(start_pos, end_pos, Color(0.75, 0.82, 0.90, 0.6), 4.0, true)
