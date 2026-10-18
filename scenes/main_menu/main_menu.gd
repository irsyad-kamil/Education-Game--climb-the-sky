extends Control
class_name MainMenu

@onready var btn_play: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnPlay
@onready var btn_select_stage: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnSelectStage
@onready var btn_story_steam: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnStorySTEAM
@onready var btn_quit: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnQuit

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

# Modals
@onready var stage_select_modal: Window = $Popups/StageSelectModal
@onready var btn_stage_1: Button = $Popups/StageSelectModal/MarginContainer/VBoxContainer/BtnStage1
@onready var btn_stage_2: Button = $Popups/StageSelectModal/MarginContainer/VBoxContainer/BtnStage2
@onready var btn_stage_3: Button = $Popups/StageSelectModal/MarginContainer/VBoxContainer/BtnStage3

@onready var about_modal: AcceptDialog = $Popups/AboutModal

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_select_stage.pressed.connect(func(): stage_select_modal.popup_centered())
	btn_story_steam.pressed.connect(func(): about_modal.popup_centered())
	btn_quit.pressed.connect(func(): get_tree().quit())

	btn_stage_1.pressed.connect(func(): _start_game_at_stage(1))
	btn_stage_2.pressed.connect(func(): _start_game_at_stage(2))

	_update_ui_state()

func _update_ui_state() -> void:
	GameState.load_game_progress()
	
	if GameState.has_completed_stage_1:
		status_label.text = "⭐ Status Progres: Tahap 1 Selesai! (Permainan dimulai dari Tahap 2)"
		btn_stage_2.disabled = false
		btn_stage_2.text = "Tahap 2: Lulus Kuliah"
	else:
		status_label.text = "🌱 Pemain Baru: Memulai dari Tahap 1 (Tutorial)"
		btn_stage_2.disabled = true
		btn_stage_2.text = "Tahap 2: Lulus Kuliah (Terkunci)"

	# GDD Bagian 7: Tahap 3 tidak dapat dimulai langsung dari menu
	btn_stage_3.disabled = true
	btn_stage_3.text = "Tahap 3: Masa Depan (Hanya terbuka dari Bos Tahap 2)"

func _on_play_pressed() -> void:
	# GDD Bagian 7: Jika belum pernah selesai Tahap 1 mulai dari 1, jika sudah mulai dari 2
	var target_stage = 2 if GameState.has_completed_stage_1 else 1
	_start_game_at_stage(target_stage)

func _start_game_at_stage(stage: int) -> void:
	stage_select_modal.hide()
	# Mulai tahap dan generate seed peta baru
	GameState.start_stage(stage)
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
