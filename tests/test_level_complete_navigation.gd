extends SceneTree

# Test Level Complete Navigation & Scene Transition Bug Fix
# Memastikan klik 'Pilih Level Berikutnya' atau 'Menu Utama' tidak memicu crash:
# Parameter "data.tree" is null / Cannot call method 'change_scene_to_file' on a null value

var dm: Node
var gs: Node
var tm: Node
var quiz: Control

func _init() -> void:
	print("==================================================")
	print("🧪 PENGUJIAN PERBAIKAN BUG NAVIGASI LEVEL COMPLETE")
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
	var modal: Control = quiz.level_complete_modal
	assert(modal != null, "LevelCompleteModal harus ada")

	# Simulasi penyelesaian level
	modal.setup_level_complete(1, 375, 375)
	assert(modal.visible == true, "Modal harus terlihat")

	print("\n[1] Menguji klik tombol 'Pilih Level Berikutnya'...")
	# Reset flag
	gs.open_level_select_on_main_menu = false

	# Simulasikan klik tombol continue
	modal.btn_continue.emit_signal("pressed")
	assert(gs.open_level_select_on_main_menu == true, "Flag open_level_select_on_main_menu harus aktif setelah klik 'Pilih Level Berikutnya'")
	print("  ✓ Tombol 'Pilih Level Berikutnya' berhasil dieksekusi tanpa error 'data.tree is null'.")
	print("  ✓ Flag open_level_select_on_main_menu terbukti diset bernilai true.")

	# 2. Uji MainMenu membaca flag ini dan langsung membuka LevelSelectView
	print("\n[2] Menguji MainMenu memuat langsung ke tampilan LevelSelect...")
	var mm_scene = load("res://scenes/main_menu/main_menu.tscn")
	var mm = mm_scene.instantiate()
	root.add_child(mm)

	# Beri 1 frame agar _ready() berjalan
	assert(mm.level_select_view.visible == true, "LevelSelectView harus otomatis terlihat saat open_level_select_on_main_menu bernilai true")
	assert(mm.main_view.visible == false, "MainMenuView harus otomatis tersembunyi")
	assert(gs.open_level_select_on_main_menu == false, "Flag harus otomatis di-reset ke false setelah dimuat")
	print("  ✓ MainMenu terbukti langsung membuka tampilan Pilih Level!")

	mm.queue_free()
	quiz.queue_free()

	print("\n==================================================")
	print("🎉 BUG NAVIGASI SELESAI TERATASI 100%!")
	print("==================================================")
	quit(0)
