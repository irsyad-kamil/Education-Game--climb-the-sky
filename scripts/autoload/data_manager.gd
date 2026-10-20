extends Node

# Data Manager v1.0 (GDD v1.0 Architecture)
# Mengelola konfigurasi permainan, tabel distribusi frekuensi, dan database soal tetap

var game_config: Dictionary = {}
var levels_config: Dictionary = {} # level (int) -> Dictionary
var frequency_tables: Dictionary = {} # level (int) -> Dictionary
var questions_by_level: Dictionary = {
	1: {},
	2: {},
	3: {}
}

func _init() -> void:
	load_game_config("res://data/game_config.json")
	load_frequency_tables("res://data/frequency_tables.json")
	load_questions("res://data/questions.json")

func _ready() -> void:
	if game_config.is_empty():
		load_game_config("res://data/game_config.json")
	if frequency_tables.is_empty():
		load_frequency_tables("res://data/frequency_tables.json")
	if questions_by_level[1].is_empty():
		load_questions("res://data/questions.json")

func load_game_config(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_error("DataManager: File konfigurasi tidak ditemukan: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("DataManager: Gagal membaca game_config.json: " + json.get_error_message())
		return

	game_config = json.get_data()
	var lvl_list = game_config.get("levels", [])
	for lvl in lvl_list:
		var l_num = int(lvl.get("level", 1))
		levels_config[l_num] = lvl

	print("DataManager: Berhasil memuat game_config.json (Versi %s)" % game_config.get("version", "1.0"))

func load_frequency_tables(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_warning("DataManager: File tabel frekuensi tidak ditemukan: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("DataManager: Gagal membaca frequency_tables.json: " + json.get_error_message())
		return

	var data = json.get_data()
	var tbl_dict: Dictionary = data.get("tables", {})
	for k in tbl_dict.keys():
		var lvl = int(k)
		frequency_tables[lvl] = tbl_dict[k]

	print("DataManager: Berhasil memuat %d tabel distribusi frekuensi (Level 1, 2, 3)." % frequency_tables.size())

func get_frequency_table(level: int) -> Dictionary:
	if frequency_tables.has(level):
		return frequency_tables[level]
	if frequency_tables.has(str(level)):
		return frequency_tables[str(level)]
	push_warning("DataManager: Tabel frekuensi untuk Level %d tidak ditemukan!" % level)
	return {}

func load_questions(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		push_error("DataManager: File data soal tidak ditemukan: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("DataManager: Gagal membaca JSON soal: " + json.get_error_message())
		return

	var data = json.get_data()
	var questions_list: Array = data.get("questions", [])

	for l in range(1, 4):
		questions_by_level[l] = {}

	for q in questions_list:
		var lvl = int(q.get("level", 1))
		var pt = int(q.get("point_index", 1))
		if questions_by_level.has(lvl):
			questions_by_level[lvl][pt] = q

	print("DataManager: Berhasil memuat %d soal tetap (Level 1: %d, Level 2: %d, Level 3: %d)." % [
		questions_list.size(),
		questions_by_level[1].size(),
		questions_by_level[2].size(),
		questions_by_level[3].size()
	])

# Mengambil 1 soal spesifik berdasarkan level dan nomor titik (1-based)
func get_question(level: int, point_index: int) -> Dictionary:
	if questions_by_level.has(level) and questions_by_level[level].has(point_index):
		return questions_by_level[level][point_index]
	push_warning("DataManager: Soal untuk Level %d Titik %d tidak ditemukan!" % [level, point_index])
	return {}

# Mengambil daftar seluruh soal di level tertentu
func get_questions_for_level(level: int) -> Array:
	var list: Array = []
	if questions_by_level.has(level):
		var keys = questions_by_level[level].keys()
		keys.sort()
		for k in keys:
			list.append(questions_by_level[level][k])
	return list

# Mengambil konfigurasi spesifik level (total points, max score, dll.)
func get_level_config(level: int) -> Dictionary:
	return levels_config.get(level, {})

func get_total_points(level: int) -> int:
	var cfg = get_level_config(level)
	return int(cfg.get("total_points", 0))

func get_max_score(level: int) -> int:
	var cfg = get_level_config(level)
	return int(cfg.get("max_score", 0))

func get_scoring_rules() -> Dictionary:
	return game_config.get("scoring", {
		"correct_score": 100,
		"wrong_score": -25,
		"allow_negative_score": true
	})

func get_short_answer_settings() -> Dictionary:
	return game_config.get("short_answer_settings", {
		"max_wrong_attempts_before_reveal": 6,
		"decimal_separator": ",",
		"allow_dot_decimal": true,
		"allow_fraction": true
	})
