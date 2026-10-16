extends SceneTree
## Headless test for Board geometry: 9x10 points, the river boundary, and
## both palaces.
##
## Run with:
##   godot_console --headless --path . --script res://tests/board_test.gd


func _initialize() -> void:
	var failures: Array[String] = []

	# 9 columns x 10 rows of points.
	if Board.COLUMNS != 9:
		failures.append("expected 9 columns, got %d" % Board.COLUMNS)
	if Board.ROWS != 10:
		failures.append("expected 10 rows, got %d" % Board.ROWS)

	# Every (column, row) pair in 1..9 x 1..10 is a point; nothing outside is.
	for column in range(1, Board.COLUMNS + 1):
		for row in range(1, Board.ROWS + 1):
			if not Board.in_bounds(column, row):
				failures.append("point (%d,%d) should be in bounds" % [column, row])
	for column in [0, 10]:
		for row in [1, 5, 10]:
			if Board.in_bounds(column, row):
				failures.append("column %d should be out of bounds" % column)
	for row in [0, 11]:
		for column in [1, 5, 9]:
			if Board.in_bounds(column, row):
				failures.append("row %d should be out of bounds" % row)

	# The river is the boundary between rows 5 and 6.
	if Board.RIVER_ROW_BELOW != 5 or Board.RIVER_ROW_ABOVE != 6:
		failures.append("river should lie between rows 5 and 6")
	if Board.RIVER_ROW_ABOVE != Board.RIVER_ROW_BELOW + 1:
		failures.append("river rows should be adjacent")

	# Both palaces: columns 4..6, rows 1..3 (Side 1) and 8..10 (Side 2).
	for column in range(4, 7):
		for row in [1, 2, 3, 8, 9, 10]:
			if not Board.is_in_palace(column, row):
				failures.append("palace point (%d,%d) missing" % [column, row])
	# Palace boundaries: outside the column span or outside either row span.
	if Board.is_in_palace(3, 2) or Board.is_in_palace(7, 2):
		failures.append("palace column span is too wide")
	if Board.is_in_palace(5, 4) or Board.is_in_palace(5, 7):
		failures.append("palace row span is wrong")

	if failures.is_empty():
		print("board_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("board_test=FAIL %s" % failure)
		quit(1)
