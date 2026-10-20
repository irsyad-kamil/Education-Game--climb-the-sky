extends Control
class_name MainMenu

# MainMenu v2.0 (Desain Modern, Responsif, & Palet desain.md)
# Tampilan awal minimalis dengan Judul Melengkung ("CLIMB THE SKY"), tombol PLAY & EXIT
# Pemilihan level ("LEVEL SELECT") muncul saat tombol PLAY diklik
# Menampilkan 3 kartu tahap dengan thumbnail ilustrasi asli: Mountain, Underground, Sky
# Menggunakan ikon vektor flat SVG (bebas emoji), tema terpusat, dan responsif

@onready var main_view: Control = $MainMenuView
@onready var main_menu_graphic: TextureRect = $MainMenuView/BackgroundGraphic
@onready var curved_title_container: Control = $MainMenuView/CurvedTitleContainer
@onready var btn_play: Button = $MainMenuView/ButtonsBox/BtnPlay
@onready var btn_quit: Button = $MainMenuView/ButtonsBox/BtnQuit

@onready var level_select_view: Control = $LevelSelectView
@onready var level_select_bg: TextureRect = $LevelSelectView/Background
@onready var btn_back: Button = $LevelSelectView/TopBar/BtnBack
@onready var back_icon: TextureRect = $LevelSelectView/TopBar/BtnBack/BackIcon

# Kartu Level 1 (Mountain)
@onready var card_1_pill: PanelContainer = $LevelSelectView/CardsCenter/CardsHBox/Card1/Content/PillMargin/Pill
@onready var card_1_thumb: TextureRect = $LevelSelectView/CardsCenter/CardsHBox/Card1/Content/ThumbClip/Thumb
@onready var card_1_info: Label = $LevelSelectView/CardsCenter/CardsHBox/Card1/Content/InfoMargin/VBox/ScoreLabel
@onready var btn_stage_1: Button = $LevelSelectView/CardsCenter/CardsHBox/Card1/BtnStage1

# Kartu Level 2 (Underground)
@onready var card_2_pill: PanelContainer = $LevelSelectView/CardsCenter/CardsHBox/Card2/Content/PillMargin/Pill
@onready var card_2_thumb: TextureRect = $LevelSelectView/CardsCenter/CardsHBox/Card2/Content/ThumbClip/Thumb
@onready var card_2_info: Label = $LevelSelectView/CardsCenter/CardsHBox/Card2/Content/InfoMargin/VBox/ScoreLabel
@onready var lock_overlay_2: Panel = $LevelSelectView/CardsCenter/CardsHBox/Card2/LockOverlay
@onready var lock_icon_2: TextureRect = $LevelSelectView/CardsCenter/CardsHBox/Card2/LockOverlay/Center/VBox/LockIcon
@onready var btn_stage_2: Button = $LevelSelectView/CardsCenter/CardsHBox/Card2/BtnStage2

# Kartu Level 3 (Sky)
@onready var card_3_pill: PanelContainer = $LevelSelectView/CardsCenter/CardsHBox/Card3/Content/PillMargin/Pill
@onready var card_3_thumb: TextureRect = $LevelSelectView/CardsCenter/CardsHBox/Card3/Content/ThumbClip/Thumb
@onready var card_3_info: Label = $LevelSelectView/CardsCenter/CardsHBox/Card3/Content/InfoMargin/VBox/ScoreLabel
@onready var lock_overlay_3: Panel = $LevelSelectView/CardsCenter/CardsHBox/Card3/LockOverlay
@onready var lock_icon_3: TextureRect = $LevelSelectView/CardsCenter/CardsHBox/Card3/LockOverlay/Center/VBox/LockIcon
@onready var btn_stage_3: Button = $LevelSelectView/CardsCenter/CardsHBox/Card3/BtnStage3

@onready var status_label: Label = $LevelSelectView/StatusContainer/StatusPill/Margin/StatusLabel

func _ready() -> void:
	var tm = _get_tm()
	if tm:
		$MainMenuView/Background.color = tm.COLOR_BG_MAIN

	_setup_visual_assets()
	_setup_curved_title()
	curved_title_container.visible = false

	btn_play.pressed.connect(_on_play_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_back.pressed.connect(_on_back_pressed)

	btn_stage_1.pressed.connect(func(): _start_game_at_level(1))
	btn_stage_2.pressed.connect(func(): _on_stage_clicked(2))
	btn_stage_3.pressed.connect(func(): _on_stage_clicked(3))

	var gs = _get_gs()
	if gs and gs.get("open_level_select_on_main_menu") == true:
		gs.open_level_select_on_main_menu = false
		main_view.visible = false
		level_select_view.visible = true
	else:
		main_view.visible = true
		level_select_view.visible = false

	_update_ui_state()

func _setup_visual_assets() -> void:
	var tm = _get_tm()
	
	# Background Main Menu (Bima's Grocery Challenges)
	var mm_bg_path = "res://assets/images/main_menu_bg.jpg"
	if FileAccess.file_exists(mm_bg_path):
		var img = Image.load_from_file(mm_bg_path)
		if img and main_menu_graphic:
			main_menu_graphic.texture = ImageTexture.create_from_image(img)

	# Background Level Select
	var bg_img_path = "res://assets/images/levels/background.jpg"
	if FileAccess.file_exists(bg_img_path):
		var img = Image.load_from_file(bg_img_path)
		if img:
			level_select_bg.texture = ImageTexture.create_from_image(img)
	elif FileAccess.file_exists("res://assets/images/level_select_bg.jpg"):
		var img = Image.load_from_file("res://assets/images/level_select_bg.jpg")
		if img:
			level_select_bg.texture = ImageTexture.create_from_image(img)

	# Ikon Tombol Back
	if tm:
		back_icon.texture = tm.get_icon("arrow_left")
		lock_icon_2.texture = tm.get_icon("lock")
		lock_icon_3.texture = tm.get_icon("lock")

	# Thumbnails Ilustrasi Level
	if tm:
		var t1 = tm.get_level_thumb(1)
		if t1:
			card_1_thumb.texture = t1
		var t2 = tm.get_level_thumb(2)
		if t2:
			card_2_thumb.texture = t2
		var t3 = tm.get_level_thumb(3)
		if t3:
			card_3_thumb.texture = t3

	# Pill Badge Styles per Level Sesuai Palet desain.md
	if tm:
		var p1_style = StyleBoxFlat.new()
		p1_style.bg_color = tm.COLOR_LVL1_ORANGE # Oranye Level 1
		p1_style.set_corner_radius_all(10)
		card_1_pill.add_theme_stylebox_override("panel", p1_style)

		var p2_style = StyleBoxFlat.new()
		p2_style.bg_color = tm.COLOR_LVL2_PINK # Pink Level 2
		p2_style.set_corner_radius_all(10)
		card_2_pill.add_theme_stylebox_override("panel", p2_style)

		var p3_style = StyleBoxFlat.new()
		p3_style.bg_color = tm.COLOR_LVL3_YELLOW # Kuning Level 3
		p3_style.set_corner_radius_all(10)
		card_3_pill.add_theme_stylebox_override("panel", p3_style)

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
		# Teks utama Navy sesuai desain.md (#1E2A4A)
		lbl.add_theme_color_override("font_color", Color("#1E2A4A"))
		lbl.add_theme_constant_override("outline_size", 4)
		lbl.add_theme_color_override("font_outline_color", Color("#121A30"))
		lbl.rotation = angle
		lbl.pivot_offset = Vector2(25, 40)
		lbl.position = Vector2(px - 25, py - 40)
		curved_title_container.add_child(lbl)

func _get_gs() -> Node:
	if is_inside_tree() and has_node("/root/GameState"):
		return get_node("/root/GameState")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var st = main_loop as SceneTree
		if st.root and st.root.has_node("GameState"):
			return st.root.get_node("GameState")
	return null

func _get_tm() -> Node:
	if is_inside_tree() and has_node("/root/ThemeManager"):
		return get_node("/root/ThemeManager")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree:
		var st = main_loop as SceneTree
		if st.root and st.root.has_node("ThemeManager"):
			return st.root.get_node("ThemeManager")
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
		info_1_text = "Selesai • Skor Terbaik: %d" % best_1
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
			info_2_text = "Selesai • Skor Terbaik: %d" % best_2
	else:
		text_2 = "Level 2: Underground (Median)\n[Terkunci - Selesaikan Level 1 Terlebih Dahulu]"
		info_2_text = "Terkunci (Selesaikan Level 1)"
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
			info_3_text = "Selesai • Skor Terbaik: %d" % best_3
	else:
		text_3 = "Level 3: Sky (Evaluasi Komparatif)\n[Terkunci - Selesaikan Level 2 Terlebih Dahulu]"
		info_3_text = "Terkunci (Selesaikan Level 2)"
	btn_stage_3.text = text_3
	if card_3_info:
		card_3_info.text = info_3_text

	# Status Label di Layar Pilih Level
	if not gs.is_level_1_cleared:
		status_label.text = "Pemain Baru: Memulai Petualangan di Level 1 (Mean)"
	elif not gs.is_level_2_cleared:
		status_label.text = "Level 1 Selesai! Level 2 (Median) Siap Dimainkan"
	elif not gs.is_level_3_cleared:
		status_label.text = "Level 2 Selesai! Level 3 (Kombinasi) Siap Dimainkan"
	else:
		status_label.text = "Prestasi: Seluruh Level (1, 2, & 3) Telah Berhasil Diselesaikan!"

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
