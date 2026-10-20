extends Control
class_name QuizScene

# QuizScene v2.0 (Modern, Bright, & Central Palette desain.md)
# Mengelola interaksi kuis pembelajaran statistika berbasis konteks toko sembako keluarga Bima
# Mendukung 4 tipe soal: PG, TF, Isian Singkat, dan Matching (3 pasangan dengan socket UX 48px)
# Terintegrasi avatar ekspresi Bima (normal, senang, bingung), tema terpusat ThemeManager,
# serta pop-up Tabel Distribusi Frekuensi modern dengan ikon flat vector SVG bebas emoji.

# --- TOP BAR & HUD ---
@onready var top_bar: Panel = $TopBar
@onready var stage_label: Label = $TopBar/MarginContainer/HBoxContainer/StageContainer/Margin/HBox/StageLabel
@onready var level_badge: PanelContainer = $TopBar/MarginContainer/HBoxContainer/StageContainer/Margin/HBox/LevelBadge
@onready var level_badge_label: Label = $TopBar/MarginContainer/HBoxContainer/StageContainer/Margin/HBox/LevelBadge/BadgeMargin/BadgeLabel
@onready var score_label: Label = $TopBar/MarginContainer/HBoxContainer/ScoreContainer/Margin/HBox/ScoreLabel
@onready var star_icon: TextureRect = $TopBar/MarginContainer/HBoxContainer/ScoreContainer/Margin/HBox/StarIcon
@onready var btn_frequency_table: Button = $TopBar/MarginContainer/HBoxContainer/BtnFrequencyTable
@onready var btn_map: Button = $TopBar/MarginContainer/HBoxContainer/BtnMap
@onready var btn_menu: Button = $TopBar/MarginContainer/HBoxContainer/BtnMenu

# --- BACKGROUND ---
@onready var background_rect: ColorRect = $Background
@onready var background_art: TextureRect = $BackgroundArt

# --- STORY PANEL (BIMA AVATAR & DIALOG) ---
@onready var story_panel: PanelContainer = $ScrollContainer/CenterContainer/MainContent/StoryPanel
@onready var bima_avatar: TextureRect = $ScrollContainer/CenterContainer/MainContent/StoryPanel/MarginContainer/HBoxContainer/AvatarFrame/Margin/BimaAvatar
@onready var speaker_badge: PanelContainer = $ScrollContainer/CenterContainer/MainContent/StoryPanel/MarginContainer/HBoxContainer/TextVBox/SpeakerBadge
@onready var speaker_label: Label = $ScrollContainer/CenterContainer/MainContent/StoryPanel/MarginContainer/HBoxContainer/TextVBox/SpeakerBadge/Margin/SpeakerLabel
@onready var narrative_label: Label = $ScrollContainer/CenterContainer/MainContent/StoryPanel/MarginContainer/HBoxContainer/TextVBox/NarrativeLabel

# --- QUESTION PANEL ---
@onready var question_panel: PanelContainer = $ScrollContainer/CenterContainer/MainContent/QuestionPanel
@onready var point_chip: PanelContainer = $ScrollContainer/CenterContainer/MainContent/QuestionPanel/MarginContainer/VBox/HeaderHBox/PointChip
@onready var point_chip_label: Label = $ScrollContainer/CenterContainer/MainContent/QuestionPanel/MarginContainer/VBox/HeaderHBox/PointChip/Margin/PointChipLabel
@onready var prompt_label: RichTextLabel = $ScrollContainer/CenterContainer/MainContent/QuestionPanel/MarginContainer/VBox/PromptLabel

# --- FEEDBACK PANEL ---
@onready var feedback_panel: PanelContainer = $ScrollContainer/CenterContainer/MainContent/FeedbackPanel
@onready var feedback_icon: TextureRect = $ScrollContainer/CenterContainer/MainContent/FeedbackPanel/MarginContainer/HBox/FeedbackIcon
@onready var feedback_label: Label = $ScrollContainer/CenterContainer/MainContent/FeedbackPanel/MarginContainer/HBox/FeedbackLabel
@onready var feedback_badge: PanelContainer = $ScrollContainer/CenterContainer/MainContent/FeedbackPanel/MarginContainer/HBox/FeedbackBadge
@onready var feedback_badge_label: Label = $ScrollContainer/CenterContainer/MainContent/FeedbackPanel/MarginContainer/HBox/FeedbackBadge/Margin/BadgeLabel

# --- SOAL PANELS ---
@onready var panel_pg: GridContainer = $ScrollContainer/CenterContainer/MainContent/Panels/MultipleChoicePanel
@onready var panel_tf: HBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/TrueFalsePanel

@onready var panel_isian: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/ShortAnswerPanel
@onready var input_isian: LineEdit = $ScrollContainer/CenterContainer/MainContent/Panels/ShortAnswerPanel/InputRow/InputIsian
@onready var btn_submit_isian: Button = $ScrollContainer/CenterContainer/MainContent/Panels/ShortAnswerPanel/InputRow/BtnSubmitIsian

@onready var panel_procedure: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/ProcedurePanel
@onready var procedure_items_list: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/ProcedurePanel/ItemsList
@onready var btn_check_procedure: Button = $ScrollContainer/CenterContainer/MainContent/Panels/ProcedurePanel/BtnCheckProcedure

@onready var panel_matching: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/MatchingPanel
@onready var matching_instruction: Label = $ScrollContainer/CenterContainer/MainContent/Panels/MatchingPanel/InstructionLabel
@onready var matching_left_col: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/MatchingPanel/Columns/LeftCol
@onready var matching_right_col: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/MatchingPanel/Columns/RightCol
@onready var matching_status_label: Label = $ScrollContainer/CenterContainer/MainContent/Panels/MatchingPanel/MatchingStatusLabel
@onready var btn_reset_matching: Button = $ScrollContainer/CenterContainer/MainContent/Panels/MatchingPanel/MatchingActionRow/BtnResetMatching
@onready var btn_check_matching: Button = $ScrollContainer/CenterContainer/MainContent/Panels/MatchingPanel/MatchingActionRow/BtnCheckMatching

# --- ACTION AREA ---
@onready var btn_next_point: Button = $ScrollContainer/CenterContainer/MainContent/ActionArea/BtnNextPoint
@onready var level_complete_modal: Control = $Popups/LevelCompleteModal

# --- MODAL TABEL DISTRIBUSI FREKUENSI ---
@onready var table_modal: Control = $Popups/TableModal
@onready var modal_subtitle: Label = $Popups/TableModal/CenterContainer/Panel/Margin/VBox/Subtitle
@onready var raw_data_label: Label = $Popups/TableModal/CenterContainer/Panel/Margin/VBox/RawDataPanel/Margin/VBox/RawText
@onready var table_rows_container: VBoxContainer = $Popups/TableModal/CenterContainer/Panel/Margin/VBox/TableScroll/TableRows
@onready var table_header_icon: TextureRect = $Popups/TableModal/CenterContainer/Panel/Margin/VBox/HeaderHBox/HeaderIcon
@onready var btn_close_x: Button = $Popups/TableModal/CenterContainer/Panel/Margin/VBox/HeaderHBox/BtnCloseX
@onready var btn_close_bottom: Button = $Popups/TableModal/CenterContainer/Panel/Margin/VBox/BtnCloseBottom

# Warna pasangan matching sesuai palet desain.md (Biru, Oranye, Pink)
const PAIR_COLORS = [
	Color("#1F6FEB"), # Pasangan 1: Biru Utama
	Color("#FF8A3D"), # Pasangan 2: Oranye Level 1
	Color("#FF6FAE")  # Pasangan 3: Pink Level 2
]

var current_question: Dictionary = {}
var procedure_order_list: Array = []
var user_pairs: Dictionary = {}       # left_id -> right_id
var selected_left_id: String = ""
var shuffled_right_items: Array = []
var is_solved: bool = false

func _ready() -> void:
	_setup_visual_theme()

	btn_map.pressed.connect(_on_map_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_frequency_table.pressed.connect(_show_frequency_table_modal)
	btn_close_x.pressed.connect(_hide_frequency_table_modal)
	btn_close_bottom.pressed.connect(_hide_frequency_table_modal)

	btn_submit_isian.pressed.connect(_on_submit_isian)
	input_isian.text_submitted.connect(func(_t): _on_submit_isian())
	btn_check_procedure.pressed.connect(_on_check_procedure)
	btn_reset_matching.pressed.connect(_on_reset_matching)
	btn_check_matching.pressed.connect(_on_check_matching)
	btn_next_point.pressed.connect(_on_next_point_pressed)
	if level_complete_modal:
		if level_complete_modal.has_signal("menu_requested"):
			level_complete_modal.menu_requested.connect(_on_level_complete_menu)
		if level_complete_modal.has_signal("continue_requested"):
			level_complete_modal.continue_requested.connect(_on_level_complete_continue)
		elif level_complete_modal.has_signal("confirmed"):
			level_complete_modal.confirmed.connect(_on_level_complete_continue)

	var gs = _get_gs()
	if gs and not gs.answer_revealed.is_connected(_on_answer_revealed):
		gs.answer_revealed.connect(_on_answer_revealed)

	_load_current_point_question()

func _setup_visual_theme() -> void:
	var tm = _get_tm()
	if not tm:
		return

	# Terapkan palet latar utama
	background_rect.color = tm.COLOR_BG_MAIN

	# Pasang icon flat vector SVG bebas emoji
	btn_map.icon = tm.get_icon("map")
	btn_menu.icon = tm.get_icon("arrow_left")
	btn_frequency_table.icon = tm.get_icon("table")
	star_icon.texture = tm.get_icon("star")
	star_icon.modulate = Color("#FFC93C") # Emas / Kuning
	table_header_icon.texture = tm.get_icon("table")
	table_header_icon.modulate = tm.COLOR_BTN_PRIMARY
	btn_reset_matching.icon = tm.get_icon("reset")

	# Kontras tinggi untuk ikon tombol sekunder (Navy di atas shape putih)
	for btn in [btn_map, btn_menu, btn_reset_matching]:
		btn.add_theme_color_override("icon_normal_color", tm.COLOR_TEXT_NAVY)
		btn.add_theme_color_override("icon_hover_color", tm.COLOR_BTN_PRIMARY)
		btn.add_theme_color_override("icon_pressed_color", tm.COLOR_BTN_PRIMARY)
		btn.add_theme_color_override("icon_focus_color", tm.COLOR_TEXT_NAVY)

	# Pasang avatar Bima ekspresi netral awal
	_set_bima_avatar("normal")

func _set_bima_avatar(expression: String) -> void:
	var tm = _get_tm()
	if tm:
		var tex = tm.get_bima_avatar(expression)
		if tex:
			bima_avatar.texture = tex

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

func _update_top_bar() -> void:
	var gs = _get_gs()
	var dm = _get_dm()
	var tm = _get_tm()
	var lvl = gs.current_level if gs else 1
	var pt = gs.current_point_index if gs else 1
	var total_pts = dm.get_total_points(lvl) if dm else 5
	var score = gs.level_score if gs else 0

	var level_titles = {
		1: "Konsep Rata-rata (Mean)",
		2: "Konsep Nilai Tengah (Median)",
		3: "Evaluasi Komparatif Mean & Median"
	}

	# Label & Badge level
	level_badge_label.text = "LEVEL %d" % lvl
	stage_label.text = "%s • Titik %d dari %d" % [level_titles.get(lvl, "Level %d" % lvl), pt, total_pts]
	score_label.text = "Skor: %d" % score

	# Warnai badge level & border soal sesuai warna aksen level (desain.md)
	if tm:
		var lvl_color = tm.get_level_color(lvl)
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = lvl_color
		b_style.set_corner_radius_all(10)
		level_badge.add_theme_stylebox_override("panel", b_style)

		# Point chip styling
		var chip_style = StyleBoxFlat.new()
		chip_style.bg_color = lvl_color
		chip_style.set_corner_radius_all(8)
		point_chip.add_theme_stylebox_override("panel", chip_style)
		point_chip_label.text = "TITIK %d DARI %d" % [pt, total_pts]
		point_chip_label.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if lvl == 3 else Color(1, 1, 1, 1))

		# Left border question card
		var q_style = tm.create_card_style(tm.COLOR_CARD_WHITE, 18, Color(0.85, 0.90, 0.96))
		q_style.border_width_left = 6
		q_style.border_color = lvl_color
		question_panel.add_theme_stylebox_override("panel", q_style)

		# Wallpaper background halus tematik per level
		var bg_tex = tm.get_level_bg(lvl)
		if bg_tex:
			background_art.texture = bg_tex
			background_art.visible = true
		else:
			background_art.visible = false

func _load_current_point_question() -> void:
	var gs = _get_gs()
	var dm = _get_dm()
	if not gs or not dm:
		return

	is_solved = false
	feedback_panel.visible = false
	btn_next_point.visible = false
	table_modal.visible = false

	_set_bima_avatar("normal")
	_update_top_bar()

	current_question = gs.get_current_question()
	if current_question.is_empty():
		current_question = dm.get_question(gs.current_level, gs.current_point_index)

	if current_question.is_empty():
		prompt_label.text = "Soal tidak ditemukan untuk level dan titik ini."
		return

	narrative_label.text = current_question.get("narrative", "Bima membantu ayah membuka buku catatan penjualan toko sembako...")
	prompt_label.text = current_question.get("prompt", "")

	# Sembunyikan semua subpanel sebelum mengaktifkan yang sesuai
	panel_pg.visible = false
	panel_tf.visible = false
	panel_isian.visible = false
	panel_procedure.visible = false
	panel_matching.visible = false

	var q_type = current_question.get("type", "")
	match q_type:
		"PG":
			_setup_multiple_choice()
		"TF":
			_setup_true_false()
		"Isian":
			_setup_short_answer()
		"Prosedur":
			_setup_procedure()
		"Matching":
			_setup_matching()

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

# --- TIPE 1: PILIHAN GANDA (PG) ---
func _setup_multiple_choice() -> void:
	panel_pg.visible = true
	for child in panel_pg.get_children():
		panel_pg.remove_child(child)
		child.queue_free()

	var tm = _get_tm()
	var options: Array = current_question.get("options", [])
	for opt in options:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(560, 64)
		btn.text = "   %s.  %s" % [opt.get("key", ""), opt.get("text", "")]
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Styling Card Putih Bersih
		var norm_style = tm.create_card_style(tm.COLOR_CARD_WHITE, 14, Color(0.84, 0.88, 0.94)) if tm else StyleBoxFlat.new()
		var hov_style = tm.create_card_style(Color("#EAF6FF"), 14, tm.COLOR_BTN_PRIMARY) if tm else StyleBoxFlat.new()
		btn.add_theme_stylebox_override("normal", norm_style)
		btn.add_theme_stylebox_override("hover", hov_style)
		btn.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))
		btn.add_theme_color_override("font_hover_color", tm.COLOR_BTN_PRIMARY if tm else Color("#1F6FEB"))

		btn.pressed.connect(func(): _on_pg_selected(opt.get("key", ""), btn))
		panel_pg.add_child(btn)

func _on_pg_selected(chosen_key: String, btn: Button) -> void:
	if is_solved:
		return
	var correct_key = current_question.get("correct_answer", "")
	if correct_key.is_empty():
		correct_key = current_question.get("correct_key", "")

	var is_correct = (chosen_key.to_upper() == correct_key.to_upper())
	var tm = _get_tm()

	if not is_correct:
		btn.disabled = true
		if tm:
			var wrong_style = tm.create_card_style(Color("#FFF0F0"), 14, tm.COLOR_WRONG_RED)
			btn.add_theme_stylebox_override("disabled", wrong_style)
			btn.add_theme_color_override("font_disabled_color", Color("#C53030"))
	else:
		if tm:
			var corr_style = tm.create_card_style(Color("#E8FAF2"), 14, tm.COLOR_CORRECT_GREEN)
			btn.add_theme_stylebox_override("normal", corr_style)
			btn.add_theme_color_override("font_color", Color("#15803D"))

	_process_answer_result(is_correct)

# --- TIPE 2: BENAR / SALAH (TF) ---
func _setup_true_false() -> void:
	panel_tf.visible = true
	for child in panel_tf.get_children():
		panel_tf.remove_child(child)
		child.queue_free()

	var tm = _get_tm()
	for val in ["BENAR", "SALAH"]:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(280, 64)
		btn.text = val
		btn.add_theme_font_size_override("font_size", 20)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var norm_style = tm.create_card_style(tm.COLOR_CARD_WHITE, 16, Color(0.84, 0.88, 0.94)) if tm else StyleBoxFlat.new()
		var hov_style = tm.create_card_style(Color("#EAF6FF"), 16, tm.COLOR_BTN_PRIMARY) if tm else StyleBoxFlat.new()
		btn.add_theme_stylebox_override("normal", norm_style)
		btn.add_theme_stylebox_override("hover", hov_style)
		btn.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))
		btn.add_theme_color_override("font_hover_color", tm.COLOR_BTN_PRIMARY if tm else Color("#1F6FEB"))

		btn.pressed.connect(func(): _on_tf_selected(val, btn))
		panel_tf.add_child(btn)

func _on_tf_selected(chosen_val: String, btn: Button) -> void:
	if is_solved:
		return
	var correct_val = current_question.get("correct_answer", "")
	var is_correct = (chosen_val.to_upper() == correct_val.to_upper())
	var tm = _get_tm()

	if not is_correct:
		btn.disabled = true
		if tm:
			var wrong_style = tm.create_card_style(Color("#FFF0F0"), 16, tm.COLOR_WRONG_RED)
			btn.add_theme_stylebox_override("disabled", wrong_style)
			btn.add_theme_color_override("font_disabled_color", Color("#C53030"))
	else:
		if tm:
			var corr_style = tm.create_card_style(Color("#E8FAF2"), 16, tm.COLOR_CORRECT_GREEN)
			btn.add_theme_stylebox_override("normal", corr_style)
			btn.add_theme_color_override("font_color", Color("#15803D"))

	_process_answer_result(is_correct)

# --- TIPE 3: ISIAN SINGKAT (SHORT ANSWER) ---
func _setup_short_answer() -> void:
	panel_isian.visible = true
	input_isian.editable = true
	input_isian.text = ""
	btn_submit_isian.disabled = false
	input_isian.grab_focus()

func _on_submit_isian() -> void:
	if is_solved:
		return
	var user_text = input_isian.text.strip_edges()
	if user_text.is_empty():
		return

	var is_correct = _check_isian_correctness(user_text)
	_process_answer_result(is_correct)

func _check_isian_correctness(user_input: String) -> bool:
	var correct_ans = str(current_question.get("correct_answer", "")).strip_edges()
	var accepted_list: Array = current_question.get("accepted_answers", [])
	if not accepted_list.has(correct_ans):
		accepted_list.append(correct_ans)

	var u_normalized = user_input.to_lower()
	var u_comma = u_normalized.replace(".", ",")
	var u_dot = u_normalized.replace(",", ".")

	for valid in accepted_list:
		var v_str = str(valid).strip_edges().to_lower()
		var v_comma = v_str.replace(".", ",")
		var v_dot = v_str.replace(",", ".")

		if u_normalized == v_str or u_comma == v_comma or u_dot == v_dot:
			return true

		if u_dot.is_valid_float() and v_dot.is_valid_float():
			if is_equal_approx(u_dot.to_float(), v_dot.to_float()):
				return true

		if "/" in u_normalized and not "/" in v_dot and v_dot.is_valid_float():
			var parts = u_normalized.split("/")
			if parts.size() == 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
				var denom = parts[1].to_float()
				if denom != 0.0:
					var frac_val = parts[0].to_float() / denom
					if is_equal_approx(frac_val, v_dot.to_float()):
						return true

	return false

# --- TIPE 4: PROSEDUR / LANGKAH URUTAN ---
func _setup_procedure() -> void:
	panel_procedure.visible = true
	btn_check_procedure.disabled = false

	procedure_order_list = current_question.get("procedure_items", []).duplicate()
	procedure_order_list.shuffle()
	var correct_order: Array = current_question.get("correct_order", [])
	if _is_procedure_matching(correct_order) and procedure_order_list.size() > 1:
		procedure_order_list.reverse()
	_render_procedure_items()

func _is_procedure_matching(correct_order: Array) -> bool:
	if procedure_order_list.size() != correct_order.size():
		return false
	for i in range(correct_order.size()):
		if procedure_order_list[i].get("id", "") != correct_order[i]:
			return false
	return true

func _render_procedure_items() -> void:
	for child in procedure_items_list.get_children():
		procedure_items_list.remove_child(child)
		child.queue_free()

	var tm = _get_tm()
	for i in range(procedure_order_list.size()):
		var item = procedure_order_list[i]
		var card = PanelContainer.new()
		var c_style = tm.create_card_style(tm.COLOR_CARD_WHITE, 14, Color(0.85, 0.90, 0.96)) if tm else StyleBoxFlat.new()
		c_style.set_content_margin_all(14)
		card.add_theme_stylebox_override("panel", c_style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)

		var lbl_num = Label.new()
		lbl_num.text = "Langkah %d" % (i + 1)
		lbl_num.add_theme_color_override("font_color", tm.COLOR_BTN_PRIMARY if tm else Color("#1F6FEB"))
		lbl_num.add_theme_font_size_override("font_size", 16)
		hbox.add_child(lbl_num)

		var lbl_text = Label.new()
		lbl_text.text = item.get("text", "")
		lbl_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_text.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))
		lbl_text.add_theme_font_size_override("font_size", 16)
		hbox.add_child(lbl_text)

		var btn_up = Button.new()
		btn_up.text = "▲"
		btn_up.custom_minimum_size = Vector2(44, 40)
		btn_up.disabled = (i == 0 or is_solved)
		var curr_idx = i
		btn_up.pressed.connect(func(): _move_procedure_item(curr_idx, -1))
		hbox.add_child(btn_up)

		var btn_down = Button.new()
		btn_down.text = "▼"
		btn_down.custom_minimum_size = Vector2(44, 40)
		btn_down.disabled = (i == procedure_order_list.size() - 1 or is_solved)
		btn_down.pressed.connect(func(): _move_procedure_item(curr_idx, 1))
		hbox.add_child(btn_down)

		card.add_child(hbox)
		procedure_items_list.add_child(card)

func _move_procedure_item(idx: int, dir: int) -> void:
	if is_solved:
		return
	var target_idx = idx + dir
	if target_idx < 0 or target_idx >= procedure_order_list.size():
		return

	var temp = procedure_order_list[idx]
	procedure_order_list[idx] = procedure_order_list[target_idx]
	procedure_order_list[target_idx] = temp
	_render_procedure_items()

func _on_check_procedure() -> void:
	if is_solved:
		return
	var correct_order: Array = current_question.get("correct_order", [])
	var is_correct = _is_procedure_matching(correct_order)
	_process_answer_result(is_correct)

# --- TIPE 5: MATCHING / MENJODOHKAN DUA KOLOM DENGAN SOCKET UX 48px ---
func _setup_matching() -> void:
	panel_matching.visible = true
	btn_check_matching.disabled = false
	btn_reset_matching.disabled = false
	user_pairs.clear()
	selected_left_id = ""

	var left_items: Array = current_question.get("left_items", [])
	var right_items: Array = current_question.get("right_items", []).duplicate()

	if right_items.size() > 1:
		right_items.shuffle()
		var is_sequential = true
		for i in range(right_items.size()):
			if right_items[i].get("id") != "R%d" % (i + 1):
				is_sequential = false
				break
		if is_sequential:
			right_items.reverse()

	shuffled_right_items = right_items
	_render_matching_ui()

func _render_matching_ui() -> void:
	for child in matching_left_col.get_children():
		matching_left_col.remove_child(child)
		child.queue_free()
	for child in matching_right_col.get_children():
		matching_right_col.remove_child(child)
		child.queue_free()

	var tm = _get_tm()
	var left_items: Array = current_question.get("left_items", [])
	var right_map: Dictionary = {}
	for r in shuffled_right_items:
		right_map[r.get("id")] = r.get("text", "")

	# Status Label
	var paired_count = user_pairs.size()
	matching_status_label.text = "Terpasang: %d dari %d pasangan" % [paired_count, left_items.size()]
	if not selected_left_id.is_empty():
		var sel_idx = -1
		for i in range(left_items.size()):
			if left_items[i].get("id") == selected_left_id:
				sel_idx = i
				break
		matching_status_label.text += "  •  [Item %d Dipilih] Klik pasangannya di kolom kanan" % (sel_idx + 1)

	# Render Left Column
	for i in range(left_items.size()):
		var item = left_items[i]
		var l_id = item.get("id", "")
		var l_text = item.get("text", "")
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 72)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var color_idx = i % PAIR_COLORS.size()
		var p_color = PAIR_COLORS[color_idx]
		var is_paired = user_pairs.has(l_id)
		var is_selected = (selected_left_id == l_id)

		# StyleBox Card Kiri
		var card_bg = Color("#FFFFFF")
		var border_c = Color(0.85, 0.90, 0.96)
		if is_paired:
			card_bg = Color("#F8FCFF")
			border_c = p_color
		elif is_selected:
			card_bg = Color("#FFFDF0")
			border_c = Color("#FFC93C")

		var b_style = tm.create_card_style(card_bg, 14, border_c) if tm else StyleBoxFlat.new()
		b_style.border_width_left = 3
		b_style.border_width_top = 3
		b_style.border_width_right = 3
		b_style.border_width_bottom = 3
		btn.add_theme_stylebox_override("normal", b_style)
		btn.add_theme_stylebox_override("hover", b_style)

		# Kontainer Isi: Teks di kiri, Bulatan (Socket 48px) di kanan
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox.add_theme_constant_override("separation", 14)

		# Spacer kiri kecil
		var pad_left = Control.new()
		pad_left.custom_minimum_size = Vector2(12, 0)
		hbox.add_child(pad_left)

		# Label Teks Kiri
		var lbl = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))

		if is_paired:
			var r_id = user_pairs[l_id]
			lbl.text = "[%d] %s  ➔  [%s]" % [i + 1, l_text, right_map.get(r_id, r_id)]
		else:
			lbl.text = "[%d] %s" % [i + 1, l_text]
		hbox.add_child(lbl)

		# Bulatan Socket UX 48px di sisi kanan kartu
		var socket = Panel.new()
		socket.custom_minimum_size = Vector2(48, 48)
		socket.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var s_style = tm.create_socket_style(is_paired, p_color) if tm else StyleBoxFlat.new()
		if is_selected and not is_paired:
			s_style.border_color = Color("#FFC93C")
			s_style.border_width_left = 4
			s_style.border_width_top = 4
			s_style.border_width_right = 4
			s_style.border_width_bottom = 4
		socket.add_theme_stylebox_override("panel", s_style)

		# Indikator nomor pasangan di dalam socket jika terhubung
		if is_paired:
			var s_lbl = Label.new()
			s_lbl.text = "✓"
			s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			s_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			s_lbl.add_theme_font_size_override("font_size", 18)
			s_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			socket.add_child(s_lbl)

		hbox.add_child(socket)

		# Spacer kanan
		var pad_right = Control.new()
		pad_right.custom_minimum_size = Vector2(12, 0)
		hbox.add_child(pad_right)

		btn.add_child(hbox)

		if is_solved:
			btn.disabled = true
		else:
			var curr_lid = l_id
			btn.pressed.connect(func(): _on_left_item_pressed(curr_lid))

		matching_left_col.add_child(btn)

	# Render Right Column
	for j in range(shuffled_right_items.size()):
		var r_item = shuffled_right_items[j]
		var r_id = r_item.get("id", "")
		var r_text = r_item.get("text", "")
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 72)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var paired_left_index = -1
		for i in range(left_items.size()):
			var lid = left_items[i].get("id", "")
			if user_pairs.get(lid) == r_id:
				paired_left_index = i
				break

		var is_paired = (paired_left_index != -1)
		var p_color = PAIR_COLORS[paired_left_index % PAIR_COLORS.size()] if is_paired else tm.COLOR_BTN_PRIMARY

		var card_bg = Color("#FFFFFF")
		var border_c = Color(0.85, 0.90, 0.96)
		if is_paired:
			card_bg = Color("#F8FCFF")
			border_c = p_color

		var b_style = tm.create_card_style(card_bg, 14, border_c) if tm else StyleBoxFlat.new()
		b_style.border_width_left = 3
		b_style.border_width_top = 3
		b_style.border_width_right = 3
		b_style.border_width_bottom = 3
		btn.add_theme_stylebox_override("normal", b_style)
		btn.add_theme_stylebox_override("hover", b_style)

		# Kontainer Isi: Bulatan (Socket 48px) di kiri, Teks di kanan
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox.add_theme_constant_override("separation", 14)

		# Spacer kiri
		var pad_left = Control.new()
		pad_left.custom_minimum_size = Vector2(12, 0)
		hbox.add_child(pad_left)

		# Bulatan Socket UX 48px di sisi kiri kartu
		var socket = Panel.new()
		socket.custom_minimum_size = Vector2(48, 48)
		socket.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var s_style = tm.create_socket_style(is_paired, p_color) if tm else StyleBoxFlat.new()
		socket.add_theme_stylebox_override("panel", s_style)

		if is_paired:
			var s_lbl = Label.new()
			s_lbl.text = "✓"
			s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			s_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			s_lbl.add_theme_font_size_override("font_size", 18)
			s_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			socket.add_child(s_lbl)

		hbox.add_child(socket)

		# Label Teks Kanan
		var lbl = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))

		if is_paired:
			lbl.text = "%s  (Pasangan %d)" % [r_text, paired_left_index + 1]
		else:
			lbl.text = r_text
		hbox.add_child(lbl)

		var pad_right = Control.new()
		pad_right.custom_minimum_size = Vector2(12, 0)
		hbox.add_child(pad_right)

		btn.add_child(hbox)

		if is_solved:
			btn.disabled = true
		else:
			var curr_rid = r_id
			btn.pressed.connect(func(): _on_right_item_pressed(curr_rid))

		matching_right_col.add_child(btn)

func _on_left_item_pressed(left_id: String) -> void:
	if is_solved:
		return
	if selected_left_id == left_id:
		selected_left_id = ""
	else:
		selected_left_id = left_id
	_render_matching_ui()

func _on_right_item_pressed(right_id: String) -> void:
	if is_solved:
		return
	if not selected_left_id.is_empty():
		for k in user_pairs.keys():
			if user_pairs[k] == right_id:
				user_pairs.erase(k)
		user_pairs[selected_left_id] = right_id
		selected_left_id = ""
		_render_matching_ui()
	else:
		var unp = false
		for k in user_pairs.keys():
			if user_pairs[k] == right_id:
				user_pairs.erase(k)
				unp = true
				break
		if unp:
			_render_matching_ui()
		else:
			matching_status_label.text = "Pilih item di kolom kiri terlebih dahulu!"

func _on_reset_matching() -> void:
	if is_solved:
		return
	user_pairs.clear()
	selected_left_id = ""
	_render_matching_ui()

func _on_check_matching() -> void:
	if is_solved:
		return
	var left_items: Array = current_question.get("left_items", [])
	if user_pairs.size() < left_items.size():
		feedback_panel.visible = true
		var tm = _get_tm()
		_style_feedback_panel(tm.COLOR_WRONG_RED if tm else Color("#FF7A7A"), "cross", "-0")
		feedback_label.text = "Hubungkan ketiga pasangan terlebih dahulu sebelum memeriksa!"
		return

	var valid_pairs: Dictionary = current_question.get("valid_pairs", {})
	var is_correct = true
	for l_id in valid_pairs.keys():
		if user_pairs.get(l_id) != valid_pairs[l_id]:
			is_correct = false
			break

	_process_answer_result(is_correct)

# --- SISTEM SKOR & HASIL EVALUASI DENGAN INDIKATOR FLAT & AVATAR BIMA ---
func _style_feedback_panel(accent_color: Color, icon_name: String, badge_text: String) -> void:
	var tm = _get_tm()
	var fb_style = StyleBoxFlat.new()
	fb_style.bg_color = accent_color
	fb_style.set_corner_radius_all(14)
	fb_style.set_content_margin_all(14)
	fb_style.border_color = Color(1, 1, 1, 0.6)
	fb_style.set_border_width_all(2)
	feedback_panel.add_theme_stylebox_override("panel", fb_style)

	if tm:
		feedback_icon.texture = tm.get_icon(icon_name)
		feedback_icon.modulate = tm.COLOR_TEXT_NAVY

	feedback_badge_label.text = badge_text
	feedback_label.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))

func _process_answer_result(is_correct: bool) -> void:
	var gs = _get_gs()
	var dm = _get_dm()
	var tm = _get_tm()
	if not gs:
		return

	var res = gs.register_answer(is_correct)
	_update_top_bar()

	feedback_panel.visible = true

	if is_correct:
		is_solved = true
		_set_bima_avatar("senang")

		var corr_col = tm.COLOR_CORRECT_GREEN if tm else Color("#3DDC97")
		_style_feedback_panel(corr_col, "check", "+%d" % res["delta"])
		feedback_label.text = "Jawaban Benar! Selamat, kamu memperoleh +%d Skor." % res["delta"]

		_lock_current_inputs()

		var lvl = gs.current_level
		var total_pts = dm.get_total_points(lvl) if dm else 5
		if gs.current_point_index >= total_pts:
			btn_next_point.text = "Selesaikan Level"
		else:
			btn_next_point.text = "Lanjut ke Titik Berikutnya"
		btn_next_point.visible = true
	else:
		_set_bima_avatar("bingung")

		var wrong_col = tm.COLOR_WRONG_RED if tm else Color("#FF7A7A")
		var sa_cfg = dm.get_short_answer_settings() if dm else {}
		var max_att = int(sa_cfg.get("max_wrong_attempts_before_reveal", 6))
		_style_feedback_panel(wrong_col, "cross", "%d" % res["delta"])
		feedback_label.text = "Jawaban Kurang Tepat (%d Skor). Coba teliti kembali! [Percobaan: %d/%d]" % [
			res["delta"], res["attempts"], max_att
		]

func _on_answer_revealed(_point_idx: int, ans_str: String) -> void:
	var tm = _get_tm()
	feedback_panel.visible = true
	_set_bima_avatar("normal")

	var help_col = tm.COLOR_LVL3_YELLOW if tm else Color("#FFC93C")
	_style_feedback_panel(help_col, "info", "KUNCI")

	var reveal_text = ans_str
	if current_question.get("type") == "Matching":
		var valid_pairs = current_question.get("valid_pairs", {})
		var left_map = {}
		for item in current_question.get("left_items", []):
			left_map[item["id"]] = item["text"]
		var right_map = {}
		for item in current_question.get("right_items", []):
			right_map[item["id"]] = item["text"]

		var lines = []
		for l_id in valid_pairs.keys():
			var r_id = valid_pairs[l_id]
			lines.append("• %s  ➔  %s" % [left_map.get(l_id, l_id), right_map.get(r_id, r_id)])
		reveal_text = "\n" + "\n".join(lines)

	feedback_label.text = "Catatan Bantuan: Kunci jawaban yang benar adalah: %s" % reveal_text
	btn_next_point.text = "Lanjut ke Titik Berikutnya"
	btn_next_point.visible = true

func _lock_current_inputs() -> void:
	for child in panel_pg.get_children():
		if child is Button:
			child.disabled = true
	for child in panel_tf.get_children():
		if child is Button:
			child.disabled = true
	input_isian.editable = false
	btn_submit_isian.disabled = true
	btn_check_procedure.disabled = true
	btn_check_matching.disabled = true
	btn_reset_matching.disabled = true
	_render_procedure_items()
	_render_matching_ui()

func _on_next_point_pressed() -> void:
	var gs = _get_gs()
	if not gs:
		return

	var is_level_complete = gs.advance_point()
	if is_level_complete:
		var lvl = gs.current_level
		var best = gs.best_scores.get(lvl, gs.level_score)
		if level_complete_modal and level_complete_modal.has_method("setup_level_complete"):
			level_complete_modal.setup_level_complete(lvl, gs.level_score, best)
		elif level_complete_modal:
			level_complete_modal.visible = true
	else:
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_level_complete_menu() -> void:
	var gs = _get_gs()
	if gs:
		gs.open_level_select_on_main_menu = false
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_level_complete_continue() -> void:
	var gs = _get_gs()
	if gs:
		gs.open_level_select_on_main_menu = true
	if is_inside_tree() and get_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_level_complete_confirmed() -> void:
	_on_level_complete_continue()

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
