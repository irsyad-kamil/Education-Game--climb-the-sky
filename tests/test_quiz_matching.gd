extends SceneTree

var dm: Node
var gs: Node
var quiz: Control

func _init() -> void:
	print("==================================================")
	print("🎯 MEMVERIFIKASI FITUR SOAL MATCHING (MENJODOHKAN)")
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
	
	gs.start_level(1)
	
	var quiz_scene = load("res://scenes/quiz/quiz_scene.tscn")
	quiz = quiz_scene.instantiate()
	root.add_child(quiz)
	
	process_frame.connect(_run_matching_test, CONNECT_ONE_SHOT)

func _run_matching_test() -> void:
	print("\n[1] Memuat soal tipe Matching...")
	var variants = dm.get_question_variants(1, 1)
	var q_matching: Dictionary = {}
	for v in variants:
		if v.get("type") == "Matching":
			q_matching = v
			break
	
	assert(not q_matching.is_empty(), "Harus ada varian Matching di Level 1 Titik 1")
	assert(q_matching.get("left_items", []).size() == 3, "Harus ada 3 item kiri")
	assert(q_matching.get("right_items", []).size() == 3, "Harus ada 3 item kanan")
	assert(q_matching.get("valid_pairs", {}).size() == 3, "Harus ada 3 valid_pairs")
	
	gs.active_level_questions[1] = q_matching
	gs.current_point_index = 1
	quiz._load_current_point_question()
	
	# Verifikasi UI Matching muncul
	assert(quiz.panel_matching.visible == true, "Panel Matching harus terlihat")
	assert(quiz.matching_left_col.get_child_count() == 3, "Kolom kiri harus berisi 3 kartu")
	assert(quiz.matching_right_col.get_child_count() == 3, "Kolom kanan harus berisi 3 kartu")
	print("  ✓ Panel Matching aktif dengan 3 kartu kiri dan 3 kartu kanan.")
	
	# Verifikasi pengacakan kolom kanan
	print("\n[2] Memverifikasi pengacakan posisi kolom kanan...")
	var is_sequential = true
	for i in range(quiz.shuffled_right_items.size()):
		if quiz.shuffled_right_items[i].get("id") != "R%d" % (i + 1):
			is_sequential = false
			break
	assert(is_sequential == false, "Kolom kanan harus teracak (tidak boleh urut R1, R2, R3)")
	print("  ✓ Kolom kanan terbukti teracak.")
	
	# Coba klik periksa sebelum memasangkan 3 pasangan
	print("\n[3] Menguji validasi kelengkapan pasangan...")
	quiz._on_check_matching()
	assert(gs.level_score == 0, "Skor tidak boleh berkurang jika belum memasangkan seluruh kartu")
	assert(quiz.is_solved == false, "Soal belum boleh solved")
	print("  ✓ Peringatan muncul dan skor tidak terpotong jika pasangan belum lengkap.")
	
	# Pasangkan secara keliru
	print("\n[4] Menguji pasangan KELIRU (Harus penalti -25)...")
	var valid_pairs = q_matching.get("valid_pairs", {})
	# Buat pasangan yang sengaja salah
	quiz._on_left_item_pressed("L1")
	# Pasangkan L1 ke selain pasangannya
	var wrong_r_for_l1 = "R2" if valid_pairs["L1"] == "R1" else "R1"
	quiz._on_right_item_pressed(wrong_r_for_l1)
	
	quiz._on_left_item_pressed("L2")
	var wrong_r_for_l2 = "R3" if valid_pairs["L2"] == "R2" else "R2"
	quiz._on_right_item_pressed(wrong_r_for_l2)
	
	quiz._on_left_item_pressed("L3")
	var remaining_r = ""
	for r in ["R1", "R2", "R3"]:
		if r != wrong_r_for_l1 and r != wrong_r_for_l2:
			remaining_r = r
			break
	quiz._on_right_item_pressed(remaining_r)
	
	assert(quiz.user_pairs.size() == 3, "Harus sudah terpasang 3")
	quiz._on_check_matching()
	assert(gs.level_score == -25, "Skor harus -25 setelah submit pasangan keliru (saat ini: %d)" % gs.level_score)
	assert(quiz.is_solved == false, "Soal keliru tidak boleh solved")
	print("  ✓ Pasangan keliru menghasilkan penalti -25 dan kesempatan mengulang terbuka.")
	
	# Reset pasangan
	print("\n[5] Menguji tombol Reset Pasangan...")
	quiz._on_reset_matching()
	assert(quiz.user_pairs.is_empty(), "user_pairs harus kosong setelah reset")
	print("  ✓ Tombol reset berhasil mengosongkan pasangan.")
	
	# Pasangkan secara BENAR (+100)
	print("\n[6] Menguji pasangan BENAR (Harus +100)...")
	for l_id in valid_pairs.keys():
		var correct_r = valid_pairs[l_id]
		quiz._on_left_item_pressed(l_id)
		quiz._on_right_item_pressed(correct_r)
		
	assert(quiz.user_pairs.size() == 3, "Harus terpasang 3 pasangan")
	quiz._on_check_matching()
	
	# Skor sebelumnya -25, tambah 100 menjadi 75
	assert(gs.level_score == 75, "Skor harus -25 + 100 = 75 (saat ini: %d)" % gs.level_score)
	assert(quiz.is_solved == true, "Soal harus tercatat solved")
	assert(quiz.btn_next_point.visible == true, "Tombol lanjut ke titik berikutnya harus muncul")
	assert(quiz.btn_check_matching.disabled == true, "Tombol periksa harus terkunci setelah benar")
	print("  ✓ Pasangan benar memberikan skor +100 dan membuka navigasi ke titik berikutnya.")
	
	print("\n==================================================")
	print("🎉 SEMUA PENGUJIAN SOAL MATCHING LULUS 100%!")
	print("==================================================")
	quit(0)
