extends Control
class_name QuizScene

# Referensi Elemen Panggung Atas (Sesuai Sketsa)
@onready var character_panel: PanelContainer = $StageArea/CharacterContainer/CharacterPanel
@onready var character_hp_label: Label = $StageArea/CharacterContainer/HPSymbol/HPLabel
@onready var character_name_label: Label = $StageArea/CharacterContainer/NameLabel

@onready var time_badge: PanelContainer = $StageArea/TimeBadge
@onready var time_label: Label = $StageArea/TimeBadge/MarginContainer/TimeLabel
@onready var time_bar: ProgressBar = $StageArea/TimeBadge/TimerBar

@onready var enemy_panel: PanelContainer = $StageArea/EnemyContainer/EnemyPanel
@onready var enemy_icon: Label = $StageArea/EnemyContainer/EnemyPanel/CenterContainer/EnemyIcon
@onready var enemy_name_label: Label = $StageArea/EnemyContainer/NameLabel

@onready var btn_map: Button = $TopBar/RightButtons/BtnMap
@onready var btn_menu: Button = $TopBar/RightButtons/BtnMenu

# Referensi Elemen Bawah (Kotak Narasi, Soal, & Jawaban)
@onready var narrative_label: Label = $BottomArea/MarginContainer/VBoxContainer/NarrativeLabel
@onready var prompt_label: RichTextLabel = $BottomArea/MarginContainer/VBoxContainer/PromptLabel
@onready var boss_tracker_label: Label = $BottomArea/MarginContainer/VBoxContainer/BossTrackerLabel

# Panel Interaksi Soal
@onready var panel_pg: GridContainer = $BottomArea/MarginContainer/VBoxContainer/Panels/MultipleChoicePanel
@onready var panel_tf: HBoxContainer = $BottomArea/MarginContainer/VBoxContainer/Panels/TrueFalsePanel
@onready var panel_isian: HBoxContainer = $BottomArea/MarginContainer/VBoxContainer/Panels/ShortAnswerPanel
@onready var input_isian: LineEdit = $BottomArea/MarginContainer/VBoxContainer/Panels/ShortAnswerPanel/InputIsian
@onready var btn_submit_isian: Button = $BottomArea/MarginContainer/VBoxContainer/Panels/ShortAnswerPanel/BtnSubmitIsian
@onready var panel_matching: Control = $BottomArea/MarginContainer/VBoxContainer/Panels/MatchingPanel
@onready var matching_left_col: VBoxContainer = $BottomArea/MarginContainer/VBoxContainer/Panels/MatchingPanel/Columns/LeftCol
@onready var matching_right_col: VBoxContainer = $BottomArea/MarginContainer/VBoxContainer/Panels/MatchingPanel/Columns/RightCol
@onready var btn_check_matching: Button = $BottomArea/MarginContainer/VBoxContainer/Panels/MatchingPanel/BtnCheckMatching

# Modals
@onready var reveal_modal: AcceptDialog = $Popups/RevealModal
@onready var victory_modal: AcceptDialog = $Popups/VictoryModal
@onready var defeat_modal: AcceptDialog = $Popups/DefeatModal
@onready var map_preview = $MapPreview

# State Kuis & Time Attack
var current_question: Dictionary = {}
var boss_questions_queue: Array = []
var boss_current_index: int = 0
var is_boss_battle: bool = false
var time_attack_timer: Timer

var wrong_attempts: int = 0
var normal_wrong_count: int = 0

# Matching state
var selected_left_id: String = ""
var connected_pairs: Dictionary = {}
var valid_pairs_data: Dictionary = {}
var socket_buttons: Dictionary = {}

func _ready() -> void:
	# Inisialisasi Timer Time Attack (30s berulang sesuai GDD 4.6)
	time_attack_timer = Timer.new()
	time_attack_timer.one_shot = true
	time_attack_timer.timeout.connect(_on_time_attack_expired)
	add_child(time_attack_timer)

	# Tombol Navigasi
	btn_map.pressed.connect(_on_view_map_pressed)
	if map_preview:
		map_preview.preview_closed.connect(_on_map_preview_closed)
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_submit_isian.pressed.connect(_on_submit_isian)
	input_isian.text_submitted.connect(func(_t): _on_submit_isian())
	btn_check_matching.pressed.connect(_on_check_matching)

	victory_modal.confirmed.connect(_on_victory_confirmed)
	defeat_modal.confirmed.connect(_on_respawn_after_defeat)

	_update_hp_display()
	_load_current_encounter()

func _process(_delta: float) -> void:
	if time_attack_timer.time_left > 0:
		var left_sec = time_attack_timer.time_left
		time_label.text = "⏱️ %02d dtk" % int(ceil(left_sec))
		time_bar.value = left_sec

func _update_hp_display() -> void:
	character_hp_label.text = "❤️ %d / %d" % [GameState.hp, GameState.max_hp]

func _load_current_encounter() -> void:
	# Ambil data tipe node dari GameState
	var stage = GameState.current_stage
	var current_node_id = GameState.current_node_id

	# Cek apakah Bos
	if GameState.current_node_type == MapGenerator.NodeType.BOSS or current_node_id.begins_with("T1_N_5") or current_node_id.begins_with("N_11_"):
		is_boss_battle = true
		boss_questions_queue = DataManager.get_boss_questions(stage)
		boss_current_index = 0
		_setup_enemy_visual("Bos Akhir Tahap", "👑", Color(1.0, 0.85, 0.2))
		_load_boss_question()
	elif GameState.current_node_type == MapGenerator.NodeType.ELITE or current_node_id == "T1_N_4_0":
		is_boss_battle = false
		current_question = DataManager.get_elite_question(stage)
		_setup_enemy_visual("Tantangan Elite", "💀", Color(1.0, 0.4, 0.4))
		_setup_question()
	else:
		# Default Normal Enemy
		is_boss_battle = false
		current_question = DataManager.get_normal_question(stage)
		_setup_enemy_visual("Soal Latihan Bima", "⚔️", Color(0.8, 0.85, 0.95))
		_setup_question()

func _setup_enemy_visual(e_name: String, icon_str: String, col: Color) -> void:
	enemy_name_label.text = e_name
	enemy_icon.text = icon_str
	enemy_panel.modulate = col

func _load_boss_question() -> void:
	if boss_current_index < boss_questions_queue.size():
		current_question = boss_questions_queue[boss_current_index]
		boss_tracker_label.visible = true
		boss_tracker_label.text = "Pertanyaan Bos: %d / 5" % (boss_current_index + 1)
		_setup_question()
	else:
		_on_battle_won()

func _setup_question() -> void:
	wrong_attempts = 0
	normal_wrong_count = 0

	# Teks narasi & soal
	var narr = current_question.get("narrative", "")
	narrative_label.text = narr
	narrative_label.visible = not narr.is_empty()
	prompt_label.text = current_question.get("prompt", "")

	# Konfigurasi Time Attack 30 Detik (GDD 4.6)
	if current_question.get("has_time_attack", false):
		time_badge.visible = true
		time_bar.max_value = 30.0
		time_bar.value = 30.0
		time_attack_timer.start(30.0)
	else:
		time_badge.visible = false
		time_attack_timer.stop()

	# Sembunyikan seluruh subpanel dulu
	panel_pg.visible = false
	panel_tf.visible = false
	panel_isian.visible = false
	panel_matching.visible = false

	# Buka panel sesuai tipe soal
	var q_type = current_question.get("type", "")
	match q_type:
		"PG":
			_build_multiple_choice()
		"TF":
			_build_true_false()
		"Isian":
			_build_short_answer()
		"Matching":
			_build_matching()

# --- TIPE 1: PILIHAN GANDA (PG) ---
func _build_multiple_choice() -> void:
	panel_pg.visible = true
	for child in panel_pg.get_children():
		child.queue_free()

	var options: Array = current_question.get("options", [])
	for opt in options:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(380, 54)
		btn.text = "%s. %s" % [opt["key"], opt["text"]]
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _on_pg_selected(opt["key"], btn))
		panel_pg.add_child(btn)

func _on_pg_selected(selected_key: String, btn: Button) -> void:
	var correct_key = current_question.get("correct_key", "")
	if selected_key == correct_key:
		_on_question_solved()
	else:
		# GDD 4.1 & 4.4: Opsi salah langsung hilang dari layar
		btn.visible = false

		if is_boss_battle or current_question.get("category", "") == "Elite":
			_apply_damage(1, "Jawaban salah")
		else:
			# Normal Enemy: maksimal 2 penalti per soal
			if normal_wrong_count < 2:
				normal_wrong_count += 1
				_apply_damage(1, "Jawaban salah Normal Enemy")

# --- TIPE 2: BENAR / SALAH (TF) ---
func _build_true_false() -> void:
	panel_tf.visible = true
	for child in panel_tf.get_children():
		child.queue_free()

	for val in ["Benar", "Salah"]:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(240, 60)
		btn.text = val
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(func(): _on_tf_selected(val, btn))
		panel_tf.add_child(btn)

func _on_tf_selected(selected_val: String, btn: Button) -> void:
	var correct_val = current_question.get("correct_answer", "")
	if selected_val.to_lower() == correct_val.to_lower():
		_on_question_solved()
	else:
		btn.visible = false # Opsi salah hilang
		_apply_damage(1, "Pilihan Benar/Salah salah")

# --- TIPE 3: ISIAN SINGKAT ---
func _build_short_answer() -> void:
	panel_isian.visible = true
	input_isian.text = ""
	input_isian.placeholder_text = "Ketik jawaban angka (contoh: 7,5)..."
	input_isian.grab_focus()

func _on_submit_isian() -> void:
	var user_text = input_isian.text.strip_edges()
	if user_text.is_empty():
		return

	var acceptable: Array = current_question.get("acceptable_answers", [])
	var is_correct = false
	var user_comma = user_text.replace(".", ",")
	var user_dot = user_text.replace(",", ".")

	for valid in acceptable:
		if user_text == valid or user_comma == valid or user_dot == valid:
			is_correct = true
			break

	if is_correct:
		_on_question_solved()
	else:
		wrong_attempts += 1
		_apply_damage(1, "Isian salah")

		# GDD 4.2 & 4.4: Setelah 5 kali salah, pop-up kunci jawaban muncul
		if wrong_attempts >= 5:
			var reveal_key = acceptable[0] if acceptable.size() > 0 else "-"
			reveal_modal.dialog_text = "Bima membuka catatan kecilnya...\nJawaban yang benar adalah: %s" % reveal_key
			reveal_modal.popup_centered()

# --- TIPE 4: MENJODOHKAN (MATCHING) ---
func _build_matching() -> void:
	panel_matching.visible = true
	selected_left_id = ""
	connected_pairs.clear()
	socket_buttons.clear()
	valid_pairs_data = current_question.get("valid_pairs", {})

	for child in matching_left_col.get_children(): child.queue_free()
	for child in matching_right_col.get_children(): child.queue_free()

	var left_items: Array = current_question.get("left_items", [])
	var right_items: Array = current_question.get("right_items", [])

	for item in left_items:
		var row = _create_matching_row(item["id"], item["text"], true)
		matching_left_col.add_child(row)

	for item in right_items:
		var row = _create_matching_row(item["id"], item["text"], false)
		matching_right_col.add_child(row)

	panel_matching.queue_redraw()

func _create_matching_row(id: String, text: String, is_left: bool) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 280

	var btn_socket = Button.new()
	btn_socket.custom_minimum_size = Vector2(36, 36)
	btn_socket.text = "○"
	socket_buttons[(("L_" if is_left else "R_") + id)] = btn_socket

	if is_left:
		hbox.add_child(label)
		hbox.add_child(btn_socket)
		btn_socket.pressed.connect(func(): _on_left_socket_pressed(id))
	else:
		hbox.add_child(btn_socket)
		hbox.add_child(label)
		btn_socket.pressed.connect(func(): _on_right_socket_pressed(id))

	return hbox

func _on_left_socket_pressed(left_id: String) -> void:
	selected_left_id = left_id
	# Update visual tanda bulatan
	for id in current_question.get("left_items", []):
		var btn: Button = socket_buttons.get("L_" + id["id"])
		if btn:
			btn.text = "●" if id["id"] == left_id else ("🔗" if connected_pairs.has(id["id"]) else "○")

func _on_right_socket_pressed(right_id: String) -> void:
	if selected_left_id.is_empty():
		return

	# Pasangkan soket kiri dengan soket kanan
	connected_pairs[selected_left_id] = right_id
	selected_left_id = ""
	
	# Perbarui status ikon tombol soket
	for item in current_question.get("left_items", []):
		var btn: Button = socket_buttons.get("L_" + item["id"])
		if btn:
			btn.text = "🔗" if connected_pairs.has(item["id"]) else "○"

	panel_matching.queue_redraw()

func _on_check_matching() -> void:
	var wrong_count = 0
	var all_correct = true

	# Periksa pasangan yang dibentuk
	for l_id in connected_pairs.keys():
		var chosen_r = connected_pairs[l_id]
		if valid_pairs_data.get(l_id, "") != chosen_r:
			all_correct = false
			wrong_count += 1

	if connected_pairs.size() < valid_pairs_data.size():
		all_correct = false
		wrong_count += (valid_pairs_data.size() - connected_pairs.size())

	if all_correct:
		_on_question_solved()
	else:
		var dmg = max(1, wrong_count)
		_apply_damage(dmg, "Pasangan mencocokkan keliru")

# --- PENANGANAN TIMER TIME ATTACK (GDD 4.6) ---
func _on_time_attack_expired() -> void:
	_apply_damage(1, "Waktu 30 detik habis!")
	# Timer otomatis mengulang 30 detik untuk soal yang sama
	time_attack_timer.start(30.0)

# --- SISTEM KERUSAKAN & STATUS ---
func _apply_damage(amount: int, reason: String) -> void:
	GameState.hp -= amount
	_update_hp_display()
	print("Bima terkena damage: -%d HP (%s). Sisa HP: %d" % [amount, reason, GameState.hp])

	if GameState.hp <= 0:
		time_attack_timer.stop()
		defeat_modal.dialog_text = "Daya tahan Bima habis...\nBima akan mengulang dari Api Unggun terbaru."
		defeat_modal.popup_centered()

func _on_question_solved() -> void:
	time_attack_timer.stop()

	if is_boss_battle:
		boss_current_index += 1
		_load_boss_question()
	else:
		_on_battle_won()

func _on_battle_won() -> void:
	var cat = "Normal"
	if is_boss_battle or GameState.current_node_type == MapGenerator.NodeType.BOSS:
		cat = "Boss"
	elif GameState.current_node_type == MapGenerator.NodeType.ELITE or GameState.current_node_id == "T1_N_4_0" or current_question.get("category", "") == "Elite":
		cat = "Elite"
	var hp_before = GameState.hp
	var max_hp_before = GameState.max_hp

	GameState.on_enemy_defeated(cat)
	_update_hp_display()

	if is_boss_battle:
		var cleared_stage = GameState.current_stage
		GameState.complete_current_stage()
		if cleared_stage == 1:
			victory_modal.dialog_text = "Luar biasa! Bima berhasil lulus SMA!\nMelanjutkan perjalanan ke Tahap 2: Lulus Kuliah..."
		elif cleared_stage == 2:
			victory_modal.dialog_text = "Sidang sarjana berhasil dilalui dengan gemilang!\nMelanjutkan ke Tahap 3: Membangun Masa Depan..."
		else:
			victory_modal.dialog_text = "Selamat! Seluruh perjuangan Bima telah paripurna!\nBima berhasil membahagiakan ibunya dan mengubah takdirnya!"
	else:
		var reward_str = ""
		if cat == "Normal":
			reward_str = "+1 Max HP & Full Heal!" if hp_before == max_hp_before else "+1 HP"
		elif cat == "Elite":
			reward_str = "+2 Max HP & Full Heal!" if hp_before == max_hp_before else "+2 HP"
		victory_modal.dialog_text = "Soal terjawab benar!\nBima semakin tangguh (%s)." % reward_str

	victory_modal.popup_centered()

func _on_victory_confirmed() -> void:
	if is_boss_battle:
		if GameState.current_stage == 1:
			# Langsung masuk ke Tahap 2
			GameState.start_stage(2)
			get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
		elif GameState.current_stage == 2:
			# Langsung masuk ke Tahap 3 (membawa Max HP dan HP penuh)
			GameState.start_stage(3)
			get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	else:
		_return_to_map()

func _on_respawn_after_defeat() -> void:
	GameState.respawn_at_checkpoint()
	_return_to_map()

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_view_map_pressed() -> void:
	if time_attack_timer and not time_attack_timer.is_stopped():
		time_attack_timer.paused = true
	if map_preview:
		map_preview.open_preview()

func _on_map_preview_closed() -> void:
	if time_attack_timer and not time_attack_timer.is_stopped():
		time_attack_timer.paused = false

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
