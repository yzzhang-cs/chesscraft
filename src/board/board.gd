class_name Board
extends RefCounted
## Board geometry: the shared 9-column x 10-row grid of points both armies
## play on. Pure model -- no Node or scene dependency, so it can be driven
## headlessly.
##
## Coordinates are 1-based and match the domain vocabulary in CONTEXT.md:
##   - column 1..9 runs left to right;
##   - row 1 is Side 1's back rank (bottom of the screen) and row 10 is
##     Side 2's back rank (top of the screen).


## Number of columns of points.
const COLUMNS := 9

## Number of rows of points.
const ROWS := 10

## The river is the gap between these two adjacent rows. Row 5 is Side 1's
## front rank and row 6 is Side 2's front rank.
const RIVER_ROW_BELOW := 5
const RIVER_ROW_ABOVE := 6

## Both palaces occupy the center three columns.
const PALACE_COL_MIN := 4
const PALACE_COL_MAX := 6

## Side 1's palace spans its own back three ranks (rows 1..3).
const PALACE_SIDE1_ROW_MIN := 1
const PALACE_SIDE1_ROW_MAX := 3

## Side 2's palace spans its own back three ranks (rows 8..10).
const PALACE_SIDE2_ROW_MIN := 8
const PALACE_SIDE2_ROW_MAX := 10


## True when (column, row) is a valid board point.
static func in_bounds(column: int, row: int) -> bool:
	return column >= 1 and column <= COLUMNS and row >= 1 and row <= ROWS


## True when (column, row) lies in either palace.
static func is_in_palace(column: int, row: int) -> bool:
	return is_in_palace_for_side(column, row, 1) or is_in_palace_for_side(column, row, 2)


## True when (column, row) lies in `side`'s own palace (Side 1's rows 1..3,
## Side 2's rows 8..10). A Xiangqi general and advisor are confined here.
static func is_in_palace_for_side(column: int, row: int, side: int) -> bool:
	if column < PALACE_COL_MIN or column > PALACE_COL_MAX:
		return false
	if side == 1:
		return row >= PALACE_SIDE1_ROW_MIN and row <= PALACE_SIDE1_ROW_MAX
	return row >= PALACE_SIDE2_ROW_MIN and row <= PALACE_SIDE2_ROW_MAX


## True when `row` lies on `side`'s own half of the board. Side 1 owns rows
## 1..5 (at or behind its river bank); Side 2 owns rows 6..10. A Xiangqi
## elephant may not cross onto the far half.
static func is_on_own_side(side: int, row: int) -> bool:
	if side == 1:
		return row <= RIVER_ROW_BELOW
	return row >= RIVER_ROW_ABOVE


## True when a soldier of `side` standing on `row` has crossed the river onto
## the opponent's half, which grants it sideways movement.
static func has_crossed_river(side: int, row: int) -> bool:
	if side == 1:
		return row >= RIVER_ROW_ABOVE
	return row <= RIVER_ROW_BELOW
