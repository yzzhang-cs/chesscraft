extends SceneTree
## Headless test for capture, check, checkmate, no-legal-move losses, and undo.
##
## Run with:
##   godot_console --headless --path . --script res://tests/check_win_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_check_detection(failures)
	_check_checkmate(failures)
	_check_no_legal_move(failures)
	_check_king_never_captured(failures)
	_check_self_check_filtered(failures)
	_check_undo(failures)

	if failures.is_empty():
		print("check_win_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("check_win_test=FAIL %s" % failure)
		quit(1)


## An empty Xiangqi-vs-Xiangqi match with Side 1 to move.
func _empty_match() -> Match:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	m.clear()
	return m


func _place(m: Match, side: int, kind: Piece.Kind, column: int, row: int) -> Piece:
	var piece := Piece.new(side, Army.Type.XIANGQI, kind, column, row)
	m.place(piece)
	return piece


## Check is detected when a general is threatened, and not otherwise.
func _check_detection(failures: Array[String]) -> void:
	var m := _empty_match()
	_place(m, 1, Piece.Kind.XIANGQI_GENERAL, 5, 1)
	_place(m, 2, Piece.Kind.XIANGQI_CHARIOT, 5, 9)
	if not m.is_in_check(1):
		failures.append("detection: Side 1 general should be in check")
	if m.is_in_check(2):
		failures.append("detection: Side 2 has no king and cannot be in check")

	# A piece between the chariot and the general blocks the threat.
	var blocked := _empty_match()
	_place(blocked, 1, Piece.Kind.XIANGQI_GENERAL, 5, 1)
	_place(blocked, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 5)
	_place(blocked, 2, Piece.Kind.XIANGQI_CHARIOT, 5, 9)
	if blocked.is_in_check(1):
		failures.append("detection: a blocking piece should stop the check")


## A back-rank checkmate: the general is in check with no escape, so Side 2 wins.
func _check_checkmate(failures: Array[String]) -> void:
	var m := _empty_match()
	_place(m, 1, Piece.Kind.XIANGQI_GENERAL, 4, 1)
	_place(m, 2, Piece.Kind.XIANGQI_CHARIOT, 9, 1)
	_place(m, 2, Piece.Kind.XIANGQI_SOLDIER, 4, 3)
	if not m.is_in_check(1):
		failures.append("checkmate: Side 1 should be in check")
	if m.has_any_legal_move(1):
		failures.append("checkmate: Side 1 should have no legal move")
	if m.winner != 2:
		failures.append("checkmate: Side 2 should win, got winner=%d" % m.winner)
	if m.end_reason != Match.REASON_CHECKMATE:
		failures.append("checkmate: end_reason should be checkmate, got %s" % m.end_reason)


## A side with no legal move and not in check loses (unified stalemate rule).
func _check_no_legal_move(failures: Array[String]) -> void:
	var m := _empty_match()
	_place(m, 1, Piece.Kind.XIANGQI_GENERAL, 4, 1)
	_place(m, 2, Piece.Kind.XIANGQI_CHARIOT, 5, 9)
	_place(m, 2, Piece.Kind.XIANGQI_SOLDIER, 4, 3)
	if m.is_in_check(1):
		failures.append("no_legal_move: Side 1 should not be in check")
	if m.has_any_legal_move(1):
		failures.append("no_legal_move: Side 1 should have no legal move")
	if m.winner != 2:
		failures.append("no_legal_move: Side 2 should win, got winner=%d" % m.winner)
	if m.end_reason != Match.REASON_NO_LEGAL_MOVE:
		failures.append("no_legal_move: end_reason should be no_legal_move, got %s" % m.end_reason)


## Kings are never captured: a point holding the enemy general is not a legal
## destination.
func _check_king_never_captured(failures: Array[String]) -> void:
	var m := _empty_match()
	var chariot := _place(m, 1, Piece.Kind.XIANGQI_CHARIOT, 1, 1)
	_place(m, 2, Piece.Kind.XIANGQI_GENERAL, 1, 3)
	if m.legal_destinations(chariot).has(Vector2i(1, 3)):
		failures.append("king capture: moving onto the general should be illegal")


## A move that leaves the mover's own king in check is not a legal destination.
func _check_self_check_filtered(failures: Array[String]) -> void:
	var m := _empty_match()
	_place(m, 1, Piece.Kind.XIANGQI_GENERAL, 5, 1)
	var chariot := _place(m, 1, Piece.Kind.XIANGQI_CHARIOT, 5, 2)
	_place(m, 2, Piece.Kind.XIANGQI_CHARIOT, 5, 9)
	var dests := m.legal_destinations(chariot)
	# Along the column the chariot stays between the general and the enemy chariot.
	if not dests.has(Vector2i(5, 3)):
		failures.append("self-check: moving up the column should stay legal")
	# Capturing the checking chariot removes the threat, so it is legal too.
	if not dests.has(Vector2i(5, 9)):
		failures.append("self-check: capturing the checking chariot should be legal")
	# Stepping off the column exposes the general to the enemy chariot.
	if dests.has(Vector2i(4, 2)):
		failures.append("self-check: a pinned piece must not leave its column")
	# The move is also rejected by move().
	if m.move(chariot, 4, 2):
		failures.append("self-check: move() should reject a move that leaves the king in check")


## Undo reverts the last move and restores any captured piece.
func _check_undo(failures: Array[String]) -> void:
	var m := _empty_match()
	var chariot := _place(m, 1, Piece.Kind.XIANGQI_CHARIOT, 1, 1)
	var soldier := _place(m, 2, Piece.Kind.XIANGQI_SOLDIER, 1, 3)
	if not m.move(chariot, 1, 3):
		failures.append("undo: capture should be legal")
	if m.piece_at(1, 3) != chariot:
		failures.append("undo: chariot should stand on the captured point")
	if m.pieces.size() != 1:
		failures.append("undo: capture should remove the soldier")
	if m.side_to_move != 2:
		failures.append("undo: turn should pass to Side 2")
	if not m.undo():
		failures.append("undo: undo() should revert the last move")
	if m.piece_at(1, 1) != chariot:
		failures.append("undo: chariot should return to its origin")
	if m.piece_at(1, 3) != soldier:
		failures.append("undo: the captured soldier should be restored")
	if m.pieces.size() != 2:
		failures.append("undo: both pieces should be back on the board")
	if m.side_to_move != 1:
		failures.append("undo: turn should return to Side 1")
	if m.undo():
		failures.append("undo: a second undo with an empty history should fail")
