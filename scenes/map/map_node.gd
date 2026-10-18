extends Button
class_name MapNodeUI

signal node_clicked(node_data: MapGenerator.MapNode)

var node_data: MapGenerator.MapNode
var is_reachable: bool = false
var is_current: bool = false

@onready var type_label: Label = $TypeLabel

func setup(data: MapGenerator.MapNode) -> void:
	node_data = data
	custom_minimum_size = Vector2(72, 72)

	if not is_inside_tree():
		await ready

	_apply_visuals()

func _apply_visuals() -> void:
	if not node_data:
		return

	# Warna dan simbol representasi tipe simpul
	match node_data.type:
		MapGenerator.NodeType.CAMPFIRE:
			text = "🔥"
			if type_label: type_label.text = "Api Unggun"
			modulate = Color(1.0, 0.65, 0.2) # Oranye hangat
		MapGenerator.NodeType.NORMAL:
			text = "⚔️"
			if type_label: type_label.text = "Musuh"
			modulate = Color(0.85, 0.85, 0.85) # Putih/abu terang
		MapGenerator.NodeType.ELITE:
			text = "💀"
			if type_label: type_label.text = "Elite"
			modulate = Color(1.0, 0.35, 0.35) # Merah tantangan
		MapGenerator.NodeType.EVENT:
			text = "❓"
			if type_label: type_label.text = "Kejadian"
			modulate = Color(0.4, 0.8, 1.0) # Biru misteri
		MapGenerator.NodeType.BOSS:
			text = "👑"
			if type_label: type_label.text = "BOS"
			custom_minimum_size = Vector2(96, 96)
			modulate = Color(1.0, 0.84, 0.0) # Emas

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	update_state(is_reachable, is_current)

func update_state(reachable: bool, current: bool) -> void:
	is_reachable = reachable
	is_current = current

	disabled = not is_reachable
	if is_current:
		self_modulate = Color(1.5, 1.5, 1.5) # Efek bersinar (glow)
	elif is_reachable:
		self_modulate = Color(1.0, 1.0, 1.0)
	else:
		self_modulate = Color(0.45, 0.45, 0.45, 0.6) # Redup jika terkunci

func _on_pressed() -> void:
	if is_reachable:
		emit_signal("node_clicked", node_data)
