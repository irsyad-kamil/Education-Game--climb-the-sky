extends Control
class_name MainMenu

# MainMenu v2.0 (Wireframe & Level Select Art Integration)
# Tampilan awal minimalis dengan Judul Melengkung ("CLIMB THE SKY"), tombol PLAY & EXIT
# Pemilihan level ("LEVEL SELECT") muncul saat tombol PLAY diklik
# Menampilkan 3 kartu tahap: Mountain (Level 1), Underground (Level 2), Sky (Level 3)

@onready var main_view: Control = $MainMenuView
@onready var curved_title_container: Control = $MainMenuView/CurvedTitleContainer
@onready var btn_play: Button = $MainMenuView/ButtonsBox/BtnPlay
@onready var btn_quit: Button = $MainMenuView/ButtonsBox/BtnQuit

@onready var level_select_view: Control = $LevelSelectView
@onready var level_select_bg: TextureRect = $LevelSelectView/Background
@onready var btn_back: Button = $LevelSelectView/BtnBack

@onready var card_1_container: Control = $LevelSelectView/Cards/Card1
@onready var btn_stage_1: Button = $LevelSelectView/Cards/Card1/BtnStage1
@onready var card_1_info: Label = $LevelSelectView/Cards/Card1/InfoPanel/Margin/VBox/ScoreLabel

@onready var card_2_container: Control = $LevelSelectView/Cards/Card2
@onready var btn_stage_2: Button = $LevelSelectView/Cards/Card2/BtnStage2
@onready var card_2_info: Label = $LevelSelectView/Cards/Card2/InfoPanel/Margin/VBox/ScoreLabel
@onready var lock_overlay_2: Control = $LevelSelectView/Cards/Card2/LockOverlay

@onready var card_3_container: Control = $LevelSelectView/Cards/Card3
@onready var btn_stage_3: Button = $LevelSelectView/Cards/Card3/BtnStage3
@onready var card_3_info: Label = $LevelSelectView/Cards/Card3/InfoPanel/Margin/VBox/ScoreLabel
@onready var lock_overlay_3: Control = $LevelSelectView/Cards/Card3/LockOverlay

@onready var status_label: Label = $LevelSelectView/StatusLabel

func _ready() -> void:
	_setup_background_texture()
	_setup_curved_title()

	btn_play.pressed.connect(_on_play_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_back.pressed.connect(_on_back_pressed)

	btn_stage_1.pressed.connect(func(): _start_game_at_level(1))
	btn_stage_2.pressed.connect(func(): _on_stage_clicked(2))
	btn_stage_3.pressed.connect(func(): _on_stage_clicked(3))

	main_view.visible = true
	level_select_view.visible = false

	_update_ui_state()

func _setup_curved_title() -> void:
	for child in curved_title_container.get_children():
		child.queue_free()

	var text = "CLIMB THE SKY"
	var radius = 680.0
	var center = Vector2(960.0, 960.0)
	var max_angle = deg_to_rad(26.0)

	for i in range(text.length()):
		var ch = text[i]
		if ch == " ":
			continue
		var t = float(i) / float(text.length() - 1)
		var angle = lerp(-max_angle, max_angle, t)
		var px = center.x + radius * sin(angle)
		var py = center.y - radius * cos(angle)

		var lbl = Label.new()
		lbl.text = ch
		lbl.add_theme_font_size_override("font_size", 72)
		lbl.add_theme_color_override("font_color", Color(0.24, 0.26, 0.29, 1.0))
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.20, 0.22, 1.0))
		lbl.rotation = angle
		lbl.pivot_offset = Vector2(25, 40)
		lbl.position = Vector2(px - 25, py - 40)
		curved_title_container.add_child(lbl)

func _setup_background_texture() -> void:
	var paths = [
		"res://assets/images/level_select_bg.jpg",
		"res://assets/images/media_1792480703648_09aa453f.jpg",
		"C:/Icad/College/DIMAS TI 2026/Game/climb-the-sky/assets/images/level_select_bg.jpg"
	]
	for p in paths:
		if FileAccess.file_exists(p):
			var img = Image.load_from_file(p)
			if img:
				level_select_bg.texture = ImageTexture.create_from_image(img)
				break

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

	# 1. Level 1: Mountain (Mean) - Selalu Terbuka
	btn_stage_1.disabled = false
	var text_1 = "Level 1: Mountain (Mean)\n5 Titik Soal • Skor Maks: 500"
	var info_1_text = "5 Titik Soal • Max Skor: 500"
	if gs.is_level_1_cleared:
		var best_1 = int(gs.best_scores.get(1, 0))
		text_1 += " | Skor Terbaik: %d" % best_1
		info_1_text = "Tamat ⭐ Skor Terbaik: %d" % best_1
	btn_stage_1.text = text_1
	if card_1_info:
		card_1_info.text = info_1_text

	# 2. Level 2: Underground (Median) - Terbuka setelah Level 1 selesai
	var is_unlocked_2 = gs.is_level_unlocked(2)
	btn_stage_2.disabled = not is_unlocked_2
	if lock_overlay_2:
		lock_overlay_2.visible = not is_unlocked_2
	var text_2 = ""
	var info_2_text = ""
	if is_unlocked_2:
		text_2 = "Level 2: Underground (Median)\n4 Titik Soal • Skor Maks: 400"
		info_2_text = "4 Titik Soal • Max Skor: 400"
		if gs.is_level_2_cleared:
			var best_2 = int(gs.best_scores.get(2, 0))
			text_2 += " | Skor Terbaik: %d" % best_2
			info_2_text = "Tamat ⭐ Skor Terbaik: %d" % best_2
	else:
		text_2 = "🔒 Level 2: Underground (Median)\n[Terkunci - Selesaikan Level 1 Terlebih Dahulu]"
		info_2_text = "Terkunci"
	btn_stage_2.text = text_2
	if card_2_info:
		card_2_info.text = info_2_text

	# 3. Level 3: Sky (Evaluasi Komparatif Mean & Median) - Terbuka setelah Level 2 selesai
	var is_unlocked_3 = gs.is_level_unlocked(3)
	btn_stage_3.disabled = not is_unlocked_3
	if lock_overlay_3:
		lock_overlay_3.visible = not is_unlocked_3
	var text_3 = ""
	var info_3_text = ""
	if is_unlocked_3:
		text_3 = "Level 3: Sky (Evaluasi Komparatif)\n3 Titik Soal • Skor Maks: 300"
		info_3_text = "3 Titik Soal • Max Skor: 300"
		if gs.is_level_3_cleared:
			var best_3 = int(gs.best_scores.get(3, 0))
			text_3 += " | Skor Terbaik: %d" % best_3
			info_3_text = "Tamat ⭐ Skor Terbaik: %d" % best_3
	else:
		text_3 = "🔒 Level 3: Sky (Evaluasi Komparatif)\n[Terkunci - Selesaikan Level 2 Terlebih Dahulu]"
		info_3_text = "Terkunci"
	btn_stage_3.text = text_3
	if card_3_info:
		card_3_info.text = info_3_text

	# Status Label
	if not gs.is_level_1_cleared:
		status_label.text = "🌱 Pemain Baru: Memulai Petualangan di Level 1 (Mean)"
	elif not gs.is_level_2_cleared:
		status_label.text = "⭐ Progres: Level 1 Selesai! Level 2 (Median) Siap Dimainkan"
	elif not gs.is_level_3_cleared:
		status_label.text = "🌟 Progres: Level 2 Selesai! Level 3 (Kombinasi) Siap Dimainkan"
	else:
		status_label.text = "🏆 Prestasi: Seluruh Level (1, 2, & 3) Telah Berhasil Diselesaikan!"

func _on_play_pressed() -> void:
	main_view.visible = false
	level_select_view.visible = true

func _on_back_pressed() -> void:
	level_select_view.visible = false
	main_view.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_stage_clicked(level: int) -> void:
	var gs = _get_gs()
	if gs and not gs.is_level_unlocked(level):
		return
	_start_game_at_level(level)

func _start_game_at_level(level: int) -> void:
	var gs = _get_gs()
	if gs:
		gs.start_level(level)
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
