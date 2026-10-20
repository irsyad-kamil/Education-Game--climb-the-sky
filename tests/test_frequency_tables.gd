extends SceneTree

var dm: Node
var gs: Node
var quiz: Control
var map: Control

func _init() -> void:
	print("--- TEST FEATURE: TABEL DISTRIBUSI FREKUENSI ---")
	
	var dm_script = load("res://scripts/autoload/data_manager.gd")
	dm = dm_script.new()
	dm.name = "DataManager"
	root.add_child(dm)
	
	var gs_script = load("res://scripts/autoload/game_state.gd")
	gs = gs_script.new()
	gs.name = "GameState"
	gs.data_manager_ref = dm
	root.add_child(gs)
	
	# 1. Verifikasi DataManager Frequency Tables
	print("\n[1] Memverifikasi data tabel di DataManager...")
	for lvl in [1, 2, 3]:
		var tbl = dm.get_frequency_table(lvl)
		assert(not tbl.is_empty(), "Tabel Level %d tidak boleh kosong" % lvl)
		assert(tbl["level"] == lvl, "Field level harus sesuai")
		assert(tbl.has("raw_data") and tbl["raw_data"].length() > 20, "Harus memuat data mentah 30 hari")
		assert(tbl["rows"].size() == 6, "Harus ada 6 baris kelas interval")
		assert(tbl["total_frequency"] == 30, "Total frekuensi harus 30")
		print("  ✓ Level %d: '%s' (%s, 6 kelas, Total: %d)" % [
			lvl, tbl["title"], tbl["topic"], tbl["total_frequency"]
		])
	
	# Level 1 Cokelat
	var tbl1 = dm.get_frequency_table(1)
	assert("Cokelat" in tbl1["title"], "Level 1 harus tentang Penjualan Cokelat")
	assert(tbl1["rows"][0]["interval"] == "12–13", "Baris pertama Level 1 harus 12–13")
	assert(tbl1["rows"][0]["frequency"] == 3, "Frekuensi baris pertama Level 1 harus 3")
	
	# Level 2 Permen
	var tbl2 = dm.get_frequency_table(2)
	assert("Permen" in tbl2["title"], "Level 2 harus tentang Penjualan Permen")
	assert(tbl2["rows"][0]["interval"] == "2,4–2,7", "Baris pertama Level 2 harus 2,4–2,7")
	assert(tbl2["rows"][0]["frequency"] == 5, "Frekuensi baris pertama Level 2 harus 5")
	
	# Level 3 Mie
	var tbl3 = dm.get_frequency_table(3)
	assert("Mie" in tbl3["title"], "Level 3 harus tentang Penjualan Mie")
	assert(tbl3["rows"][0]["interval"] == "24–32", "Baris pertama Level 3 harus 24–32")
	assert(tbl3["rows"][0]["frequency"] == 5, "Frekuensi baris pertama Level 3 harus 5")
	
	# 2. Verifikasi UI di QuizScene
	gs.start_level(1)
	var quiz_scene = load("res://scenes/quiz/quiz_scene.tscn")
	quiz = quiz_scene.instantiate()
	root.add_child(quiz)
	
	# 3. Verifikasi UI di MapScene
	var map_scene = load("res://scenes/map/map_scene.tscn")
	map = map_scene.instantiate()
	root.add_child(map)
	
	process_frame.connect(_run_ui_test, CONNECT_ONE_SHOT)

func _run_ui_test() -> void:
	print("\n[2] Memverifikasi interaksi UI di QuizScene...")
	assert(quiz.btn_frequency_table != null, "Tombol tabel di TopBar kuis harus ada")
	assert(quiz.table_modal.visible == false, "Modal tabel kuis awalnya harus tersembunyi")
	
	# Buka modal tabel Level 1
	quiz._show_frequency_table_modal()
	assert(quiz.table_modal.visible == true, "Modal tabel harus terlihat setelah dibuka")
	assert("Cokelat" in quiz.modal_subtitle.text, "Subtitle modal harus memuat nama produk level 1")
	# 1 header + 6 data + 1 total = 8 baris container
	assert(quiz.table_rows_container.get_child_count() == 8, "Harus ada 8 baris tabel (header, 6 data, 1 total)")
	print("  ✓ Modal tabel frekuensi QuizScene Level 1 terbuka dan terisi 8 baris elemen tabel.")
	
	# Tutup modal
	quiz._hide_frequency_table_modal()
	assert(quiz.table_modal.visible == false, "Modal tabel harus tertutup setelah tombol tutup ditekan")
	print("  ✓ Modal tabel frekuensi QuizScene berhasil ditutup.")
	
	print("\n[3] Memverifikasi interaksi UI di MapScene...")
	assert(map.btn_frequency_table != null, "Tombol tabel di HUD peta harus ada")
	assert(map.table_modal.visible == false, "Modal tabel peta awalnya harus tersembunyi")
	
	# Buka modal di peta
	map._show_frequency_table_modal()
	assert(map.table_modal.visible == true, "Modal tabel di peta harus terlihat")
	assert(map.table_rows_container.get_child_count() == 8, "Harus ada 8 baris tabel di peta")
	map._hide_frequency_table_modal()
	assert(map.table_modal.visible == false, "Modal tabel di peta berhasil ditutup")
	print("  ✓ Modal tabel frekuensi MapScene terbuka dan tertutup dengan benar.")
	
	print("\nALL FREQUENCY TABLE TESTS PASSED SUCCESSFULLY!")
	quit()
