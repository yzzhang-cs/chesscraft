extends SceneTree
## Headless test for Xiangqi movement: every Xiangqi piece honors its movement
## rules (general/advisor palace confinement, elephant eye and river, horse leg,
## chariot slide, cannon screen capture, soldier river-cross), and the match
## applies a move, alternates the turn, and captures.
##
## Run with:
##   godot_console --headless --path . --script res://tests/xiangqi_movement_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_check_general(failures)
	_check_advisor(failures)
	_check_elephant(failures)
	_check_horse(failures)
	_check_chariot(failures)
	_check_cannon(failures)
	_check_soldier(failures)
	_check_move(failures)

	if failures.is_empty():
		print("xiangqi_movement_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("xiangqi_movement_test=FAIL %s" % failure)
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


func _check_general(failures: Array[String]) -> void:
	var m := _empty_match()
	var g := _place(m, 1, Piece.Kind.XIANGQI_GENERAL, 5, 1)
	_assert_same(failures, "general back rank", m.legal_destinations(g), [_p(4, 1), _p(6, 1), _p(5, 2)])

	# Confined to the palace: (5, 4) is one step past the palace's row-3 edge.
	var edge := _empty_match()
	var g2 := _place(edge, 1, Piece.Kind.XIANGQI_GENERAL, 5, 3)
	var dests := edge.legal_destinations(g2)
	_assert_same(failures, "general palace edge", dests, [_p(4, 3), _p(6, 3), _p(5, 2)])
	_expect_not_in(failures, "general palace edge", dests, _p(5, 4))


func _check_advisor(failures: Array[String]) -> void:
	var m := _empty_match()
	var a := _place(m, 1, Piece.Kind.XIANGQI_ADVISOR, 5, 2)
	_assert_same(failures, "advisor center", m.legal_destinations(a), [_p(4, 1), _p(6, 1), _p(4, 3), _p(6, 3)])


func _check_elephant(failures: Array[String]) -> void:
	var m := _empty_match()
	var e := _place(m, 1, Piece.Kind.XIANGQI_ELEPHANT, 3, 1)
	_assert_same(failures, "elephant open", m.legal_destinations(e), [_p(1, 3), _p(5, 3)])

	# The eye (midpoint) blocks the leg it sits on.
	var blocked := _empty_match()
	var e2 := _place(blocked, 1, Piece.Kind.XIANGQI_ELEPHANT, 3, 1)
	_place(blocked, 1, Piece.Kind.XIANGQI_SOLDIER, 2, 2)
	_assert_same(failures, "elephant eye block", blocked.legal_destinations(e2), [_p(5, 3)])

	# Cannot cross the river: the two forward-diagonal destinations (row 7) drop.
	var river := _empty_match()
	var e3 := _place(river, 1, Piece.Kind.XIANGQI_ELEPHANT, 5, 5)
	_assert_same(failures, "elephant river", river.legal_destinations(e3), [_p(3, 3), _p(7, 3)])


func _check_horse(failures: Array[String]) -> void:
	var m := _empty_match()
	var h := _place(m, 1, Piece.Kind.XIANGQI_HORSE, 5, 5)
	_assert_same(failures, "horse open", m.legal_destinations(h), [
		_p(4, 7), _p(6, 7), _p(4, 3), _p(6, 3),
		_p(3, 4), _p(3, 6), _p(7, 4), _p(7, 6),
	])

	# The leg (the adjacent orthogonal point in the long direction) blocks the
	# two destinations reached through it.
	var blocked := _empty_match()
	var h2 := _place(blocked, 1, Piece.Kind.XIANGQI_HORSE, 5, 5)
	_place(blocked, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 6)
	_assert_same(failures, "horse leg block", blocked.legal_destinations(h2), [
		_p(4, 3), _p(6, 3), _p(3, 4), _p(3, 6), _p(7, 4), _p(7, 6),
	])


func _check_chariot(failures: Array[String]) -> void:
	var m := _empty_match()
	var c := _place(m, 1, Piece.Kind.XIANGQI_CHARIOT, 5, 5)
	var open: Array[Vector2i] = []
	for column in range(1, 10):
		if column != 5:
			open.append(_p(column, 5))
	for row in range(1, 11):
		if row != 5:
			open.append(_p(5, row))
	_assert_same(failures, "chariot open", m.legal_destinations(c), open)

	# A friendly piece stops the slide.
	var blocked := _empty_match()
	var c2 := _place(blocked, 1, Piece.Kind.XIANGQI_CHARIOT, 5, 5)
	_place(blocked, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 7)
	var dests := blocked.legal_destinations(c2)
	_expect_in(failures, "chariot block", dests, _p(5, 6))
	_expect_not_in(failures, "chariot block", dests, _p(5, 7))
	_expect_not_in(failures, "chariot block", dests, _p(5, 8))

	# An enemy piece is a capture destination; the slide ends there.
	var capture := _empty_match()
	var c3 := _place(capture, 1, Piece.Kind.XIANGQI_CHARIOT, 5, 5)
	_place(capture, 2, Piece.Kind.XIANGQI_SOLDIER, 5, 7)
	var cdests := capture.legal_destinations(c3)
	_expect_in(failures, "chariot capture", cdests, _p(5, 7))
	_expect_not_in(failures, "chariot capture", cdests, _p(5, 8))


func _check_cannon(failures: Array[String]) -> void:
	var m := _empty_match()
	var c := _place(m, 1, Piece.Kind.XIANGQI_CANNON, 5, 5)
	var open: Array[Vector2i] = []
	for column in range(1, 10):
		if column != 5:
			open.append(_p(column, 5))
	for row in range(1, 11):
		if row != 5:
			open.append(_p(5, row))
	_assert_same(failures, "cannon open", m.legal_destinations(c), open)

	# Without a screen, the cannon cannot capture an adjacent enemy.
	var no_screen := _empty_match()
	var c1 := _place(no_screen, 1, Piece.Kind.XIANGQI_CANNON, 5, 5)
	_place(no_screen, 2, Piece.Kind.XIANGQI_SOLDIER, 5, 7)
	var d1 := no_screen.legal_destinations(c1)
	_expect_in(failures, "cannon no screen", d1, _p(5, 6))
	_expect_not_in(failures, "cannon no screen", d1, _p(5, 7))

	# Exactly one screen, then an enemy: captures over the screen.
	var one_screen := _empty_match()
	var c2 := _place(one_screen, 1, Piece.Kind.XIANGQI_CANNON, 5, 5)
	_place(one_screen, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 7)
	_place(one_screen, 2, Piece.Kind.XIANGQI_SOLDIER, 5, 8)
	var d2 := one_screen.legal_destinations(c2)
	_expect_in(failures, "cannon one screen", d2, _p(5, 6))
	_expect_in(failures, "cannon one screen", d2, _p(5, 8))
	_expect_not_in(failures, "cannon one screen", d2, _p(5, 7))
	_expect_not_in(failures, "cannon one screen", d2, _p(5, 9))

	# Two screens block the capture entirely.
	var two_screens := _empty_match()
	var c3 := _place(two_screens, 1, Piece.Kind.XIANGQI_CANNON, 5, 5)
	_place(two_screens, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 6)
	_place(two_screens, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 7)
	_place(two_screens, 2, Piece.Kind.XIANGQI_SOLDIER, 5, 8)
	var d3 := two_screens.legal_destinations(c3)
	_expect_not_in(failures, "cannon two screens", d3, _p(5, 7))
	_expect_not_in(failures, "cannon two screens", d3, _p(5, 8))


func _check_soldier(failures: Array[String]) -> void:
	var own_side := _empty_match()
	var s := _place(own_side, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 5)
	_assert_same(failures, "soldier own side", own_side.legal_destinations(s), [_p(5, 6)])

	var crossed := _empty_match()
	var s2 := _place(crossed, 1, Piece.Kind.XIANGQI_SOLDIER, 5, 6)
	_assert_same(failures, "soldier crossed", crossed.legal_destinations(s2), [_p(5, 7), _p(4, 6), _p(6, 6)])

	var side2_own := _empty_match()
	var s3 := _place(side2_own, 2, Piece.Kind.XIANGQI_SOLDIER, 5, 6)
	_assert_same(failures, "soldier side2 own", side2_own.legal_destinations(s3), [_p(5, 5)])

	var side2_crossed := _empty_match()
	var s4 := _place(side2_crossed, 2, Piece.Kind.XIANGQI_SOLDIER, 5, 5)
	_assert_same(failures, "soldier side2 crossed", side2_crossed.legal_destinations(s4), [_p(5, 4), _p(4, 5), _p(6, 5)])


func _check_move(failures: Array[String]) -> void:
	var m := _empty_match()
	if m.side_to_move != 1:
		failures.append("move: Side 1 should move first")
	var c := _place(m, 1, Piece.Kind.XIANGQI_CHARIOT, 1, 1)
	if not m.move(c, 1, 9):
		failures.append("move: chariot 1,1 -> 1,9 should be legal")
	elif m.piece_at(1, 9) != c or m.piece_at(1, 1) != null:
		failures.append("move: chariot should now stand at (1,9)")
	if m.side_to_move != 2:
		failures.append("move: turn should pass to Side 2")

	# Out of turn: the Side 1 piece cannot move again.
	if m.move(c, 1, 8):
		failures.append("move: Side 1 piece moved out of turn")
	if m.side_to_move != 2:
		failures.append("move: an out-of-turn move must not change the turn")

	# Capturing removes the enemy piece from the board.
	var cap := _empty_match()
	var c2 := _place(cap, 1, Piece.Kind.XIANGQI_CHARIOT, 1, 1)
	_place(cap, 2, Piece.Kind.XIANGQI_SOLDIER, 1, 3)
	var before := cap.pieces.size()
	if not cap.move(c2, 1, 3):
		failures.append("move: capture 1,1 -> 1,3 should be legal")
	elif cap.piece_at(1, 3) != c2 or cap.pieces.size() != before - 1:
		failures.append("move: capture should remove the enemy piece")

	# An illegal destination is rejected and changes no state.
	var illegal := _empty_match()
	var c3 := _place(illegal, 1, Piece.Kind.XIANGQI_CHARIOT, 1, 1)
	if illegal.move(c3, 2, 2):
		failures.append("move: a diagonal chariot move should be illegal")
	if illegal.side_to_move != 1 or illegal.piece_at(1, 1) != c3:
		failures.append("move: an illegal move must not change state")
