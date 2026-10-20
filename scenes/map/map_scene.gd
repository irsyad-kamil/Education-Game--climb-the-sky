extends Control
class_name MapScene

# MapScene v1.0 (GDD v1.0 Architecture)
# Menampilkan peta jalur vertikal linear naik ke atas dari Titik 1 ke Titik N.

@export var node_scene: PackedScene = preload("res://scenes/map/map_node.tscn")

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_canvas: Control = $ScrollContainer/MapCanvas
@onready var stage_label: Label = $TopHUD/MarginContainer/HBoxContainer/StageLabel
@onready var progress_label: Label = $TopHUD/MarginContainer/HBoxContainer/ProgressLabel
@onready var score_label: Label = $TopHUD/MarginContainer/HBoxContainer/ScoreLabel
@onready var btn_menu: Button = $TopHUD/MarginContainer/HBoxContainer/BtnMenu
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_text: Label = $InfoPanel/MarginContainer/VBoxContainer/InfoText

# State peta linear
var total_points: int = 5
var current_point: int = 1
var point_positions: Dictionary = {} # int (1..N) -> Vector2
var node_ui_map: Dictionary = {} # int (1..N) -> MapNodeUI

# Kompatibilitas legacy
var map_data: Dictionary = {"nodes": {}, "rows": []}
var node_positions: Dictionary:
	get:
		var legacy_dict: Dictionary = {}
		for k in point_positions.keys():
			legacy_dict[str(k)] = point_positions[k]
		return legacy_dict

func _ready() -> void:
	btn_menu.pressed.connect(_on_menu_pressed)
	
	var gs = _get_gs()
	if gs:
		if not gs.score_changed.is_connected(_on_score_changed):
			gs.score_changed.connect(_on_score_changed)
		if not gs.point_advanced.is_connected(_on_point_advanced):
			gs.point_advanced.connect(_on_point_advanced)
			
	build_linear_map()
	_update_hud()
	
	await get_tree().process_frame
	_scroll_to_current_point()

func _get_gs() -> Node:
	if is_inside_tree() and has_node("/root/GameState"):
		return get_node("/root/GameState")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("GameState"):
		return main_loop.root.get_node("GameState")
	return null

func _get_dm() -> Node:
	if is_inside_tree() and has_node("/root/DataManager"):
		return get_node("/root/DataManager")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("DataManager"):
		return main_loop.root.get_node("DataManager")
	return null

func _update_hud() -> void:
	var gs = _get_gs()
	var level_names = {
		1: "Level 1: Konsep & Perhitungan Rata-rata (Mean)",
		2: "Level 2: Konsep & Penentuan Nilai Tengah (Median)",
		3: "Level 3: Evaluasi Komparatif Mean & Median"
	}
	
	var lvl = gs.current_level if gs else 1
	var score = gs.level_score if gs else 0
	
	if stage_label:
		stage_label.text = level_names.get(lvl, "Level %d" % lvl)
	if progress_label:
		progress_label.text = "Titik %d dari %d" % [current_point, total_points]
	if score_label:
		score_label.text = "⭐ Skor: %d" % score

func _on_score_changed(new_score: int, _delta: int) -> void:
	if score_label:
		score_label.text = "⭐ Skor: %d" % new_score

func _on_point_advanced(new_point: int, _total_pts: int) -> void:
	current_point = new_point
	_update_hud()
	_refresh_node_states()
	map_canvas.queue_redraw()
	_scroll_to_current_point()

func build_linear_map() -> void:
	# Bersihkan node lama di canvas
	for child in map_canvas.get_children():
		child.queue_free()
	node_ui_map.clear()
	point_positions.clear()

	var gs = _get_gs()
	var dm = _get_dm()

	var lvl = gs.current_level if gs else 1
	total_points = dm.get_total_points(lvl) if dm else 5
	current_point = gs.current_point_index if gs else 1

	var canvas_width = 1920.0
	var step_y = 190.0
	var canvas_height = max(1080.0, (total_points + 1) * step_y + 220.0)
	map_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)

	var center_x = canvas_width / 2.0
	var y_bottom = canvas_height - 200.0

	# Susun titik dari Titik 1 (paling bawah) ke Titik N (paling atas)
	for p in range(1, total_points + 1):
		var y_pos = y_bottom - ((p - 1) * step_y)
		var pos = Vector2(center_x, y_pos)
		point_positions[p] = pos

		var node_instance: MapNodeUI = node_scene.instantiate()
		node_instance.position = pos - Vector2(42.0, 42.0)

		# Tentukan state simpul
		var p_state: MapNodeUI.NodeState = MapNodeUI.NodeState.LOCKED
		if p < current_point:
			p_state = MapNodeUI.NodeState.COMPLETED
		elif p == current_point:
			p_state = MapNodeUI.NodeState.CURRENT
		else:
			p_state = MapNodeUI.NodeState.LOCKED

		var q_data: Dictionary = dm.get_question(lvl, p) if dm else {}
		node_instance.setup_point(p, q_data, p_state)
		node_instance.node_clicked.connect(_on_node_clicked)

		map_canvas.add_child(node_instance)
		node_ui_map[p] = node_instance

	map_canvas.queue_redraw()

func _refresh_node_states() -> void:
	for p in node_ui_map.keys():
		var ui_node: MapNodeUI = node_ui_map[p]
		if p < current_point:
			ui_node.update_state(MapNodeUI.NodeState.COMPLETED)
		elif p == current_point:
			ui_node.update_state(MapNodeUI.NodeState.CURRENT)
		else:
			ui_node.update_state(MapNodeUI.NodeState.LOCKED)

func _on_node_clicked(p_index: int) -> void:
	print("Pemain memilih Titik %d (Titik aktif: %d)" % [p_index, current_point])
	if p_index == current_point:
		# Masuk ke kuis
		get_tree().change_scene_to_file("res://scenes/quiz/quiz_scene.tscn")
	elif p_index < current_point:
		_show_info("Titik %d telah selesai dikerjakan! Lanjutkan ke Titik %d yang sedang aktif." % [p_index, current_point])
	else:
		_show_info("Titik %d masih terkunci. Kerjakan soal pada Titik %d terlebih dahulu." % [p_index, current_point])

func _show_info(msg: String) -> void:
	if info_text:
		info_text.text = msg
	if info_panel:
		info_panel.visible = true

func _scroll_to_current_point() -> void:
	if point_positions.has(current_point):
		var target_y = point_positions[current_point].y
		# Letakkan titik aktif di tengah layar secara vertikal
		scroll_container.scroll_vertical = int(max(0, target_y - 480.0))
	else:
		scroll_container.scroll_vertical = int(map_canvas.custom_minimum_size.y)

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
