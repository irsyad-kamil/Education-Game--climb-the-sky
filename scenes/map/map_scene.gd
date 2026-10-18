extends Control
class_name MapScene

@export var node_scene: PackedScene = preload("res://scenes/map/map_node.tscn")

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_canvas: Control = $ScrollContainer/MapCanvas
@onready var hp_label: Label = $TopHUD/MarginContainer/HBoxContainer/HPLabel
@onready var stage_label: Label = $TopHUD/MarginContainer/HBoxContainer/StageLabel
@onready var btn_menu: Button = $TopHUD/MarginContainer/HBoxContainer/BtnMenu
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_text: Label = $InfoPanel/MarginContainer/VBoxContainer/InfoText

var map_data: Dictionary = {}
var node_ui_map: Dictionary = {} # id -> MapNodeUI
var node_positions: Dictionary = {} # id -> Vector2

func _ready() -> void:
	GameState.hp_changed.connect(_on_hp_changed)
	btn_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
	_update_hud()
	
	# Ambil data peta dari seed yang sedang aktif di GameState
	if GameState.current_map_seed == 0:
		GameState.start_stage(GameState.current_stage)
	
	build_map()
	_update_node_reachability()
	
	# Atur posisi scroll awal ke baris paling bawah (tempat Bima mendaki)
	await get_tree().process_frame
	_scroll_to_current_progress()

func _update_hud() -> void:
	hp_label.text = "❤️ HP: %d / %d" % [GameState.hp, GameState.max_hp]
	var stage_names = {
		1: "Tahap 1: Lulus SMA (Tutorial)",
		2: "Tahap 2: Lulus Kuliah",
		3: "Tahap 3: Membangun Masa Depan"
	}
	stage_label.text = stage_names.get(GameState.current_stage, "Climb the Sky")

func _on_hp_changed(curr: int, max_val: int) -> void:
	hp_label.text = "❤️ HP: %d / %d" % [curr, max_val]

func build_map() -> void:
	# Bersihkan kanvas lama
	for child in map_canvas.get_children():
		child.queue_free()
	node_ui_map.clear()
	node_positions.clear()

	map_data = MapGenerator.generate_map(GameState.current_stage, GameState.current_map_seed)
	var rows_data: Array = map_data.get("rows", [])
	if rows_data.is_empty():
		return

	var total_rows = rows_data.size()
	var row_height = 180.0
	var canvas_width = 1920.0
	var canvas_height = max(1080.0, total_rows * row_height + 250.0)
	map_canvas.custom_minimum_size = Vector2(canvas_width, canvas_height)

	# Buat simpul-simpul dari bawah (Baris 1) ke atas (Baris Boss)
	for r in range(total_rows):
		var row_nodes: Array = rows_data[r]
		# Y koordinat: baris 1 di bagian bawah kanvas, baris terakhir di atas
		var y_pos = canvas_height - 180.0 - (r * row_height)
		var count = row_nodes.size()

		for c in range(count):
			var node_data: MapGenerator.MapNode = row_nodes[c]
			var x_pos = (canvas_width / (count + 1)) * (c + 1)
			var pos = Vector2(x_pos, y_pos)

			var node_instance: MapNodeUI = node_scene.instantiate()
			node_instance.position = pos - Vector2(36, 36)
			map_canvas.add_child(node_instance)
			node_instance.setup(node_data)
			node_instance.node_clicked.connect(_on_node_selected)

			node_ui_map[node_data.id] = node_instance
			node_positions[node_data.id] = pos

	map_canvas.queue_redraw()

func _update_node_reachability() -> void:
	var current_node_id = GameState.current_node_id
	var nodes_dict: Dictionary = map_data.get("nodes", {})

	# Jika Bima belum memilih simpul awal di baris 1
	if current_node_id.is_empty():
		for id in node_ui_map.keys():
			var ui_node: MapNodeUI = node_ui_map[id]
			# Seluruh simpul di baris 1 dapat dipilih
			if ui_node.node_data.row == 1:
				ui_node.update_state(true, false)
			else:
				ui_node.update_state(false, false)
		return

	# Jika Bima sudah berada pada simpul tertentu
	var current_node: MapGenerator.MapNode = nodes_dict.get(current_node_id)
	if not current_node:
		return

	for id in node_ui_map.keys():
		var ui_node: MapNodeUI = node_ui_map[id]
		var is_curr = (id == current_node_id)
		var is_next_target = current_node.connections.has(id)
		ui_node.update_state(is_next_target, is_curr)

func _on_node_selected(node: MapGenerator.MapNode) -> void:
	print("Pemain memilih simpul: %s (%s) di baris %d" % [node.id, node.type, node.row])
	
	# Update posisi Bima di GameState
	GameState.current_row = node.row
	GameState.current_node_id = node.id
	GameState.current_node_type = node.type
	_update_node_reachability()
	_scroll_to_current_progress()

	# Reaksi berdasarkan tipe simpul
	match node.type:
		MapGenerator.NodeType.CAMPFIRE:
			get_tree().change_scene_to_file("res://scenes/campfire/campfire_scene.tscn")
		MapGenerator.NodeType.NORMAL, MapGenerator.NodeType.ELITE, MapGenerator.NodeType.BOSS:
			get_tree().change_scene_to_file("res://scenes/quiz/quiz_scene.tscn")
		MapGenerator.NodeType.EVENT:
			get_tree().change_scene_to_file("res://scenes/event/event_scene.tscn")

func _show_info(msg: String) -> void:
	info_text.text = msg
	info_panel.visible = true

func _scroll_to_current_progress() -> void:
	if node_positions.has(GameState.current_node_id):
		var target_y = node_positions[GameState.current_node_id].y
		# Posisikan scroll di tengah layar
		scroll_container.scroll_vertical = int(max(0, target_y - 540.0))
	else:
		# Default scroll paling bawah
		scroll_container.scroll_vertical = int(map_canvas.custom_minimum_size.y)
