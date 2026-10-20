extends SceneTree

# Test Short Answer Attempt Counter & Reveal Display
# Memverifikasi:
# 1. Counter salah [Percobaan: X/6] HANYA muncul di tipe Isian Singkat.
# 2. Pada PG, TF, dan Matching, teks salah tidak menampilkan counter percobaan.
# 3. Pada Isian Singkat jika salah >= 6x, kunci jawaban tampil jelas pada feedback_label,
#    input_isian terisi kunci jawaban, helper_label menampilkan kunci jawaban, dan tombol lanjut muncul.

var dm: Node
var gs: Node
var tm: Node
var quiz: Control

func _init() -> void:
	print("==================================================")
	print("🧪 VERIFIKASI PENGHITUNG SALAH KHUSUS ISIAN SINGKAT")
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
	# [1] UJI PILIHAN GANDA (PG) - TIDAK BOLEH MUNCUL COUNTER PERCOBAAN
	print("\n[1] Memvalidasi umpan balik salah pada Pilihan Ganda (PG)...")
	var q_pg: Dictionary = {}
	for v in dm.get_question_variants(1, 1):
		if v.get("type") == "PG":
			q_pg = v
			break
	gs.active_level_questions[1] = q_pg
	gs.current_point_index = 1
	quiz._load_current_point_question()

	var wrong_opt = "B" if q_pg.get("correct_answer") != "B" else "A"
	quiz._on_pg_selected(wrong_opt, Button.new())
	assert(not "Percobaan" in quiz.feedback_label.text, "PG tidak boleh memuat teks 'Percobaan'")
	assert(not "/6" in quiz.feedback_label.text, "PG tidak boleh memuat rasio '/6'")
	assert("Jawaban Kurang Tepat" in quiz.feedback_label.text, "PG harus memuat umpan balik salah")
	print("  ✓ Umpan balik PG terbukti bersih tanpa penghitung percobaan 6x.")

	# [2] UJI BENAR / SALAH (TF) - TIDAK BOLEH MUNCUL COUNTER PERCOBAAN
	print("\n[2] Memvalidasi umpan balik salah pada Benar / Salah (TF)...")
	var q_tf: Dictionary = {}
	for v in dm.get_question_variants(1, 1):
		if v.get("type") == "TF":
			q_tf = v
			break
	gs.active_level_questions[1] = q_tf
	quiz._load_current_point_question()

	var wrong_tf = "SALAH" if q_tf.get("correct_answer") == "BENAR" else "BENAR"
	quiz._on_tf_selected(wrong_tf, Button.new())
	assert(not "Percobaan" in quiz.feedback_label.text, "TF tidak boleh memuat teks 'Percobaan'")
	assert(not "/6" in quiz.feedback_label.text, "TF tidak boleh memuat rasio '/6'")
	print("  ✓ Umpan balik TF terbukti bersih tanpa penghitung percobaan 6x.")

	# [3] UJI MATCHING - TIDAK BOLEH MUNCUL COUNTER PERCOBAAN
	print("\n[3] Memvalidasi umpan balik salah pada Matching...")
	var q_mat: Dictionary = {}
	for v in dm.get_question_variants(1, 1):
		if v.get("type") == "Matching":
			q_mat = v
			break
	gs.active_level_questions[1] = q_mat
	quiz._load_current_point_question()

	quiz.user_pairs["L1"] = "WRONG_1"
	quiz.user_pairs["L2"] = "WRONG_2"
	quiz.user_pairs["L3"] = "WRONG_3"
	quiz._on_check_matching()
	assert(not "Percobaan" in quiz.feedback_label.text, "Matching tidak boleh memuat teks 'Percobaan'")
	assert(not "/6" in quiz.feedback_label.text, "Matching tidak boleh memuat rasio '/6'")
	assert("Jawaban Kurang Tepat" in quiz.feedback_label.text, "Matching harus memuat feedback salah")
	print("  ✓ Umpan balik Matching terbukti bersih tanpa penghitung percobaan 6x.")

	# [4] UJI ISIAN SINGKAT (SHORT ANSWER) - COUNTER HARUS MUNCUL PADA PERCOBAAN 1-5
	print("\n[4] Memvalidasi penghitung percobaan pada Isian Singkat...")
	var q_isi: Dictionary = {}
	for v in dm.get_question_variants(1, 1):
		if v.get("type") == "Isian":
			q_isi = v
			break
	gs.active_level_questions[1] = q_isi
	quiz._load_current_point_question()

	var key_answer = str(q_isi.get("correct_answer", "15,8"))

	for att in range(1, 6):
		quiz.input_isian.text = "SALAH_%d" % att
		quiz._on_submit_isian()
		assert("Percobaan: %d/6" % att in quiz.feedback_label.text, "Isian percobaan ke-%d harus menampilkan '[Percobaan: %d/6]'" % [att, att])
		assert(quiz.btn_next_point.visible == false, "Tombol lanjut belum boleh tampil sebelum selesai/kunci")
	print("  ✓ Counter percobaan [Percobaan: 1/6] s.d. [Percobaan: 5/6] terverifikasi muncul hanya pada Isian Singkat.")

	# [5] UJI PERCOBAAN KE-6 PADA ISIAN SINGKAT (KUNCI JAWABAN & TOMBOL LANJUT HARUS MUNCUL)
	print("\n[5] Memvalidasi percobaan ke-6 pada Isian Singkat...")
	quiz.input_isian.text = "SALAH_6"
	quiz._on_submit_isian()

	# Kunci jawaban harus terlihat jelas pada feedback_label
	assert(key_answer in quiz.feedback_label.text, "Kunci jawaban '%s' harus tercantum di feedback_label" % key_answer)
	assert("Kunci jawaban yang benar" in quiz.feedback_label.text, "Teks harus mengumumkan kunci jawaban yang benar")
	assert(not "Coba teliti kembali!" in quiz.feedback_label.text, "Teks tidak boleh tertimpa 'Coba teliti kembali!'")

	# Kunci jawaban terisi pada input field dan label bantuan
	assert(quiz.input_isian.text == key_answer, "InputIsian harus otomatis terisi kunci jawaban '%s'" % key_answer)
	assert(quiz.input_isian.editable == false, "InputIsian harus dinonaktifkan")
	assert(quiz.btn_submit_isian.disabled == true, "BtnSubmitIsian harus dinonaktifkan")
	assert(key_answer in quiz.helper_isian.text, "HelperLabel harus mengumumkan kunci jawaban")

	# Tombol lanjut harus terlihat
	assert(quiz.btn_next_point.visible == true, "Tombol lanjut ke titik berikutnya harus tampil bersama jawaban")
	assert(quiz.is_solved == true, "Soal harus tercatat solved")
	print("  ✓ Pada percobaan ke-6, kunci jawaban terbukti tampil lengkap dan jelas bersamaan dengan tombol lanjut!")

	print("\n==================================================")
	print("🎉 SEMUA PENGUJIAN PENGHITUNG SALAH LULUS 100%!")
	print("==================================================")
	quit(0)
