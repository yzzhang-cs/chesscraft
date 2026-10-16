class_name Moves
extends RefCounted
## Pure Xiangqi movement rules: computes the destinations a piece may move to,
## honoring occupancy, palaces, the river, and the elephant eye / horse leg /
## cannon screen blocks. Shogi movement arrives in a later issue, so Shogi kinds
## currently report no destinations.
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
	return []


## True when `piece` may land on (column, row): the point is on the board and
## either empty or occupied by an opponent (a capture).
static func _can_land(board: Match, piece: Piece, column: int, row: int) -> bool:
	if not Board.in_bounds(column, row):
		return false
	var occupant := board.piece_at(column, row)
	return occupant == null or occupant.side != piece.side


## General: one orthogonal step, confined to its own palace.
static func _general(board: Match, piece: Piece) -> Array[Vector2i]:
	return _palace_step(board, piece, _ORTHOGONAL)


## Advisor: one diagonal step, confined to its own palace.
static func _advisor(board: Match, piece: Piece) -> Array[Vector2i]:
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
## to cross the river.
static func _elephant(board: Match, piece: Piece) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in _DIAGONAL:
		var column := piece.column + dir.x * 2
		var row := piece.row + dir.y * 2
		if not Board.is_on_own_side(piece.side, row):
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
	var forward := 1 if piece.side == 1 else -1
	if _can_land(board, piece, piece.column, piece.row + forward):
		result.append(Vector2i(piece.column, piece.row + forward))
	if Board.has_crossed_river(piece.side, piece.row):
		for column in [piece.column - 1, piece.column + 1]:
			if _can_land(board, piece, column, piece.row):
				result.append(Vector2i(column, piece.row))
	return result
