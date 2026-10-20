extends Button
class_name MapNodeUI

# MapNodeUI v1.0 (GDD v1.0 Architecture)
# Mengelola tampilan visual simpul titik soal linear (Selesai, Aktif, Terkunci)

signal node_clicked(point_index: int)

enum NodeState {
	COMPLETED,
	CURRENT,
	LOCKED
}

var point_index: int = 1
var state: NodeState = NodeState.LOCKED
var question_data: Dictionary = {}

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

func _apply_visuals() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
		
	match state:
		NodeState.COMPLETED:
			text = "✅"
			disabled = false
			self_modulate = Color(0.4, 0.9, 0.5) # Hijau selesai
			if type_label:
				type_label.text = "Titik %d (Selesai)" % point_index
				type_label.modulate = Color(0.6, 1.0, 0.7)
		NodeState.CURRENT:
			text = "📍 %d" % point_index
			disabled = false
			self_modulate = Color(1.3, 1.1, 0.3) # Emas aktif
			if type_label:
				var q_type = question_data.get("type", "Soal")
				type_label.text = "Titik %d: %s\n[Klik untuk Mulai!]" % [point_index, q_type]
				type_label.modulate = Color(1.0, 0.9, 0.4)
		NodeState.LOCKED:
			text = "🔒"
			disabled = true
			self_modulate = Color(0.4, 0.45, 0.5, 0.6) # Redup terkunci
			if type_label:
				type_label.text = "Titik %d" % point_index
				type_label.modulate = Color(0.5, 0.55, 0.6)

func update_state(new_state: NodeState) -> void:
	state = new_state
	_apply_visuals()

func _on_pressed() -> void:
	emit_signal("node_clicked", point_index)
