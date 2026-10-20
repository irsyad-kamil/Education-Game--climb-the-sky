extends SceneTree

func _init() -> void:
	print("--- TEST PHASE 2: GAME_STATE & SCORING SYSTEM ---")
	
	var dm_script = load("res://scripts/autoload/data_manager.gd")
	var dm = dm_script.new()
	dm.name = "DataManager"
	root.add_child(dm)
	
	var gs_script = load("res://scripts/autoload/game_state.gd")
	var gs = gs_script.new()
	gs.name = "GameState"
	gs.data_manager_ref = dm
	root.add_child(gs)
	
	# 1. Test Reset Progress
	gs.reset_progress()
	assert(gs.is_level_1_cleared == false, "Level 1 should not be cleared initially")
	assert(gs.is_level_unlocked(1) == true, "Level 1 should always be unlocked")
	assert(gs.is_level_unlocked(2) == false, "Level 2 should be locked")
	assert(gs.is_level_unlocked(3) == false, "Level 3 should be locked")
	print("[PASS] Initial unlock states verified.")
	
	# 2. Test Start Level 1
	gs.start_level(1)
	assert(gs.current_level == 1, "Current level should be 1")
	assert(gs.current_point_index == 1, "Current point index should be 1")
	assert(gs.level_score == 0, "Level score should start at 0")
	print("[PASS] start_level(1) verified.")
	
	# 3. Test Scoring (Negative penalty & Positive correct)
	var res1 = gs.register_answer(false)
	assert(res1["is_correct"] == false, "Should be marked incorrect")
	assert(res1["delta"] == -25, "Delta should be -25")
	assert(gs.level_score == -25, "Score should allow negative (-25)")
	assert(gs.wrong_attempts_current_question == 1, "Attempts should be 1")
	print("[PASS] Wrong answer penalty (-25) verified. Score: %d" % gs.level_score)
	
	var res2 = gs.register_answer(false)
	assert(gs.level_score == -50, "Score should decrease to -50")
	assert(gs.wrong_attempts_current_question == 2, "Attempts should be 2")
	print("[PASS] Second wrong answer (-25) verified. Score: %d" % gs.level_score)
	
	var res3 = gs.register_answer(true)
	assert(res3["is_correct"] == true, "Should be marked correct")
	assert(res3["delta"] == 100, "Delta should be +100")
	assert(gs.level_score == 50, "Score should be 50 (-50 + 100)")
	assert(gs.wrong_attempts_current_question == 0, "Attempts should reset on correct")
	print("[PASS] Correct answer (+100) verified. Score: %d" % gs.level_score)
	
	# 4. Test Short Answer Reveal Threshold (6 attempts)
	var test_state = {"answer_revealed": false, "revealed_pt": -1, "revealed_ans": ""}
	gs.answer_revealed.connect(func(pt, ans):
		test_state["answer_revealed"] = true
		test_state["revealed_pt"] = pt
		test_state["revealed_ans"] = ans
	)
	
	for i in range(5):
		var res = gs.register_answer(false)
		assert(res["revealed"] == false, "Attempt %d should not reveal" % (i + 1))
	
	var res_final = gs.register_answer(false)
	assert(res_final["revealed"] == true, "Attempt 6 should reveal answer")
	assert(test_state["answer_revealed"] == true, "Signal answer_revealed should have fired")
	var expected_answer = str(gs.get_current_question().get("correct_answer"))
	assert(test_state["revealed_ans"] == expected_answer, "Revealed answer for L1-P1 should match active question answer")
	print("[PASS] Reveal threshold (6 wrong attempts) verified. Answer revealed: %s" % test_state["revealed_ans"])
	
	# 5. Test Linear Point Progression & Level Completion
	gs.start_level(1)
	var total_pts = dm.get_total_points(1) # 5
	assert(total_pts == 5, "Level 1 total points should be 5")
	
	for p in range(1, total_pts):
		var is_finished = gs.advance_point()
		assert(is_finished == false, "Point %d should not finish level" % p)
		assert(gs.current_point_index == p + 1, "Point index should advance")
		
	assert(gs.current_point_index == 5, "Should be at point 5")
	var is_finished_last = gs.advance_point()
	assert(is_finished_last == true, "Point 5 advance should complete level 1")
	assert(gs.is_level_1_cleared == true, "Level 1 should be marked cleared")
	assert(gs.is_level_unlocked(2) == true, "Level 2 should now be unlocked")
	assert(gs.is_level_unlocked(3) == false, "Level 3 should still be locked")
	print("[PASS] Level 1 progression and completion verified. Level 2 unlocked!")
	
	# 6. Test Persistence (Save & Load)
	var gs2 = gs_script.new()
	gs2.name = "GameState2"
	gs2.data_manager_ref = dm
	root.add_child(gs2)
	assert(gs2.is_level_1_cleared == true, "gs2 should load saved progress with Level 1 cleared")
	assert(gs2.is_level_unlocked(2) == true, "gs2 should have Level 2 unlocked")
	print("[PASS] Persistence (Save & Load) verified.")
	
	# Bersihkan file save agar kembali bersih untuk sesi pemain baru
	gs2.reset_progress()
	
	print("\nALL PHASE 2 TESTS PASSED SUCCESSFULLY!")
	quit()
