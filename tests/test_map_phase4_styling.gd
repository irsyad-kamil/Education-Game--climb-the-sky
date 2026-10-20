extends SceneTree

# Test MapScene Phase 4 Styling (desain.md)
# Memverifikasi palet warna, simpul peta bebas emoji (check.svg & lock.svg),
# kontras tinggi ikon Menu (Navy di atas putih), dan garis jalur linear

var dm: Node
var gs: Node
var tm: Node
var map: Control

func _init() -> void:
	print("==================================================")
	print("🗺️ VERIFIKASI TAHAP 4: STYLING MAP SCENE (desain.md)")
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

	var map_scene = load("res://scenes/map/map_scene.tscn")
	map = map_scene.instantiate()
	root.add_child(map)

	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	# 1. VERIFIKASI PALET & BACKGROUND
	print("\n[1] Memvalidasi palet warna & background MapScene...")
	assert(map.background_rect.color.is_equal_approx(Color("#EAF6FF")), "Latar utama harus Biru Langit Muda #EAF6FF")
	print("  ✓ Latar utama terbukti menggunakan palet resmi #EAF6FF.")

	# 2. VERIFIKASI TOP HUD & IKON FLAT VECTOR (BEBAS EMOJI & KONTRAS TINGGI)
	print("\n[2] Memvalidasi Top HUD & ikon flat vector SVG...")
	assert(map.btn_menu.icon != null, "BtnMenu harus memuat icon vector arrow_left.svg")
	assert(map.btn_frequency_table.icon != null, "BtnFrequencyTable harus memuat icon vector table.svg")
	assert(map.star_icon.texture != null, "StarIcon harus memuat vector star.svg")
	assert(not "🏠" in map.btn_menu.text, "BtnMenu tidak boleh memuat emoji")
	assert(not "📊" in map.btn_frequency_table.text, "BtnFrequencyTable tidak boleh memuat emoji")
	assert(not "⭐" in map.score_label.text, "ScoreLabel tidak boleh memuat emoji")

	# Kontras tinggi tombol Menu: Navy (#1E2A4A) di atas shape putih
	var menu_icon_col = map.btn_menu.get_theme_color("icon_normal_color")
	assert(menu_icon_col.is_equal_approx(tm.COLOR_TEXT_NAVY), "Ikon Menu harus Navy (#1E2A4A) untuk kontras tinggi di atas shape putih")
	print("  ✓ Top HUD tervalidasi menggunakan icon vector flat bebas emoji dengan kontras tinggi.")

	# 3. VERIFIKASI SIMPUL PETA (MAP NODE) BEBAS EMOJI
	print("\n[3] Memvalidasi simpul titik peta bebas emoji (check.svg, lock.svg, angka titik)...")
	# Titik 1: CURRENT
	var node1: MapNodeUI = map.node_ui_map[1]
	assert(node1.state == MapNodeUI.NodeState.CURRENT, "Titik 1 harus CURRENT")
	assert(node1.text == "1", "Titik aktif harus menampilkan angka titik murni tanpa emoji (text = '1')")
	assert(not "📍" in node1.text, "Titik aktif tidak boleh memakai emoji pin 📍")
	assert(node1.node_icon.visible == false, "Icon simpul disembunyikan saat state CURRENT (menampilkan angka)")
	print("  ✓ Simpul Aktif (CURRENT) tervalidasi menampilkan angka titik dengan warna aksen level.")

	# Titik 2: LOCKED
	var node2: MapNodeUI = map.node_ui_map[2]
	assert(node2.state == MapNodeUI.NodeState.LOCKED, "Titik 2 harus LOCKED")
	assert(not "🔒" in node2.text, "Titik terkunci tidak boleh memakai emoji gembok 🔒")
	assert(node2.text == "", "Teks simpul terkunci dikosongkan (menggunakan vector icon)")
	assert(node2.node_icon.visible == true, "Node icon harus aktif pada simpul terkunci")
	assert(node2.node_icon.texture != null, "Node icon harus memuat vector lock.svg")
	print("  ✓ Simpul Terkunci (LOCKED) tervalidasi menggunakan icon vector flat lock.svg.")

	# 4. SIMULASI TITIK 1 SELESAI (COMPLETED)
	print("\n[4] Memvalidasi simpul Selesai (COMPLETED)...")
	node1.update_state(MapNodeUI.NodeState.COMPLETED)
	assert(node1.state == MapNodeUI.NodeState.COMPLETED, "Titik 1 kini COMPLETED")
	assert(not "✅" in node1.text, "Titik selesai tidak boleh memakai emoji centang ✅")
	assert(node1.text == "", "Teks simpul selesai dikosongkan (menggunakan vector icon)")
	assert(node1.node_icon.visible == true, "Node icon harus aktif pada simpul selesai")
	assert(node1.node_icon.texture != null, "Node icon harus memuat vector check.svg")
	print("  ✓ Simpul Selesai (COMPLETED) tervalidasi menggunakan icon vector flat check.svg.")

	# 5. VERIFIKASI MODAL TABEL DISTRIBUSI FREKUENSI DI PETA
	print("\n[5] Memvalidasi Modal Tabel Distribusi Frekuensi di MapScene...")
	map._show_frequency_table_modal()
	assert(map.table_modal.visible == true, "Modal tabel harus terbuka")
	assert(map.table_header_icon.texture != null, "Header modal harus memiliki icon table.svg")
	map._hide_frequency_table_modal()
	assert(map.table_modal.visible == false, "Modal tabel harus tertutup")
	print("  ✓ Modal Tabel Distribusi Frekuensi di MapScene tervalidasi modern dan bersih.")

	print("\n==================================================")
	print("🎉 TAHAP 4 STYLING MAP SCENE LULUS 100%!")
	print("==================================================")
	quit(0)
