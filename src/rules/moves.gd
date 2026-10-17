class_name Moves
extends RefCounted
## Pure movement rules: computes the destinations a piece may move to, honoring
## occupancy, palaces, the river, and the elephant eye / horse leg / cannon
## screen blocks (Xiangqi), plus the step/slide/jump patterns of Shogi
## including their promoted forms.
##
## Move generation is turn-agnostic: it answers "where can this piece go" from
## its position and kind, leaving whose turn it is to the Match.


const _ORTHOGONAL: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const _DIAGONAL: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]


## Every board point `piece` may move to under its movement rules, keyed by
## `board` for occupancy. The caller decides whether it is the piece's turn.
static func destinations(board: Match, piece: Piece) -> Array[Vector2i]:
	if piece == null:
		return []
	match piece.kind:
		Piece.Kind.XIANGQI_GENERAL:
			return _general(board, piece)
		Piece.Kind.XIANGQI_ADVISOR:
			return _advisor(board, piece)
		Piece.Kind.XIANGQI_ELEPHANT:
			return _elephant(board, piece)
		Piece.Kind.XIANGQI_HORSE:
			return _horse(board, piece)
		Piece.Kind.XIANGQI_CHARIOT:
			return _chariot(board, piece)
		Piece.Kind.XIANGQI_CANNON:
			return _cannon(board, piece)
		Piece.Kind.XIANGQI_SOLDIER:
			return _soldier(board, piece)
		Piece.Kind.SHOGI_KING:
			return _king(board, piece)
		Piece.Kind.SHOGI_ROOK:
			return _rook(board, piece)
		Piece.Kind.SHOGI_BISHOP:
			return _bishop(board, piece)
		Piece.Kind.SHOGI_GOLD:
			return _gold(board, piece)
		Piece.Kind.SHOGI_SILVER:
			return _silver(board, piece)
		Piece.Kind.SHOGI_KNIGHT:
			return _knight(board, piece)
		Piece.Kind.SHOGI_LANCE:
			return _lance(board, piece)
		Piece.Kind.SHOGI_PAWN:
			return _pawn(board, piece)
	return []


## True when `piece` may land on (column, row): the point is on the board and
## either empty or occupied by an opponent (a capture).
static func _can_land(board: Match, piece: Piece, column: int, row: int) -> bool:
	if not Board.in_bounds(column, row):
		return false
	var occupant := board.piece_at(column, row)
	return occupant == null or occupant.side != piece.side


## True when `piece` is a Xiangqi-family piece now owned by a Shogi side -- a
## captured 相 or 士 re-dropped by Shogi. Only such a piece is freed from its
## river/palace confinement. (The dropped-兵 half-board rule is a drop-legality
## concern handled in Match.can_drop, not here.)
static func _is_freed(board: Match, piece: Piece) -> bool:
	return piece.army != Army.Type.SHOGI and board.army_of(piece.side) == Army.Type.SHOGI


## General: one orthogonal step, confined to its own palace.
static func _general(board: Match, piece: Piece) -> Array[Vector2i]:
	return _palace_step(board, piece, _ORTHOGONAL)


## Advisor: one diagonal step, confined to its own palace. A freed advisor (a
## captured 士 re-dropped by Shogi) steps one point diagonally anywhere.
static func _advisor(board: Match, piece: Piece) -> Array[Vector2i]:
	if _is_freed(board, piece):
		return _steps(board, piece, _DIAGONAL)
	return _palace_step(board, piece, _DIAGONAL)


## One step along each of `directions`, confined to the piece's own palace.
static func _palace_step(board: Match, piece: Piece, directions: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in directions:
		var column := piece.column + dir.x
		var row := piece.row + dir.y
		if Board.is_in_palace_for_side(column, row, piece.side) and _can_land(board, piece, column, row):
			result.append(Vector2i(column, row))
	return result


## Elephant: two diagonal steps, blocked by its eye (the midpoint), and unable
## to cross the river. A freed elephant (a captured 相 re-dropped by Shogi) may
## cross the river; its eye still blocks.
static func _elephant(board: Match, piece: Piece) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in _DIAGONAL:
		var column := piece.column + dir.x * 2
		var row := piece.row + dir.y * 2
		if not _is_freed(board, piece) and not Board.is_on_own_side(piece.side, row):
			continue
		if not _can_land(board, piece, column, row):
			continue
		var eye := Vector2i(piece.column + dir.x, piece.row + dir.y)
		if board.piece_at(eye.x, eye.y) != null:
			continue
		result.append(Vector2i(column, row))
	return result


## Horse: two steps in one orthogonal direction then one perpendicular, blocked
## by its leg (the adjacent orthogonal point in the long direction).
static func _horse(board: Match, piece: Piece) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for long in _ORTHOGONAL:
		var leg := Vector2i(piece.column + long.x, piece.row + long.y)
		if board.piece_at(leg.x, leg.y) != null:
			continue
		var foot := Vector2i(piece.column + long.x * 2, piece.row + long.y * 2)
		for short in _perpendicular(long):
			var column := foot.x + short.x
			var row := foot.y + short.y
			if _can_land(board, piece, column, row):
				result.append(Vector2i(column, row))
	return result


## The two directions perpendicular to an orthogonal `dir`.
static func _perpendicular(dir: Vector2i) -> Array[Vector2i]:
	if dir.x == 0:
		return [Vector2i(1, 0), Vector2i(-1, 0)]
	return [Vector2i(0, 1), Vector2i(0, -1)]


## Chariot: slides any orthogonal distance, stopping at the first piece.
static func _chariot(board: Match, piece: Piece) -> Array[Vector2i]:
	return _slide(board, piece, _ORTHOGONAL)


## Slide along `directions`, capturing the first enemy piece but stopping at any
## piece.
static func _slide(board: Match, piece: Piece, directions: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in directions:
		var column := piece.column + dir.x
		var row := piece.row + dir.y
		while Board.in_bounds(column, row):
			var occupant := board.piece_at(column, row)
			if occupant == null:
				result.append(Vector2i(column, row))
			else:
				if occupant.side != piece.side:
					result.append(Vector2i(column, row))
				break
			column += dir.x
			row += dir.y
	return result


## Cannon: slides like a chariot to empty points, but captures only by jumping
## exactly one screen (an intervening piece).
static func _cannon(board: Match, piece: Piece) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in _ORTHOGONAL:
		var column := piece.column + dir.x
		var row := piece.row + dir.y
		var screens := 0
		while Board.in_bounds(column, row):
			var occupant := board.piece_at(column, row)
			if screens == 0:
				if occupant == null:
					result.append(Vector2i(column, row))
				else:
					screens = 1
			elif occupant != null:
				if occupant.side != piece.side:
					result.append(Vector2i(column, row))
				break
			column += dir.x
			row += dir.y
	return result


## Soldier: one step forward, plus one sideways step after crossing the river,
## never backward.
static func _soldier(board: Match, piece: Piece) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var forward := _forward(piece.side)
	if _can_land(board, piece, piece.column, piece.row + forward):
		result.append(Vector2i(piece.column, piece.row + forward))
	if Board.has_crossed_river(piece.side, piece.row):
		for column in [piece.column - 1, piece.column + 1]:
			if _can_land(board, piece, column, piece.row):
				result.append(Vector2i(column, piece.row))
	return result


## Shogi king: one step in any of the 8 directions.
static func _king(board: Match, piece: Piece) -> Array[Vector2i]:
	return _steps(board, piece, _ORTHOGONAL + _DIAGONAL)


## Shogi rook: slides any orthogonal distance; promoted (龍王) also steps one
## point along each diagonal.
static func _rook(board: Match, piece: Piece) -> Array[Vector2i]:
	var result := _slide(board, piece, _ORTHOGONAL)
	if piece.promoted:
		result.append_array(_steps(board, piece, _DIAGONAL))
	return result


## Shogi bishop: slides any diagonal distance; promoted (龍馬) also steps one
## point along each orthogonal.
static func _bishop(board: Match, piece: Piece) -> Array[Vector2i]:
	var result := _slide(board, piece, _DIAGONAL)
	if piece.promoted:
		result.append_array(_steps(board, piece, _ORTHOGONAL))
	return result


## Shogi gold: one step forward/back/left/right plus the two forward-diagonals.
## The promoted forms of silver, knight, lance, and pawn move as a gold.
static func _gold(board: Match, piece: Piece) -> Array[Vector2i]:
	return _steps(board, piece, _gold_directions(piece.side))


## The six gold steps: forward, back, left, right, and the two forward-diagonals.
static func _gold_directions(side: int) -> Array[Vector2i]:
	var forward := _forward(side)
	return [
		Vector2i(0, forward), Vector2i(0, -forward),
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(1, forward), Vector2i(-1, forward),
	]


## Shogi silver: one step forward plus the four diagonals; promoted (成銀)
## moves as a gold.
static func _silver(board: Match, piece: Piece) -> Array[Vector2i]:
	if piece.promoted:
		return _gold(board, piece)
	return _steps(board, piece, _silver_directions(piece.side))


## The five silver steps: one forward plus the four diagonals.
static func _silver_directions(side: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = [Vector2i(0, _forward(side))]
	result.append_array(_DIAGONAL)
	return result


## Shogi knight: jumps two forward and one sideways (no leg block); promoted
## (成桂) moves as a gold.
static func _knight(board: Match, piece: Piece) -> Array[Vector2i]:
	if piece.promoted:
		return _gold(board, piece)
	var result: Array[Vector2i] = []
	var row := piece.row + 2 * _forward(piece.side)
	for column in [piece.column - 1, piece.column + 1]:
		if _can_land(board, piece, column, row):
			result.append(Vector2i(column, row))
	return result


## Shogi lance: slides any forward distance; promoted (成香) moves as a gold.
static func _lance(board: Match, piece: Piece) -> Array[Vector2i]:
	if piece.promoted:
		return _gold(board, piece)
	var forward: Array[Vector2i] = [Vector2i(0, _forward(piece.side))]
	return _slide(board, piece, forward)


## Shogi pawn: one step forward; promoted (と) moves as a gold.
static func _pawn(board: Match, piece: Piece) -> Array[Vector2i]:
	if piece.promoted:
		return _gold(board, piece)
	var result: Array[Vector2i] = []
	var row := piece.row + _forward(piece.side)
	if _can_land(board, piece, piece.column, row):
		result.append(Vector2i(piece.column, row))
	return result


## Forward is toward the opponent: +1 row for Side 1 (which advances to higher
## rows), -1 for Side 2.
static func _forward(side: int) -> int:
	return 1 if side == 1 else -1


## One step along each of `directions`, honoring occupancy.
static func _steps(board: Match, piece: Piece, directions: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in directions:
		var column := piece.column + dir.x
		var row := piece.row + dir.y
		if _can_land(board, piece, column, row):
			result.append(Vector2i(column, row))
	return result
