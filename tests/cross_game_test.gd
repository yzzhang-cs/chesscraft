extends SceneTree
## Headless test for cross-game rules: a Shogi side capturing a Xiangqi piece
## puts it in hand and keeps its Xiangqi movement, a Xiangqi side capturing a
## Shogi piece removes it permanently, dropped 相/士 are freed, and a dropped 兵
## may only land behind the river with its crossed-river state starting false.
##
## Run with:
##   godot_console --headless --path . --script res://tests/cross_game_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_check_shogi_capture_xiangqi_into_hand(failures)
	_check_xiangqi_capture_removes_permanently(failures)
	_check_big_fat_whale_cross_game(failures)
	_check_dropped_piece_keeps_xiangqi_movement(failures)
	_check_freed_advisor(failures)
	_check_freed_elephant(failures)
	_check_soldier_drop_half_board(failures)

	if failures.is_empty():
		print("cross_game_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("cross_game_test=FAIL %s" % failure)
		quit(1)


## An empty Shogi-vs-Xiangqi match with Side 1 (Shogi) to move. Side 1 is Shogi
## so a captured Xiangqi piece is owned by the Shogi side, which the freed and
## 兵-drop tests rely on.
func _empty_match() -> Match:
	var m := Match.new(Army.Type.SHOGI, Army.Type.XIANGQI)
	m.clear()
	return m


func _place(m: Match, side: int, army: Army.Type, kind: Piece.Kind, column: int, row: int) -> Piece:
	var piece := Piece.new(side, army, kind, column, row)
	m.place(piece)
	return piece


func _p(column: int, row: int) -> Vector2i:
	return Vector2i(column, row)


func _expect_in(failures: Array[String], label: String, actual: Array[Vector2i], point: Vector2i) -> void:
	if not actual.has(point):
		failures.append("%s: expected %s to be legal" % [label, str(point)])


func _expect_not_in(failures: Array[String], label: String, actual: Array[Vector2i], point: Vector2i) -> void:
	if actual.has(point):
		failures.append("%s: expected %s to be illegal" % [label, str(point)])


## A Shogi capture of a Xiangqi piece moves it into the Shogi hand, re-owned to
## the captor and off the board, while keeping its intrinsic Xiangqi army.
func _check_shogi_capture_xiangqi_into_hand(failures: Array[String]) -> void:
	var m := _empty_match()
	var rook := _place(m, 1, Army.Type.SHOGI, Piece.Kind.SHOGI_ROOK, 1, 1)
	var soldier := _place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 1, 3)
	if not m.move(rook, 1, 3):
		failures.append("cross capture: the rook should capture the 兵")
		return
	if m.piece_at(1, 3) != rook:
		failures.append("cross capture: the rook should stand on (1,3)")
	if m.pieces.size() != 1:
		failures.append("cross capture: the captured 兵 should leave the board")
	if m.hand_of(1).size() != 1:
		failures.append("cross capture: Side 1 should hold one piece, got %d" % m.hand_of(1).size())
		return
	var held: Piece = m.hand_of(1)[0]
	if held != soldier:
		failures.append("cross capture: the held piece should be the captured 兵")
	if held.side != 1:
		failures.append("cross capture: a captured piece should be re-owned to the captor")
	if held.army != Army.Type.XIANGQI:
		failures.append("cross capture: the held piece must keep its Xiangqi army")
	if held.column != 0 or held.row != 0:
		failures.append("cross capture: a held piece should be off the board")
	if m.hand_of(2).size() != 0:
		failures.append("cross capture: Side 2 should hold nothing")


## A Xiangqi capture of a Shogi piece removes it permanently: no hand for either
## side and the piece is gone from the board.
func _check_xiangqi_capture_removes_permanently(failures: Array[String]) -> void:
	# A Xiangqi-vs-Shogi match puts the Xiangqi side first, so it captures a
	# Shogi piece on its own turn.
	var m := Match.new(Army.Type.XIANGQI, Army.Type.SHOGI)
	m.clear()
	var chariot := _place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_CHARIOT, 1, 1)
	_place(m, 2, Army.Type.SHOGI, Piece.Kind.SHOGI_PAWN, 1, 3)
	if not m.move(chariot, 1, 3):
		failures.append("permanent capture: the chariot should capture the Shogi pawn")
		return
	if m.piece_at(1, 3) != chariot:
		failures.append("permanent capture: the chariot should stand on (1,3)")
	if m.pieces.size() != 1:
		failures.append("permanent capture: the Shogi pawn should leave the board")
	if m.hand_of(1).size() != 0:
		failures.append("permanent capture: a Xiangqi side must not gain a hand")
	if m.hand_of(2).size() != 0:
		failures.append("permanent capture: the captured piece must not enter the opponent's hand")


## The 大肥鱼的象棋 army shares Xiangqi's kinds, so its captured pieces obey the
## same cross-game rules: a captured 相 keeps its army and is freed once dropped.
func _check_big_fat_whale_cross_game(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.SHOGI, Army.Type.BIG_FAT_WHALE)
	m.clear()
	var rook := _place(m, 1, Army.Type.SHOGI, Piece.Kind.SHOGI_ROOK, 1, 1)
	_place(m, 2, Army.Type.BIG_FAT_WHALE, Piece.Kind.XIANGQI_ELEPHANT, 1, 3)
	if not m.move(rook, 1, 3):
		failures.append("big-fat-whale: the rook should capture the 相")
		return
	if m.hand_of(1).size() != 1:
		failures.append("big-fat-whale: Side 1 should hold the captured 相")
		return
	if m.hand_of(1)[0].army != Army.Type.BIG_FAT_WHALE:
		failures.append("big-fat-whale: the held 相 must keep its 大肥鱼 army")
	# Return the turn to Side 1, then drop the 相 and verify it is freed.
	var chariot := _place(m, 2, Army.Type.BIG_FAT_WHALE, Piece.Kind.XIANGQI_CHARIOT, 9, 10)
	if not m.move(chariot, 9, 9):
		failures.append("big-fat-whale: the Side 2 chariot should return the turn")
		return
	var held: Piece = m.hand_of(1)[0]
	if not m.drop(held, 5, 5):
		failures.append("big-fat-whale: dropping the 相 should succeed")
		return
	_expect_in(failures, "big-fat-whale freed elephant", m.legal_destinations(held), _p(3, 7))


## A captured Xiangqi piece dropped by Shogi keeps Xiangqi movement: a 馬 is
## blocked by its leg, where a Shogi knight would jump over it.
func _check_dropped_piece_keeps_xiangqi_movement(failures: Array[String]) -> void:
	var m := _empty_match()
	var horse := _place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_HORSE, 5, 5)
	var unblocked := m.legal_destinations(horse)
	_expect_in(failures, "horse no blocker", unblocked, _p(4, 7))
	_expect_in(failures, "horse no blocker", unblocked, _p(6, 7))
	_place(m, 2, Army.Type.SHOGI, Piece.Kind.SHOGI_PAWN, 5, 6)
	var blocked := m.legal_destinations(horse)
	_expect_not_in(failures, "horse leg blocker", blocked, _p(4, 7))
	_expect_not_in(failures, "horse leg blocker", blocked, _p(6, 7))


## A freed advisor (a captured 士 re-dropped by Shogi) moves one diagonal
## anywhere; a Xiangqi side's own advisor stays palace-confined.
func _check_freed_advisor(failures: Array[String]) -> void:
	var m := _empty_match()
	var advisor := _place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_ADVISOR, 1, 1)
	var dests := m.legal_destinations(advisor)
	_expect_in(failures, "freed advisor", dests, _p(2, 2))

	var confined := _place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_ADVISOR, 1, 9)
	var confined_dests := m.legal_destinations(confined)
	_expect_not_in(failures, "confined advisor", confined_dests, _p(2, 8))


## A freed elephant (a captured 相 re-dropped by Shogi) may cross the river; its
## eye still blocks.
func _check_freed_elephant(failures: Array[String]) -> void:
	var m := _empty_match()
	var elephant := _place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_ELEPHANT, 5, 5)
	var dests := m.legal_destinations(elephant)
	_expect_in(failures, "freed elephant cross river", dests, _p(3, 7))
	_expect_in(failures, "freed elephant cross river", dests, _p(7, 7))

	_place(m, 2, Army.Type.SHOGI, Piece.Kind.SHOGI_PAWN, 4, 6)
	var blocked := m.legal_destinations(elephant)
	_expect_not_in(failures, "freed elephant eye", blocked, _p(3, 7))
	_expect_in(failures, "freed elephant other diagonal", blocked, _p(7, 7))


## A held 兵 drops only on the dropper's own half (behind the river), and after
## dropping its crossed-river state starts false (no sideways move yet).
func _check_soldier_drop_half_board(failures: Array[String]) -> void:
	var m := _empty_match()
	# Fill Side 1's hand through a real capture, then return the turn to Side 1
	# with a Side 2 move, mirroring shogi_drops_hand_test's setup.
	var rook := _place(m, 1, Army.Type.SHOGI, Piece.Kind.SHOGI_ROOK, 1, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 1, 3)
	if not m.move(rook, 1, 3):
		failures.append("soldier drop: the rook should capture the 兵")
		return
	var chariot := _place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_CHARIOT, 9, 10)
	if not m.move(chariot, 9, 9):
		failures.append("soldier drop: the Side 2 chariot should return the turn")
		return
	var soldier: Piece = m.hand_of(1)[0]
	var dests := m.legal_drop_destinations(soldier)
	_expect_in(failures, "soldier drop own half", dests, _p(5, 1))
	_expect_in(failures, "soldier drop own half", dests, _p(5, 5))
	_expect_not_in(failures, "soldier drop far half", dests, _p(5, 6))
	_expect_not_in(failures, "soldier drop far half", dests, _p(5, 10))
	if m.drop(soldier, 5, 6):
		failures.append("soldier drop: dropping onto the far half should be rejected")
	if not m.drop(soldier, 5, 2):
		failures.append("soldier drop: dropping onto the own half should succeed")
		return
	if m.piece_at(5, 2) != soldier:
		failures.append("soldier drop: the soldier should stand on (5,2)")
	var move_dests := m.legal_destinations(soldier)
	_expect_in(failures, "soldier forward", move_dests, _p(5, 3))
	_expect_not_in(failures, "soldier crossed-river sideways", move_dests, _p(4, 2))
	_expect_not_in(failures, "soldier crossed-river sideways", move_dests, _p(6, 2))
