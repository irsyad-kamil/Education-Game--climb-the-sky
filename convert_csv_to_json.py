import csv
import json
import re
import os

def parse_options_pg(raw_text):
    options = []
    for line in raw_text.strip().split("\n"):
        match = re.match(r"^([A-E])\.\s*(.+)$", line.strip())
        if match:
            options.append({"key": match.group(1), "text": match.group(2)})
    return options

def parse_matching(raw_text, key_text):
    left_items = []
    right_items = []
    
    parts = re.split(r"JAWABAN:\s*", raw_text, flags=re.IGNORECASE)
    soal_part = parts[0].replace("SOAL:", "").strip() if len(parts) > 0 else ""
    jawaban_part = parts[1].strip() if len(parts) > 1 else ""

    for line in soal_part.split("\n"):
        m = re.match(r"^(\d+)\.\s*(.+)$", line.strip())
        if m:
            left_items.append({"id": m.group(1), "text": m.group(2)})

    for line in jawaban_part.split("\n"):
        m = re.match(r"^([A-E])\.\s*(.+)$", line.strip())
        if m:
            right_items.append({"id": m.group(1), "text": m.group(2)})

    valid_pairs = {}
    pair_matches = re.findall(r"(\d+)-([A-E])", key_text)
    for left_id, right_id in pair_matches:
        valid_pairs[left_id] = right_id

    return left_items, right_items, valid_pairs

def parse_isian_answers(key_text):
    answers = set()
    clean = key_text.strip()
    match = re.search(r"diterima:\s*([^\)]+)", clean)
    
    main_ans = re.sub(r"\(.*?\)", "", clean).strip()
    answers.add(main_ans)
    if "," in main_ans:
        answers.add(main_ans.replace(",", "."))
    elif "." in main_ans:
        answers.add(main_ans.replace(".", ","))

    if match:
        alt_ans = match.group(1).strip()
        answers.add(alt_ans)

    return list(answers)

def convert_csv(csv_filepath, json_filepath):
    questions = []
    with open(csv_filepath, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not row.get("ID Soal") or not row["ID Soal"].startswith("T"):
                continue
            
            q_id = row["ID Soal"].strip()
            stage = int(row["Tahap (1/2/3)"].strip())
            category = row["Kategori (Normal/Elite/Boss)"].strip()
            bentuk = row["Bentuk (PG/TF/Isian/Matching)"].strip()
            narrative = row["Narasi Konteks Bima (Optional)"].strip() if row.get("Narasi Konteks Bima (Optional)") else ""
            prompt = row["Teks Soal"].strip()
            raw_choices = row["Pilihan Jawaban / Pasangan"].strip()
            raw_key = row["Kunci Jawaban"].strip()
            time_attack = row["Time Attack? (Ya/Tidak)"].strip().lower() == "ya"

            boss_type = ""
            if category == "Boss":
                boss_match = re.search(r"-BOS-([A-E])", q_id)
                if boss_match:
                    boss_type = boss_match.group(1)

            item = {
                "id": q_id,
                "stage": stage,
                "category": category,
                "boss_type": boss_type,
                "type": bentuk,
                "narrative": narrative,
                "prompt": prompt,
                "has_time_attack": time_attack
            }

            if bentuk == "PG":
                item["options"] = parse_options_pg(raw_choices)
                item["correct_key"] = raw_key
            elif bentuk == "TF":
                item["correct_answer"] = raw_key.capitalize()
            elif bentuk == "Isian":
                item["acceptable_answers"] = parse_isian_answers(raw_key)
            elif bentuk == "Matching":
                left, right, pairs = parse_matching(raw_choices, raw_key)
                item["left_items"] = left
                item["right_items"] = right
                item["valid_pairs"] = pairs

            questions.append(item)

    with open(json_filepath, 'w', encoding='utf-8') as out_f:
        json.dump({"total": len(questions), "questions": questions}, out_f, indent=2, ensure_ascii=False)
    print(f"Berhasil mengonversi {len(questions)} soal ke {json_filepath}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(base_dir, "data", "draft_soal.csv")
    json_path = os.path.join(base_dir, "data", "questions.json")
    convert_csv(csv_path, json_path)
