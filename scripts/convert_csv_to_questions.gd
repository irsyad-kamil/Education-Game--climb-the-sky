extends SceneTree

func _init() -> void:
	print("--- CONVERTING BANK SOAL 48 CSV TO JSON (WITH MATCHING) ---")
	var file = FileAccess.open("res://data/bank_soal_48.csv", FileAccess.READ)
	if not file:
		push_error("Gagal membuka res://data/bank_soal_48.csv")
		quit(1)
		return

	var questions: Array = []
	var line_count = 0
	
	while not file.eof_reached():
		var row = file.get_csv_line()
		if row.is_empty() or row.size() < 9:
			continue
		var id_soal = row[0].strip_edges()
		if id_soal == "ID Soal" or not id_soal.begins_with("L"):
			continue

		var lvl = int(row[1])
		var pt = int(row[2])
		var q_type = row[3].strip_edges()
		var narrative = row[4].strip_edges()
		var prompt = row[5].strip_edges()
		var data_used = row[6].strip_edges()
		var raw_options = row[7].strip_edges()
		var raw_key = row[8].strip_edges()

		var q_dict: Dictionary = {
			"id": id_soal,
			"level": lvl,
			"point_index": pt,
			"type": q_type,
			"narrative": narrative,
			"prompt": prompt,
			"data_used": data_used
		}

		match q_type:
			"PG":
				var options_array: Array = []
				var opt_lines = raw_options.split("\n")
				for line in opt_lines:
					line = line.strip_edges()
					if line.length() >= 3 and line[1] == "." and line[2] == " ":
						var k = line.substr(0, 1).to_upper()
						var txt = line.substr(3).strip_edges()
						options_array.append({"key": k, "text": txt})
				q_dict["options"] = options_array
				q_dict["correct_answer"] = raw_key.to_upper().strip_edges()

			"TF":
				q_dict["correct_answer"] = raw_key.to_upper().strip_edges()

			"Isian":
				var clean_key = raw_key.strip_edges()
				q_dict["correct_answer"] = clean_key
				var accepted: Array = [clean_key]
				if "," in clean_key:
					accepted.append(clean_key.replace(",", "."))
				elif "." in clean_key:
					accepted.append(clean_key.replace(".", ","))
				q_dict["accepted_answers"] = accepted

			"Matching":
				var left_items: Array = []
				var right_items: Array = []
				var valid_pairs: Dictionary = {}
				var pair_lines = raw_options.split("\n")
				var pair_idx = 1
				for p_line in pair_lines:
					p_line = p_line.strip_edges()
					if p_line.is_empty() or p_line.begins_with("PASANGAN"):
						continue
					var arrow_pos = p_line.find("↔")
					if arrow_pos == -1:
						arrow_pos = p_line.find("<->")
					if arrow_pos != -1:
						var left_raw = p_line.substr(0, arrow_pos).strip_edges()
						var right_raw = p_line.substr(arrow_pos + 1).strip_edges()
						var dot_pos = left_raw.find(". ")
						if dot_pos != -1:
							left_raw = left_raw.substr(dot_pos + 2).strip_edges()

						var l_id = "L%d" % pair_idx
						var r_id = "R%d" % pair_idx
						left_items.append({"id": l_id, "text": left_raw})
						right_items.append({"id": r_id, "text": right_raw})
						valid_pairs[l_id] = r_id
						pair_idx += 1

				q_dict["left_items"] = left_items
				q_dict["right_items"] = right_items
				q_dict["valid_pairs"] = valid_pairs
				q_dict["correct_answer"] = "1↔1, 2↔2, 3↔3"

		questions.append(q_dict)
		line_count += 1

	file.close()
	print("Berhasil memproses %d soal." % questions.size())
	assert(questions.size() == 48, "Harus ada tepat 48 soal!")

	var output_dict = {
		"total": questions.size(),
		"questions": questions
	}

	var json_out = JSON.stringify(output_dict, "  ")
	var out_file = FileAccess.open("res://data/questions.json", FileAccess.WRITE)
	if out_file:
		out_file.store_string(json_out)
		out_file.close()
		print("SUKSES: File res://data/questions.json berhasil diperbarui dengan 48 soal (Matching aktif)!")
	else:
		push_error("Gagal menulis ke res://data/questions.json")
		quit(1)
		return

	quit(0)
