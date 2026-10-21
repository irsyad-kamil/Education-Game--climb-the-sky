extends SceneTree

var dm: Node
var gs: Node
var menu: Control

func _init() -> void:
	print("==================================================")
	print("🔍 MEMULAI VERIFIKASI MENYELURUH (FASE 1, 2, 3)")
	print("==================================================")
	
	# Load Autoloads
	var dm_script = load("res://scripts/autoload/data_manager.gd")
	dm = dm_script.new()
	dm.name = "DataManager"
	root.add_child(dm)
	
	var gs_script = load("res://scripts/autoload/game_state.gd")
	gs = gs_script.new()
	gs.name = "GameState"
	gs.data_manager_ref = dm
	root.add_child(gs)
	
	# 1. VERIFIKASI FASE 1: DATA MANAGER & SOAL
	print("\n--- [1] PENGUJIAN FASE 1: DATA & KONFIGURASI SOAL ---")
	var cfg = dm.get_scoring_rules()
	assert(cfg["correct_score"] == 100, "Skor benar harus 100")
	assert(cfg["wrong_score"] == -25, "Penalti salah harus -25")
	assert(cfg["allow_negative_score"] == true, "Harus mengizinkan skor negatif")
	print("  ✓ Konfigurasi skor valid (+100 / -25 / negatif diizinkan)")
	
	var sa_cfg = dm.get_short_answer_settings()
	assert(sa_cfg["max_wrong_attempts_before_reveal"] == 6, "Threshold reveal harus 6")
	print("  ✓ Konfigurasi isian singkat valid (threshold reveal 6 kali salah)")
	
	var total_q = 0
	for lvl in range(1, 4):
		var total_pts = dm.get_total_points(lvl)
		var q_list = dm.get_questions_for_level(lvl)
		assert(q_list.size() == total_pts * 4, "Jumlah soal level %d harus sesuai total points * 4" % lvl)
		total_q += q_list.size()
		print("  ✓ Level %d: %d titik terindeks (%d varian soal, Max skor: %d)" % [
			lvl, total_pts, q_list.size(), dm.get_max_score(lvl)
		])
		
		# Validasi kelengkapan struktur soal
		for pt in range(1, total_pts + 1):
			var variants = dm.get_question_variants(lvl, pt)
			assert(variants.size() == 4, "Tiap titik harus memiliki 4 varian")
			for q in variants:
				var has_ans = q.has("correct_answer") or q.has("valid_pairs")
				assert(q.has("id") and q.has("type") and q.has("prompt") and has_ans,
					"Soal Level %d Titik %d (%s) tidak lengkap" % [lvl, pt, q.get("id")])
	
	assert(total_q == 48, "Total keseluruhan soal harus tepat 48")
	print("  ✓ Total 48 soal tetap tervalidasi lengkap tanpa duplikasi/kekurangan")
	
	# 2. VERIFIKASI FASE 2: GAME STATE & SKOR
	print("\n--- [2] PENGUJIAN FASE 2: GAME STATE & PERHITUNGAN SKOR ---")
	gs.reset_progress()
	assert(gs.is_level_unlocked(1) == true, "Level 1 harus selalu terbuka")
	assert(gs.is_level_unlocked(2) == false, "Level 2 harus terkunci pada awal")
	assert(gs.is_level_unlocked(3) == false, "Level 3 harus terkunci pada awal")
	print("  ✓ State unlock awal valid (Hanya Level 1 yang terbuka)")
	
	gs.start_level(1)
	assert(gs.current_level == 1 and gs.current_point_index == 1 and gs.level_score == 0,
		"Inisialisasi level harus bersih")
	print("  ✓ Inisialisasi Level 1 berhasil (Titik: 1, Skor: 0)")
	
	# Tetapkan tipe Isian pada Titik 1 untuk menguji counter percobaan dan threshold bantuan
	gs.active_level_questions[1] = {"type": "Isian", "correct_answer": "15,8"}
	
	# Simulasi salah 2 kali berturut-turut (skor negatif)
	gs.register_answer(false)
	assert(gs.level_score == -25, "Skor harus -25 setelah salah pertama")
	gs.register_answer(false)
	assert(gs.level_score == -50, "Skor harus -50 setelah salah kedua")
	assert(gs.wrong_attempts_current_question == 2, "Percobaan salah harus tercatat 2")
	print("  ✓ Penalti jawaban salah dan toleransi skor negatif (-50) terverifikasi")
	
	# Simulasi benar
	gs.register_answer(true)
	assert(gs.level_score == 50, "Skor harus -50 + 100 = 50")
	assert(gs.wrong_attempts_current_question == 0, "Counter salah harus di-reset saat benar")
	print("  ✓ Penambahan skor jawaban benar (+100) dan reset counter terverifikasi")
	
	# Simulasi 6 kali salah hingga kunci jawaban terbuka
	var reveal_data = {"fired": false, "ans": ""}
	gs.answer_revealed.connect(func(pt, ans):
		reveal_data["fired"] = true
		reveal_data["ans"] = ans
	)
	for i in range(5):
		var r = gs.register_answer(false)
		assert(r["revealed"] == false, "Sebelum 6 kali salah, revealed harus false")
	var r_final = gs.register_answer(false)
	assert(r_final["revealed"] == true and reveal_data["fired"] == true, "Percobaan ke-6 harus membuka jawaban")
	assert(not reveal_data["ans"].is_empty(), "Kunci jawaban harus terbuka")
	print("  ✓ Mekanisme threshold bantuan 6x salah terverifikasi (Kunci jawaban '%s' terbuka)" % reveal_data["ans"])
	
	# Selesaikan Level 1
	for p in range(1, 5):
		var is_end = gs.advance_point()
		assert(is_end == false, "Titik %d belum akhir level" % p)
	var is_lvl1_complete = gs.advance_point()
	assert(is_lvl1_complete == true, "Titik ke-5 harus menyelesaikan Level 1")
	assert(gs.is_level_1_cleared == true, "Level 1 harus tercatat cleared")
	assert(gs.is_level_unlocked(2) == true, "Level 2 harus otomatis terbuka")
	print("  ✓ Selesai Level 1: Progresi titik linear sukses, Level 2 otomatis terbuka")
	
	# Hubungkan testing UI menu pada frame berikutnya
	process_frame.connect(_run_ui_verification, CONNECT_ONE_SHOT)

func _run_ui_verification() -> void:
	print("\n--- [3] PENGUJIAN FASE 3: MENU UTAMA & LEVEL SELECTION ---")
	var menu_scene = load("res://scenes/main_menu/main_menu.tscn")
	menu = menu_scene.instantiate()
	root.add_child(menu)
	
	# Update UI berdasarkan progres yang sedang berlangsung (Level 1 cleared, Level 2 unlocked)
	menu._update_ui_state()
	assert(menu.btn_stage_1.disabled == false, "Btn Level 1 harus aktif")
	assert(menu.btn_stage_2.disabled == false, "Btn Level 2 harus aktif (Level 1 sudah tamat)")
	assert(menu.btn_stage_3.disabled == true, "Btn Level 3 harus masih terkunci")
	assert("Level 2 Siap Dimainkan" in menu.status_label.text, "Status label harus mengarahkan ke Level 2")
	print("  ✓ Tampilan menu sinkron dengan status unlock Level 2")
	
	# Simulasikan penyelesaian Level 2
	gs.is_level_2_cleared = true
	gs.best_scores[2] = 375
	gs.save_progress()
	menu._update_ui_state()
	assert(menu.btn_stage_3.disabled == false, "Btn Level 3 harus terbuka sekarang")
	assert("Skor Terbaik: 375" in menu.btn_stage_2.text, "Skor terbaik Level 2 harus tampil")
	print("  ✓ Tampilan menu sinkron setelah Level 2 tamat (Level 3 terbuka & skor tampil)")
	
	# Simulasikan penyelesaian Level 3 (Game Tamat)
	gs.is_level_3_cleared = true
	gs.best_scores[3] = 300
	gs.save_progress()
	menu._update_ui_state()
	assert("Seluruh Level" in menu.status_label.text, "Status label mengonfirmasi seluruh level tamat")
	print("  ✓ Status kelulusan seluruh materi terkonfirmasi pada Menu Utama")
	
	# Bersihkan data progres kembali ke default
	gs.reset_progress()
	print("  ✓ Reset data progres pengujian kembali ke status bersih")
	
	print("\n==================================================")
	print("🎉 SEMUA VERIFIKASI (FASE 1, 2, 3) BERHASIL 100%!")
	print("==================================================")
	quit()
