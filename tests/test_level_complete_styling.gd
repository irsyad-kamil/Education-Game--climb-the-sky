extends SceneTree

# Test LevelCompleteModal Phase 5 Styling (desain.md)
# Memverifikasi tampilan pop-up perayaan penyelesaian level:
# - Bima avatar senang.jpg
# - Header banner dengan warna aksen level
# - Card skor & skor terbaik dengan icon star.svg
# - Banner unlock materi dengan icon check.svg
# - Tombol aksi navigasi bersih tanpa emoji

var dm: Node
var gs: Node
var tm: Node
var quiz: Control

func _init() -> void:
	print("==================================================")
	print("🎨 VERIFIKASI TAHAP 5: STYLING LEVEL COMPLETE MODAL (desain.md)")
	print("==================================================")

	var dm_script = load("res://scripts/autoload/data_manager.gd")
	dm = dm_script.new()
	dm.name = "DataManager"
	root.add_child(dm)

	var gs_script = load("res://scripts/autoload/game_state.gd")
	gs = gs_script.new()
	gs.name = "GameState"
	gs.data_manager_ref = dm
	root.add_child(gs)

	var tm_script = load("res://scripts/autoload/theme_manager.gd")
	tm = tm_script.new()
	tm.name = "ThemeManager"
	root.add_child(tm)

	gs.start_level(1)

	var quiz_scene = load("res://scenes/quiz/quiz_scene.tscn")
	quiz = quiz_scene.instantiate()
	root.add_child(quiz)

	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	var modal: Control = quiz.level_complete_modal
	assert(modal != null, "LevelCompleteModal harus terpasang di QuizScene")

	# 1. VERIFIKASI SETUP LEVEL 1
	print("\n[1] Memvalidasi LevelCompleteModal untuk Level 1 (Cokelat - Mean)...")
	modal.setup_level_complete(1, 400, 400)
	assert(modal.visible == true, "Modal harus terlihat setelah setup_level_complete")
	assert("LEVEL 1" in modal.title_label.text and "SELESAI" in modal.title_label.text, "Judul harus memuat LEVEL 1 dan SELESAI")
	assert(not "🎉" in modal.title_label.text, "Judul modal tidak boleh menggunakan emoji")
	
	# Avatar Bima
	assert(modal.bima_avatar.texture != null, "Bima avatar harus memuat gambar")
	var tex_senang = tm.get_bima_avatar("senang")
	assert(modal.bima_avatar.texture == tex_senang, "Bima avatar harus senang.jpg saat level selesai")
	print("  ✓ Bima avatar senang.jpg terpasang dengan dialog apresiatif.")

	# Header Accent Color Level 1 (#FF8A3D)
	var header_sb = modal.header_banner.get_theme_stylebox("panel") as StyleBoxFlat
	assert(header_sb != null, "Header harus menggunakan StyleBoxFlat")
	assert(header_sb.bg_color.is_equal_approx(tm.COLOR_LVL1_ORANGE), "Warna header Level 1 harus Oranye #FF8A3D")
	print("  ✓ Header modal menggunakan warna aksen Level 1 (#FF8A3D).")

	# Skor & Best Score Cards
	assert("400 Poin" in modal.score_value.text, "ScoreValue harus menampilkan '400 Poin'")
	assert("400 Poin" in modal.best_value.text, "BestValue harus menampilkan '400 Poin'")
	assert(modal.score_star_icon.texture != null, "ScoreStarIcon harus memuat star.svg")
	assert(modal.best_star_icon.texture != null, "BestStarIcon harus memuat star.svg")
	print("  ✓ Ringkasan skor & skor terbaik memuat ikon vector star.svg.")

	# Unlock Announcement Level 1 -> Buka Level 2
	assert(modal.unlock_icon.texture != null, "UnlockIcon harus memuat check.svg")
	assert("Level 2" in modal.unlock_text.text, "Teks unlock harus mengumumkan terbukanya Level 2")
	assert(not "🔓" in modal.unlock_text.text, "Teks unlock tidak boleh menggunakan emoji")
	print("  ✓ Pengumuman unlock Level 2 terverifikasi dengan ikon vector check.svg.")

	# Action Buttons
	assert(modal.btn_menu.icon != null, "BtnMenu harus memiliki icon arrow_left.svg")
	assert(modal.btn_continue.icon != null, "BtnContinue harus memiliki icon map.svg")
	assert(not "🚪" in modal.btn_menu.text, "BtnMenu tidak boleh menggunakan emoji")
	assert(not "➡️" in modal.btn_continue.text, "BtnContinue tidak boleh menggunakan emoji")
	print("  ✓ Tombol aksi terbukti bersih tanpa emoji dan berikon flat vector.")

	# 2. VERIFIKASI SETUP LEVEL 2
	print("\n[2] Memvalidasi LevelCompleteModal untuk Level 2 (Permen - Median)...")
	modal.setup_level_complete(2, 350, 400)
	var h_sb_lvl2 = modal.header_banner.get_theme_stylebox("panel") as StyleBoxFlat
	assert(h_sb_lvl2.bg_color.is_equal_approx(tm.COLOR_LVL2_PINK), "Warna header Level 2 harus Pink #FF6FAE")
	assert("Level 3" in modal.unlock_text.text, "Level 2 selesai harus mengumumkan Level 3 terbuka")
	print("  ✓ Header aksen Pink (#FF6FAE) & pengumuman Level 3 terverifikasi.")

	# 3. VERIFIKASI SETUP LEVEL 3 (TAMAT)
	print("\n[3] Memvalidasi LevelCompleteModal untuk Level 3 (Mi Instan - Komparatif)...")
	modal.setup_level_complete(3, 300, 300)
	var h_sb_lvl3 = modal.header_banner.get_theme_stylebox("panel") as StyleBoxFlat
	assert(h_sb_lvl3.bg_color.is_equal_approx(tm.COLOR_LVL3_YELLOW), "Warna header Level 3 harus Kuning #FFC93C")
	assert("berhasil kamu kuasai" in modal.unlock_text.text, "Level 3 tamat harus memuat pesan penguasaan seluruh materi")
	print("  ✓ Header aksen Kuning (#FFC93C) & pengumuman kelulusan seluruh materi terverifikasi.")

	# 4. VERIFIKASI TRIGGER OTOMATIS DARI QUIZ SCENE SAAT TITIK TERAKHIR
	print("\n[4] Memvalidasi trigger otomatis modal saat menyelesaikan titik terakhir...")
	modal.hide_modal()
	assert(modal.visible == false, "Modal harus tertutup sebelum trigger")
	gs.current_point_index = dm.get_total_points(1)
	gs.level_score = 450
	quiz._on_next_point_pressed()
	assert(modal.visible == true, "Menekan Selesaikan Level di titik terakhir harus otomatis membuka LevelCompleteModal")
	print("  ✓ Selesaikan Level otomatis membuka dialog modal LevelCompleteModal.")

	print("\n==================================================")
	print("🎉 TAHAP 5 STYLING LEVEL COMPLETE MODAL LULUS 100%!")
	print("==================================================")
	quit(0)
