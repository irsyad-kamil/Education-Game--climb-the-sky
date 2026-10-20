extends SceneTree

var dm: Node
var gs: Node

func _init() -> void:
	print("==================================================")
	print("🎯 MEMVERIFIKASI BANK 48 SOAL & ROLL 25% PER TIPE (DENGAN MATCHING)")
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
	
	# 1. PENGUJIAN INTEGRITAS BANK 48 SOAL
	print("\n[1] Memvalidasi struktur & kelengkapan 48 soal...")
	var all_questions = dm.get_questions_for_level(1) + dm.get_questions_for_level(2) + dm.get_questions_for_level(3)
	assert(all_questions.size() == 48, "Total bank soal harus tepat 48 (saat ini: %d)" % all_questions.size())
	print("  ✓ Total 48 soal berhasil dimuat.")
	
	var expected_counts = {1: 5, 2: 4, 3: 3}
	for lvl in [1, 2, 3]:
		var pts = expected_counts[lvl]
		for p in range(1, pts + 1):
			var variants = dm.get_question_variants(lvl, p)
			assert(variants.size() == 4, "Level %d Titik %d harus memiliki tepat 4 varian soal" % [lvl, p])
			
			var types_present = {}
			for v in variants:
				var t = v.get("type", "")
				types_present[t] = true
				assert(not v.get("prompt", "").is_empty(), "Prompt soal tidak boleh kosong: %s" % v.get("id"))
				
				# Validasi per tipe
				match t:
					"PG":
						assert(v.get("options", []).size() == 4, "PG harus ada 4 opsi: %s" % v.get("id"))
						assert(v.get("correct_answer", "") in ["A", "B", "C", "D"], "Kunci PG harus A-D: %s" % v.get("id"))
					"TF":
						assert(v.get("correct_answer", "").to_upper() in ["BENAR", "SALAH"], "Kunci TF harus Benar/Salah: %s" % v.get("id"))
					"Isian":
						assert(not str(v.get("correct_answer", "")).is_empty(), "Kunci isian tidak boleh kosong: %s" % v.get("id"))
						assert(v.get("accepted_answers", []).size() >= 1, "Harus ada accepted_answers: %s" % v.get("id"))
					"Matching":
						assert(v.get("left_items", []).size() == 3, "Matching harus ada 3 item kiri: %s" % v.get("id"))
						assert(v.get("right_items", []).size() == 3, "Matching harus ada 3 item kanan: %s" % v.get("id"))
						assert(v.get("valid_pairs", {}).size() == 3, "Matching harus ada 3 pasangan valid: %s" % v.get("id"))
			
			assert(types_present.has("PG") and types_present.has("TF") and types_present.has("Isian") and types_present.has("Matching"),
				"Level %d Titik %d harus memuat 4 tipe lengkap (PG, TF, Isian, Matching)" % [lvl, p])
	
	print("  ✓ Seluruh 48 soal tervalidasi: Tiap titik memiliki varian lengkap PG, TF, Isian, dan Matching.")
	
	# 2. PENGUJIAN ROLL ACAK DENGAN PELUANG 25% TIAP JENIS
	print("\n[2] Menguji distribusi acak (25% peluang per jenis soal)...")
	var type_distribution = {"PG": 0, "TF": 0, "Isian": 0, "Matching": 0}
	var simulation_runs = 200
	
	for run in range(simulation_runs):
		gs.start_level(1)
		for p in range(1, 6):
			var q = gs.active_level_questions[p]
			var t = q.get("type", "")
			if type_distribution.has(t):
				type_distribution[t] += 1
				
	var total_rolls = simulation_runs * 5
	print("  Hasil simulasi %d kali pemilihan soal:" % total_rolls)
	for t in type_distribution.keys():
		var pct = (float(type_distribution[t]) / float(total_rolls)) * 100.0
		print("    - %s: %d kali (%.1f%%)" % [t, type_distribution[t], pct])
		# Peluang teoritis 25%, dalam 1000 roll batas wajar toleransi statistik 18% - 32%
		assert(pct >= 18.0 and pct <= 32.0, "Persentase %s (%.1f%%) harus berada di kisaran 25%%" % [t, pct])
		
	print("  ✓ Peluang pemilihan 4 tipe soal terbukti merata ~25% per jenis.")
	
	# 3. PENGUJIAN PENGACAKAN AWAL KOLOM KANAN MATCHING DI QUIZ SCENE
	print("\n[3] Menguji pengacakan kolom kanan Matching di QuizScene...")
	gs.start_level(1)
	# Paksa titik 4 menggunakan varian Matching
	var variants_l1_t4 = dm.get_question_variants(1, 4)
	for v in variants_l1_t4:
		if v.get("type") == "Matching":
			gs.active_level_questions[4] = v
			break
			
	gs.current_point_index = 4
	var quiz_scene = load("res://scenes/quiz/quiz_scene.tscn")
	var quiz = quiz_scene.instantiate()
	root.add_child(quiz)
	
	process_frame.connect(func():
		assert(quiz.current_question["type"] == "Matching", "Harus memuat tipe Matching")
		var is_sequential = true
		for i in range(quiz.shuffled_right_items.size()):
			if quiz.shuffled_right_items[i].get("id") != "R%d" % (i + 1):
				is_sequential = false
				break
		assert(is_sequential == false, "Kolom kanan Matching TIDAK boleh sudah terurut R1, R2, R3 (harus teracak)")
		print("  ✓ Kolom kanan Matching terbukti teracak saat pertama kali ditampilkan.")
		
		print("\n==================================================")
		print("🎉 SEMUA PENGUJIAN BANK 48 SOAL LULUS 100%!")
		print("==================================================")
		quit(0)
	, CONNECT_ONE_SHOT)
