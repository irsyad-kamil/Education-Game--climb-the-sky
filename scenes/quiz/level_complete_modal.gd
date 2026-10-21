extends Control
class_name LevelCompleteModalUI

# LevelCompleteModalUI v1.0 (desain.md Architecture)
# Modal perayaan penyelesaian level dengan ekspresi Bima senang,
# ringkasan skor level, skor terbaik, status unlock materi berikutnya,
# serta navigasi kembali ke Menu Utama atau Pilih Level.

signal confirmed
signal menu_requested
signal continue_requested

var dialog_text: String = ""

@onready var header_banner: PanelContainer = $CenterContainer/Card/Margin/VBox/HeaderBanner
@onready var title_label: Label = $CenterContainer/Card/Margin/VBox/HeaderBanner/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/Card/Margin/VBox/HeaderBanner/Margin/VBox/SubtitleLabel

@onready var bima_avatar: TextureRect = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/BimaSection/AvatarFrame/Margin/BimaAvatar
@onready var speech_text: Label = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/BimaSection/SpeechBubble/Margin/SpeechVBox/SpeechText

@onready var score_value: Label = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/ScoreHBox/CardScore/Margin/ScoreVBox/HBox/ScoreValue
@onready var best_value: Label = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/ScoreHBox/CardBest/Margin/BestVBox/HBox/BestValue
@onready var score_star_icon: TextureRect = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/ScoreHBox/CardScore/Margin/ScoreVBox/HBox/StarIcon
@onready var best_star_icon: TextureRect = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/ScoreHBox/CardBest/Margin/BestVBox/HBox/StarIcon

@onready var unlock_banner: PanelContainer = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/UnlockBanner
@onready var unlock_icon: TextureRect = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/UnlockBanner/Margin/UnlockHBox/UnlockIcon
@onready var unlock_text: Label = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/UnlockBanner/Margin/UnlockHBox/UnlockText

@onready var btn_menu: Button = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/ActionButtons/BtnMenu
@onready var btn_continue: Button = $CenterContainer/Card/Margin/VBox/ContentMargin/ContentVBox/ActionButtons/BtnContinue

func _ready() -> void:
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)

func popup_centered() -> void:
	visible = true

func hide_modal() -> void:
	visible = false

func setup_level_complete(lvl: int, final_score: int, best_score: int) -> void:
	var tm = _get_tm()
	var lvl_col = tm.get_level_color(lvl) if tm else Color("#FF8A3D")
	
	# Header Title & Subtitle
	var level_titles = {
		1: "Level 1: Cokelat (Mean)",
		2: "Level 2: Permen (Mean)",
		3: "Level 3: Mi Instan (Mean)"
	}
	title_label.text = "%s SELESAI!" % level_titles.get(lvl, "LEVEL %d" % lvl).to_upper()
	title_label.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if lvl == 3 else Color(1, 1, 1, 1))
	subtitle_label.text = "Hebat! Seluruh data penjualan pada level ini berhasil diselesaikan!"
	subtitle_label.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if lvl == 3 else Color(0.95, 0.95, 0.95, 1))
	
	# Header styling dengan warna aksen level (desain.md)
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = lvl_col
	h_style.corner_radius_top_left = 22
	h_style.corner_radius_top_right = 22
	h_style.corner_radius_bottom_left = 0
	h_style.corner_radius_bottom_right = 0
	header_banner.add_theme_stylebox_override("panel", h_style)
	
	# Bima Avatar Senang
	if tm:
		var tex = tm.get_bima_avatar("senang")
		if tex:
			bima_avatar.texture = tex
	
	speech_text.text = "Luar biasa! Terima kasih telah membantuku dan Ayah mengolah catatan penjualan toko sembako ini dengan teliti!"
	
	# Score Cards
	score_value.text = "%d Poin" % final_score
	best_value.text = "%d Poin" % best_score
	
	if tm:
		var star_tex = tm.get_icon("star")
		if star_tex:
			score_star_icon.texture = star_tex
			score_star_icon.modulate = Color("#FFC93C")
			best_star_icon.texture = star_tex
			best_star_icon.modulate = Color("#FFC93C")
		
		var check_tex = tm.get_icon("check")
		if check_tex:
			unlock_icon.texture = check_tex
			unlock_icon.modulate = tm.COLOR_CORRECT_GREEN
			
		btn_menu.icon = tm.get_icon("arrow_left")
		btn_menu.add_theme_color_override("icon_normal_color", tm.COLOR_TEXT_NAVY)
		btn_menu.add_theme_color_override("icon_hover_color", tm.COLOR_BTN_PRIMARY)
		btn_continue.icon = tm.get_icon("map")
	
	# Unlock Announcement Text
	if lvl == 1:
		unlock_text.text = "Level 2 (Penjualan Permen) Kini Terbuka di Menu Level!"
		btn_continue.text = "Pilih Level Berikutnya"
	elif lvl == 2:
		unlock_text.text = "Level 3 (Penjualan Mi Instan) Kini Terbuka di Menu Level!"
		btn_continue.text = "Pilih Level Berikutnya"
	else:
		unlock_text.text = "Selamat! Seluruh materi Mean (Rata-rata) telah berhasil kamu kuasai!"
		btn_continue.text = "Selesai & Ke Menu Utama"
	
	visible = true

func _on_menu_pressed() -> void:
	visible = false
	var gs = _get_gs()
	if gs:
		gs.open_level_select_on_main_menu = false
	if get_signal_connection_list("menu_requested").size() > 0:
		emit_signal("menu_requested")
	elif is_inside_tree() and get_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_continue_pressed() -> void:
	visible = false
	var gs = _get_gs()
	if gs:
		gs.open_level_select_on_main_menu = true
	var has_listener = get_signal_connection_list("continue_requested").size() > 0 or get_signal_connection_list("confirmed").size() > 0
	if has_listener:
		emit_signal("continue_requested")
		emit_signal("confirmed")
	elif is_inside_tree() and get_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _get_gs() -> Node:
	if is_inside_tree() and has_node("/root/GameState"):
		return get_node("/root/GameState")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("GameState"):
		return main_loop.root.get_node("GameState")
	return null

func _get_tm() -> Node:
	if is_inside_tree() and has_node("/root/ThemeManager"):
		return get_node("/root/ThemeManager")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("ThemeManager"):
		return main_loop.root.get_node("ThemeManager")
	return null
