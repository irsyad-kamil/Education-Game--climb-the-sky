extends Node

# GameState v1.0 (GDD v1.0 Architecture)
# Mengelola alur permainan linear, skor per level, dan status unlock level
# Setiap titik memilih 1 dari 4 varian soal (PG, TF, Isian, Prosedur) dengan peluang merata (25% masing-masing)

# Signals untuk sistem skor dan progres baru
signal score_changed(current_score: int, delta: int)
signal point_advanced(current_point: int, total_points: int)
signal level_started(level: int)
signal level_completed(level: int, final_score: int)
signal wrong_attempt_added(attempts: int, max_attempts: int)
signal answer_revealed(point_index: int, answer: String)

# Legacy Signals (Untuk kompatibilitas scene lama yang belum dimigrasi)
signal hp_changed(current_hp: int, max_hp: int)
signal stage_changed(stage: int)
signal checkpoint_updated(row: int)
signal game_over
signal stage_cleared(stage: int)

# Status Utama Permainan (GDD v1.0)
var current_level: int = 1
var current_point_index: int = 1
var level_score: int = 0
var wrong_attempts_current_question: int = 0
var active_level_questions: Dictionary = {} # point_index (int) -> Dictionary (varian soal terpilih 25% tiap jenis)
var open_level_select_on_main_menu: bool = false

# Status Unlock Level & Skor Terbaik
var is_level_1_cleared: bool = false
var is_level_2_cleared: bool = false
var is_level_3_cleared: bool = false
var best_scores: Dictionary = {
	1: 0,
	2: 0,
	3: 0
}

# --- Kompatibilitas Legacy v0.4 ---
var hp: int = 10
var max_hp: int = 10
var current_stage: int:
	get:
		return current_level
	set(val):
		current_level = val
var has_completed_stage_1: bool:
	get:
		return is_level_1_cleared
	set(val):
		is_level_1_cleared = val
var current_row: int = 1
var current_node_id: String = ""
var current_node_type: int = 1
var current_map_seed: int = 0
var latest_checkpoint: Dictionary = {}
var run_history: Array = []
# ----------------------------------

const SAVE_PATH: String = "user://save_progress.json"

func _init() -> void:
	load_progress()

func _ready() -> void:
	load_progress()

var data_manager_ref: Node = null

# Helper untuk mendapatkan referensi DataManager secara dinamis & aman
func _get_dm() -> Node:
	if data_manager_ref != null and is_instance_valid(data_manager_ref):
		return data_manager_ref
	if is_inside_tree() and has_node("/root/DataManager"):
		data_manager_ref = get_node("/root/DataManager")
		return data_manager_ref
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("DataManager"):
		data_manager_ref = main_loop.root.get_node("DataManager")
		return data_manager_ref
	return null

# Memulai level baru & mengocok 1 dari 4 varian soal per titik (25% PG, 25% TF, 25% Isian, 25% Prosedur)
func start_level(level: int) -> void:
	current_level = clampi(level, 1, 3)
	current_point_index = 1
	level_score = 0
	wrong_attempts_current_question = 0
	active_level_questions.clear()

	var dm = _get_dm()
	var total_points = dm.get_total_points(current_level) if dm else 5
	for p in range(1, total_points + 1):
		if dm:
			active_level_questions[p] = dm.get_random_question(current_level, p)
		else:
			active_level_questions[p] = {}

	emit_signal("level_started", current_level)
	emit_signal("score_changed", level_score, 0)
	print("GameState: Memulai Level %d (Skor awal: %d, Titik: %d, Soal aktif: %d titik ter-roll acak 25%% per tipe)" % [
		current_level, level_score, current_point_index, active_level_questions.size()
	])

# Mengambil soal aktif pada titik saat ini
func get_current_question() -> Dictionary:
	if active_level_questions.has(current_point_index):
		return active_level_questions[current_point_index]
	var dm = _get_dm()
	if dm:
		return dm.get_question(current_level, current_point_index)
	return {}

# Mendaftarkan jawaban (benar / salah) dan memperbarui skor
func register_answer(is_correct: bool) -> Dictionary:
	var dm = _get_dm()
	var scoring_rules = dm.get_scoring_rules() if dm else {"correct_score": 100, "wrong_score": -25, "allow_negative_score": true}
	var delta: int = 0
	var revealed: bool = false

	if is_correct:
		delta = int(scoring_rules.get("correct_score", 100))
		level_score += delta
		wrong_attempts_current_question = 0
		emit_signal("score_changed", level_score, delta)
		print("GameState: Jawaban BENAR! Skor +%d (Total skor level: %d)" % [delta, level_score])
		return {
			"is_correct": true,
			"delta": delta,
			"new_score": level_score,
			"revealed": false,
			"attempts": 0
		}
	else:
		delta = int(scoring_rules.get("wrong_score", -25))
		level_score += delta
		wrong_attempts_current_question += 1
		emit_signal("score_changed", level_score, delta)

		var sa_settings = dm.get_short_answer_settings() if dm else {"max_wrong_attempts_before_reveal": 6}
		var max_attempts = int(sa_settings.get("max_wrong_attempts_before_reveal", 6))
		emit_signal("wrong_attempt_added", wrong_attempts_current_question, max_attempts)

		if wrong_attempts_current_question >= max_attempts:
			revealed = true
			var correct_ans = ""
			var q = get_current_question()
			if q.has("correct_answer"):
				correct_ans = str(q.get("correct_answer", ""))
			elif q.has("correct_order"):
				correct_ans = ", ".join(q.get("correct_order", []))
			emit_signal("answer_revealed", current_point_index, correct_ans)
			print("GameState: Jawaban SALAH ke-%d! Kunci jawaban dibuka: %s" % [wrong_attempts_current_question, correct_ans])
		else:
			print("GameState: Jawaban SALAH! Penalti %d (Total skor level: %d, Percobaan salah: %d/%d)" % [
				delta, level_score, wrong_attempts_current_question, max_attempts
			])

		return {
			"is_correct": false,
			"delta": delta,
			"new_score": level_score,
			"revealed": revealed,
			"attempts": wrong_attempts_current_question
		}

# Pindah ke titik berikutnya pada level aktif
# Mengembalikan true jika level selesai (titik terakhir telah dilalui)
func advance_point() -> bool:
	var dm = _get_dm()
	var total_points = dm.get_total_points(current_level) if dm else 5
	wrong_attempts_current_question = 0

	if current_point_index < total_points:
		current_point_index += 1
		emit_signal("point_advanced", current_point_index, total_points)
		print("GameState: Melangkah ke Titik %d/%d di Level %d" % [current_point_index, total_points, current_level])
		return false
	else:
		# Level Selesai!
		_complete_current_level()
		return true

func _complete_current_level() -> void:
	if current_level == 1:
		is_level_1_cleared = true
	elif current_level == 2:
		is_level_2_cleared = true
	elif current_level == 3:
		is_level_3_cleared = true

	if not best_scores.has(current_level) or level_score > best_scores[current_level]:
		best_scores[current_level] = level_score

	save_progress()
	emit_signal("level_completed", current_level, level_score)
	print("GameState: LEVEL %d SELESAI! Skor Akhir: %d (Skor Terbaik: %d)" % [
		current_level, level_score, best_scores[current_level]
	])

# Pengecekan apakah suatu level sudah terbuka
func is_level_unlocked(level: int) -> bool:
	match level:
		1:
			return true
		2:
			return is_level_1_cleared
		3:
			return is_level_2_cleared
		_:
			return false

# Simpan progres unlock ke JSON lokal
func save_progress() -> void:
	var save_dict = {
		"is_level_1_cleared": is_level_1_cleared,
		"is_level_2_cleared": is_level_2_cleared,
		"is_level_3_cleared": is_level_3_cleared,
		"best_scores": {
			"1": best_scores.get(1, 0),
			"2": best_scores.get(2, 0),
			"3": best_scores.get(3, 0)
		},
		"last_played": Time.get_datetime_string_from_system()
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()
		print("GameState: Progres tersimpan ke %s" % SAVE_PATH)
	else:
		push_error("GameState: Gagal menyimpan progres ke %s" % SAVE_PATH)

# Muat progres unlock dari JSON lokal
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) == OK:
		var data = json.get_data()
		is_level_1_cleared = data.get("is_level_1_cleared", false)
		is_level_2_cleared = data.get("is_level_2_cleared", false)
		is_level_3_cleared = data.get("is_level_3_cleared", false)

		var b_scores = data.get("best_scores", {})
		for k in b_scores.keys():
			best_scores[int(k)] = int(b_scores[k])

		print("GameState: Progres dimuat. Level 1 Cleared: %s, Level 2 Cleared: %s, Level 3 Cleared: %s" % [
			is_level_1_cleared, is_level_2_cleared, is_level_3_cleared
		])

# Reset progres (opsional/debug)
func reset_progress() -> void:
	is_level_1_cleared = false
	is_level_2_cleared = false
	is_level_3_cleared = false
	best_scores = {1: 0, 2: 0, 3: 0}
	open_level_select_on_main_menu = false
	save_progress()
	print("GameState: Progres di-reset ke nilai awal.")

# --- Fungsi Kompatibilitas Legacy v0.4 ---
func start_stage(stage_number: int, _seed_value: int = 0) -> void:
	start_level(stage_number)
	emit_signal("stage_changed", current_stage)

func reach_bonfire(_row: int, _node_id: String) -> void:
	pass

func save_bonfire_checkpoint(_row: int, _node_id: String, _emit_event: bool = true) -> void:
	pass

func on_enemy_defeated(_category: String) -> void:
	pass

func apply_event_hp_change(_delta: int) -> void:
	pass

func respawn_at_checkpoint() -> void:
	pass

func complete_current_stage() -> void:
	_complete_current_level()
	emit_signal("stage_cleared", current_level)

func save_game_progress() -> void:
	save_progress()

func load_game_progress() -> void:
	load_progress()
