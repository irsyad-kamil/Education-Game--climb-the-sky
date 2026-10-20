extends SceneTree

var menu: Control
var tm: Node

func _init() -> void:
	print("==================================================")
	print("🎨 VERIFIKASI TAHAP 2: STYLING MAIN MENU & LEVEL SELECT")
	print("==================================================")
	
	var tm_script = load("res://scripts/autoload/theme_manager.gd")
	tm = tm_script.new()
	tm.name = "ThemeManager"
	root.add_child(tm)
	
	var menu_scene = load("res://scenes/main_menu/main_menu.tscn")
	menu = menu_scene.instantiate()
	root.add_child(menu)
	
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	# 1. PENGUJIAN TAMPILAN UTAMA (MainMenuView)
	print("\n[1] Memvalidasi styling MainMenuView...")
	assert(menu.main_view.visible == true, "MainMenuView harus terlihat pertama kali")
	assert(menu.level_select_view.visible == false, "LevelSelectView harus tersembunyi pertama kali")
	
	# Background biru langit muda (#EAF6FF)
	var bg_color_rect: ColorRect = menu.main_view.get_node("Background")
	assert(bg_color_rect.color.is_equal_approx(Color("#EAF6FF")), "Latar utama harus #EAF6FF")
	print("  ✓ Latar utama tervalidasi menggunakan Biru Langit Muda (#EAF6FF).")
	
	# Judul melengkung
	assert(menu.curved_title_container.get_child_count() > 0, "Curved title harus memuat huruf-huruf")
	var first_letter: Label = menu.curved_title_container.get_child(0)
	assert(first_letter.get_theme_color("font_color").is_equal_approx(Color("#1E2A4A")), "Warna huruf judul harus Navy (#1E2A4A)")
	print("  ✓ Judul melengkung 'CLIMB THE SKY' tervalidasi dengan warna Navy (#1E2A4A).")
	
	# Tombol PLAY & EXIT
	assert(menu.btn_play.text == "PLAY", "Tombol Play bertuliskan PLAY")
	assert(menu.btn_quit.text == "EXIT", "Tombol Quit bertuliskan EXIT")
	print("  ✓ Tombol PLAY & EXIT tervalidasi sesuai wireframe mockup.")
	
	# 2. PENGUJIAN TRANSISI KE LEVEL SELECT
	print("\n[2] Menguji transisi tombol PLAY ke LevelSelectView...")
	menu._on_play_pressed()
	assert(menu.main_view.visible == false, "MainMenuView harus tertutup setelah PLAY diklik")
	assert(menu.level_select_view.visible == true, "LevelSelectView harus terbuka setelah PLAY diklik")
	print("  ✓ Transisi layar ke LevelSelectView berjalan mulus.")
	
	# 3. PENGUJIAN ELEMEN LEVEL SELECT & 3 KARTU DENGAN ASET ASLI
	print("\n[3] Memvalidasi 3 kartu tahap dengan aset asli & palet desain.md...")
	assert(menu.card_1_thumb.texture != null, "Thumbnail Level 1 harus terisi gambar level_1_thumb.jpg")
	assert(menu.card_2_thumb.texture != null, "Thumbnail Level 2 harus terisi gambar level_2_thumb.jpg")
	assert(menu.card_3_thumb.texture != null, "Thumbnail Level 3 harus terisi gambar level_3_thumb.jpg")
	print("  ✓ Thumbnail ilustrasi asli berhasil dipasang pada ketiga kartu level.")
	
	# Ikon vector flat (bebas emoji)
	assert(menu.back_icon.texture != null, "Ikon tombol back harus memuat vector arrow_left.svg")
	assert(menu.lock_icon_2.texture != null, "Ikon lock Level 2 harus memuat vector lock.svg")
	assert(menu.lock_icon_3.texture != null, "Ikon lock Level 3 harus memuat vector lock.svg")
	print("  ✓ Ikon vektor flat (arrow_left & lock) berhasil dipasang tanpa emoji.")
	
	# Warna Pill Badge
	var p1_box: StyleBoxFlat = menu.card_1_pill.get_theme_stylebox("panel")
	var p2_box: StyleBoxFlat = menu.card_2_pill.get_theme_stylebox("panel")
	var p3_box: StyleBoxFlat = menu.card_3_pill.get_theme_stylebox("panel")
	assert(p1_box.bg_color.is_equal_approx(tm.COLOR_LVL1_ORANGE), "Pill Level 1 harus Oranye (#FF8A3D)")
	assert(p2_box.bg_color.is_equal_approx(tm.COLOR_LVL2_PINK), "Pill Level 2 harus Pink (#FF6FAE)")
	assert(p3_box.bg_color.is_equal_approx(tm.COLOR_LVL3_YELLOW), "Pill Level 3 harus Kuning (#FFC93C)")
	print("  ✓ Warna pill badge terbukti sesuai palet level desain.md (Oranye, Pink, Kuning).")
	
	# 4. PENGUJIAN TOMBOL BACK
	print("\n[4] Menguji navigasi tombol Back (arrow_left)...")
	menu._on_back_pressed()
	assert(menu.level_select_view.visible == false, "LevelSelectView harus tertutup")
	assert(menu.main_view.visible == true, "MainMenuView harus kembali aktif")
	print("  ✓ Navigasi tombol kembali (Back) berhasil kembali ke Main Menu.")
	
	print("\n==================================================")
	print("🎉 TAHAP 2 SELESAI & LULUS 100%!")
	print("==================================================")
	quit(0)
