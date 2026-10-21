extends Control
class_name CampfireScene

@onready var title_label: Label = $TopBar/HBoxContainer/TitleLabel
@onready var hp_label: Label = $TopBar/HBoxContainer/HPLabel
@onready var intro_label: Label = $CenterContainer/MainCard/MarginContainer/VBoxContainer/IntroLabel
@onready var slide_heading: Label = $CenterContainer/MainCard/MarginContainer/VBoxContainer/SlideContent/SlideHeading
@onready var slide_body: RichTextLabel = $CenterContainer/MainCard/MarginContainer/VBoxContainer/SlideContent/SlideBody
@onready var page_indicator: Label = $CenterContainer/MainCard/MarginContainer/VBoxContainer/Navigation/PageIndicator

@onready var btn_prev: Button = $CenterContainer/MainCard/MarginContainer/VBoxContainer/Navigation/BtnPrev
@onready var btn_next: Button = $CenterContainer/MainCard/MarginContainer/VBoxContainer/Navigation/BtnNext
@onready var btn_continue: Button = $BottomBar/BtnContinue
@onready var btn_map: Button = $TopBar/HBoxContainer/BtnMap
@onready var map_preview = $MapPreview

var current_slides: Array = []
var current_slide_index: int = 0
var campfire_data: Dictionary = {}

func _ready() -> void:
	btn_prev.pressed.connect(_on_prev_slide)
	btn_next.pressed.connect(_on_next_slide)
	btn_continue.pressed.connect(_return_to_map)
	if btn_map and map_preview:
		btn_map.pressed.connect(map_preview.open_preview)

	_apply_bonfire_effect()
	_load_campfire_content()
	_show_slide(0)

func _apply_bonfire_effect() -> void:
	var row = GameState.current_row
	# Terapkan pemulihan dan simpan checkpoint ke GameState (GDD 4.3 & 5.6)
	GameState.reach_bonfire(row, GameState.current_node_id)

	var heal_msg = " (+5 HP Pulih!)" if (row == 4 or row == 7) else ""
	hp_label.text = "❤️ HP: %d / %d%s" % [GameState.hp, GameState.max_hp, heal_msg]

func _load_campfire_content() -> void:
	var stage = GameState.current_stage
	var row = GameState.current_row

	campfire_data = _find_campfire_data(stage, row)
	title_label.text = campfire_data.get("title", "Titik Belajar & Api Unggun")
	intro_label.text = campfire_data.get("flavor_intro", "Bima beristirahat sejenak untuk mempelajari materi...")
	current_slides = campfire_data.get("slides", [])

func _find_campfire_data(stage: int, row: int) -> Dictionary:
	var file_path = "res://data/campfires.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var text = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(text) == OK:
			var all_camps = json.get_data().get("campfires", [])
			for c in all_camps:
				if int(c.get("stage")) == stage and int(c.get("row")) == row:
					return c
			# Jika tidak ada baris yang sama persis, ambil yang stage-nya sama
			for c in all_camps:
				if int(c.get("stage")) == stage:
					return c

	# Draf fallback default jika file JSON tidak terbaca
	return {
		"title": "Kamar Belajar Bima",
		"flavor_intro": "Bima membaca kembali catatan konsep ukuran pemusatan data.",
		"slides": [
			{
				"heading": "Ukuran Pemusatan Data",
				"body": "• Mean: Rata-rata hitung semua data.\n• Median: Nilai tengah setelah data diurutkan.\n• Modus: Nilai yang paling sering muncul."
			}
		]
	}

func _show_slide(idx: int) -> void:
	if current_slides.is_empty():
		return

	current_slide_index = clampi(idx, 0, current_slides.size() - 1)
	var slide = current_slides[current_slide_index]

	slide_heading.text = slide.get("heading", "")
	slide_body.text = slide.get("body", "")
	page_indicator.text = "Halaman %d / %d" % [current_slide_index + 1, current_slides.size()]

	btn_prev.disabled = (current_slide_index == 0)
	btn_next.disabled = (current_slide_index == current_slides.size() - 1)

	# Beri sorotan pada tombol lanjutkan jika sudah di slide terakhir
	if current_slide_index == current_slides.size() - 1:
		btn_continue.text = "LANJUTKAN PENDAKIAN ➔"
		btn_continue.modulate = Color(1.2, 1.2, 1.0)
	else:
		btn_continue.text = "Lanjutkan Pendakian"
		btn_continue.modulate = Color(1.0, 1.0, 1.0)

func _on_prev_slide() -> void:
	if current_slide_index > 0:
		_show_slide(current_slide_index - 1)

func _on_next_slide() -> void:
	if current_slide_index < current_slides.size() - 1:
		_show_slide(current_slide_index + 1)

func _return_to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
