extends SceneTree

# Test Verifikasi Soal Baru Khusus Materi Mean (Tahap 2)
# Memastikan 48 soal lengkap, terindeks akurat per titik, dan bersih dari materi median/modus.

func _init() -> void:
	print("\n==================================================")
	print("📋 MEMULAI VERIFIKASI BANK SOAL TERBARU (KHUSUS MEAN)")
	print("==================================================")

	var dm = null
	if root.has_node("DataManager"):
		dm = root.get_node("DataManager")
	else:
		var dm_script = load("res://scripts/autoload/data_manager.gd")
		dm = dm_script.new()
		dm.name = "DataManager"
		root.add_child(dm)

	# 1. Total Soal & Level Points Check
	var l1_pts = dm.questions_by_level[1].size()
	var l2_pts = dm.questions_by_level[2].size()
	var l3_pts = dm.questions_by_level[3].size()
	print("[1] Memeriksa jumlah titik per level...")
	print("  Level 1: %d titik (ekspektasi: 5)" % l1_pts)
	print("  Level 2: %d titik (ekspektasi: 4)" % l2_pts)
	print("  Level 3: %d titik (ekspektasi: 3)" % l3_pts)
	assert(l1_pts == 5, "Level 1 harus memiliki 5 titik!")
	assert(l2_pts == 4, "Level 2 harus memiliki 4 titik!")
	assert(l3_pts == 3, "Level 3 harus memiliki 3 titik!")

	# 2. Periksa varian soal per titik
	print("\n[2] Memeriksa varian soal (PG, TF, Isian, Matching) di setiap titik...")
	var total_questions = 0
	for lvl in [1, 2, 3]:
		var pts_count = 5 if lvl == 1 else (4 if lvl == 2 else 3)
		for pt in range(1, pts_count + 1):
			var variants = dm.get_question_variants(lvl, pt)
			assert(variants.size() == 4, "Level %d Titik %d harus memiliki tepat 4 varian!" % [lvl, pt])
			var types_found = []
			for q in variants:
				total_questions += 1
				var q_type = q.get("type", "")
				types_found.append(q_type)
				
				# Cek bahwa tidak ada kata median atau modus
				var p_lower = q.get("prompt", "").to_lower()
				var n_lower = q.get("narrative", "").to_lower()
				assert(not "median" in p_lower, "Ditemukan kata 'median' di soal %s: %s" % [q.get("id"), q.get("prompt")])
				assert(not "modus" in p_lower, "Ditemukan kata 'modus' di soal %s: %s" % [q.get("id"), q.get("prompt")])
				assert(not "median" in n_lower, "Ditemukan kata 'median' di narasi %s: %s" % [q.get("id"), q.get("narrative")])
				assert(not "modus" in n_lower, "Ditemukan kata 'modus' di narasi %s: %s" % [q.get("id"), q.get("narrative")])

				# Validasi bentuk spesifik
				match q_type:
					"PG":
						var opts = q.get("options", [])
						assert(opts.size() == 4, "PG %s harus memiliki 4 opsi" % q.get("id"))
						var ans = q.get("correct_answer", "")
						assert(ans in ["A", "B", "C", "D"], "Kunci PG %s harus A/B/C/D" % q.get("id"))
					"TF":
						var ans = q.get("correct_answer", "")
						assert(ans in ["BENAR", "SALAH"], "Kunci TF %s harus BENAR/SALAH" % q.get("id"))
					"Isian":
						var ans = q.get("correct_answer", "")
						assert(ans != "", "Kunci Isian %s tidak boleh kosong" % q.get("id"))
						var acc = q.get("accepted_answers", [])
						assert(acc.size() > 0, "Accepted answers %s tidak boleh kosong" % q.get("id"))
					"Matching":
						var left = q.get("left_items", [])
						var right = q.get("right_items", [])
						var pairs = q.get("valid_pairs", {})
						assert(left.size() == 3, "Matching %s harus memiliki 3 item kiri" % q.get("id"))
						assert(right.size() == 3, "Matching %s harus memiliki 3 item kanan" % q.get("id"))
						assert(pairs.size() == 3, "Matching %s harus memiliki 3 pasangan valid" % q.get("id"))

			assert("PG" in types_found, "Titik %d kurang PG" % pt)
			assert("TF" in types_found, "Titik %d kurang TF" % pt)
			assert("Isian" in types_found, "Titik %d kurang Isian" % pt)
			assert("Matching" in types_found, "Titik %d kurang Matching" % pt)

	print("  ✓ Total %d soal tervalidasi lengkap dan terstruktur rapi." % total_questions)
	assert(total_questions == 48, "Total harus tepat 48 soal!")

	# 3. Validasi simulasi GameState memulai setiap level
	print("\n[3] Menguji GameState start_level pada Level 1, 2, dan 3...")
	var gs = null
	if root.has_node("GameState"):
		gs = root.get_node("GameState")
	else:
		var gs_script = load("res://scripts/autoload/game_state.gd")
		gs = gs_script.new()
		gs.name = "GameState"
		gs.data_manager_ref = dm
		root.add_child(gs)

	for lvl in [1, 2, 3]:
		gs.start_level(lvl)
		var expected_pts = 5 if lvl == 1 else (4 if lvl == 2 else 3)
		assert(gs.active_level_questions.size() == expected_pts, "GameState harus me-roll %d soal aktif untuk Level %d (didapat %d)" % [expected_pts, lvl, gs.active_level_questions.size()])
		print("  ✓ Level %d berhasil memulai dengan %d soal aktif unik per titik." % [lvl, expected_pts])

	print("\n==================================================")
	print("🎉 SEMUA PENGUJIAN SOAL TAHAP 2 LULUS 100%!")
	print("==================================================")
	quit(0)
