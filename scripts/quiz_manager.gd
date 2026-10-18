extends Control
class_name QuizManager

signal quiz_completed(category: String)
signal player_defeated

# Data Soal Aktif
var current_question: Dictionary = {}
var boss_questions_queue: Array = []
var boss_current_index: int = 0
var is_boss_battle: bool = false

# Counter Penalti
var wrong_attempts: int = 0
var normal_wrong_count: int = 0 # Maksimal 2 penalti untuk PG Normal

# Timer Time Attack
var time_attack_timer: Timer

func _ready() -> void:
	time_attack_timer = Timer.new()
	time_attack_timer.one_shot = true
	time_attack_timer.timeout.connect(_on_time_attack_cycle_finished)
	add_child(time_attack_timer)

# Memulai Pertarungan Normal / Elite
func start_single_quiz(question_data: Dictionary) -> void:
	is_boss_battle = false
	current_question = question_data
	_setup_question_view()

# Memulai Pertarungan Boss (5 Soal Berturut-turut)
func start_boss_battle(questions_array: Array) -> void:
	is_boss_battle = true
	boss_questions_queue = questions_array
	boss_current_index = 0
	_load_next_boss_question()

func _load_next_boss_question() -> void:
	if boss_current_index < boss_questions_queue.size():
		current_question = boss_questions_queue[boss_current_index]
		_setup_question_view()
	else:
		emit_signal("quiz_completed", "Boss")

func _setup_question_view() -> void:
	wrong_attempts = 0
	normal_wrong_count = 0

	# Reset & Mulai Time Attack jika soal memilikinya (GDD 4.6)
	if current_question.get("has_time_attack", false):
		time_attack_timer.start(30.0)
	else:
		time_attack_timer.stop()

# Siklus Time Attack 30 Detik Habis
func _on_time_attack_cycle_finished() -> void:
	apply_damage(1, "Waktu 30 detik habis!")
	# Timer otomatis berulang dari 30 detik untuk soal yang sama
	time_attack_timer.start(30.0)

# Penerapan Pengurangan HP Terpusat
func apply_damage(amount: int, reason: String = "") -> void:
	GameState.hp -= amount
	print("Bima terkena damage: -%d HP. Sisa HP: %d (%s)" % [amount, GameState.hp, reason])

	if GameState.hp <= 0:
		time_attack_timer.stop()
		emit_signal("player_defeated")

# Dipanggil saat jawaban BENAR
func handle_correct_answer() -> void:
	time_attack_timer.stop()
	print("Jawaban Benar!")

	if is_boss_battle:
		boss_current_index += 1
		_load_next_boss_question()
	else:
		# Beri hadiah kemenangan ke GameState
		var cat = current_question.get("category", "Normal")
		GameState.on_enemy_defeated(cat)
		emit_signal("quiz_completed", cat)
