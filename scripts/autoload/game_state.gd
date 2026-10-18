extends Node

# Signal global untuk sinkronisasi UI
signal hp_changed(current_hp: int, max_hp: int)
signal stage_changed(stage: int)
signal checkpoint_updated(row: int)
signal game_over
signal stage_cleared(stage: int)

# Parameter Utama Karakter Bima
var hp: int = 10:
	set(val):
		hp = clampi(val, 0, max_hp)
		emit_signal("hp_changed", hp, max_hp)
		if hp == 0:
			emit_signal("game_over")

var max_hp: int = 10:
	set(val):
		max_hp = val
		emit_signal("hp_changed", hp, max_hp)

var current_stage: int = 1
var has_completed_stage_1: bool = false
var current_map_seed: int = 0

# Data Posisi Perjalanan
var current_row: int = 1
var current_node_id: String = ""
var current_node_type: int = 1 # MapGenerator.NodeType (0=CAMPFIRE, 1=NORMAL, 2=ELITE, 3=EVENT, 4=BOSS)

# Data Titik Simpan Api Unggun (GDD 5.6)
var latest_checkpoint: Dictionary = {
	"stage": 1,
	"row": 1,
	"node_id": "",
	"saved_hp": 10,
	"saved_max_hp": 10,
	"map_seed": 0
}

# Riwayat Permainan
var run_history: Array = []

func _ready() -> void:
	load_game_progress()

# Memulai Permainan / Tahap Baru
func start_stage(stage_number: int, seed_value: int = 0) -> void:
	current_stage = stage_number
	current_row = 1
	current_node_id = ""
	current_map_seed = seed_value if seed_value != 0 else randi()

	if stage_number == 1 or stage_number == 2:
		# GDD 5.1 & 5.5: Tahap 1 dan 2 dimulai dengan HP 10 dan Max HP 10
		max_hp = 10
		hp = 10
	elif stage_number == 3:
		# GDD 5.5: Tahap 3 membawa Max HP setelah Boss Tahap 2, dan HP dipulihkan penuh
		hp = max_hp

	# Catat Api Unggun baris 1 sebagai checkpoint pertama tahap ini
	save_bonfire_checkpoint(1, "", false)
	emit_signal("stage_changed", current_stage)

# Pemulihan & Penyimpanan di Titik Api Unggun (GDD 4.3 & 5.6)
func reach_bonfire(row: int, node_id: String) -> void:
	current_row = row
	current_node_id = node_id

	# Pemulihan HP di baris 4 dan 7 (Baris 1 tidak memberi pemulihan)
	if row == 4 or row == 7:
		hp = min(hp + 5, max_hp)
		print("Api Unggun Baris %d: HP pulih +5 (HP saat ini: %d/%d)" % [row, hp, max_hp])

	# Simpan checkpoint SETELAH pemulihan diterapkan
	save_bonfire_checkpoint(row, node_id, true)

func save_bonfire_checkpoint(row: int, node_id: String, emit_event: bool = true) -> void:
	latest_checkpoint = {
		"stage": current_stage,
		"row": row,
		"node_id": node_id,
		"saved_hp": hp,
		"saved_max_hp": max_hp,
		"map_seed": current_map_seed
	}
	if emit_event:
		emit_signal("checkpoint_updated", row)
	print("Checkpoint tersimpan di Api Unggun Baris %d (HP: %d/%d)" % [row, hp, max_hp])

# Hadiah Mengalahkan Musuh (GDD 5.3)
func on_enemy_defeated(category: String) -> void:
	if category == "Normal":
		if hp == max_hp:
			max_hp += 1
			hp += 1 # HP ikut naik agar tetap penuh
		else:
			hp = min(hp + 1, max_hp)
	elif category == "Elite":
		if hp == max_hp:
			max_hp += 2
			hp += 2
		else:
			hp = min(hp + 2, max_hp)
	# Boss tidak mengubah HP atau Max HP (GDD 5.3 & 5.5)

# Efek Tanda Tanya (GDD 4.5)
func apply_event_hp_change(delta: int) -> void:
	if delta > 0:
		hp = min(hp + delta, max_hp)
	elif delta < 0:
		hp += delta # Pengurangan HP bisa memicu game over jika <= 0

# Mengulang Setelah Kalah (GDD 5.6)
func respawn_at_checkpoint() -> void:
	current_stage = latest_checkpoint["stage"]
	current_row = latest_checkpoint["row"]
	current_node_id = latest_checkpoint["node_id"]
	current_map_seed = latest_checkpoint["map_seed"]

	# Pulihkan nilai HP ke kondisi saat tiba di checkpoint
	max_hp = latest_checkpoint["saved_max_hp"]
	hp = latest_checkpoint["saved_hp"]
	print("Bima mengulang dari Api Unggun Baris %d (HP dipulihkan ke: %d/%d)" % [current_row, hp, max_hp])

# Kemenangan Bos Tahap
func complete_current_stage() -> void:
	if current_stage == 1:
		has_completed_stage_1 = true
		save_game_progress()
		emit_signal("stage_cleared", 1)
	elif current_stage == 2:
		save_game_progress()
		emit_signal("stage_cleared", 2)
	elif current_stage == 3:
		save_game_progress()
		emit_signal("stage_cleared", 3)

# Penyimpanan Riwayat Lokal ke user://history.json (GDD Bagian 7)
func save_game_progress() -> void:
	var save_data = {
		"has_completed_stage_1": has_completed_stage_1,
		"last_played": Time.get_datetime_string_from_system()
	}
	var file = FileAccess.open("user://history.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()

func load_game_progress() -> void:
	if FileAccess.file_exists("user://history.json"):
		var file = FileAccess.open("user://history.json", FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK:
				var data = json.get_data()
				has_completed_stage_1 = data.get("has_completed_stage_1", false)
