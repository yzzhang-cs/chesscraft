extends SceneTree
## Headless test for Shogi promotion: a move beginning or ending in the
## promotion zone may promote, stranded pawns/lances/knights are forced to
## promote, promoted pieces move by their promoted patterns, `move()` applies
## promotion and `undo()` reverts it, and a captured promoted piece reverts to
## its unpromoted form.
##
## Run with:
##   godot_console --headless --path . --script res://tests/shogi_promotion_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_check_can_promote(failures)
	_check_must_promote(failures)
	_check_promote_and_undo(failures)
	_check_forced_promotion(failures)
	_check_promoted_rook(failures)
	_check_promoted_bishop(failures)
	_check_promoted_gold_move(failures)
	_check_unpromote_revert(failures)

	if failures.is_empty():
		print("shogi_promotion_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("shogi_promotion_test=FAIL %s" % failure)
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


func _assert_same(failures: Array[String], label: String, actual: Array[Vector2i], expected: Array[Vector2i]) -> void:
	if actual.size() != expected.size():
		failures.append("%s: expected %d destinations, got %d %s" % [label, expected.size(), actual.size(), str(actual)])
		return
	for point in expected:
		if not actual.has(point):
			failures.append("%s: missing destination %s" % [label, str(point)])
	for point in actual:
		if not expected.has(point):
			failures.append("%s: unexpected destination %s" % [label, str(point)])


func _expect_in(failures: Array[String], label: String, actual: Array[Vector2i], point: Vector2i) -> void:
	if not actual.has(point):
		failures.append("%s: expected %s to be legal" % [label, str(point)])


func _expect_not_in(failures: Array[String], label: String, actual: Array[Vector2i], point: Vector2i) -> void:
	if actual.has(point):
		failures.append("%s: expected %s to be illegal" % [label, str(point)])


## The gold move from (column, row) for Side 1 (forward = +1 row).
func _gold_set(column: int, row: int) -> Array[Vector2i]:
	return [
		_p(column, row + 1), _p(column, row - 1),
		_p(column - 1, row), _p(column + 1, row),
		_p(column - 1, row + 1), _p(column + 1, row + 1),
	]


## A move beginning or ending in the promotion zone may promote; anything else
## (gold, king, Xiangqi pieces, or an already-promoted piece) may not.
func _check_can_promote(failures: Array[String]) -> void:
	# Begins in the zone: the piece stands on row 8 (Side 1's promotion zone is
	# rows 8..10).
	var m := _empty_match()
	var silver := _place(m, 1, Piece.Kind.SHOGI_SILVER, 5, 8)
	if not m.can_promote(silver, 9):
		failures.append("can_promote: a move beginning in the zone should promote")

	# Ends in the zone: moving from row 7 onto row 8.
	var m2 := _empty_match()
	var silver2 := _place(m2, 1, Piece.Kind.SHOGI_SILVER, 5, 7)
	if not m2.can_promote(silver2, 8):
		failures.append("can_promote: a move ending in the zone should promote")

	# Neither begins nor ends in the zone.
	var m3 := _empty_match()
	var silver3 := _place(m3, 1, Piece.Kind.SHOGI_SILVER, 5, 7)
	if m3.can_promote(silver3, 6):
		failures.append("can_promote: a move entirely outside the zone must not promote")

	# Gold and king never promote.
	var m4 := _empty_match()
	var gold := _place(m4, 1, Piece.Kind.SHOGI_GOLD, 5, 8)
	var king := _place(m4, 1, Piece.Kind.SHOGI_KING, 6, 8)
	if m4.can_promote(gold, 9):
		failures.append("can_promote: a gold must not promote")
	if m4.can_promote(king, 9):
		failures.append("can_promote: a king must not promote")

	# Xiangqi pieces never promote, even standing in the zone.
	var m5 := _empty_match()
	var soldier := Piece.new(1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 5, 8)
	m5.place(soldier)
	if m5.can_promote(soldier, 9):
		failures.append("can_promote: a Xiangqi piece must not promote")


## A pawn or lance landing on the last rank, or a knight on the last two ranks,
## is forced to promote; other pieces are never forced.
func _check_must_promote(failures: Array[String]) -> void:
	var m := _empty_match()
	var pawn := _place(m, 1, Piece.Kind.SHOGI_PAWN, 5, 9)
	var lance := _place(m, 1, Piece.Kind.SHOGI_LANCE, 4, 9)
	var knight := _place(m, 1, Piece.Kind.SHOGI_KNIGHT, 6, 7)
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 7, 9)
	var silver := _place(m, 1, Piece.Kind.SHOGI_SILVER, 8, 9)

	if not m.must_promote(pawn, 10):
		failures.append("must_promote: a pawn on the last rank must promote")
	if not m.must_promote(lance, 10):
		failures.append("must_promote: a lance on the last rank must promote")
	if m.must_promote(pawn, 9):
		failures.append("must_promote: a pawn on the second-to-last rank is not forced")
	if not m.must_promote(knight, 9) or not m.must_promote(knight, 10):
		failures.append("must_promote: a knight on the last two ranks must promote")
	if m.must_promote(knight, 8):
		failures.append("must_promote: a knight three ranks out is not forced")
	if m.must_promote(rook, 10):
		failures.append("must_promote: a rook is never forced (it still slides sideways)")
	if m.must_promote(silver, 10):
		failures.append("must_promote: a silver is never forced (it still has diagonals)")

	# Side 2's last rank is row 1; its last two ranks are rows 1..2.
	var m2 := _empty_match()
	var pawn2 := _place(m2, 2, Piece.Kind.SHOGI_PAWN, 5, 2)
	var knight2 := _place(m2, 2, Piece.Kind.SHOGI_KNIGHT, 4, 4)
	if not m2.must_promote(pawn2, 1):
		failures.append("must_promote: Side 2 pawn on row 1 must promote")
	if not m2.must_promote(knight2, 1) or not m2.must_promote(knight2, 2):
		failures.append("must_promote: Side 2 knight on rows 1..2 must promote")
	if m2.must_promote(knight2, 3):
		failures.append("must_promote: Side 2 knight on row 3 is not forced")


## An optional promotion applies the promoted glyph and movement, a declined
## promotion leaves the piece unpromoted, and undo reverts the promotion.
func _check_promote_and_undo(failures: Array[String]) -> void:
	var m := _empty_match()
	var pawn := _place(m, 1, Piece.Kind.SHOGI_PAWN, 5, 7)
	if not m.move(pawn, 5, 8, true):
		failures.append("promote: pawn 5,7 -> 5,8 with promote should be legal")
	elif pawn.glyph() != "と":
		failures.append("promote: promoted pawn should glyph と, got %s" % pawn.glyph())
	if m.piece_at(5, 8) != pawn:
		failures.append("promote: the pawn should stand on (5,8)")
	if m.side_to_move != 2:
		failures.append("promote: turn should pass to Side 2")

	# An already-promoted piece cannot promote again.
	if m.can_promote(pawn, 9):
		failures.append("promote: an already-promoted piece must not promote again")

	# Undo reverts the promotion, the position, and the turn.
	if not m.undo():
		failures.append("promote: undo should revert the move")
	elif pawn.glyph() != "歩兵":
		failures.append("promote: undo should un-promote the pawn")
	elif m.piece_at(5, 7) != pawn:
		failures.append("promote: undo should return the pawn to (5,7)")
	elif m.side_to_move != 1:
		failures.append("promote: undo should return the turn to Side 1")

	# Declining an optional promotion leaves the piece unpromoted.
	var m2 := _empty_match()
	var pawn2 := _place(m2, 1, Piece.Kind.SHOGI_PAWN, 5, 7)
	if not m2.move(pawn2, 5, 8, false):
		failures.append("promote: pawn 5,7 -> 5,8 with decline should be legal")
	elif pawn2.glyph() != "歩兵":
		failures.append("promote: a declined promotion must leave the piece unpromoted")


## A forced promotion happens even when the caller passes promote = false.
func _check_forced_promotion(failures: Array[String]) -> void:
	var m := _empty_match()
	var pawn := _place(m, 1, Piece.Kind.SHOGI_PAWN, 5, 9)
	if not m.move(pawn, 5, 10):
		failures.append("forced: pawn 5,9 -> 5,10 should be legal")
	elif pawn.glyph() != "と":
		failures.append("forced: the pawn on the last rank must auto-promote")

	var m2 := _empty_match()
	var knight := _place(m2, 1, Piece.Kind.SHOGI_KNIGHT, 5, 7)
	if not m2.move(knight, 4, 9):
		failures.append("forced: knight 5,7 -> 4,9 should be legal")
	elif knight.glyph() != "成桂":
		failures.append("forced: the knight on the last two ranks must auto-promote")


## 龍王 moves as a rook plus one diagonal step (not a diagonal slide).
func _check_promoted_rook(failures: Array[String]) -> void:
	var m := _empty_match()
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 5, 7)
	if not m.move(rook, 5, 8, true):
		failures.append("promoted rook: rook 5,7 -> 5,8 with promote should be legal")
		return
	if rook.glyph() != "龍王":
		failures.append("promoted rook: should glyph 龍王, got %s" % rook.glyph())
	var dests := m.legal_destinations(rook)
	_expect_in(failures, "promoted rook", dests, _p(4, 9))   # diagonal step
	_expect_in(failures, "promoted rook", dests, _p(6, 7))   # diagonal step
	_expect_in(failures, "promoted rook", dests, _p(5, 10))  # orthogonal slide
	_expect_in(failures, "promoted rook", dests, _p(1, 8))   # orthogonal slide
	_expect_not_in(failures, "promoted rook", dests, _p(3, 10))  # two diagonal steps


## 龍馬 moves as a bishop plus one orthogonal step (not an orthogonal slide).
func _check_promoted_bishop(failures: Array[String]) -> void:
	var m := _empty_match()
	var bishop := _place(m, 1, Piece.Kind.SHOGI_BISHOP, 4, 7)
	if not m.move(bishop, 5, 8, true):
		failures.append("promoted bishop: bishop 4,7 -> 5,8 with promote should be legal")
		return
	if bishop.glyph() != "龍馬":
		failures.append("promoted bishop: should glyph 龍馬, got %s" % bishop.glyph())
	var dests := m.legal_destinations(bishop)
	_expect_in(failures, "promoted bishop", dests, _p(5, 9))   # orthogonal step
	_expect_in(failures, "promoted bishop", dests, _p(4, 8))   # orthogonal step
	_expect_in(failures, "promoted bishop", dests, _p(7, 10))  # diagonal slide
	_expect_in(failures, "promoted bishop", dests, _p(1, 4))   # diagonal slide
	_expect_not_in(failures, "promoted bishop", dests, _p(3, 8))  # two orthogonal steps


## 成銀, 成香, and と (all landing at 5,8) and 成桂 (at 4,8) move as a gold.
func _check_promoted_gold_move(failures: Array[String]) -> void:
	var m := _empty_match()
	var silver := _place(m, 1, Piece.Kind.SHOGI_SILVER, 5, 7)
	if not m.move(silver, 5, 8, true):
		failures.append("gold move: silver promote should be legal")
	else:
		if silver.glyph() != "成銀":
			failures.append("gold move: promoted silver should glyph 成銀")
		_assert_same(failures, "成銀 gold move", m.legal_destinations(silver), _gold_set(5, 8))

	var m2 := _empty_match()
	var lance := _place(m2, 1, Piece.Kind.SHOGI_LANCE, 5, 6)
	if not m2.move(lance, 5, 8, true):
		failures.append("gold move: lance promote should be legal")
	else:
		if lance.glyph() != "成香":
			failures.append("gold move: promoted lance should glyph 成香")
		_assert_same(failures, "成香 gold move", m2.legal_destinations(lance), _gold_set(5, 8))

	var m3 := _empty_match()
	var pawn := _place(m3, 1, Piece.Kind.SHOGI_PAWN, 5, 7)
	if not m3.move(pawn, 5, 8, true):
		failures.append("gold move: pawn promote should be legal")
	else:
		if pawn.glyph() != "と":
			failures.append("gold move: promoted pawn should glyph と")
		_assert_same(failures, "と gold move", m3.legal_destinations(pawn), _gold_set(5, 8))

	var m4 := _empty_match()
	var knight := _place(m4, 1, Piece.Kind.SHOGI_KNIGHT, 5, 6)
	if not m4.move(knight, 4, 8, true):
		failures.append("gold move: knight promote should be legal")
	else:
		if knight.glyph() != "成桂":
			failures.append("gold move: promoted knight should glyph 成桂")
		_assert_same(failures, "成桂 gold move", m4.legal_destinations(knight), _gold_set(4, 8))


## A captured promoted piece reverts to its unpromoted form. Issue 07 wires this
## into the capture-into-hand path; here we assert the reversion primitive.
func _check_unpromote_revert(failures: Array[String]) -> void:
	var m := _empty_match()
	var silver := _place(m, 1, Piece.Kind.SHOGI_SILVER, 5, 7)
	if not m.move(silver, 5, 8, true):
		failures.append("unpromote: silver promote should be legal")
		return
	if silver.glyph() != "成銀":
		failures.append("unpromote: silver should be promoted (成銀)")
	silver.unpromote()
	if silver.glyph() != "銀将":
		failures.append("unpromote: unpromoted silver should glyph 銀将, got %s" % silver.glyph())
	_assert_same(failures, "unpromote silver move", m.legal_destinations(silver), [
		_p(5, 9), _p(4, 7), _p(6, 7), _p(4, 9), _p(6, 9),
	])
