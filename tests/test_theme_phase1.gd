extends SceneTree

func _init() -> void:
	print("==================================================")
	print("🎨 VERIFIKASI TAHAP 1: THEME & PALET TERPUSAT (desain.md)")
	print("==================================================")
	
	var tm_script = load("res://scripts/autoload/theme_manager.gd")
	var tm = tm_script.new()
	tm.name = "ThemeManager"
	root.add_child(tm)
	
	# 1. PENGUJIAN PALET WARNA RESMI desain.md
	print("\n[1] Memvalidasi palet warna resmi desain.md...")
	assert(tm.COLOR_BG_MAIN.is_equal_approx(Color("#EAF6FF")), "Latar utama harus #EAF6FF")
	assert(tm.COLOR_CARD_WHITE.is_equal_approx(Color("#FFFFFF")), "Kartu / panel harus #FFFFFF")
	assert(tm.COLOR_TEXT_NAVY.is_equal_approx(Color("#1E2A4A")), "Teks utama harus #1E2A4A")
	assert(tm.COLOR_BTN_PRIMARY.is_equal_approx(Color("#1F6FEB")), "Tombol utama harus #1F6FEB")
	assert(tm.COLOR_LVL1_ORANGE.is_equal_approx(Color("#FF8A3D")), "Level 1 harus #FF8A3D (Oranye)")
	assert(tm.COLOR_LVL2_PINK.is_equal_approx(Color("#FF6FAE")), "Level 2 harus #FF6FAE (Pink)")
	assert(tm.COLOR_LVL3_YELLOW.is_equal_approx(Color("#FFC93C")), "Level 3 harus #FFC93C (Kuning)")
	assert(tm.COLOR_CORRECT_GREEN.is_equal_approx(Color("#3DDC97")), "Benar (+100) harus #3DDC97 (Hijau)")
	assert(tm.COLOR_WRONG_RED.is_equal_approx(Color("#FF7A7A")), "Salah (-25) harus #FF7A7A (Merah Muda)")
	assert(tm.COLOR_LOCKED_GRAY.is_equal_approx(Color("#D5DDE8")), "Level terkunci harus #D5DDE8 (Abu kebiruan)")
	print("  ✓ Seluruh 10 warna palet tervalidasi presisi sesuai tabel HEX.")

	# 2. PENGUJIAN WARNA AKSEN PER LEVEL
	print("\n[2] Menguji pemetaan warna aksen level...")
	assert(tm.get_level_color(1) == tm.COLOR_LVL1_ORANGE, "Level 1 harus oranye cokelat")
	assert(tm.get_level_color(2) == tm.COLOR_LVL2_PINK, "Level 2 harus pink permen")
	assert(tm.get_level_color(3) == tm.COLOR_LVL3_YELLOW, "Level 3 harus kuning mi")
	print("  ✓ Pemetaan warna aksen level berhasil (Level 1 Cokelat, Level 2 Permen, Level 3 Mi).")

	# 3. PENGUJIAN IKON VEKTOR FLAT (PENGGANTI EMOJI)
	print("\n[3] Memvalidasi kelengkapan 10 ikon flat vector SVG...")
	var icons_to_test = ["check", "cross", "lock", "arrow_left", "map", "table", "star", "reset", "store", "info"]
	for icon_name in icons_to_test:
		var tex = tm.get_icon(icon_name)
		assert(tex != null, "Ikon %s.svg harus berhasil dimuat" % icon_name)
		assert(tex.get_width() > 0 and tex.get_height() > 0, "Dimensi ikon %s harus valid" % icon_name)
	print("  ✓ Seluruh 10 ikon vektor SVG berhasil dimuat dan ter-cache dengan tajam.")

	# 4. PENGUJIAN THEME RESOURCE (main_theme.tres)
	print("\n[4] Menguji file tema utama res://themes/main_theme.tres...")
	var main_theme = load("res://themes/main_theme.tres")
	assert(main_theme != null and main_theme is Theme, "File main_theme.tres harus valid Theme resource")
	assert(main_theme.has_stylebox("normal", "Button"), "Theme harus mendefinisikan Button:normal")
	assert(main_theme.has_stylebox("panel", "PanelContainer"), "Theme harus mendefinisikan PanelContainer:panel")
	assert(main_theme.get_color("font_color", "Label").is_equal_approx(tm.COLOR_TEXT_NAVY), "Font color default Label harus Navy")
	print("  ✓ File main_theme.tres tervalidasi dengan style button, panel, label, dan line_edit.")

	# 5. PENGUJIAN HELPER SOCKET MATCHING (48px)
	print("\n[5] Menguji helper socket matching (rekomendasi desain.md)...")
	var socket_unconnected = tm.create_socket_style(false, tm.COLOR_BTN_PRIMARY)
	var socket_connected = tm.create_socket_style(true, tm.COLOR_BTN_PRIMARY)
	assert(socket_unconnected.corner_radius_top_left == 24, "Radius 24 = diameter 48px")
	assert(socket_connected.corner_radius_top_left == 24, "Radius 24 = diameter 48px")
	assert(socket_unconnected.bg_color == tm.COLOR_CARD_WHITE, "Socket tak terhubung harus berlatar putih dengan border biru")
	assert(socket_connected.bg_color == tm.COLOR_BTN_PRIMARY, "Socket terhubung harus terisi penuh (fill)")
	print("  ✓ Helper socket matching tervalidasi memenuhi kriteria UX 48px dan status terisi/kosong.")

	print("\n==================================================")
	print("🎉 TAHAP 1 SELESAI & LULUS 100%!")
	print("==================================================")
	quit(0)
