extends SceneTree
## Headless test for Shogi movement: every Shogi piece moves by its standard
## pattern (king, rook, bishop, gold, silver, knight, lance, pawn), forward is
## toward the opponent, and slides stop at the first piece.
##
## Run with:
##   godot_console --headless --path . --script res://tests/shogi_movement_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_check_king(failures)
	_check_rook(failures)
	_check_bishop(failures)
	_check_gold(failures)
	_check_silver(failures)
	_check_knight(failures)
	_check_lance(failures)
	_check_pawn(failures)

	if failures.is_empty():
		print("shogi_movement_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("shogi_movement_test=FAIL %s" % failure)
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


## Full set equality: the destinations must be exactly `expected`.
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


func _check_king(failures: Array[String]) -> void:
	var m := _empty_match()
	var king := _place(m, 1, Piece.Kind.SHOGI_KING, 5, 5)
	_assert_same(failures, "king center", m.legal_destinations(king), [
		_p(4, 4), _p(5, 4), _p(6, 4),
		_p(4, 5), _p(6, 5),
		_p(4, 6), _p(5, 6), _p(6, 6),
	])

	# At the board edge the off-board steps drop.
	var edge := _empty_match()
	var king2 := _place(edge, 1, Piece.Kind.SHOGI_KING, 1, 1)
	_assert_same(failures, "king corner", edge.legal_destinations(king2), [
		_p(1, 2), _p(2, 2), _p(2, 1),
	])


func _check_rook(failures: Array[String]) -> void:
	var m := _empty_match()
	var rook := _place(m, 1, Piece.Kind.SHOGI_ROOK, 5, 5)
	var open: Array[Vector2i] = []
	for column in range(1, 10):
		if column != 5:
			open.append(_p(column, 5))
	for row in range(1, 11):
		if row != 5:
			open.append(_p(5, row))
	_assert_same(failures, "rook open", m.legal_destinations(rook), open)

	# A friendly piece stops the slide.
	var blocked := _empty_match()
	var rook2 := _place(blocked, 1, Piece.Kind.SHOGI_ROOK, 5, 5)
	_place(blocked, 1, Piece.Kind.SHOGI_PAWN, 5, 8)
	var dests := blocked.legal_destinations(rook2)
	_expect_in(failures, "rook block", dests, _p(5, 6))
	_expect_in(failures, "rook block", dests, _p(5, 7))
	_expect_not_in(failures, "rook block", dests, _p(5, 8))
	_expect_not_in(failures, "rook block", dests, _p(5, 9))

	# An enemy piece is a capture destination; the slide ends there.
	var capture := _empty_match()
	var rook3 := _place(capture, 1, Piece.Kind.SHOGI_ROOK, 5, 5)
	_place(capture, 2, Piece.Kind.SHOGI_PAWN, 5, 8)
	var cdests := capture.legal_destinations(rook3)
	_expect_in(failures, "rook capture", cdests, _p(5, 8))
	_expect_not_in(failures, "rook capture", cdests, _p(5, 9))


func _check_bishop(failures: Array[String]) -> void:
	var m := _empty_match()
	var bishop := _place(m, 1, Piece.Kind.SHOGI_BISHOP, 5, 5)
	_assert_same(failures, "bishop open", m.legal_destinations(bishop), [
		_p(6, 6), _p(7, 7), _p(8, 8), _p(9, 9),
		_p(6, 4), _p(7, 3), _p(8, 2), _p(9, 1),
		_p(4, 6), _p(3, 7), _p(2, 8), _p(1, 9),
		_p(4, 4), _p(3, 3), _p(2, 2), _p(1, 1),
	])


func _check_gold(failures: Array[String]) -> void:
	var m := _empty_match()
	var gold := _place(m, 1, Piece.Kind.SHOGI_GOLD, 5, 5)
	_assert_same(failures, "gold side1", m.legal_destinations(gold), [
		_p(5, 6), _p(5, 4), _p(4, 5), _p(6, 5), _p(4, 6), _p(6, 6),
	])

	# Forward points toward the opponent: downward for Side 2.
	var side2 := _empty_match()
	var gold2 := _place(side2, 2, Piece.Kind.SHOGI_GOLD, 5, 5)
	_assert_same(failures, "gold side2", side2.legal_destinations(gold2), [
		_p(5, 4), _p(5, 6), _p(4, 5), _p(6, 5), _p(4, 4), _p(6, 4),
	])


func _check_silver(failures: Array[String]) -> void:
	var m := _empty_match()
	var silver := _place(m, 1, Piece.Kind.SHOGI_SILVER, 5, 5)
	_assert_same(failures, "silver side1", m.legal_destinations(silver), [
		_p(5, 6), _p(4, 4), _p(6, 4), _p(4, 6), _p(6, 6),
	])

	# Side 2's silver steps forward (downward) plus the same four diagonals.
	var side2 := _empty_match()
	var silver2 := _place(side2, 2, Piece.Kind.SHOGI_SILVER, 5, 5)
	_assert_same(failures, "silver side2", side2.legal_destinations(silver2), [
		_p(5, 4), _p(4, 4), _p(6, 4), _p(4, 6), _p(6, 6),
	])


func _check_knight(failures: Array[String]) -> void:
	var m := _empty_match()
	var knight := _place(m, 1, Piece.Kind.SHOGI_KNIGHT, 5, 5)
	_assert_same(failures, "knight side1", m.legal_destinations(knight), [_p(4, 7), _p(6, 7)])

	var side2 := _empty_match()
	var knight2 := _place(side2, 2, Piece.Kind.SHOGI_KNIGHT, 5, 5)
	_assert_same(failures, "knight side2", side2.legal_destinations(knight2), [_p(4, 3), _p(6, 3)])

	# The knight jumps: intervening pieces do not block its two destinations.
	var jumping := _empty_match()
	var knight3 := _place(jumping, 1, Piece.Kind.SHOGI_KNIGHT, 5, 5)
	_place(jumping, 1, Piece.Kind.SHOGI_PAWN, 5, 6)
	_place(jumping, 1, Piece.Kind.SHOGI_PAWN, 5, 7)
	_assert_same(failures, "knight jump", jumping.legal_destinations(knight3), [_p(4, 7), _p(6, 7)])


func _check_lance(failures: Array[String]) -> void:
	var m := _empty_match()
	var lance := _place(m, 1, Piece.Kind.SHOGI_LANCE, 5, 5)
	_assert_same(failures, "lance side1", m.legal_destinations(lance), [
		_p(5, 6), _p(5, 7), _p(5, 8), _p(5, 9), _p(5, 10),
	])

	# Side 2's lance advances downward; it never moves sideways or backward.
	var side2 := _empty_match()
	var lance2 := _place(side2, 2, Piece.Kind.SHOGI_LANCE, 5, 5)
	_assert_same(failures, "lance side2", side2.legal_destinations(lance2), [
		_p(5, 4), _p(5, 3), _p(5, 2), _p(5, 1),
	])

	# A friendly piece stops the forward slide.
	var blocked := _empty_match()
	var lance3 := _place(blocked, 1, Piece.Kind.SHOGI_LANCE, 5, 5)
	_place(blocked, 1, Piece.Kind.SHOGI_PAWN, 5, 8)
	var dests := blocked.legal_destinations(lance3)
	_expect_in(failures, "lance block", dests, _p(5, 7))
	_expect_not_in(failures, "lance block", dests, _p(5, 8))


func _check_pawn(failures: Array[String]) -> void:
	var m := _empty_match()
	var pawn := _place(m, 1, Piece.Kind.SHOGI_PAWN, 5, 5)
	_assert_same(failures, "pawn side1", m.legal_destinations(pawn), [_p(5, 6)])

	var side2 := _empty_match()
	var pawn2 := _place(side2, 2, Piece.Kind.SHOGI_PAWN, 5, 5)
	_assert_same(failures, "pawn side2", side2.legal_destinations(pawn2), [_p(5, 4)])
