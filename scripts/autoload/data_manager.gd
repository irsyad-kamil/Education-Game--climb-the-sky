extends Node

# Data Manager v1.0 (GDD v1.0 Architecture)
# Mengelola konfigurasi permainan, tabel distribusi frekuensi, dan bank 48 soal
# Setiap titik memiliki 4 varian soal (PG, TF, Isian, Prosedur) dengan peluang 25% per tipe

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
			if not questions_by_level[lvl].has(pt):
				questions_by_level[lvl][pt] = []
			questions_by_level[lvl][pt].append(q)

	print("DataManager: Berhasil memuat %d soal dalam bank soal (Level 1: %d titik, Level 2: %d titik, Level 3: %d titik)." % [
		questions_list.size(),
		questions_by_level[1].size(),
		questions_by_level[2].size(),
		questions_by_level[3].size()
	])

# Mengambil seluruh varian soal pada titik tertentu (4 varian: PG, TF, Isian, Prosedur)
func get_question_variants(level: int, point_index: int) -> Array:
	if questions_by_level.has(level) and questions_by_level[level].has(point_index):
		return questions_by_level[level][point_index]
	push_warning("DataManager: Varian soal untuk Level %d Titik %d tidak ditemukan!" % [level, point_index])
	return []

# Mengambil 1 varian acak dari 4 jenis soal dengan peluang sama (25% PG, 25% TF, 25% Isian, 25% Prosedur)
func get_random_question(level: int, point_index: int) -> Dictionary:
	var variants = get_question_variants(level, point_index)
	if variants.is_empty():
		return {}
	return variants.pick_random()

# Mengambil soal aktif untuk level dan titik (prioritas dari GameState sesi aktif, atau acak 25%)
func get_question(level: int, point_index: int) -> Dictionary:
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("GameState"):
		var gs = main_loop.root.get_node("GameState")
		if gs and "active_level_questions" in gs and gs.active_level_questions.has(point_index):
			return gs.active_level_questions[point_index]

	return get_random_question(level, point_index)

# Mengambil daftar seluruh soal di level tertentu (seluruh varian)
func get_questions_for_level(level: int) -> Array:
	var list: Array = []
	if questions_by_level.has(level):
		var keys = questions_by_level[level].keys()
		keys.sort()
		for k in keys:
			var var_list: Array = questions_by_level[level][k]
			for q in var_list:
				list.append(q)
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
