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

func _run_test() -> void:
	# 1. PENGUJIAN TIPE 1: PILIHAN GANDA (L1-P1)
	print("\n[1] Menguji Soal Tipe Pilihan Ganda (PG)...")
	assert(quiz.current_question["id"] == "L1-P1", "Harus memuat soal L1-P1")
	assert(quiz.panel_pg.visible == true, "Panel PG harus terlihat")
	assert(quiz.panel_pg.get_child_count() == 4, "Harus ada 4 tombol opsi PG")
	
	# Pilih opsi salah (A)
	var btn_a: Button = quiz.panel_pg.get_child(0)
	quiz._on_pg_selected("A", btn_a)
	assert(gs.level_score == -25, "Skor harus -25 setelah memilih A (salah)")
	assert(btn_a.disabled == true, "Tombol opsi salah harus dinonaktifkan")
	assert(quiz.btn_next_point.visible == false, "Tombol lanjut belum boleh muncul jika belum benar")
	print("  ✓ Opsi salah (A) memberikan penalti -25 dan mendisabel tombol.")
	
	# Pilih opsi benar (B)
	var btn_b: Button = quiz.panel_pg.get_child(1)
	quiz._on_pg_selected("B", btn_b)
	assert(gs.level_score == 75, "Skor harus -25 + 100 = 75")
	assert(quiz.is_solved == true, "Soal harus tercatat solved")
	assert(quiz.btn_next_point.visible == true, "Tombol lanjut harus muncul")
	print("  ✓ Opsi benar (B) menambah +100 skor dan menampilkan tombol lanjut.")
	
	# 2. PENGUJIAN TIPE 2: BENAR / SALAH (L1-P2)
	print("\n[2] Menguji Soal Tipe Benar / Salah (TF)...")
	gs.current_point_index = 2
	quiz._load_current_point_question()
	assert(quiz.current_question["id"] == "L1-P2", "Harus memuat soal L1-P2")
	assert(quiz.panel_tf.visible == true, "Panel TF harus terlihat")
	
	# Pilih opsi salah ("SALAH")
	var btn_salah: Button = quiz.panel_tf.get_child(1)
	quiz._on_tf_selected("SALAH", btn_salah)
	assert(gs.level_score == 50, "Skor 75 - 25 = 50")
	assert(btn_salah.disabled == true, "Tombol SALAH harus dinonaktifkan")
	
	# Pilih opsi benar ("BENAR")
	var btn_benar: Button = quiz.panel_tf.get_child(0)
	quiz._on_tf_selected("BENAR", btn_benar)
	assert(gs.level_score == 150, "Skor 50 + 100 = 150")
	assert(quiz.is_solved == true, "Soal TF harus solved")
	print("  ✓ Soal TF terverifikasi (Salah dinonaktifkan, Benar membuka tombol lanjut).")
	
	# 3. PENGUJIAN TIPE 3: ISIAN SINGKAT (L1-P3, Kunci: 25)
	print("\n[3] Menguji Soal Tipe Isian Singkat (Short Answer)...")
	gs.current_point_index = 3
	quiz._load_current_point_question()
	assert(quiz.current_question["id"] == "L1-P3", "Harus memuat soal L1-P3")
	assert(quiz.panel_isian.visible == true, "Panel Isian harus terlihat")
	
	# Submit angka salah
	quiz.input_isian.text = "100"
	quiz._on_submit_isian()
	assert(gs.level_score == 125, "Skor 150 - 25 = 125")
	
	# Submit variasi desimal koma yang valid ("25,0")
	quiz.input_isian.text = "25,0"
	quiz._on_submit_isian()
	assert(gs.level_score == 225, "Skor 125 + 100 = 225")
	assert(quiz.is_solved == true, "Isian dengan koma harus valid")
	print("  ✓ Soal Isian terverifikasi dengan toleransi penulisan koma desimal (25,0).")
	
	# 4. PENGUJIAN TIPE 4: PROSEDUR / LANGKAH URUTAN (L1-P4)
	print("\n[4] Menguji Soal Tipe Prosedur (Urutan Langkah)...")
	gs.current_point_index = 4
	quiz._load_current_point_question()
	assert(quiz.current_question["id"] == "L1-P4", "Harus memuat soal L1-P4")
	assert(quiz.panel_procedure.visible == true, "Panel Prosedur harus terlihat")
	assert(quiz.procedure_order_list.size() == 4, "Harus ada 4 langkah prosedur")
	
	# Tukar langkah 0 dengan langkah 1 sehingga urutan keliru
	quiz._move_procedure_item(0, 1)
	quiz._on_check_procedure()
	assert(gs.level_score == 200, "Skor 225 - 25 = 200 saat urutan keliru")
	assert(quiz.is_solved == false, "Urutan salah tidak boleh solved")
	
	# Kembalikan ke urutan yang benar
	quiz._move_procedure_item(1, -1)
	quiz._on_check_procedure()
	assert(gs.level_score == 300, "Skor 200 + 100 = 300 saat urutan benar")
	assert(quiz.is_solved == true, "Urutan benar harus solved")
	print("  ✓ Soal Prosedur terverifikasi (Evaluasi urutan langkah berhasil).")
	
	# 5. PENGUJIAN PENYELESAIAN LEVEL PADA TITIK TERAKHIR (L1-P5)
	print("\n[5] Menguji Titik Akhir & Penyelesaian Level...")
	gs.current_point_index = 5
	quiz._load_current_point_question()
	assert("Selesaikan Level" in quiz.btn_next_point.text or quiz.btn_next_point.visible == false)
	
	# Jawab benar L1-P5 (Kunci: B)
	quiz._on_pg_selected("B", Button.new())
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
