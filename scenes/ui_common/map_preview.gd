extends CanvasLayer

signal preview_closed

@onready var title_label: Label = $TopBar/HBoxContainer/TitleLabel
@onready var btn_close: Button = $TopBar/HBoxContainer/BtnClose
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_canvas: Control = $ScrollContainer/MapCanvas

var node_positions: Dictionary = {}
var map_data: Dictionary = {}

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(close_preview)
	if map_canvas:
		map_canvas.preview_owner = self

func open_preview() -> void:
	visible = true
	_update_title()
	_build_preview_map()
	await get_tree().process_frame
	_scroll_to_current_node()

func close_preview() -> void:
	visible = false
	emit_signal("preview_closed")

func _update_title() -> void:
	var stage_names = {
		1: "Tahap 1: Lulus SMA (Tutorial)",
		2: "Tahap 2: Lulus Kuliah",
		3: "Tahap 3: Membangun Masa Depan"
	}
	var s_name = stage_names.get(GameState.current_stage, "Climb the Sky")
	title_label.text = "🗺️ %s — Pratinjau Rute Peta" % s_name

func _build_preview_map() -> void:
	for child in map_canvas.get_children():
		child.queue_free()
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

	for r in range(total_rows):
		var row_nodes: Array = rows_data[r]
		var y_pos = canvas_height - 180.0 - (r * row_height)
		var count = row_nodes.size()

		for c in range(count):
			var node_data: MapGenerator.MapNode = row_nodes[c]
			var x_pos = (canvas_width / (count + 1)) * (c + 1)
			var pos = Vector2(x_pos, y_pos)
			node_positions[node_data.id] = pos

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(72, 72)
			btn.position = pos - Vector2(36, 36)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var is_current = (node_data.id == GameState.current_node_id)
			var current_node: MapGenerator.MapNode = map_data["nodes"].get(GameState.current_node_id)
			var is_next = current_node and current_node.connections.has(node_data.id)

			match node_data.type:
				MapGenerator.NodeType.CAMPFIRE:
					btn.text = "🔥"
					btn.modulate = Color(1.0, 0.65, 0.2)
				MapGenerator.NodeType.NORMAL:
					btn.text = "⚔️"
					btn.modulate = Color(0.85, 0.85, 0.85)
				MapGenerator.NodeType.ELITE:
					btn.text = "💀"
					btn.modulate = Color(1.0, 0.35, 0.35)
				MapGenerator.NodeType.EVENT:
					btn.text = "❓"
					btn.modulate = Color(0.4, 0.8, 1.0)
				MapGenerator.NodeType.BOSS:
					btn.text = "👑"
					btn.custom_minimum_size = Vector2(96, 96)
					btn.position = pos - Vector2(48, 48)
					btn.modulate = Color(1.0, 0.84, 0.0)

			btn.add_theme_font_size_override("font_size", 24)

			if is_current:
				btn.self_modulate = Color(2.0, 2.0, 2.0)
			elif is_next:
				btn.self_modulate = Color(1.0, 1.0, 1.0)
			else:
				btn.self_modulate = Color(0.4, 0.4, 0.4, 0.6)

			var lbl = Label.new()
			lbl.text = _get_type_name(node_data.type)
			if is_current:
				lbl.text += " (Di Sini)"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.position = Vector2(-36, 74)
			lbl.custom_minimum_size = Vector2(144, 24)
			btn.add_child(lbl)

			map_canvas.add_child(btn)

	map_canvas.queue_redraw()

func _get_type_name(t: MapGenerator.NodeType) -> String:
	match t:
		MapGenerator.NodeType.CAMPFIRE: return "Api Unggun"
		MapGenerator.NodeType.NORMAL: return "Musuh"
		MapGenerator.NodeType.ELITE: return "Elite"
		MapGenerator.NodeType.EVENT: return "Kejadian"
		MapGenerator.NodeType.BOSS: return "BOS"
	return ""

func _scroll_to_current_node() -> void:
	if node_positions.has(GameState.current_node_id):
		var target_y = node_positions[GameState.current_node_id].y
		scroll_container.scroll_vertical = int(max(0, target_y - 540.0))
	else:
		scroll_container.scroll_vertical = int(map_canvas.custom_minimum_size.y)
