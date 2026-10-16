class_name Match
extends RefCounted
## One complete game between two sides. Holds each side's chosen army and the
## board's pieces, and answers the two questions the presentation asks of the
## rules engine: where a piece may move, and applying a move. Pure model -- no
## Node/scene dependency, so it can be driven headlessly.
##
## Side 1 always moves first; its back rank is row 1. Side 2's back rank is
## row 10. A king (Xiangqi general or Shogi king) is never captured: threatening
## it is check, and checkmate ends the match.


## End reasons: the match ended by checkmate or by a side with no legal move.
const REASON_CHECKMATE := "checkmate"
const REASON_NO_LEGAL_MOVE := "no_legal_move"


## Side 1's army.
var side1_army: Army.Type

## Side 2's army.
var side2_army: Army.Type

## The side whose turn it is: 1 or 2. Side 1 always moves first.
var side_to_move := 1

## Every piece on the board, in no guaranteed order.
var pieces: Array[Piece] = []

## Piece lookup by board point, keyed by Vector2i(column, row).
var _pieces_by_point: Dictionary = {}

## Undo stack: one record per applied move, newest last. Each record holds the
## moved piece, its origin, and the piece it captured (or null).
var _history: Array[Dictionary] = []


## The winning side once the match ends, or 0 while it is ongoing. Derived from
## the current position: the side to move loses when it has no legal move.
var winner: int:
	get:
		if has_any_legal_move(side_to_move):
			return 0
		return other_side(side_to_move)


## How the match ended: "" while ongoing, "checkmate" when the side to move is
## in check with no legal move, or "no_legal_move" otherwise.
var end_reason: String:
	get:
		if has_any_legal_move(side_to_move):
			return ""
		return REASON_CHECKMATE if is_in_check(side_to_move) else REASON_NO_LEGAL_MOVE


func _init(side1_army: Army.Type, side2_army: Army.Type) -> void:
	self.side1_army = side1_army
	self.side2_army = side2_army
	for placement in Openings.for_army(side1_army, 1):
		place(Piece.new(1, side1_army, placement["kind"], placement["column"], placement["row"]))
	for placement in Openings.for_army(side2_army, 2):
		place(Piece.new(2, side2_army, placement["kind"], placement["column"], placement["row"]))


## The army a side is playing.
func army_of(side: int) -> Army.Type:
	return side1_army if side == 1 else side2_army


## The side opposing `side`: 1 -> 2, 2 -> 1.
func other_side(side: int) -> int:
	return 3 - side


## The piece standing at a board point, or null when the point is empty.
func piece_at(column: int, row: int) -> Piece:
	return _pieces_by_point.get(Vector2i(column, row))


## Removes every piece, resetting the board, the turn (Side 1), and the undo
## history. Used to build test positions and (later) to restart a match.
func clear() -> void:
	pieces.clear()
	_pieces_by_point.clear()
	_history.clear()
	side_to_move = 1


## Places `piece` at its own column/row, replacing whatever already stands
## there. The opening setup uses this; tests and (later) Shogi drops will too.
func place(piece: Piece) -> void:
	var existing := piece_at(piece.column, piece.row)
	if existing != null:
		pieces.erase(existing)
	pieces.append(piece)
	_pieces_by_point[Vector2i(piece.column, piece.row)] = piece


## Every board point `piece` may legally move to, as a set of (column, row)
## points. Legal means: within the piece's movement rules, not onto a king
## (which is never captured), and not leaving the mover's own king in check.
func legal_destinations(piece: Piece) -> Array[Vector2i]:
	if piece == null:
		return []
	var result: Array[Vector2i] = []
	for dest in Moves.destinations(self, piece):
		var occupant := piece_at(dest.x, dest.y)
		if occupant != null and occupant.side != piece.side and _is_king(occupant.kind):
			continue
		var from := Vector2i(piece.column, piece.row)
		var captured := _apply(piece, dest.x, dest.y)
		if not is_in_check(piece.side):
			result.append(dest)
		_revert(piece, from, captured)
	return result


## Moves `piece` to (column, row) when it is the side to move, the match is
## ongoing, and the point is one of its legal destinations. A capture removes
## the enemy piece. Records the move for undo and returns true when applied
## (and the turn passed to the other side).
func move(piece: Piece, column: int, row: int) -> bool:
	if piece == null or piece.side != side_to_move:
		return false
	if winner != 0:
		return false
	if not legal_destinations(piece).has(Vector2i(column, row)):
		return false
	var from := Vector2i(piece.column, piece.row)
	var captured := _apply(piece, column, row)
	_history.append({"piece": piece, "from": from, "captured": captured})
	side_to_move = other_side(side_to_move)
	return true


## Reverts the last move and restores any captured piece, returning the turn to
## the side that made it. Returns true when there was a move to undo.
func undo() -> bool:
	if _history.is_empty():
		return false
	var record: Dictionary = _history.pop_back()
	var piece: Piece = record["piece"]
	var from: Vector2i = record["from"]
	var captured: Piece = record["captured"]
	_revert(piece, from, captured)
	side_to_move = other_side(side_to_move)
	return true


## True when the last move can be undone.
func can_undo() -> bool:
	return not _history.is_empty()


## The king of `side` (a Xiangqi general or a Shogi king), or null when that
## side has none. A king is never captured, so a side cannot be without one
## while the match is ongoing.
func king_of(side: int) -> Piece:
	for piece in pieces:
		if piece.side == side and _is_king(piece.kind):
			return piece
	return null


## True when `side`'s king is threatened by an enemy piece (in check).
func is_in_check(side: int) -> bool:
	var king := king_of(side)
	if king == null:
		return false
	return is_attacked(king.column, king.row, side)


## True when (column, row) is attacked by an enemy piece -- the point lies in
## some opposing piece's move set. For an occupied point (how check detection
## uses it, on the king) that means the occupant can be captured there.
func is_attacked(column: int, row: int, side: int) -> bool:
	var target := Vector2i(column, row)
	for piece in pieces:
		if piece.side == side:
			continue
		if Moves.destinations(self, piece).has(target):
			return true
	return false


## True when `side` has at least one legal move (one that does not leave its
## own king in check).
func has_any_legal_move(side: int) -> bool:
	for piece in pieces:
		if piece.side == side and not legal_destinations(piece).is_empty():
			return true
	return false


## Relocates `piece` to (column, row), capturing whatever stands there, without
## toggling the turn or recording history. Returns the captured piece (or null).
## Paired with `_revert` for the make/unmake used by legal-move filtering.
func _apply(piece: Piece, column: int, row: int) -> Piece:
	var captured := piece_at(column, row)
	if captured != null:
		_remove(captured)
	_pieces_by_point.erase(Vector2i(piece.column, piece.row))
	piece.column = column
	piece.row = row
	_pieces_by_point[Vector2i(column, row)] = piece
	return captured


## Reverts an `_apply`: moves `piece` back to `from` and restores `captured`
## (which still remembers its own point) to the board.
func _revert(piece: Piece, from: Vector2i, captured: Piece) -> void:
	_pieces_by_point.erase(Vector2i(piece.column, piece.row))
	piece.column = from.x
	piece.row = from.y
	_pieces_by_point[from] = piece
	if captured != null:
		pieces.append(captured)
		_pieces_by_point[Vector2i(captured.column, captured.row)] = captured


func _remove(piece: Piece) -> void:
	pieces.erase(piece)
	_pieces_by_point.erase(Vector2i(piece.column, piece.row))


## True for the two king kinds, which are never captured.
func _is_king(kind: Piece.Kind) -> bool:
	return kind == Piece.Kind.XIANGQI_GENERAL or kind == Piece.Kind.SHOGI_KING
