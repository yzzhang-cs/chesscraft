extends SceneTree
## Headless test for restart: resetting a match to its opening position for the
## same two armies, clearing hands and the undo history, and returning the turn
## to Side 1 with no winner.
##
## Run with:
##   godot_console --headless --path . --script res://tests/restart_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_restart_restores_opening(failures)
	_restart_restores_captured_and_clears_hand(failures)
	_restart_after_win(failures)

	if failures.is_empty():
		print("restart_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("restart_test=FAIL %s" % failure)
		quit(1)


## Restart returns every army pairing to its full opening layout. The board is
## emptied first so a restart that failed to re-place the opening would fail.
func _restart_restores_opening(failures: Array[String]) -> void:
	for combo in [
		[Army.Type.XIANGQI, Army.Type.XIANGQI],
		[Army.Type.SHOGI, Army.Type.SHOGI],
		[Army.Type.BIG_FAT_WHALE, Army.Type.BIG_FAT_WHALE],
		[Army.Type.XIANGQI, Army.Type.SHOGI],
		[Army.Type.SHOGI, Army.Type.XIANGQI],
	]:
		var m := Match.new(combo[0], combo[1])
		m.clear()
		m.restart()
		_assert_opening(failures, m)
		_assert_fresh_state(failures, m)


## Restart restores a captured piece and empties a side's hand, proving that a
## mid-match position is fully discarded.
func _restart_restores_captured_and_clears_hand(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.SHOGI, Army.Type.XIANGQI)
	m.clear()
	var rook := _place(m, 1, Army.Type.SHOGI, Piece.Kind.SHOGI_ROOK, 1, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 1, 3)
	_place(m, 1, Army.Type.SHOGI, Piece.Kind.SHOGI_KING, 5, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 5, 10)
	if not m.move(rook, 1, 3):
		failures.append("restart: the capture should be legal")
	elif m.hand1.size() != 1:
		failures.append("restart: the Shogi capture should enter Side 1's hand")
	m.restart()
	_assert_opening(failures, m)
	if not m.hand1.is_empty() or not m.hand2.is_empty():
		failures.append("restart: both hands should be empty")
	_assert_fresh_state(failures, m)


## Restart clears a finished match (a win banner) back to an ongoing one.
func _restart_after_win(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	m.clear()
	_place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 4, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_CHARIOT, 9, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 4, 3)
	if m.winner != 2:
		failures.append("restart: the setup should be a Side 2 win, got winner=%d" % m.winner)
	m.restart()
	_assert_opening(failures, m)
	_assert_fresh_state(failures, m)


## Compares the match point by point against a freshly built match of the same
## two armies, which is the canonical opening. Absolute opening correctness is
## covered by openings_test.gd; this checks restart reaches that same position.
func _assert_opening(failures: Array[String], m: Match) -> void:
	var ref := Match.new(m.side1_army, m.side2_army)
	if m.pieces.size() != ref.pieces.size():
		failures.append("restart: expected %d pieces, got %d" % [ref.pieces.size(), m.pieces.size()])
	for column in range(1, Board.COLUMNS + 1):
		for row in range(1, Board.ROWS + 1):
			var got := m.piece_at(column, row)
			var want := ref.piece_at(column, row)
			if (got == null) != (want == null):
				failures.append("restart: point (%d,%d) occupancy differs" % [column, row])
				continue
			if got != null and (got.kind != want.kind or got.side != want.side or got.army != want.army):
				failures.append("restart: point (%d,%d) piece differs" % [column, row])


## The fresh-match invariants restart must restore.
func _assert_fresh_state(failures: Array[String], m: Match) -> void:
	if m.side_to_move != 1:
		failures.append("restart: Side 1 should move first, got side_to_move=%d" % m.side_to_move)
	if m.can_undo():
		failures.append("restart: the undo history should be empty")
	if m.winner != 0:
		failures.append("restart: the winner should be 0, got %d" % m.winner)
	if m.end_reason != "":
		failures.append("restart: end_reason should be empty, got %s" % m.end_reason)


func _place(m: Match, side: int, army: Army.Type, kind: Piece.Kind, column: int, row: int) -> Piece:
	var piece := Piece.new(side, army, kind, column, row)
	m.place(piece)
	return piece
