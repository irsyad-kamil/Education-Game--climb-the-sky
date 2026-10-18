class_name MapGenerator
extends RefCounted

# Definisi Tipe Simpul
enum NodeType {
	CAMPFIRE,
	NORMAL,
	ELITE,
	EVENT,
	BOSS
}

# Representasi Satu Simpul Peta
class MapNode:
	var id: String
	var row: int
	var col: int
	var type: NodeType
	var connections: Array[String] = [] # ID simpul di baris berikutnya
	var incoming: Array[String] = []    # ID simpul dari baris sebelumnya

	func _init(p_id: String, p_row: int, p_col: int, p_type: NodeType) -> void:
		id = p_id
		row = p_row
		col = p_col
		type = p_type

# Menghasilkan Peta Lengkap Berdasarkan Tahap & Seed
static func generate_map(stage: int, map_seed: int = 0) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if map_seed == 0:
		rng.randomize()
		map_seed = rng.seed
	else:
		rng.seed = map_seed

	if stage == 1:
		return _generate_stage_1(map_seed)

	var nodes: Dictionary = {}
	var rows_data: Array[Array] = []

	# 1. Tentukan jumlah simpul per baris (Baris 1-10: 3-5 simpul; Baris 11: 1 simpul)
	for r in range(11):
		var row_nodes: Array = []
		var count = 1 if r == 10 else rng.randi_range(3, 5)

		for c in range(count):
			var node_id = "N_%d_%d" % [r + 1, c]
			var n_type = _determine_initial_type(r + 1, rng)
			var node = MapNode.new(node_id, r + 1, c, n_type)
			nodes[node_id] = node
			row_nodes.append(node)
		rows_data.append(row_nodes)

	# 2. Hubungkan simpul antar-baris bersebelahan (tanpa garis bersilangan)
	_build_connections(rows_data, rng, nodes)

	# 3. Garansi rute Elite: pastikan setiap jalur memuat minimal 2 dan maksimal 6 Elite
	_repair_elite_paths(rows_data, nodes)

	return {
		"seed": map_seed,
		"stage": stage,
		"nodes": nodes,
		"rows": rows_data
	}

# --- TAHAP 1 (Linear 5 Titik) ---
static func _generate_stage_1(map_seed: int) -> Dictionary:
	var nodes: Dictionary = {}
	var rows_data: Array[Array] = []
	var types = [
		NodeType.CAMPFIRE,
		NodeType.NORMAL,
		NodeType.EVENT,
		NodeType.ELITE,
		NodeType.BOSS
	]

	var prev_node: MapNode = null
	for r in range(5):
		var node_id = "T1_N_%d_0" % (r + 1)
		var node = MapNode.new(node_id, r + 1, 0, types[r])
		nodes[node_id] = node
		rows_data.append([node])

		if prev_node:
			prev_node.connections.append(node_id)
			node.incoming.append(prev_node.id)
		prev_node = node

	return {"seed": map_seed, "stage": 1, "nodes": nodes, "rows": rows_data}

# --- PENETAPAN TIPE SIMPUL ---
static func _determine_initial_type(row_number: int, rng: RandomNumberGenerator) -> NodeType:
	# Aturan GDD: Baris 1, 4, 7 Api Unggun
	if row_number in [1, 4, 7]:
		return NodeType.CAMPFIRE
	# Baris 2: Hanya Normal Enemy
	if row_number == 2:
		return NodeType.NORMAL
	# Baris 11: Boss
	if row_number == 11:
		return NodeType.BOSS

	# Baris 3, 5, 6, 8, 9, 10: 50% Normal, 25% Elite, 25% Tanda Tanya
	var roll = rng.randf()
	if roll < 0.50:
		return NodeType.NORMAL
	elif roll < 0.75:
		return NodeType.ELITE
	else:
		return NodeType.EVENT

# --- ALGORITMA KONEKSI NON-CROSSING DENGAN PROBABILITAS ---
static func _build_connections(rows_data: Array[Array], rng: RandomNumberGenerator, nodes: Dictionary) -> void:
	for r in range(rows_data.size() - 1):
		var current_row = rows_data[r]
		var next_row = rows_data[r + 1]

		# Kasus Khusus: Menuju Boss di baris 11 (seluruh baris 10 tersambung ke Boss)
		if r == 9:
			var boss_node: MapNode = next_row[0]
			for node in current_row:
				node.connections.append(boss_node.id)
				boss_node.incoming.append(node.id)
			continue

		for i in range(current_row.size()):
			var curr_node: MapNode = current_row[i]
			var ratio = float(i) / float(max(1, current_row.size() - 1))
			var target_center = int(round(ratio * (next_row.size() - 1)))

			# 1. Rute lurus / segaris: 100% PASTI TERHUBUNG
			var center_node: MapNode = next_row[target_center]
			if not curr_node.connections.has(center_node.id):
				curr_node.connections.append(center_node.id)
				center_node.incoming.append(curr_node.id)

			# 2. Rute cabang kiri (jarak 1 titik): Probabilitas 30%
			if target_center - 1 >= 0:
				if rng.randf() < 0.30:
					var left_node: MapNode = next_row[target_center - 1]
					if not curr_node.connections.has(left_node.id):
						curr_node.connections.append(left_node.id)
						left_node.incoming.append(curr_node.id)

			# 3. Rute cabang kanan (jarak 1 titik): Probabilitas 30%
			if target_center + 1 < next_row.size():
				if rng.randf() < 0.30:
					var right_node: MapNode = next_row[target_center + 1]
					if not curr_node.connections.has(right_node.id):
						curr_node.connections.append(right_node.id)
						right_node.incoming.append(curr_node.id)

		# 4. Garansi tidak ada simpul buntu di baris berikutnya (minimal 1 incoming)
		for target_node in next_row:
			if target_node.incoming.is_empty():
				var best_parent: MapNode = null
				var min_dist = 999
				for parent_node in current_row:
					var p_ratio = float(parent_node.col) / float(max(1, current_row.size() - 1))
					var p_center = int(round(p_ratio * (next_row.size() - 1)))
					var dist = abs(target_node.col - p_center)
					if dist <= 1 and dist < min_dist:
						min_dist = dist
						best_parent = parent_node

				if best_parent:
					best_parent.connections.append(target_node.id)
					target_node.incoming.append(best_parent.id)
				else:
					var fallback = current_row[clampi(target_node.col, 0, current_row.size() - 1)]
					fallback.connections.append(target_node.id)
					target_node.incoming.append(fallback.id)

		# 5. ELIMINASI GARIS BERPOTONGAN (PILIH SALAH SATU JIKA BERPOTONGAN X)
		_eliminate_crossings(current_row, next_row, nodes, rng)

# --- ELIMINASI GARIS BERPOTONGAN (ANTI-CROSSING PASS) ---
static func _eliminate_crossings(current_row: Array, _next_row: Array, nodes: Dictionary, rng: RandomNumberGenerator) -> void:
	var has_crossings = true
	var safety_counter = 0

	while has_crossings and safety_counter < 100:
		has_crossings = false
		safety_counter += 1

		for i in range(current_row.size()):
			var u1: MapNode = current_row[i]
			for v1_id in u1.connections:
				var v1: MapNode = nodes[v1_id]

				for j in range(i + 1, current_row.size()):
					var u2: MapNode = current_row[j]
					for v2_id in u2.connections:
						var v2: MapNode = nodes[v2_id]

						# Terjadi perpotongan (X): u1 di kiri u2, tetapi v1 di kanan v2
						if u1.col < u2.col and v1.col > v2.col:
							has_crossings = true

							# Cek apakah masing-masing sisi aman dihapus tanpa membuat simpul kehilangan koneksi
							var u1_can_remove = (u1.connections.size() > 1 and v1.incoming.size() > 1)
							var u2_can_remove = (u2.connections.size() > 1 and v2.incoming.size() > 1)

							if u1_can_remove and not u2_can_remove:
								_remove_edge(u1, v1)
							elif u2_can_remove and not u1_can_remove:
								_remove_edge(u2, v2)
							elif u1_can_remove and u2_can_remove:
								# Kedua sisi aman dihapus: pilih salah satu acak (50%)
								if rng.randf() < 0.5:
									_remove_edge(u1, v1)
								else:
									_remove_edge(u2, v2)
							else:
								# Kasus tepi jika keduanya adalah satu-satunya koneksi:
								# Putus u1->v1 dan alihkan u1 menuju v2 (sehingga berbagi simpul V-shape tanpa silang)
								_remove_edge(u1, v1)
								if not u1.connections.has(v2.id):
									u1.connections.append(v2.id)
									v2.incoming.append(u1.id)
							break
					if has_crossings: break
				if has_crossings: break
			if has_crossings: break

static func _remove_edge(u: MapNode, v: MapNode) -> void:
	u.connections.erase(v.id)
	v.incoming.erase(u.id)

# --- JAMINAN BATASAN ELITE (2 - 6 PER JALUR) ---
static func _repair_elite_paths(rows_data: Array[Array], nodes: Dictionary) -> void:
	for start_node in rows_data[0]:
		_dfs_repair(start_node, [], nodes)

static func _dfs_repair(current_node: MapNode, current_path: Array, nodes: Dictionary) -> void:
	var path_so_far = current_path.duplicate()
	path_so_far.append(current_node)

	if current_node.type == NodeType.BOSS:
		var elite_count = 0
		for n in path_so_far:
			if n.type == NodeType.ELITE:
				elite_count += 1

		# Jika jalur memiliki kurang dari 2 Elite, jadikan simpul kandidat menjadi Elite
		if elite_count < 2:
			var candidates: Array = []
			for n in path_so_far:
				if n.row in [3, 5, 6, 8, 9, 10] and n.type != NodeType.ELITE:
					candidates.append(n)

			candidates.shuffle()
			var needed = 2 - elite_count
			for i in range(min(needed, candidates.size())):
				candidates[i].type = NodeType.ELITE
		return

	for next_id in current_node.connections:
		var next_node: MapNode = nodes[next_id]
		_dfs_repair(next_node, path_so_far, nodes)
