extends SceneTree
## Headless test for the AIController: it only ever plays legal moves (turn
## advances and it never leaves its own king in check), prefers the
## highest-value capture, prefers check among equal captures, drops a held piece
## when that is its only option, always takes an optional Shogi promotion, and
## is reproducible under a fixed seed.
##
## Run with:
##   godot_console --headless --path . --script res://tests/ai_controller_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	_only_legal_and_turn_advance(failures)
	_prefers_higher_capture(failures)
	_prefers_check_among_equal_captures(failures)
	_drops_when_forced(failures)
	_promotes_optionally(failures)
	_reproducible(failures)

	if failures.is_empty():
		print("ai_controller_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("ai_controller_test=FAIL %s" % failure)
		quit(1)


func _place(m: Match, side: int, army: Army.Type, kind: Piece.Kind, column: int, row: int) -> Piece:
	var piece := Piece.new(side, army, kind, column, row)
	m.place(piece)
	return piece


func _shogi_place(m: Match, side: int, kind: Piece.Kind, column: int, row: int) -> Piece:
	return _place(m, side, Army.Type.SHOGI, kind, column, row)


## A full self-play match (Xiangqi vs Xiangqi) proves the AI plays only legal
## moves: every `act()` succeeds, the turn advances, and the mover never leaves
## its own king in check.
func _only_legal_and_turn_advance(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	var ai1 := AIController.new(1, m, 12345)
	var ai2 := AIController.new(2, m, 67890)
	var controllers := {1: ai1, 2: ai2}
	var plies := 0
	while m.winner == 0 and plies < 200:
		var side := m.side_to_move
		var ai: AIController = controllers[side]
		if not ai.act():
			failures.append("self-play: act() should succeed on ply %d (side %d)" % [plies, side])
			return
		if m.side_to_move == side:
			failures.append("self-play: the turn should advance on ply %d" % plies)
			return
		if m.is_in_check(side):
			failures.append("self-play: side %d left its own king in check on ply %d" % [side, plies])
			return
		plies += 1


## A chariot with a choice of captures takes the higher-value one (a chariot,
## value 9) over the lower-value one (a soldier, value 1).
func _prefers_higher_capture(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	m.clear()
	var chariot := _place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_CHARIOT, 5, 5)
	_place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 5, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 5, 10)
	var soldier := _place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 1, 5)
	var enemy_chariot := _place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_CHARIOT, 9, 5)

	var ai := AIController.new(1, m, 7)
	if not ai.act():
		failures.append("capture: act() should succeed")
		return
	if chariot.column != 9 or chariot.row != 5:
		failures.append("capture: the AI should capture the chariot (value 9), got (%d,%d)" % [chariot.column, chariot.row])
		return
	if m.piece_at(9, 5) != chariot:
		failures.append("capture: the chariot should stand on (9,5)")
	if enemy_chariot in m.pieces:
		failures.append("capture: the captured chariot should leave the board")
	if not (soldier in m.pieces):
		failures.append("capture: the low-value soldier should remain on the board")


## Among two equal-value captures, the AI prefers the one that gives check.
func _prefers_check_among_equal_captures(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	m.clear()
	var chariot := _place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_CHARIOT, 5, 5)
	_place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 5, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 5, 9)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 1, 5)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 5, 7)

	var ai := AIController.new(1, m, 7)
	if not ai.act():
		failures.append("check: act() should succeed")
		return
	if chariot.column != 5 or chariot.row != 7:
		failures.append("check: the AI should capture the check-giving soldier at (5,7), got (%d,%d)" % [chariot.column, chariot.row])
		return
	if not m.is_in_check(2):
		failures.append("check: capturing (5,7) should give check to Side 2")


## A held pawn is dropped when it is the side's only legal action (no board
## pieces at all).
func _drops_when_forced(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.SHOGI, Army.Type.SHOGI)
	m.clear()
	var pawn := Piece.new(1, Army.Type.SHOGI, Piece.Kind.SHOGI_PAWN, 0, 0)
	m.hand_of(1).append(pawn)

	var ai := AIController.new(1, m, 7)
	if not ai.act():
		failures.append("drop: act() should succeed")
		return
	if not m.hand_of(1).is_empty():
		failures.append("drop: the hand should empty after the drop")
	if m.pieces.size() != 1:
		failures.append("drop: the dropped pawn should be the only board piece")
		return
	if m.piece_at(pawn.column, pawn.row) != pawn:
		failures.append("drop: the pawn should stand where it was dropped")
	if pawn.column < 1 or pawn.column > Board.COLUMNS or pawn.row < 1 or pawn.row > Board.ROWS:
		failures.append("drop: the pawn should be in bounds")
	if pawn.row == Board.ROWS:
		failures.append("drop: a pawn must not drop on the last rank")
	if m.side_to_move != 2:
		failures.append("drop: the turn should pass to Side 2")


## A promotable Shogi move is always made with promotion (optional promotion is
## always taken).
func _promotes_optionally(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.SHOGI, Army.Type.SHOGI)
	m.clear()
	_shogi_place(m, 1, Piece.Kind.SHOGI_KING, 5, 1)
	var silver := _shogi_place(m, 1, Piece.Kind.SHOGI_SILVER, 5, 7)
	_shogi_place(m, 2, Piece.Kind.SHOGI_KING, 5, 9)

	var ai := AIController.new(1, m, 7)
	if not ai.act():
		failures.append("promote: act() should succeed")
		return
	if not silver.promoted:
		failures.append("promote: the AI should take the optional promotion")
	if silver.row != 8:
		failures.append("promote: the silver should end in the promotion zone, got row %d" % silver.row)


## The same seed on an identical position produces the same result.
func _reproducible(failures: Array[String]) -> void:
	var m1 := _tiebreak_position()
	var m2 := _tiebreak_position()
	var ai1 := AIController.new(1, m1, 42)
	var ai2 := AIController.new(1, m2, 42)
	ai1.act()
	ai2.act()
	if _snapshot(m1) != _snapshot(m2):
		failures.append("determinism: the same seed should produce the same board")


## A position with two equal-value captures (a soldier on either side), so the
## choice is a true random tiebreak.
func _tiebreak_position() -> Match:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	m.clear()
	_place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_CHARIOT, 5, 5)
	_place(m, 1, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 5, 1)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_GENERAL, 4, 10)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 1, 5)
	_place(m, 2, Army.Type.XIANGQI, Piece.Kind.XIANGQI_SOLDIER, 9, 5)
	return m


## A canonical string of every board piece, so two matches can be compared.
func _snapshot(m: Match) -> String:
	var parts: Array[String] = []
	for piece in m.pieces:
		parts.append("%d,%d,%d,%d,%s" % [piece.column, piece.row, piece.side, piece.kind, piece.promoted])
	parts.sort()
	return ",".join(parts)
