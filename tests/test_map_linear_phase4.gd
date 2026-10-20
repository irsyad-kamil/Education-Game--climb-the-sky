extends SceneTree

var dm: Node
var gs: Node
var map: Control

func _init() -> void:
	print("--- TEST PHASE 4: LINEAR MAP & VERTICAL PROGRESSION ---")
	
	var dm_script = load("res://scripts/autoload/data_manager.gd")
	dm = dm_script.new()
	dm.name = "DataManager"
	root.add_child(dm)
	
	var gs_script = load("res://scripts/autoload/game_state.gd")
	gs = gs_script.new()
	gs.name = "GameState"
	gs.data_manager_ref = dm
	root.add_child(gs)
	
	gs.start_level(1)
	
	var map_scene = load("res://scenes/map/map_scene.tscn")
	map = map_scene.instantiate()
	root.add_child(map)
	
	process_frame.connect(_run_test, CONNECT_ONE_SHOT)

func _run_test() -> void:
	# 1. Verifikasi Level 1 Linear Map
	assert(map.total_points == 5, "Total points Level 1 harus 5")
	assert(map.point_positions.size() == 5, "Harus ada 5 titik koordinat")
	assert(map.node_ui_map.size() == 5, "Harus ada 5 UI node")
	
	# Verifikasi sumbu vertikal (Titik 1 di bawah, Titik 5 di atas)
	var prev_y = 999999.0
	for p in range(1, 6):
		var pos: Vector2 = map.point_positions[p]
		assert(pos.x == 960.0, "Titik %d harus tepat di tengah sumbu X (960)" % p)
		assert(pos.y < prev_y, "Titik %d harus lebih tinggi (Y lebih kecil) daripada titik sebelumnya" % p)
		prev_y = pos.y
	print("[PASS] Level 1: 5 Titik vertikal linear tersusun tepat ke atas dari bawah.")
	
	# Verifikasi status node awal (Titik 1 aktif, Titik 2-5 terkunci)
	var node1: MapNodeUI = map.node_ui_map[1]
	assert(node1.state == MapNodeUI.NodeState.CURRENT, "Titik 1 harus dalam state CURRENT")
	assert(node1.disabled == false, "Titik 1 harus aktif (bisa diklik)")
	
	for p in range(2, 6):
		var node: MapNodeUI = map.node_ui_map[p]
		assert(node.state == MapNodeUI.NodeState.LOCKED, "Titik %d harus LOCKED" % p)
		assert(node.disabled == true, "Titik %d harus disabled" % p)
	print("[PASS] Level 1: Status awal simpul terverifikasi (Titik 1 Aktif, Titik 2-5 Terkunci).")
	
	# 2. Simulasi Progres ke Titik 3
	gs.current_point_index = 3
	map.current_point = 3
	map._refresh_node_states()
	
	assert(map.node_ui_map[1].state == MapNodeUI.NodeState.COMPLETED, "Titik 1 harus COMPLETED")
	assert(map.node_ui_map[2].state == MapNodeUI.NodeState.COMPLETED, "Titik 2 harus COMPLETED")
	assert(map.node_ui_map[3].state == MapNodeUI.NodeState.CURRENT, "Titik 3 harus CURRENT")
	assert(map.node_ui_map[4].state == MapNodeUI.NodeState.LOCKED, "Titik 4 harus LOCKED")
	assert(map.node_ui_map[5].state == MapNodeUI.NodeState.LOCKED, "Titik 5 harus LOCKED")
	print("[PASS] Level 1: Progres ke Titik 3 terverifikasi (Titik 1 & 2 Selesai, 3 Aktif, 4 & 5 Terkunci).")
	
	# 3. Verifikasi Level 2 Linear Map (4 Titik)
	gs.start_level(2)
	map.build_linear_map()
	assert(map.total_points == 4, "Total points Level 2 harus 4")
	assert(map.node_ui_map.size() == 4, "Harus ada 4 UI node di Level 2")
	assert(map.point_positions[1].y > map.point_positions[4].y, "Titik 1 harus di bawah Titik 4")
	print("[PASS] Level 2: 4 Titik vertikal linear terverifikasi.")
	
	# 4. Verifikasi Level 3 Linear Map (3 Titik)
	gs.start_level(3)
	map.build_linear_map()
	assert(map.total_points == 3, "Total points Level 3 harus 3")
	assert(map.node_ui_map.size() == 3, "Harus ada 3 UI node di Level 3")
	assert(map.point_positions[1].y > map.point_positions[3].y, "Titik 1 harus di bawah Titik 3")
	print("[PASS] Level 3: 3 Titik vertikal linear terverifikasi.")
	
	print("\nALL PHASE 4 TESTS PASSED SUCCESSFULLY!")
	quit()
