extends Control
class_name MapScene

# MapScene v2.0 (Modern, Clean, & Palette desain.md)
# Menampilkan peta jalur vertikal linear naik ke atas dari Titik 1 ke Titik N
# Terintegrasi ThemeManager, palet warna desain.md, ikon vektor flat SVG,
# serta pop-up Tabel Distribusi Frekuensi modern bebas emoji.

@export var node_scene: PackedScene = preload("res://scenes/map/map_node.tscn")

# --- BACKGROUND ---
@onready var background_rect: ColorRect = $Background
@onready var background_art: TextureRect = $BackgroundArt

# --- SCROLL & KANVAS JALUR ---
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_canvas: Control = $ScrollContainer/MapCanvas

# --- TOP HUD ---
@onready var top_hud: Panel = $TopHUD
@onready var btn_menu: Button = $TopHUD/MarginContainer/HBoxContainer/BtnMenu
@onready var level_badge: PanelContainer = $TopHUD/MarginContainer/HBoxContainer/StageContainer/Margin/HBox/LevelBadge
@onready var level_badge_label: Label = $TopHUD/MarginContainer/HBoxContainer/StageContainer/Margin/HBox/LevelBadge/BadgeMargin/BadgeLabel
@onready var stage_label: Label = $TopHUD/MarginContainer/HBoxContainer/StageContainer/Margin/HBox/StageLabel
@onready var progress_label: Label = $TopHUD/MarginContainer/HBoxContainer/ProgressContainer/Margin/ProgressLabel
@onready var btn_frequency_table: Button = $TopHUD/MarginContainer/HBoxContainer/BtnFrequencyTable
@onready var star_icon: TextureRect = $TopHUD/MarginContainer/HBoxContainer/ScoreContainer/Margin/HBox/StarIcon
@onready var score_label: Label = $TopHUD/MarginContainer/HBoxContainer/ScoreContainer/Margin/HBox/ScoreLabel

# --- INFO PANEL ---
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_text: Label = $InfoPanel/MarginContainer/VBoxContainer/InfoText

# --- MODAL TABEL DISTRIBUSI FREKUENSI ---
@onready var table_modal: Control = $TableModal
@onready var modal_subtitle: Label = $TableModal/CenterContainer/Panel/Margin/VBox/Subtitle
@onready var raw_data_label: Label = $TableModal/CenterContainer/Panel/Margin/VBox/RawDataPanel/Margin/VBox/RawText
@onready var table_rows_container: VBoxContainer = $TableModal/CenterContainer/Panel/Margin/VBox/TableScroll/TableRows
@onready var table_header_icon: TextureRect = $TableModal/CenterContainer/Panel/Margin/VBox/HeaderHBox/HeaderIcon
@onready var btn_close_x: Button = $TableModal/CenterContainer/Panel/Margin/VBox/HeaderHBox/BtnCloseX
@onready var btn_close_bottom: Button = $TableModal/CenterContainer/Panel/Margin/VBox/BtnCloseBottom

# State peta linear
var total_points: int = 5
var current_point: int = 1
var point_positions: Dictionary = {} # int (1..N) -> Vector2
var node_ui_map: Dictionary = {} # int (1..N) -> MapNodeUI

# Kompatibilitas legacy
var map_data: Dictionary = {"nodes": {}, "rows": []}
var node_positions: Dictionary:
	get:
		var legacy_dict: Dictionary = {}
		for k in point_positions.keys():
			legacy_dict[str(k)] = point_positions[k]
		return legacy_dict

func _ready() -> void:
	_setup_visual_theme()

	btn_menu.pressed.connect(_on_menu_pressed)
	btn_frequency_table.pressed.connect(_show_frequency_table_modal)
	btn_close_x.pressed.connect(_hide_frequency_table_modal)
	btn_close_bottom.pressed.connect(_hide_frequency_table_modal)

	var gs = _get_gs()
	if gs:
		if not gs.score_changed.is_connected(_on_score_changed):
			gs.score_changed.connect(_on_score_changed)
		if not gs.point_advanced.is_connected(_on_point_advanced):
			gs.point_advanced.connect(_on_point_advanced)

	build_linear_map()
	_update_hud()

	await get_tree().process_frame
	_scroll_to_current_point()

func _setup_visual_theme() -> void:
	var tm = _get_tm()
	if not tm:
		return

	# Terapkan palet latar utama #EAF6FF
	background_rect.color = tm.COLOR_BG_MAIN

	# Pasang icon flat vector SVG bebas emoji
	btn_menu.icon = tm.get_icon("arrow_left")
	btn_menu.add_theme_color_override("icon_normal_color", tm.COLOR_TEXT_NAVY)
	btn_menu.add_theme_color_override("icon_hover_color", tm.COLOR_BTN_PRIMARY)
	btn_menu.add_theme_color_override("icon_pressed_color", tm.COLOR_BTN_PRIMARY)
	btn_menu.add_theme_color_override("icon_focus_color", tm.COLOR_TEXT_NAVY)

	btn_frequency_table.icon = tm.get_icon("table")

	star_icon.texture = tm.get_icon("star")
	star_icon.modulate = Color("#FFC93C") # Emas / Kuning

	table_header_icon.texture = tm.get_icon("table")
	table_header_icon.modulate = tm.COLOR_BTN_PRIMARY

func _get_gs() -> Node:
	if is_inside_tree() and has_node("/root/GameState"):
		return get_node("/root/GameState")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("GameState"):
		return main_loop.root.get_node("GameState")
	return null

func _get_dm() -> Node:
	if is_inside_tree() and has_node("/root/DataManager"):
		return get_node("/root/DataManager")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("DataManager"):
		return main_loop.root.get_node("DataManager")
	return null

func _get_tm() -> Node:
	if is_inside_tree() and has_node("/root/ThemeManager"):
		return get_node("/root/ThemeManager")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("ThemeManager"):
		return main_loop.root.get_node("ThemeManager")
	return null

func _update_hud() -> void:
	var gs = _get_gs()
	var tm = _get_tm()
	var level_names = {
		1: "Level 1: Konsep & Perhitungan Rata-rata (Mean)",
		2: "Level 2: Perhitungan Rata-rata Tabel Frekuensi (Mean)",
		3: "Level 3: Analisis & Evaluasi Rata-rata (Mean)"
	}

	var lvl = gs.current_level if gs else 1
	var score = gs.level_score if gs else 0

	if level_badge_label:
		level_badge_label.text = "LEVEL %d" % lvl
	if stage_label:
		stage_label.text = level_names.get(lvl, "Level %d" % lvl)
	if progress_label:
		progress_label.text = "Titik %d dari %d" % [current_point, total_points]
	if score_label:
		score_label.text = "Skor: %d" % score

	if tm:
		var lvl_col = tm.get_level_color(lvl)
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = lvl_col
		b_style.set_corner_radius_all(10)
		level_badge.add_theme_stylebox_override("panel", b_style)

		# Wallpaper latar tematik toko sembako per level
		var bg_tex = tm.get_level_bg(lvl)
		if bg_tex:
			background_art.texture = bg_tex
			background_art.visible = true
		else:
			background_art.visible = false

func _on_score_changed(new_score: int, _delta: int) -> void:
	if score_label:
		score_label.text = "Skor: %d" % new_score

func _on_point_advanced(new_point: int, _total_pts: int) -> void:
	current_point = new_point
	_update_hud()
	_refresh_node_states()
	map_canvas.queue_redraw()
	_scroll_to_current_point()

func build_linear_map() -> void:
	for child in map_canvas.get_children():
		child.queue_free()
	node_ui_map.clear()
	point_positions.clear()

	var gs = _get_gs()
	var dm = _get_dm()

	var lvl = gs.current_level if gs else 1
	total_points = dm.get_total_points(lvl) if dm else 5
	current_point = gs.current_point_index if gs else 1

	var canvas_width = 1920.0
	var step_y = 190.0
	var canvas_height = max(1080.0, (total_points + 1) * step_y + 220.0)
	map_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)

	var center_x = canvas_width / 2.0
	var y_bottom = canvas_height - 200.0

	for p in range(1, total_points + 1):
		var y_pos = y_bottom - ((p - 1) * step_y)
		var pos = Vector2(center_x, y_pos)
		point_positions[p] = pos

		var node_instance: MapNodeUI = node_scene.instantiate()
		node_instance.position = pos - Vector2(42.0, 42.0)

		var p_state: MapNodeUI.NodeState = MapNodeUI.NodeState.LOCKED
		if p < current_point:
			p_state = MapNodeUI.NodeState.COMPLETED
		elif p == current_point:
			p_state = MapNodeUI.NodeState.CURRENT
		else:
			p_state = MapNodeUI.NodeState.LOCKED

		var q_data: Dictionary = dm.get_question(lvl, p) if dm else {}
		node_instance.setup_point(p, q_data, p_state)
		node_instance.node_clicked.connect(_on_node_clicked)

		map_canvas.add_child(node_instance)
		node_ui_map[p] = node_instance

	map_canvas.queue_redraw()

func _refresh_node_states() -> void:
	for p in node_ui_map.keys():
		var ui_node: MapNodeUI = node_ui_map[p]
		if p < current_point:
			ui_node.update_state(MapNodeUI.NodeState.COMPLETED)
		elif p == current_point:
			ui_node.update_state(MapNodeUI.NodeState.CURRENT)
		else:
			ui_node.update_state(MapNodeUI.NodeState.LOCKED)

func _on_node_clicked(p_index: int) -> void:
	print("Pemain memilih Titik %d (Titik aktif: %d)" % [p_index, current_point])
	if p_index == current_point:
		get_tree().change_scene_to_file("res://scenes/quiz/quiz_scene.tscn")
	elif p_index < current_point:
		_show_info("Titik %d telah selesai dikerjakan! Lanjutkan ke Titik %d yang sedang aktif." % [p_index, current_point])
	else:
		_show_info("Titik %d masih terkunci. Kerjakan soal pada Titik %d terlebih dahulu." % [p_index, current_point])

func _show_info(msg: String) -> void:
	if info_text:
		info_text.text = msg
	if info_panel:
		info_panel.visible = true

func _scroll_to_current_point() -> void:
	if point_positions.has(current_point):
		var target_y = point_positions[current_point].y
		scroll_container.scroll_vertical = int(max(0, target_y - 480.0))
	else:
		scroll_container.scroll_vertical = int(map_canvas.custom_minimum_size.y)

# --- MODAL TABEL DISTRIBUSI FREKUENSI ---
func _show_frequency_table_modal() -> void:
	var gs = _get_gs()
	var dm = _get_dm()
	var lvl = gs.current_level if gs else 1
	var tbl_data = dm.get_frequency_table(lvl) if dm else {}
	if tbl_data.is_empty():
		return

	modal_subtitle.text = "Level %d - %s: %s" % [
		lvl, tbl_data.get("topic", ""), tbl_data.get("title", "")
	]
	raw_data_label.text = tbl_data.get("raw_data", "")

	for child in table_rows_container.get_children():
		table_rows_container.remove_child(child)
		child.queue_free()

	# Baris Header
	var col_int = tbl_data.get("column_interval", "Interval")
	var col_freq = tbl_data.get("column_frequency", "Frekuensi")
	table_rows_container.add_child(_create_table_row(col_int, col_freq, true, false))

	# Baris Data Kelas Interval
	var rows: Array = tbl_data.get("rows", [])
	for i in range(rows.size()):
		var r = rows[i]
		var interval_str = str(r.get("interval", ""))
		var freq_str = str(r.get("frequency", ""))
		table_rows_container.add_child(_create_table_row(interval_str, freq_str, false, false, i % 2 == 1))

	# Baris Total / Jumlah
	var total_freq = str(tbl_data.get("total_frequency", 30))
	table_rows_container.add_child(_create_table_row("Jumlah", total_freq, false, true))

	table_modal.visible = true

func _hide_frequency_table_modal() -> void:
	table_modal.visible = false

func _create_table_row(col1: String, col2: String, is_header: bool, is_total: bool, is_zebra: bool = false) -> PanelContainer:
	var tm = _get_tm()
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)

	var hbox = HBoxContainer.new()
	var lbl1 = Label.new()
	lbl1.text = col1
	lbl1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl1.add_theme_font_size_override("font_size", 16)

	var lbl2 = Label.new()
	lbl2.text = col2
	lbl2.custom_minimum_size = Vector2(160, 0)
	lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl2.add_theme_font_size_override("font_size", 16)

	if is_header:
		style.bg_color = tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A")
		lbl1.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lbl2.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	elif is_total:
		style.bg_color = Color("#EAF6FF")
		style.border_color = tm.COLOR_BTN_PRIMARY if tm else Color("#1F6FEB")
		style.set_border_width_all(2)
		lbl1.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))
		lbl2.add_theme_color_override("font_color", tm.COLOR_BTN_PRIMARY if tm else Color("#1F6FEB"))
	else:
		style.bg_color = Color("#F4F9FF") if is_zebra else Color("#FFFFFF")
		style.border_color = Color("#E2E9F2")
		style.set_border_width_all(1)
		lbl1.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))
		lbl2.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))

	panel.add_theme_stylebox_override("panel", style)
	hbox.add_child(lbl1)
	hbox.add_child(lbl2)
	panel.add_child(hbox)
	return panel

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
