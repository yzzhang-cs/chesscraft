extends SceneTree
## Headless test for Shogi drops and the hand: a Shogi capture moves the
## captured piece into the captor's hand unpromoted, a held piece drops onto an
## empty point, drops are always unpromoted, a pawn/lance cannot drop onto the
## last rank and a knight cannot drop onto the last two ranks, and undo reverts
## both a capture-into-hand and a drop.
##
## Run with:
##   godot_console --headless --path . --script res://tests/shogi_drops_hand_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_check_capture_into_hand(failures)
	_check_capture_unpromotes(failures)
	_check_legal_drop(failures)
	_check_drop_restrictions(failures)
	_check_undo_capture_into_hand(failures)
	_check_undo_capture_promoted_restores(failures)
	_check_undo_drop(failures)

	if failures.is_empty():
		print("shogi_drops_hand_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("shogi_drops_hand_test=FAIL %s" % failure)
		quit(1)


## An empty Shogi-vs-Shogi match with Side 1 to move.
func _empty_match() -> Match:
	var m := Match.new(Army.Type.SHOGI, Army.Type.SHOGI)
	m.clear()
	return m


func _place(m: Match, side: int, kind: Piece.Kind, column: int, row: int) -> Piece:
	var piece := Piece.new(side, Army.Type.SHOGI, kind, column, row)
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


## Captures an enemy piece of `kind` with a Side 1 rook to fill Side 1's hand,
## then moves a Side 2 gold so the turn returns to Side 1. The returned match
## has Side 1 to move holding exactly that piece.
func _match_with_held_piece(kind: Piece.Kind) -> Match:
	var m := _empty_match()
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 1, 1)
	_place(m, 2, kind, 1, 3)
	if not m.move(rook, 1, 3):
		push_error("setup: rook capture should succeed")
		return m
	var gold := _place(m, 2, Piece.Kind.SHOGI_GOLD, 9, 10)
	m.move(gold, 9, 9)
	return m


## A Shogi capture moves the captured piece into the captor's hand, off the
## board and re-owned to the captor.
func _check_capture_into_hand(failures: Array[String]) -> void:
	var m := _empty_match()
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 1, 1)
	var pawn := _place(m, 2, Piece.Kind.SHOGI_PAWN, 1, 3)
	if not m.move(rook, 1, 3):
		failures.append("capture: the rook should capture the pawn")
		return
	if m.piece_at(1, 3) != rook:
		failures.append("capture: the rook should stand on (1,3)")
	if m.pieces.size() != 1:
		failures.append("capture: the captured pawn should leave the board")
	if m.hand_of(1).size() != 1:
		failures.append("capture: Side 1 should hold one piece, got %d" % m.hand_of(1).size())
		return
	var held: Piece = m.hand_of(1)[0]
	if held != pawn:
		failures.append("capture: the held piece should be the captured pawn")
	if held.side != 1:
		failures.append("capture: a captured piece should be re-owned to the captor")
	if held.column != 0 or held.row != 0:
		failures.append("capture: a held piece should be off the board")
	if m.hand_of(2).size() != 0:
		failures.append("capture: Side 2 should hold nothing")


## A captured promoted piece reverts to its unpromoted form in hand.
func _check_capture_unpromotes(failures: Array[String]) -> void:
	var m := _empty_match()
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 1, 1)
	var silver := _place(m, 2, Piece.Kind.SHOGI_SILVER, 1, 3)
	silver.promoted = true
	if silver.glyph() != "成銀":
		failures.append("unpromote: setup should place a promoted silver")
		return
	if not m.move(rook, 1, 3):
		failures.append("unpromote: the rook should capture the promoted silver")
		return
	var held: Piece = m.hand_of(1)[0]
	if held.promoted:
		failures.append("unpromote: a captured promoted piece must revert to unpromoted")
	if held.glyph() != "銀将":
		failures.append("unpromote: the held silver should glyph 銀将, got %s" % held.glyph())


## A held piece drops onto an empty point, stays unpromoted, leaves the hand,
## and passes the turn.
func _check_legal_drop(failures: Array[String]) -> void:
	var m := _match_with_held_piece(Piece.Kind.SHOGI_PAWN)
	var held: Piece = m.hand_of(1)[0]
	if held == null:
		failures.append("drop: setup should hold a pawn")
		return
	if held.promoted:
		failures.append("drop: a held piece should already be unpromoted")
	var dests := m.legal_drop_destinations(held)
	_expect_in(failures, "legal drop", dests, _p(5, 3))
	_expect_not_in(failures, "drop onto occupied point", dests, _p(1, 3))
	if not m.drop(held, 5, 3):
		failures.append("drop: dropping the pawn onto (5,3) should succeed")
		return
	if m.piece_at(5, 3) != held:
		failures.append("drop: the pawn should stand on (5,3)")
	if held.promoted:
		failures.append("drop: a dropped piece must stay unpromoted")
	if m.hand_of(1).size() != 0:
		failures.append("drop: the hand should empty after the drop")
	if m.side_to_move != 2:
		failures.append("drop: the turn should pass to Side 2")


## A pawn or lance cannot drop onto the last rank; a knight cannot drop onto the
## last two ranks.
func _check_drop_restrictions(failures: Array[String]) -> void:
	var m := _match_with_held_piece(Piece.Kind.SHOGI_PAWN)
	var pawn: Piece = m.hand_of(1)[0]
	var pdests := m.legal_drop_destinations(pawn)
	_expect_not_in(failures, "pawn last rank", pdests, _p(5, 10))
	_expect_in(failures, "pawn second-to-last", pdests, _p(5, 9))
	if m.drop(pawn, 5, 10):
		failures.append("pawn drop: dropping onto the last rank should be rejected")

	var ml := _match_with_held_piece(Piece.Kind.SHOGI_LANCE)
	var lance: Piece = ml.hand_of(1)[0]
	var ldests := ml.legal_drop_destinations(lance)
	_expect_not_in(failures, "lance last rank", ldests, _p(4, 10))
	_expect_in(failures, "lance second-to-last", ldests, _p(4, 9))

	var mk := _match_with_held_piece(Piece.Kind.SHOGI_KNIGHT)
	var knight: Piece = mk.hand_of(1)[0]
	var kdests := mk.legal_drop_destinations(knight)
	_expect_not_in(failures, "knight last rank", kdests, _p(5, 10))
	_expect_not_in(failures, "knight second-to-last", kdests, _p(5, 9))
	_expect_in(failures, "knight third rank", kdests, _p(5, 8))
	if mk.drop(knight, 5, 9):
		failures.append("knight drop: dropping onto the second-to-last rank should be rejected")


## Undo reverts a capture-into-hand: the captured piece returns to the board
## with its original side, and the hand empties.
func _check_undo_capture_into_hand(failures: Array[String]) -> void:
	var m := _empty_match()
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 1, 1)
	var pawn := _place(m, 2, Piece.Kind.SHOGI_PAWN, 1, 3)
	m.move(rook, 1, 3)
	if m.hand_of(1).size() != 1:
		failures.append("undo capture: Side 1 should hold the pawn before undo")
		return
	if not m.undo():
		failures.append("undo capture: undo should revert the capture")
		return
	if m.piece_at(1, 1) != rook:
		failures.append("undo capture: the rook should return to (1,1)")
	if m.piece_at(1, 3) != pawn:
		failures.append("undo capture: the pawn should return to (1,3)")
	if pawn.side != 2:
		failures.append("undo capture: the pawn should return to Side 2, got side %d" % pawn.side)
	if m.hand_of(1).size() != 0:
		failures.append("undo capture: the hand should empty after undo")
	if m.pieces.size() != 2:
		failures.append("undo capture: both pieces should be back on the board")
	if m.side_to_move != 1:
		failures.append("undo capture: the turn should return to Side 1")


## Undo of a capture of a promoted piece restores its promoted state on the
## board, not the unpromoted form it had while in hand.
func _check_undo_capture_promoted_restores(failures: Array[String]) -> void:
	var m := _empty_match()
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 1, 1)
	var silver := _place(m, 2, Piece.Kind.SHOGI_SILVER, 1, 3)
	silver.promoted = true
	if not m.move(rook, 1, 3):
		failures.append("undo promoted: the rook should capture the promoted silver")
		return
	if not m.undo():
		failures.append("undo promoted: undo should revert the capture")
		return
	if m.piece_at(1, 3) != silver:
		failures.append("undo promoted: the silver should return to (1,3)")
	if silver.side != 2:
		failures.append("undo promoted: the silver should return to Side 2")
	if not silver.promoted:
		failures.append("undo promoted: the silver should return promoted")
	if silver.glyph() != "成銀":
		failures.append("undo promoted: the silver should glyph 成銀, got %s" % silver.glyph())


## Undo reverts a drop: the dropped piece returns to the hand off the board.
func _check_undo_drop(failures: Array[String]) -> void:
	var m := _match_with_held_piece(Piece.Kind.SHOGI_PAWN)
	var pawn: Piece = m.hand_of(1)[0]
	if not m.drop(pawn, 5, 3):
		failures.append("undo drop: the drop should succeed")
		return
	if m.piece_at(5, 3) != pawn:
		failures.append("undo drop: the pawn should stand on (5,3) before undo")
		return
	if not m.undo():
		failures.append("undo drop: undo should revert the drop")
		return
	if m.piece_at(5, 3) != null:
		failures.append("undo drop: (5,3) should be empty after undo")
	if m.hand_of(1).size() != 1:
		failures.append("undo drop: the pawn should return to the hand")
		return
	if m.hand_of(1)[0] != pawn:
		failures.append("undo drop: the hand should hold the same pawn")
	if pawn.column != 0 or pawn.row != 0:
		failures.append("undo drop: the pawn should be off the board again")
	if m.side_to_move != 1:
		failures.append("undo drop: the turn should return to Side 1")
