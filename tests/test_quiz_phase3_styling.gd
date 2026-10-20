extends SceneTree

# Test QuizScene Phase 3 Styling (desain.md)
# Memverifikasi palet warna, avatar Bima ekspresi, socket UX 48px, dan icon flat vector

var dm: Node
var gs: Node
var tm: Node
var quiz: Control

func _init() -> void:
	print("==================================================")
	print("🎨 VERIFIKASI TAHAP 3: STYLING QUIZ SCENE (desain.md)")
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
	# 1. VERIFIKASI PALET & BACKGROUND
	print("\n[1] Memvalidasi palet warna & background QuizScene...")
	assert(quiz.background_rect.color.is_equal_approx(Color("#EAF6FF")), "Latar utama harus Biru Langit Muda #EAF6FF")
	print("  ✓ Latar utama terbukti menggunakan palet resmi #EAF6FF.")

	# 2. VERIFIKASI TOP BAR & IKON FLAT VECTOR
	print("\n[2] Memvalidasi Top Bar & ikon flat vector SVG (bebas emoji & kontras tinggi)...")
	assert(quiz.btn_map.icon != null, "BtnMap harus menggunakan icon vector map.svg")
	assert(quiz.btn_menu.icon != null, "BtnMenu harus menggunakan icon vector arrow_left.svg")
	assert(quiz.btn_frequency_table.icon != null, "BtnFrequencyTable harus menggunakan icon vector table.svg")
	assert(quiz.star_icon.texture != null, "StarIcon harus memuat vector star.svg")
	assert(not "🗺️" in quiz.btn_map.text, "BtnMap tidak boleh memuat emoji")
	assert(not "📊" in quiz.btn_frequency_table.text, "BtnFrequencyTable tidak boleh memuat emoji")
	assert(not "⭐" in quiz.score_label.text, "ScoreLabel tidak boleh memuat emoji (gunakan StarIcon)")

	# Validasi kontras tinggi: icon berwarna Navy (#1E2A4A) di atas shape putih (#FFFFFF)
	var map_icon_col = quiz.btn_map.get_theme_color("icon_normal_color")
	assert(map_icon_col.is_equal_approx(tm.COLOR_TEXT_NAVY), "Ikon Peta harus berwarna Navy (#1E2A4A) untuk kontras tinggi di atas shape putih")
	var menu_icon_col = quiz.btn_menu.get_theme_color("icon_normal_color")
	assert(menu_icon_col.is_equal_approx(tm.COLOR_TEXT_NAVY), "Ikon Menu harus berwarna Navy (#1E2A4A) untuk kontras tinggi di atas shape putih")
	var reset_icon_col = quiz.btn_reset_matching.get_theme_color("icon_normal_color")
	assert(reset_icon_col.is_equal_approx(tm.COLOR_TEXT_NAVY), "Ikon Reset Matching harus berwarna Navy (#1E2A4A) untuk kontras tinggi di atas shape putih")
	print("  ✓ Ikon vector Peta, Menu, dan Reset terbukti berkontras tinggi (Navy #1E2A4A di atas latar shape putih).")

	# 3. VERIFIKASI AVATAR BIMA & EKSPRESI DIALOG
	print("\n[3] Memvalidasi Avatar Bima & perubahan ekspresi dialog...")
	assert(quiz.bima_avatar.texture != null, "Avatar Bima harus menampilkan gambar")
	var tex_normal = tm.get_bima_avatar("normal")
	assert(quiz.bima_avatar.texture == tex_normal, "Ekspresi awal Bima harus normal.jpg")
	print("  ✓ Avatar Bima berhasil terpasang dengan ekspresi awal (normal.jpg).")

	# Simulasi Jawaban Salah -> Ekspresi Bingung
	quiz._process_answer_result(false)
	var tex_bingung = tm.get_bima_avatar("bingung")
	assert(quiz.bima_avatar.texture == tex_bingung, "Ekspresi Bima saat salah harus bingung.jpg")
	assert(quiz.feedback_icon.texture != null, "FeedbackIcon harus memuat cross.svg")
	assert("-25" in quiz.feedback_badge_label.text, "Badge feedback harus menampilkan penalti -25")
	print("  ✓ Jawaban salah mengubah ekspresi Bima menjadi bingung.jpg & memunculkan feedback penalti -25.")

	# Simulasi Jawaban Benar -> Ekspresi Senang
	quiz._process_answer_result(true)
	var tex_senang = tm.get_bima_avatar("senang")
	assert(quiz.bima_avatar.texture == tex_senang, "Ekspresi Bima saat benar harus senang.jpg")
	assert(quiz.feedback_icon.texture != null, "FeedbackIcon harus memuat check.svg")
	assert("+100" in quiz.feedback_badge_label.text, "Badge feedback harus menampilkan skor +100")
	print("  ✓ Jawaban benar mengubah ekspresi Bima menjadi senang.jpg & memunculkan feedback skor +100.")

	# 4. VERIFIKASI MATCHING DENGAN SOCKET UX 48px
	print("\n[4] Memvalidasi komponen Matching dengan bulatan socket UX 48px...")
	var q_matching: Dictionary = {}
	for v in dm.get_question_variants(1, 1):
		if v.get("type") == "Matching":
			q_matching = v
			break
	gs.active_level_questions[1] = q_matching
	gs.current_point_index = 1
	quiz._load_current_point_question()

	assert(quiz.matching_left_col.get_child_count() == 3, "Kolom kiri harus 3 kartu")
	assert(quiz.matching_right_col.get_child_count() == 3, "Kolom kanan harus 3 kartu")

	# Periksa ukuran socket di kartu kiri pertama
	var left_btn: Button = quiz.matching_left_col.get_child(0)
	var left_hbox: HBoxContainer = left_btn.get_child(0)
	var left_socket: Panel = left_hbox.get_child(2) # [pad_left, lbl, socket, pad_right]
	assert(left_socket.custom_minimum_size == Vector2(48, 48), "Socket harus berukuran minimal 48x48 px sesuai desain.md")

	# Periksa ukuran socket di kartu kanan pertama
	var right_btn: Button = quiz.matching_right_col.get_child(0)
	var right_hbox: HBoxContainer = right_btn.get_child(0)
	var right_socket: Panel = right_hbox.get_child(1) # [pad_left, socket, lbl, pad_right]
	assert(right_socket.custom_minimum_size == Vector2(48, 48), "Socket kanan harus berukuran minimal 48x48 px sesuai desain.md")
	print("  ✓ Socket bulatan matching tervalidasi memenuhi kriteria UX 48px (diameter nyaman diklik).")

	# 5. VERIFIKASI MODAL TABEL DISTRIBUSI FREKUENSI
	print("\n[5] Memvalidasi Modal Tabel Distribusi Frekuensi modern...")
	quiz._show_frequency_table_modal()
	assert(quiz.table_modal.visible == true, "Modal tabel harus terbuka")
	assert(quiz.table_header_icon.texture != null, "Header tabel harus memiliki icon table.svg")
	quiz._hide_frequency_table_modal()
	assert(quiz.table_modal.visible == false, "Modal tabel harus tertutup")
	print("  ✓ Modal Tabel Distribusi Frekuensi tervalidasi modern dan bersih.")

	print("\n==================================================")
	print("🎉 TAHAP 3 STYLING QUIZ SCENE LULUS 100%!")
	print("==================================================")
	quit(0)
