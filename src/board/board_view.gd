class_name BoardView
extends Node2D
## Draws the empty Xiangqi-style board: grid lines, the river, and both
## palaces. Reads geometry from the pure `Board` model.
##
## Point (column, row) maps to screen space with column 1 on the left and
## row 1 at the bottom (Side 1's back rank).


## Distance, in pixels, between adjacent points.
const POINT_SPACING := 64.0

## Empty margin around the outermost points.
const MARGIN := 64.0

const BOARD_FILL := Color(0.93, 0.82, 0.62)
const RIVER_FILL := Color(0.72, 0.82, 0.90, 0.55)
const LINE_COLOR := Color(0.12, 0.10, 0.08)
const LINE_WIDTH := 2.0


## Screen position of a board point.
func point_position(column: int, row: int) -> Vector2:
	return Vector2(
		MARGIN + float(column - 1) * POINT_SPACING,
		MARGIN + float(Board.ROWS - row) * POINT_SPACING
	)


func _draw() -> void:
	_draw_background()
	_draw_river()
	_draw_grid()
	_draw_palaces()


func _draw_background() -> void:
	var top_left := point_position(1, Board.ROWS)
	var bottom_right := point_position(Board.COLUMNS, 1)
	draw_rect(Rect2(top_left, bottom_right - top_left), BOARD_FILL, true)


func _draw_river() -> void:
	# The river is the band between rows 5 and 6. Its banks are the row-5 and
	# row-6 grid lines; the fill marks the gap the pieces cannot occupy.
	var top_left := point_position(1, Board.RIVER_ROW_ABOVE)
	var bottom_right := point_position(Board.COLUMNS, Board.RIVER_ROW_BELOW)
	draw_rect(Rect2(top_left, bottom_right - top_left), RIVER_FILL, true)


func _draw_grid() -> void:
	# Horizontal lines: one per row.
	for row in range(1, Board.ROWS + 1):
		var left := point_position(1, row)
		var right := point_position(Board.COLUMNS, row)
		draw_line(left, right, LINE_COLOR, LINE_WIDTH)

	# Vertical lines: the border columns run full height; the inner columns
	# are broken by the river, as on a real Xiangqi board.
	for column in range(1, Board.COLUMNS + 1):
		if column == 1 or column == Board.COLUMNS:
			_draw_vertical(column, 1, Board.ROWS)
		else:
			_draw_vertical(column, 1, Board.RIVER_ROW_BELOW)
			_draw_vertical(column, Board.RIVER_ROW_ABOVE, Board.ROWS)


func _draw_vertical(column: int, row_from: int, row_to: int) -> void:
	var top := point_position(column, row_to)
	var bottom := point_position(column, row_from)
	draw_line(top, bottom, LINE_COLOR, LINE_WIDTH)


func _draw_palaces() -> void:
	_draw_palace_diagonals(Board.PALACE_SIDE1_ROW_MIN, Board.PALACE_SIDE1_ROW_MAX)
	_draw_palace_diagonals(Board.PALACE_SIDE2_ROW_MIN, Board.PALACE_SIDE2_ROW_MAX)


## Draws the X across a palace: two diagonals between opposite corners.
func _draw_palace_diagonals(row_min: int, row_max: int) -> void:
	var col_min := Board.PALACE_COL_MIN
	var col_max := Board.PALACE_COL_MAX
	draw_line(point_position(col_min, row_min), point_position(col_max, row_max), LINE_COLOR, LINE_WIDTH)
	draw_line(point_position(col_max, row_min), point_position(col_min, row_max), LINE_COLOR, LINE_WIDTH)
