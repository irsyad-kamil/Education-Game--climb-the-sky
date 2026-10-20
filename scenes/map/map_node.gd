extends Button
class_name MapNodeUI

# MapNodeUI v2.0 (Modern, Clean, & Palette desain.md)
# Mengelola visual simpul titik soal linear (Selesai, Aktif, Terkunci)
# Bebas emoji: Menggunakan icon vektor flat SVG (check.svg, lock.svg) dan tipografi tajam

signal node_clicked(point_index: int)

enum NodeState {
	COMPLETED,
	CURRENT,
	LOCKED
}

var point_index: int = 1
var state: NodeState = NodeState.LOCKED
var question_data: Dictionary = {}

@onready var node_icon: TextureRect = $NodeIcon
@onready var type_label: Label = $TypeLabel

func setup_point(p_index: int, q_data: Dictionary, p_state: NodeState) -> void:
	point_index = p_index
	question_data = q_data
	state = p_state
	
	if not is_inside_tree():
		await ready
		
	_apply_visuals()

# Stub kompatibilitas
func setup(data) -> void:
	if data is int:
		setup_point(data, {}, NodeState.CURRENT)
	elif data is Dictionary:
		setup_point(int(data.get("point_index", 1)), data, NodeState.CURRENT)
	else:
		setup_point(1, {}, NodeState.CURRENT)

func _get_tm() -> Node:
	if is_inside_tree() and has_node("/root/ThemeManager"):
		return get_node("/root/ThemeManager")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("ThemeManager"):
		return main_loop.root.get_node("ThemeManager")
	return null

func _get_gs() -> Node:
	if is_inside_tree() and has_node("/root/GameState"):
		return get_node("/root/GameState")
	var main_loop = Engine.get_main_loop()
	if main_loop and main_loop is SceneTree and main_loop.root.has_node("GameState"):
		return main_loop.root.get_node("GameState")
	return null

func _apply_visuals() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	var tm = _get_tm()
	var gs = _get_gs()
	var lvl = gs.current_level if gs else 1
	var lvl_col = tm.get_level_color(lvl) if tm else Color("#FF8A3D")
	
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	match state:
		NodeState.COMPLETED:
			text = ""
			disabled = false
			if node_icon:
				node_icon.visible = true
				if tm:
					node_icon.texture = tm.get_icon("check")
					node_icon.modulate = Color(1, 1, 1, 1)

			var comp_style = StyleBoxFlat.new()
			comp_style.bg_color = tm.COLOR_CORRECT_GREEN if tm else Color("#3DDC97")
			comp_style.border_color = Color(1, 1, 1, 1)
			comp_style.set_border_width_all(3)
			comp_style.set_corner_radius_all(42)
			comp_style.shadow_color = Color(0.1, 0.4, 0.2, 0.3)
			comp_style.shadow_size = 10
			comp_style.shadow_offset = Vector2(0, 4)

			add_theme_stylebox_override("normal", comp_style)
			add_theme_stylebox_override("hover", comp_style)
			add_theme_stylebox_override("pressed", comp_style)

			if type_label:
				type_label.text = "Titik %d (Selesai)" % point_index
				type_label.add_theme_color_override("font_color", Color("#15803D"))

		NodeState.CURRENT:
			text = str(point_index)
			disabled = false
			if node_icon:
				node_icon.visible = false

			var curr_style = StyleBoxFlat.new()
			curr_style.bg_color = lvl_col
			curr_style.border_color = Color(1, 1, 1, 1)
			curr_style.set_border_width_all(4)
			curr_style.set_corner_radius_all(42)
			curr_style.shadow_color = Color(lvl_col.r, lvl_col.g, lvl_col.b, 0.5)
			curr_style.shadow_size = 14
			curr_style.shadow_offset = Vector2(0, 4)

			var hov_style = curr_style.duplicate()
			hov_style.set_border_width_all(6)

			add_theme_stylebox_override("normal", curr_style)
			add_theme_stylebox_override("hover", hov_style)
			add_theme_stylebox_override("pressed", curr_style)
			
			var text_col = tm.COLOR_TEXT_NAVY if lvl == 3 else Color(1, 1, 1, 1)
			add_theme_color_override("font_color", text_col)
			add_theme_color_override("font_hover_color", text_col)

			if type_label:
				var q_type = question_data.get("type", "Soal")
				type_label.text = "Titik %d: %s\n[Mulai Soal]" % [point_index, q_type]
				type_label.add_theme_color_override("font_color", tm.COLOR_TEXT_NAVY if tm else Color("#1E2A4A"))

		NodeState.LOCKED:
			text = ""
			disabled = true
			if node_icon:
				node_icon.visible = true
				if tm:
					node_icon.texture = tm.get_icon("lock")
					node_icon.modulate = Color("#758296")

			var lock_style = StyleBoxFlat.new()
			lock_style.bg_color = tm.COLOR_LOCKED_GRAY if tm else Color("#D5DDE8")
			lock_style.border_color = Color(0.75, 0.80, 0.88, 1)
			lock_style.set_border_width_all(2)
			lock_style.set_corner_radius_all(42)
			add_theme_stylebox_override("disabled", lock_style)

			if type_label:
				type_label.text = "Titik %d (Terkunci)" % point_index
				type_label.add_theme_color_override("font_color", Color("#758296"))

func update_state(new_state: NodeState) -> void:
	state = new_state
	_apply_visuals()

func _on_pressed() -> void:
	emit_signal("node_clicked", point_index)
