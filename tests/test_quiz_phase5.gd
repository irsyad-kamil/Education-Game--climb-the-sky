extends SceneTree

var dm: Node
var gs: Node
var quiz: Control

func _init() -> void:
	print("--- TEST PHASE 5: QUIZ SCENE & EDUCATIONAL INTERACTIONS ---")
	
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
	
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _get_variant(lvl: int, pt: int, q_type: String) -> Dictionary:
	var list = dm.get_question_variants(lvl, pt)
	for q in list:
		if q.get("type") == q_type:
			return q
	return {}

func _run_test() -> void:
	# 1. PENGUJIAN TIPE 1: PILIHAN GANDA (L1-T1-PG, Kunci: C)
	print("\n[1] Menguji Soal Tipe Pilihan Ganda (PG)...")
	var q_pg = _get_variant(1, 1, "PG")
	assert(not q_pg.is_empty(), "Harus ada varian PG di L1-T1")
	gs.active_level_questions[1] = q_pg
	gs.current_point_index = 1
	quiz._load_current_point_question()
	
	assert(quiz.panel_pg.visible == true, "Panel PG harus terlihat")
	assert(quiz.panel_pg.get_child_count() == 4, "Harus ada 4 tombol opsi PG")
	
	# Pilih opsi salah (A)
	var btn_a: Button = quiz.panel_pg.get_child(0)
	quiz._on_pg_selected("A", btn_a)
	assert(gs.level_score == -25, "Skor harus -25 setelah memilih A (salah)")
	assert(btn_a.disabled == true, "Tombol opsi salah harus dinonaktifkan")
	assert(quiz.btn_next_point.visible == false, "Tombol lanjut belum boleh muncul jika belum benar")
	print("  ✓ Opsi salah (A) memberikan penalti -25 dan mendisabel tombol.")
	
	# Pilih opsi benar (C)
	var btn_c: Button = quiz.panel_pg.get_child(2)
	quiz._on_pg_selected("C", btn_c)
	assert(gs.level_score == 75, "Skor harus -25 + 100 = 75")
	assert(quiz.is_solved == true, "Soal harus tercatat solved")
	assert(quiz.btn_next_point.visible == true, "Tombol lanjut harus muncul")
	print("  ✓ Opsi benar (C) menambah +100 skor dan menampilkan tombol lanjut.")
	
	# 2. PENGUJIAN TIPE 2: BENAR / SALAH (L1-T1-TF, Kunci: SALAH)
	print("\n[2] Menguji Soal Tipe Benar / Salah (TF)...")
	var q_tf = _get_variant(1, 1, "TF")
	gs.active_level_questions[2] = q_tf
	gs.current_point_index = 2
	quiz._load_current_point_question()
	assert(quiz.panel_tf.visible == true, "Panel TF harus terlihat")
	
	# Pilih opsi salah ("BENAR")
	var btn_benar: Button = quiz.panel_tf.get_child(0)
	quiz._on_tf_selected("BENAR", btn_benar)
	assert(gs.level_score == 50, "Skor 75 - 25 = 50")
	assert(btn_benar.disabled == true, "Tombol BENAR harus dinonaktifkan")
	
	# Pilih opsi benar ("SALAH")
	var btn_salah: Button = quiz.panel_tf.get_child(1)
	quiz._on_tf_selected("SALAH", btn_salah)
	assert(gs.level_score == 150, "Skor 50 + 100 = 150")
	assert(quiz.is_solved == true, "Soal TF harus solved")
	print("  ✓ Soal TF terverifikasi (Salah dinonaktifkan, Benar membuka tombol lanjut).")
	
	# 3. PENGUJIAN TIPE 3: ISIAN SINGKAT (L1-T1-ISI, Kunci: 15,8)
	print("\n[3] Menguji Soal Tipe Isian Singkat (Short Answer)...")
	var q_isi = _get_variant(1, 1, "Isian")
	gs.active_level_questions[3] = q_isi
	gs.current_point_index = 3
	quiz._load_current_point_question()
	assert(quiz.panel_isian.visible == true, "Panel Isian harus terlihat")
	
	# Submit angka salah
	quiz.input_isian.text = "100"
	quiz._on_submit_isian()
	assert(gs.level_score == 125, "Skor 150 - 25 = 125")
	
	# Submit variasi desimal koma yang valid ("15,8")
	quiz.input_isian.text = "15,8"
	quiz._on_submit_isian()
	assert(gs.level_score == 225, "Skor 125 + 100 = 225")
	assert(quiz.is_solved == true, "Isian dengan koma harus valid")
	print("  ✓ Soal Isian terverifikasi dengan toleransi penulisan koma desimal (15,8).")
	
	# 4. PENGUJIAN TIPE 4: PROSEDUR / LANGKAH URUTAN (L1-T1-PRO)
	print("\n[4] Menguji Soal Tipe Prosedur (Urutan Langkah)...")
	var q_pro = _get_variant(1, 1, "Prosedur")
	gs.active_level_questions[4] = q_pro
	gs.current_point_index = 4
	quiz._load_current_point_question()
	assert(quiz.panel_procedure.visible == true, "Panel Prosedur harus terlihat")
	assert(quiz.procedure_order_list.size() == 4, "Harus ada 4 langkah prosedur")
	
	# Tukar langkah 0 dengan langkah 1 sehingga urutan keliru
	quiz._move_procedure_item(0, 1)
	quiz._on_check_procedure()
	assert(gs.level_score == 200, "Skor 225 - 25 = 200 saat urutan keliru")
	assert(quiz.is_solved == false, "Urutan salah tidak boleh solved")
	
	# Urutkan secara benar
	var target_order = q_pro["correct_order"]
	quiz.procedure_order_list.sort_custom(func(a, b):
		return target_order.find(a["id"]) < target_order.find(b["id"])
	)
	quiz._on_check_procedure()
	assert(gs.level_score == 300, "Skor 200 + 100 = 300 saat urutan benar")
	assert(quiz.is_solved == true, "Urutan benar harus solved")
	print("  ✓ Soal Prosedur terverifikasi (Evaluasi urutan langkah berhasil).")
	
	# 5. PENGUJIAN PENYELESAIAN LEVEL PADA TITIK TERAKHIR (Titik 5)
	print("\n[5] Menguji Titik Akhir & Penyelesaian Level...")
	var q_last = _get_variant(1, 5, "PG") # Kunci: A
	gs.active_level_questions[5] = q_last
	gs.current_point_index = 5
	quiz._load_current_point_question()
	assert("Selesaikan Level" in quiz.btn_next_point.text or quiz.btn_next_point.visible == false)
	
	# Jawab benar (Kunci: A)
	quiz._on_pg_selected("A", Button.new())
	assert("Selesaikan Level" in quiz.btn_next_point.text, "Tombol harus bertuliskan 'Selesaikan Level'")
	
	# Tekan tombol selesaikan level
	quiz._on_next_point_pressed()
	assert(gs.is_level_1_cleared == true, "Level 1 harus cleared")
	assert(gs.is_level_unlocked(2) == true, "Level 2 harus otomatis terbuka")
	print("  ✓ Penyelesaian level terverifikasi, Level 2 otomatis terbuka.")
	
	# Reset progress
	gs.reset_progress()
	
	print("\nALL PHASE 5 TESTS PASSED SUCCESSFULLY!")
	quit()
