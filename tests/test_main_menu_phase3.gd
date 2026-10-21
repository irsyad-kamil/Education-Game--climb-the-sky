extends SceneTree

var dm: Node
var gs: Node
var menu: Control

func _init() -> void:
	print("--- TEST PHASE 3: MAIN MENU & LEVEL SELECTION ---")
	
	var dm_script = load("res://scripts/autoload/data_manager.gd")
	dm = dm_script.new()
	dm.name = "DataManager"
	root.add_child(dm)
	
	var gs_script = load("res://scripts/autoload/game_state.gd")
	gs = gs_script.new()
	gs.name = "GameState"
	gs.data_manager_ref = dm
	root.add_child(gs)
	
	# Bersihkan data progres awal
	gs.reset_progress()
	
	# Muat scene MainMenu
	var menu_scene = load("res://scenes/main_menu/main_menu.tscn")
	menu = menu_scene.instantiate()
	root.add_child(menu)
	
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	# 1. State Awal (Pemain Baru)
	menu._update_ui_state()
	assert(menu.btn_stage_1.disabled == false, "Btn Level 1 harus aktif")
	assert(menu.btn_stage_2.disabled == true, "Btn Level 2 harus terkunci")
	assert(menu.btn_stage_3.disabled == true, "Btn Level 3 harus terkunci")
	assert("Memulai Petualangan di Level 1" in menu.status_label.text, "Status label harus menunjukkan Level 1")
	print("[PASS] Initial Main Menu state verified (Level 1 unlocked, 2 & 3 locked).")
	
	# 2. State setelah Level 1 Cleared
	gs.is_level_1_cleared = true
	gs.best_scores[1] = 450
	gs.save_progress()
	menu._update_ui_state()
	assert(menu.btn_stage_1.disabled == false, "Btn Level 1 harus aktif")
	assert(menu.btn_stage_2.disabled == false, "Btn Level 2 harus terbuka")
	assert(menu.btn_stage_3.disabled == true, "Btn Level 3 harus masih terkunci")
	assert("Skor Terbaik: 450" in menu.btn_stage_1.text, "Teks Level 1 harus menampilkan skor terbaik 450")
	assert("Level 2 Siap Dimainkan" in menu.status_label.text, "Status label harus mengarahkan ke Level 2")
	print("[PASS] State after Level 1 cleared verified (Level 2 unlocked, best score displayed).")
	
	# 3. State setelah Level 2 Cleared
	gs.is_level_2_cleared = true
	gs.best_scores[2] = 375
	gs.save_progress()
	menu._update_ui_state()
	assert(menu.btn_stage_2.disabled == false, "Btn Level 2 harus aktif")
	assert(menu.btn_stage_3.disabled == false, "Btn Level 3 harus sekarang terbuka")
	assert("Skor Terbaik: 375" in menu.btn_stage_2.text, "Teks Level 2 harus menampilkan skor terbaik 375")
	assert("Level 3 Siap Dimainkan" in menu.status_label.text, "Status label harus mengarahkan ke Level 3")
	print("[PASS] State after Level 2 cleared verified (Level 3 unlocked, best score displayed).")
	
	# 4. State setelah Semua Level Cleared
	gs.is_level_3_cleared = true
	gs.best_scores[3] = 300
	gs.save_progress()
	menu._update_ui_state()
	assert(menu.btn_stage_3.disabled == false, "Btn Level 3 harus aktif")
	assert("Skor Terbaik: 300" in menu.btn_stage_3.text, "Teks Level 3 harus menampilkan skor terbaik 300")
	assert("Seluruh Level" in menu.status_label.text, "Status label harus mengumumkan semua level tamat")
	print("[PASS] State after all levels cleared verified.")
	
	# 5. Clean up reset
	gs.reset_progress()
	
	print("\nALL PHASE 3 TESTS PASSED SUCCESSFULLY!")
	quit()
