extends SceneTree
## Headless test for army openings: each of the three armies places its pieces
## in the correct opening position on both sides, Side 1 moves first, and each
## piece reports the right glyph.
##
## Run with:
##   godot_console --headless --path . --script res://tests/openings_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	for army in [Army.Type.XIANGQI, Army.Type.BIG_FAT_WHALE, Army.Type.SHOGI]:
		var match := Match.new(army, army)
		var expected: Array = []
		match army:
			Army.Type.XIANGQI:
				expected = _expected_xiangqi(1, 3, 4) + _expected_xiangqi(10, 8, 7)
			Army.Type.BIG_FAT_WHALE:
				expected = _expected_xiangqi(1, 2, 3) + _expected_xiangqi(10, 9, 8)
			Army.Type.SHOGI:
				expected = _expected_shogi(1, 2, 3, 8, 2) + _expected_shogi(10, 9, 8, 2, 8)
		_check_layout(failures, match, expected, Army.display_name(army))
		_check_side_to_move(failures, match)

	_check_glyphs(failures)
	_check_cross_game(failures)

	if failures.is_empty():
		print("openings_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("openings_test=FAIL %s" % failure)
		quit(1)


## Expected opening for a Xiangqi-style army (Xiangqi and 大肥鱼的象棋 share the
## back rank; they differ only in the cannon and soldier rows). Rows are absolute
## board rows; columns 1..9 are screen-left to screen-right.
func _expected_xiangqi(back_row: int, cannon_row: int, soldier_row: int) -> Array:
	var expected: Array = []
	var back_rank := [
		Piece.Kind.XIANGQI_CHARIOT,
		Piece.Kind.XIANGQI_HORSE,
		Piece.Kind.XIANGQI_ELEPHANT,
		Piece.Kind.XIANGQI_ADVISOR,
		Piece.Kind.XIANGQI_GENERAL,
		Piece.Kind.XIANGQI_ADVISOR,
		Piece.Kind.XIANGQI_ELEPHANT,
		Piece.Kind.XIANGQI_HORSE,
		Piece.Kind.XIANGQI_CHARIOT,
	]
	for column in range(1, 10):
		expected.append([column, back_row, back_rank[column - 1]])
	expected.append([2, cannon_row, Piece.Kind.XIANGQI_CANNON])
	expected.append([8, cannon_row, Piece.Kind.XIANGQI_CANNON])
	for column in [1, 3, 5, 7, 9]:
		expected.append([column, soldier_row, Piece.Kind.XIANGQI_SOLDIER])
	return expected


## Expected Shogi opening. The back rank 香桂銀金王金銀桂香 is palindromic, so it
## reads the same on both sides; only the rook/bishop columns differ per side
## (rook on the owner's right, bishop on the owner's left).
func _expected_shogi(back_row: int, major_row: int, pawn_row: int, rook_col: int, bishop_col: int) -> Array:
	var expected: Array = []
	var back_rank := [
		Piece.Kind.SHOGI_LANCE,
		Piece.Kind.SHOGI_KNIGHT,
		Piece.Kind.SHOGI_SILVER,
		Piece.Kind.SHOGI_GOLD,
		Piece.Kind.SHOGI_KING,
		Piece.Kind.SHOGI_GOLD,
		Piece.Kind.SHOGI_SILVER,
		Piece.Kind.SHOGI_KNIGHT,
		Piece.Kind.SHOGI_LANCE,
	]
	for column in range(1, 10):
		expected.append([column, back_row, back_rank[column - 1]])
	expected.append([rook_col, major_row, Piece.Kind.SHOGI_ROOK])
	expected.append([bishop_col, major_row, Piece.Kind.SHOGI_BISHOP])
	for column in range(1, 10):
		expected.append([column, pawn_row, Piece.Kind.SHOGI_PAWN])
	return expected


## Every expected piece is present with the right kind, and there are no extra
## pieces.
func _check_layout(failures: Array[String], match: Match, expected: Array, label: String) -> void:
	for triple in expected:
		var column: int = triple[0]
		var row: int = triple[1]
		var kind: int = triple[2]
		var piece := match.piece_at(column, row)
		if piece == null:
			failures.append("%s: missing piece at (%d,%d)" % [label, column, row])
		elif piece.kind != kind:
			failures.append("%s: piece at (%d,%d) has kind %d, want %d" % [label, column, row, piece.kind, kind])
	if match.pieces.size() != expected.size():
		failures.append("%s: expected %d pieces, got %d" % [label, expected.size(), match.pieces.size()])


func _check_side_to_move(failures: Array[String], match: Match) -> void:
	if match.side_to_move != 1:
		failures.append("Side 1 should move first, but side_to_move=%d" % match.side_to_move)


func _check_glyphs(failures: Array[String]) -> void:
	# Red Xiangqi glyphs are for Side 1 (the first mover); black for Side 2.
	var red := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	if red.piece_at(5, 1).glyph() != "帥":
		failures.append("Side 1 general should glyph 帥")
	if red.piece_at(1, 1).glyph() != "俥":
		failures.append("Side 1 chariot should glyph 俥")
	if red.piece_at(5, 10).glyph() != "將":
		failures.append("Side 2 general should glyph 將")
	if red.piece_at(9, 10).glyph() != "車":
		failures.append("Side 2 chariot should glyph 車")

	# Shogi glyphs are two characters and independent of side.
	var shogi := Match.new(Army.Type.SHOGI, Army.Type.SHOGI)
	if shogi.piece_at(5, 1).glyph() != "王将":
		failures.append("Shogi king should glyph 王将")
	if shogi.piece_at(8, 2).glyph() != "飛車":
		failures.append("Shogi rook should glyph 飛車")
	if shogi.piece_at(2, 2).glyph() != "角行":
		failures.append("Shogi bishop should glyph 角行")
	if shogi.piece_at(1, 3).glyph() != "歩兵":
		failures.append("Shogi pawn should glyph 歩兵")


func _check_cross_game(failures: Array[String]) -> void:
	# The two sides pick armies independently.
	var match := Match.new(Army.Type.XIANGQI, Army.Type.SHOGI)
	if match.army_of(1) != Army.Type.XIANGQI:
		failures.append("Side 1 should be Xiangqi in the cross-game match")
	if match.army_of(2) != Army.Type.SHOGI:
		failures.append("Side 2 should be Shogi in the cross-game match")
	if match.piece_at(5, 1) == null or match.piece_at(5, 1).kind != Piece.Kind.XIANGQI_GENERAL:
		failures.append("Side 1 Xiangqi general missing in cross-game match")
	if match.piece_at(5, 10) == null or match.piece_at(5, 10).kind != Piece.Kind.SHOGI_KING:
		failures.append("Side 2 Shogi king missing in cross-game match")
	# Every piece carries its own army, matching the side that placed it.
	for piece in match.pieces:
		var side_army: Army.Type = match.army_of(piece.side)
		if piece.army != side_army:
			failures.append("piece at (%d,%d) army %d != side %d army %d" % [piece.column, piece.row, piece.army, piece.side, side_army])
