extends Control
class_name QuizScene

# QuizScene v1.0 (GDD v1.0 Architecture)
# Mengelola interaksi kuis pembelajaran statistika berbasis konteks toko sembako
# Mendukung 4 tipe soal: PG, TF, Isian Singkat, dan Prosedur (Urutan Langkah)

@onready var stage_label: Label = $TopBar/MarginContainer/HBoxContainer/StageLabel
@onready var score_label: Label = $TopBar/MarginContainer/HBoxContainer/ScoreLabel
@onready var btn_map: Button = $TopBar/MarginContainer/HBoxContainer/BtnMap
@onready var btn_menu: Button = $TopBar/MarginContainer/HBoxContainer/BtnMenu

@onready var narrative_label: Label = $ScrollContainer/CenterContainer/MainContent/StoryPanel/MarginContainer/HBoxContainer/NarrativeLabel
@onready var prompt_label: RichTextLabel = $ScrollContainer/CenterContainer/MainContent/QuestionPanel/MarginContainer/PromptLabel

@onready var feedback_panel: PanelContainer = $ScrollContainer/CenterContainer/MainContent/FeedbackPanel
@onready var feedback_label: Label = $ScrollContainer/CenterContainer/MainContent/FeedbackPanel/MarginContainer/FeedbackLabel

# Panels Soal
@onready var panel_pg: GridContainer = $ScrollContainer/CenterContainer/MainContent/Panels/MultipleChoicePanel
@onready var panel_tf: HBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/TrueFalsePanel

@onready var panel_isian: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/ShortAnswerPanel
@onready var input_isian: LineEdit = $ScrollContainer/CenterContainer/MainContent/Panels/ShortAnswerPanel/InputRow/InputIsian
@onready var btn_submit_isian: Button = $ScrollContainer/CenterContainer/MainContent/Panels/ShortAnswerPanel/InputRow/BtnSubmitIsian

@onready var panel_procedure: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/ProcedurePanel
@onready var procedure_items_list: VBoxContainer = $ScrollContainer/CenterContainer/MainContent/Panels/ProcedurePanel/ItemsList
@onready var btn_check_procedure: Button = $ScrollContainer/CenterContainer/MainContent/Panels/ProcedurePanel/BtnCheckProcedure

@onready var btn_next_point: Button = $ScrollContainer/CenterContainer/MainContent/ActionArea/BtnNextPoint
@onready var level_complete_modal: AcceptDialog = $Popups/LevelCompleteModal

var current_question: Dictionary = {}
var procedure_order_list: Array = []
var is_solved: bool = false

func _ready() -> void:
	btn_map.pressed.connect(_on_map_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_submit_isian.pressed.connect(_on_submit_isian)
	input_isian.text_submitted.connect(func(_t): _on_submit_isian())
	btn_check_procedure.pressed.connect(_on_check_procedure)
	btn_next_point.pressed.connect(_on_next_point_pressed)
	level_complete_modal.confirmed.connect(_on_level_complete_confirmed)

	var gs = _get_gs()
	if gs and not gs.answer_revealed.is_connected(_on_answer_revealed):
		gs.answer_revealed.connect(_on_answer_revealed)

	_load_current_point_question()

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

func _update_top_bar() -> void:
	var gs = _get_gs()
	var dm = _get_dm()
	var lvl = gs.current_level if gs else 1
	var pt = gs.current_point_index if gs else 1
	var total_pts = dm.get_total_points(lvl) if dm else 5
	var score = gs.level_score if gs else 0

	var level_titles = {
		1: "Level 1: Konsep Rata-rata (Mean)",
		2: "Level 2: Konsep Nilai Tengah (Median)",
		3: "Level 3: Evaluasi Komparatif Mean & Median"
	}

	stage_label.text = "%s • Titik %d dari %d" % [level_titles.get(lvl, "Level %d" % lvl), pt, total_pts]
	score_label.text = "⭐ Skor: %d" % score

func _load_current_point_question() -> void:
	var gs = _get_gs()
	var dm = _get_dm()
	if not gs or not dm:
		return

	is_solved = false
	feedback_panel.visible = false
	btn_next_point.visible = false

	_update_top_bar()

	current_question = dm.get_question(gs.current_level, gs.current_point_index)
	if current_question.is_empty():
		prompt_label.text = "Soal tidak ditemukan untuk level dan titik ini."
		return

	narrative_label.text = current_question.get("narrative", "Bima mencatat transaksi harian toko sembako.")
	prompt_label.text = current_question.get("prompt", "")

	# Sembunyikan semua subpanel
	panel_pg.visible = false
	panel_tf.visible = false
	panel_isian.visible = false
	panel_procedure.visible = false

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

# --- TIPE 1: PILIHAN GANDA (PG) ---
func _setup_multiple_choice() -> void:
	panel_pg.visible = true
	for child in panel_pg.get_children():
		child.queue_free()

	var options: Array = current_question.get("options", [])
	for opt in options:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(480, 58)
		btn.text = "  %s. %s" % [opt.get("key", ""), opt.get("text", "")]
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _on_pg_selected(opt.get("key", ""), btn))
		panel_pg.add_child(btn)

func _on_pg_selected(chosen_key: String, btn: Button) -> void:
	if is_solved:
		return
	var correct_key = current_question.get("correct_answer", "")
	if correct_key.is_empty():
		correct_key = current_question.get("correct_key", "")

	var is_correct = (chosen_key.to_upper() == correct_key.to_upper())
	if not is_correct:
		btn.disabled = true
		btn.self_modulate = Color(0.5, 0.5, 0.5, 0.6)

	_process_answer_result(is_correct)

# --- TIPE 2: BENAR / SALAH (TF) ---
func _setup_true_false() -> void:
	panel_tf.visible = true
	for child in panel_tf.get_children():
		child.queue_free()

	for val in ["BENAR", "SALAH"]:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(260, 64)
		btn.text = val
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(func(): _on_tf_selected(val, btn))
		panel_tf.add_child(btn)

func _on_tf_selected(chosen_val: String, btn: Button) -> void:
	if is_solved:
		return
	var correct_val = current_question.get("correct_answer", "")
	var is_correct = (chosen_val.to_upper() == correct_val.to_upper())

	if not is_correct:
		btn.disabled = true
		btn.self_modulate = Color(0.5, 0.5, 0.5, 0.6)

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

		# Evaluasi nilai numerik/desimal jika memungkinkan
		if u_dot.is_valid_float() and v_dot.is_valid_float():
			if is_equal_approx(u_dot.to_float(), v_dot.to_float()):
				return true

		# Evaluasi pecahan sederhana (misal 1/2 == 0.5)
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
	_render_procedure_items()

func _render_procedure_items() -> void:
	for child in procedure_items_list.get_children():
		child.queue_free()

	for i in range(procedure_order_list.size()):
		var item = procedure_order_list[i]
		var card = PanelContainer.new()
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)

		var lbl_num = Label.new()
		lbl_num.text = " Langkah %d " % (i + 1)
		lbl_num.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		lbl_num.add_theme_font_size_override("font_size", 16)
		hbox.add_child(lbl_num)

		var lbl_text = Label.new()
		lbl_text.text = item.get("text", "")
		lbl_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_text.add_theme_font_size_override("font_size", 16)
		hbox.add_child(lbl_text)

		# Tombol ⬆️
		var btn_up = Button.new()
		btn_up.text = "⬆️"
		btn_up.custom_minimum_size = Vector2(44, 40)
		btn_up.disabled = (i == 0 or is_solved)
		var curr_idx = i
		btn_up.pressed.connect(func(): _move_procedure_item(curr_idx, -1))
		hbox.add_child(btn_up)

		# Tombol ⬇️
		var btn_down = Button.new()
		btn_down.text = "⬇️"
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
	var is_correct = true

	if procedure_order_list.size() != correct_order.size():
		is_correct = false
	else:
		for i in range(correct_order.size()):
			if procedure_order_list[i].get("id", "") != correct_order[i]:
				is_correct = false
				break

	_process_answer_result(is_correct)

# --- SISTEM SKOR & HASIL EVALUASI ---
func _process_answer_result(is_correct: bool) -> void:
	var gs = _get_gs()
	var dm = _get_dm()
	if not gs:
		return

	var res = gs.register_answer(is_correct)
	_update_top_bar()

	feedback_panel.visible = true

	if is_correct:
		is_solved = true
		feedback_panel.self_modulate = Color(0.2, 0.85, 0.35, 1.0)
		feedback_label.text = "🎉 Jawaban Benar! (+%d Skor)" % res["delta"]
		feedback_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))

		_lock_current_inputs()

		var lvl = gs.current_level
		var total_pts = dm.get_total_points(lvl) if dm else 5
		if gs.current_point_index >= total_pts:
			btn_next_point.text = "Selesaikan Level 🎉"
		else:
			btn_next_point.text = "Lanjut ke Titik Berikutnya ➡️"
		btn_next_point.visible = true
	else:
		feedback_panel.self_modulate = Color(0.9, 0.25, 0.25, 1.0)
		var sa_cfg = dm.get_short_answer_settings() if dm else {}
		var max_att = int(sa_cfg.get("max_wrong_attempts_before_reveal", 6))
		feedback_label.text = "❌ Jawaban Kurang Tepat! (%d Skor) [Percobaan Salah: %d / %d]" % [
			res["delta"], res["attempts"], max_att
		]
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _on_answer_revealed(_point_idx: int, ans_str: String) -> void:
	feedback_panel.visible = true
	feedback_panel.self_modulate = Color(0.95, 0.8, 0.2, 1.0)
	feedback_label.text = "💡 Catatan Bantuan: Kunci jawaban yang benar adalah: %s" % ans_str
	feedback_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	# Tampilkan tombol lanjut agar pemain tidak terjebak jika menemui kesulitan berulang
	btn_next_point.text = "Lanjut ke Titik Berikutnya ➡️"
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
	_render_procedure_items()

func _on_next_point_pressed() -> void:
	var gs = _get_gs()
	if not gs:
		return

	var is_level_complete = gs.advance_point()
	if is_level_complete:
		var lvl = gs.current_level
		var best = gs.best_scores.get(lvl, gs.level_score)
		level_complete_modal.dialog_text = (
			"Selamat! Kamu berhasil menuntaskan seluruh titik soal di Level %d!\n\n" +
			"Skor Akhir Level: %d\n" +
			"Skor Terbaik: %d\n\n" +
			"Level berikutnya kini telah terbuka di Menu Pemilihan Level!"
		) % [lvl, gs.level_score, best]
		level_complete_modal.popup_centered()
	else:
		# Kembali ke peta linear untuk melanjutkan pendakian
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_level_complete_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
