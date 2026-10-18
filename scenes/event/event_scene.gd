extends Control
class_name EventScene

# Elemen UI
@onready var title_label: Label = $TopBar/HBoxContainer/TitleLabel
@onready var hp_label: Label = $TopBar/HBoxContainer/HPLabel
@onready var btn_map: Button = $TopBar/HBoxContainer/BtnMap

@onready var event_title: Label = $CenterContainer/MainCard/MarginContainer/VBoxContainer/EventTitle
@onready var story_text: Label = $CenterContainer/MainCard/MarginContainer/VBoxContainer/StoryText
@onready var outcome_badge: PanelContainer = $CenterContainer/MainCard/MarginContainer/VBoxContainer/OutcomeBadge
@onready var outcome_label: Label = $CenterContainer/MainCard/MarginContainer/VBoxContainer/OutcomeBadge/MarginContainer/OutcomeLabel
@onready var result_desc: Label = $CenterContainer/MainCard/MarginContainer/VBoxContainer/ResultDesc
@onready var btn_action: Button = $BottomBar/BtnAction

@onready var defeat_modal: AcceptDialog = $Popups/DefeatModal
@onready var map_preview = $MapPreview

enum OutcomeType {
	HP_PLUS,
	HP_MINUS,
	NORMAL_ENEMY,
	ELITE_ENEMY,
	NEUTRAL
}

var rolled_outcome: OutcomeType
var rolled_delta: int = 0
var current_event_data: Dictionary = {}

func _ready() -> void:
	btn_action.pressed.connect(_on_action_pressed)
	defeat_modal.confirmed.connect(_on_respawn_after_defeat)
	if btn_map and map_preview:
		btn_map.pressed.connect(map_preview.open_preview)

	_roll_event()
	_update_hud()

func _update_hud() -> void:
	hp_label.text = "❤️ HP: %d / %d" % [GameState.hp, GameState.max_hp]

func _roll_event() -> void:
	var stage = GameState.current_stage

	# GDD 4.5: Kelima hasil memiliki peluang sama (20% untuk setiap hasil)
	var roll = randf()
	var outcome_key = ""

	if roll < 0.20:
		rolled_outcome = OutcomeType.HP_PLUS
		outcome_key = "hp_plus"
		# Perubahan HP acak +1 hingga +3 (peluang sama, dibatasi Max HP)
		rolled_delta = randi_range(1, 3)
	elif roll < 0.40:
		rolled_outcome = OutcomeType.HP_MINUS
		outcome_key = "hp_minus"
		# Perubahan HP acak -1 hingga -3
		rolled_delta = -randi_range(1, 3)
	elif roll < 0.60:
		rolled_outcome = OutcomeType.NORMAL_ENEMY
		outcome_key = "normal_enemy"
	elif roll < 0.80:
		rolled_outcome = OutcomeType.ELITE_ENEMY
		outcome_key = "elite_enemy"
	else:
		rolled_outcome = OutcomeType.NEUTRAL
		outcome_key = "neutral"

	current_event_data = _find_event_story(stage, outcome_key)
	_display_event()

func _find_event_story(stage: int, outcome_key: String) -> Dictionary:
	var file_path = "res://data/events.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var text = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(text) == OK:
			var all_events = json.get_data().get("events", [])
			var matching = []
			for ev in all_events:
				if int(ev.get("stage")) == stage and ev.get("outcome") == outcome_key:
					matching.append(ev)
			if matching.size() > 0:
				return matching.pick_random()

	# Fallback draf jika file tidak terbaca
	return {
		"title": "Kejadian di Perjalanan",
		"story": "Bima melangkah mantap menyusuri lorong menuju tujuannya.",
		"flavor_result": "Perjalanan berlanjut."
	}

func _display_event() -> void:
	event_title.text = current_event_data.get("title", "Kejadian Tak Terduga")
	story_text.text = current_event_data.get("story", "")
	result_desc.text = current_event_data.get("flavor_result", "")

	match rolled_outcome:
		OutcomeType.HP_PLUS:
			outcome_badge.modulate = Color(0.4, 1.0, 0.4) # Hijau
			outcome_label.text = "❤️ DAYA TAHAN BERTAMBAH (+%d HP)" % rolled_delta
			btn_action.text = "LANJUTKAN PERJALANAN ➔"
			# Terapkan penambahan HP ke GameState
			GameState.apply_event_hp_change(rolled_delta)
			_update_hud()

		OutcomeType.HP_MINUS:
			outcome_badge.modulate = Color(1.0, 0.4, 0.4) # Merah
			outcome_label.text = "💔 DAYA TAHAN BERKURANG (%d HP)" % rolled_delta
			# Terapkan pengurangan HP ke GameState
			GameState.apply_event_hp_change(rolled_delta)
			_update_hud()

			if GameState.hp <= 0:
				btn_action.disabled = true
				defeat_modal.dialog_text = "Kejadian tak terduga menguras habis tenaga Bima...\nBima akan mengulang dari Api Unggun terbaru."
				defeat_modal.popup_centered()
			else:
				btn_action.text = "LANJUTKAN PERJALANAN ➔"

		OutcomeType.NORMAL_ENEMY:
			outcome_badge.modulate = Color(0.6, 0.8, 1.0) # Biru terang
			outcome_label.text = "⚔️ TANTANGAN LATIHAN SPONTAN!"
			btn_action.text = "HADAPI TANTANGAN ➔"

		OutcomeType.ELITE_ENEMY:
			outcome_badge.modulate = Color(1.0, 0.35, 0.35) # Merah tua
			outcome_label.text = "💀 TANTANGAN ELITE MENDADAK!"
			btn_action.text = "MASUKI TANTANGAN ELITE ➔"

		OutcomeType.NEUTRAL:
			outcome_badge.modulate = Color(0.8, 0.8, 0.8) # Netral
			outcome_label.text = "🕊️ KETENANGAN BATIN (TIDAK ADA EFEK)"
			btn_action.text = "LANJUTKAN PERJALANAN ➔"

func _on_action_pressed() -> void:
	match rolled_outcome:
		OutcomeType.NORMAL_ENEMY:
			GameState.current_node_type = MapGenerator.NodeType.NORMAL
			get_tree().change_scene_to_file("res://scenes/quiz/quiz_scene.tscn")
		OutcomeType.ELITE_ENEMY:
			GameState.current_node_type = MapGenerator.NodeType.ELITE
			get_tree().change_scene_to_file("res://scenes/quiz/quiz_scene.tscn")
		_:
			# Kembali ke peta
			get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_respawn_after_defeat() -> void:
	GameState.respawn_at_checkpoint()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
