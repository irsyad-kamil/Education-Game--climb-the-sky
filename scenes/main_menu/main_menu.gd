extends Control
class_name MainMenu

# MainMenu v1.0 (GDD v1.0 Architecture)
# Menangani navigasi menu utama, modal pemilihan 3 level tetap, dan tampilan progres/skor terbaik

@onready var btn_play: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnPlay
@onready var btn_select_stage: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnSelectStage
@onready var btn_story_steam: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnStorySTEAM
@onready var btn_quit: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnQuit

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

# Modals
@onready var stage_select_modal: PopupPanel = $Popups/StageSelectModal
@onready var btn_stage_1: Button = $Popups/StageSelectModal/MarginContainer/VBoxContainer/BtnStage1
@onready var btn_stage_2: Button = $Popups/StageSelectModal/MarginContainer/VBoxContainer/BtnStage2
@onready var btn_stage_3: Button = $Popups/StageSelectModal/MarginContainer/VBoxContainer/BtnStage3

@onready var about_modal: AcceptDialog = $Popups/AboutModal

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_select_stage.pressed.connect(func(): stage_select_modal.popup_centered())
	btn_story_steam.pressed.connect(func(): about_modal.popup_centered())
	btn_quit.pressed.connect(func(): get_tree().quit())

	btn_stage_1.pressed.connect(func(): _start_game_at_level(1))
	btn_stage_2.pressed.connect(func(): _start_game_at_level(2))
	btn_stage_3.pressed.connect(func(): _start_game_at_level(3))

	_update_ui_state()

func _get_gs() -> Node:
	if is_inside_tree() and has_node("/root/GameState"):
		return get_node("/root/GameState")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var st = main_loop as SceneTree
		if st.root and st.root.has_node("GameState"):
			return st.root.get_node("GameState")
	return null

func _update_ui_state() -> void:
	var gs = _get_gs()
	if not gs:
		return
		
	gs.load_progress()

	# 1. Level 1 (Selalu Terbuka)
	var text_1 = "Level 1: Konsep & Perhitungan Rata-rata (Mean)\n5 Titik Soal • Skor Maks: 500"
	if gs.is_level_1_cleared:
		text_1 += " | Skor Terbaik: %d" % int(gs.best_scores.get(1, 0))
	btn_stage_1.text = text_1
	btn_stage_1.disabled = false

	# 2. Level 2 (Terbuka setelah Level 1 selesai)
	var is_unlocked_2 = gs.is_level_unlocked(2)
	btn_stage_2.disabled = not is_unlocked_2
	if is_unlocked_2:
		var text_2 = "Level 2: Konsep & Penentuan Nilai Tengah (Median)\n4 Titik Soal • Skor Maks: 400"
		if gs.is_level_2_cleared:
			text_2 += " | Skor Terbaik: %d" % int(gs.best_scores.get(2, 0))
		btn_stage_2.text = text_2
	else:
		btn_stage_2.text = "🔒 Level 2: Konsep Nilai Tengah (Median)\n[Terkunci - Selesaikan Level 1 Terlebih Dahulu]"

	# 3. Level 3 (Terbuka setelah Level 2 selesai)
	var is_unlocked_3 = gs.is_level_unlocked(3)
	btn_stage_3.disabled = not is_unlocked_3
	if is_unlocked_3:
		var text_3 = "Level 3: Evaluasi Komparatif Mean & Median\n3 Titik Soal • Skor Maks: 300"
		if gs.is_level_3_cleared:
			text_3 += " | Skor Terbaik: %d" % int(gs.best_scores.get(3, 0))
		btn_stage_3.text = text_3
	else:
		btn_stage_3.text = "🔒 Level 3: Evaluasi Komparatif Mean & Median\n[Terkunci - Selesaikan Level 2 Terlebih Dahulu]"

	# Status Label di Layar Utama
	if not gs.is_level_1_cleared:
		status_label.text = "🌱 Pemain Baru: Memulai Petualangan di Level 1 (Mean)"
	elif not gs.is_level_2_cleared:
		status_label.text = "⭐ Progres: Level 1 Selesai! Level 2 (Median) Siap Dimainkan"
	elif not gs.is_level_3_cleared:
		status_label.text = "🌟 Progres: Level 2 Selesai! Level 3 (Kombinasi) Siap Dimainkan"
	else:
		status_label.text = "🏆 Prestasi: Seluruh Level (1, 2, & 3) Telah Berhasil Diselesaikan!"

func _on_play_pressed() -> void:
	var gs = _get_gs()
	var target_level = 1
	if gs:
		if not gs.is_level_1_cleared:
			target_level = 1
		elif not gs.is_level_2_cleared:
			target_level = 2
		elif not gs.is_level_3_cleared:
			target_level = 3
		else:
			target_level = 1
	_start_game_at_level(target_level)

func _start_game_at_level(level: int) -> void:
	if stage_select_modal.visible:
		stage_select_modal.hide()
	var gs = _get_gs()
	if gs:
		gs.start_level(level)
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
