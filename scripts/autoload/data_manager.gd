extends Node

# Database pertanyaan terindeks: questions_by_stage[tahap][kategori]
var questions_by_stage: Dictionary = {
	1: {"Normal": [], "Elite": [], "Boss": {}},
	2: {"Normal": [], "Elite": [], "Boss": {}},
	3: {"Normal": [], "Elite": [], "Boss": {}}
}

# Riwayat ID soal yang sudah pernah ditampilkan dalam sesi permainan
var used_question_ids: Array = []

func _ready() -> void:
	load_questions("res://data/questions.json")

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

	for q in questions_list:
		var stage = int(q.get("stage", 1))
		var cat = q.get("category", "Normal")

		if cat == "Boss":
			var b_type = q.get("boss_type", "A")
			if not questions_by_stage[stage]["Boss"].has(b_type):
				questions_by_stage[stage]["Boss"][b_type] = []
			questions_by_stage[stage]["Boss"][b_type].append(q)
		else:
			if questions_by_stage[stage].has(cat):
				questions_by_stage[stage][cat].append(q)

	print("DataManager: Berhasil memuat %d soal ke dalam database." % questions_list.size())

# Mengambil 1 soal Normal Enemy
func get_normal_question(stage: int) -> Dictionary:
	var pool: Array = questions_by_stage[stage]["Normal"]
	return _pick_unseen_question(pool)

# Mengambil 1 soal Elite Enemy
func get_elite_question(stage: int) -> Dictionary:
	var pool: Array = questions_by_stage[stage]["Elite"]
	return _pick_unseen_question(pool)

# Mengambil 5 pertanyaan Boss sesuai aturan GDD 4.4:
# Diacak dari jenis A-E, jenis boleh berulang, tetapi MINIMAL 3 jenis berbeda
func get_boss_questions(stage: int) -> Array:
	var boss_pools: Dictionary = questions_by_stage[stage]["Boss"]
	var all_types = ["A", "B", "C", "D", "E"]
	var selected_questions: Array = []

	var chosen_types: Array = []
	while true:
		chosen_types.clear()
		for i in range(5):
			chosen_types.append(all_types.pick_random())

		var unique_map = {}
		for t in chosen_types:
			unique_map[t] = true

		if unique_map.size() >= 3:
			break # Syarat minimal 3 jenis berbeda terpenuhi

	for b_type in chosen_types:
		var sub_pool: Array = boss_pools.get(b_type, [])
		if sub_pool.size() > 0:
			selected_questions.append(sub_pool.pick_random())

	return selected_questions

func _pick_unseen_question(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}

	var available = pool.filter(func(q): return not used_question_ids.has(q["id"]))
	if available.is_empty():
		available = pool # Reset penggunaan bila seluruh pool sudah pernah keluar

	var chosen = available.pick_random()
	used_question_ids.append(chosen["id"])
	return chosen
