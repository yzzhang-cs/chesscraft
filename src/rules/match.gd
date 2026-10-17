class_name Match
extends RefCounted
## One complete game between two sides. Holds each side's chosen army and the
## board's pieces, and answers the two questions the presentation asks of the
## rules engine: where a piece may move, and applying a move. Pure model -- no
## Node/scene dependency, so it can be driven headlessly.
##
## Side 1 always moves first; its back rank is row 1. Side 2's back rank is
## row 10. A king (Xiangqi general or Shogi king) is never captured: threatening
## it is check, and checkmate ends the match. Shogi promotion is optional when a
## move begins or ends in the promotion zone, and forced for a stranded piece;
## `move()` applies it and `undo()` reverts it.


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

## The pieces each side holds in hand (captured and awaiting a drop). Only a
## Shogi side captures into a hand; a Xiangqi/大肥鱼 side removes captured
## pieces permanently and never holds a hand. A hand piece has column/row 0
## (off the board) and belongs to the side that captured it.
var hand1: Array[Piece] = []
var hand2: Array[Piece] = []


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


## The pieces `side` holds in hand, captured and awaiting a drop.
func hand_of(side: int) -> Array[Piece]:
	return hand1 if side == 1 else hand2


## The piece standing at a board point, or null when the point is empty.
func piece_at(column: int, row: int) -> Piece:
	return _pieces_by_point.get(Vector2i(column, row))


## Removes every piece, resetting the board, the hands, the turn (Side 1), and
## the undo history. Used to build test positions and (later) to restart a
## match.
func clear() -> void:
	pieces.clear()
	_pieces_by_point.clear()
	_history.clear()
	hand1.clear()
	hand2.clear()
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


## True when a move of `piece` to `row` may promote: the piece is an unpromoted
## promotable Shogi kind and the move begins or ends in the promotion zone (the
## enemy's three back ranks). Xiangqi pieces never promote.
func can_promote(piece: Piece, row: int) -> bool:
	if piece == null or piece.promoted or not Piece.is_promotable(piece.kind):
		return false
	return Board.is_in_promotion_zone(piece.side, piece.row) or Board.is_in_promotion_zone(piece.side, row)


## True when a move of `piece` to `row` forces promotion: a pawn or lance
## landing on the enemy's back rank, or a knight landing on the enemy's last
## two ranks (where it would have no forward move left).
func must_promote(piece: Piece, row: int) -> bool:
	if piece == null or piece.promoted or not Piece.is_promotable(piece.kind):
		return false
	match piece.kind:
		Piece.Kind.SHOGI_PAWN, Piece.Kind.SHOGI_LANCE:
			return row == Board.enemy_back_rank(piece.side)
		Piece.Kind.SHOGI_KNIGHT:
			return Board.is_enemy_last_two_ranks(piece.side, row)
	return false


## Moves `piece` to (column, row) when it is the side to move, the match is
## ongoing, and the point is one of its legal destinations. A capture removes
## the enemy piece. A Shogi promotion applies when `promote` is true or the
## move is a forced promotion. Records the move (and any promotion) for undo
## and returns true when applied (and the turn passed to the other side).
func move(piece: Piece, column: int, row: int, promote: bool = false) -> bool:
	if piece == null or piece.side != side_to_move:
		return false
	if winner != 0:
		return false
	if not legal_destinations(piece).has(Vector2i(column, row)):
		return false
	var from := Vector2i(piece.column, piece.row)
	var was_promoted := piece.promoted
	var should_promote := (promote or must_promote(piece, row)) and can_promote(piece, row)
	var captured := _apply(piece, column, row)
	var captured_from := Vector2i.ZERO
	var captured_was_promoted := false
	var captured_to_hand := false
	if captured != null:
		captured_from = Vector2i(captured.column, captured.row)
		captured_was_promoted = captured.promoted
		if _captures_into_hand(piece.side):
			_add_to_hand(captured, piece.side)
			captured_to_hand = true
	if should_promote:
		piece.promoted = true
	_history.append({
		"piece": piece,
		"from": from,
		"captured": captured,
		"captured_from": captured_from,
		"captured_to_hand": captured_to_hand,
		"captured_was_promoted": captured_was_promoted,
		"was_promoted": was_promoted,
	})
	side_to_move = other_side(side_to_move)
	return true


## Reverts the last move or drop, restoring any captured piece to the board and
## undoing any promotion, returning the turn to the side that made it. Returns
## true when there was a move to undo.
func undo() -> bool:
	if _history.is_empty():
		return false
	var record: Dictionary = _history.pop_back()
	var piece: Piece = record["piece"]
	if record.get("drop", false):
		_undrop(piece)
	else:
		var from: Vector2i = record["from"]
		var captured: Piece = record["captured"]
		var captured_from: Vector2i = record.get("captured_from", Vector2i.ZERO)
		var captured_to_hand: bool = record.get("captured_to_hand", false)
		if captured != null and captured_to_hand:
			_remove_from_hand(captured)
			captured.side = other_side(piece.side)
			captured.column = captured_from.x
			captured.row = captured_from.y
			captured.promoted = record.get("captured_was_promoted", false)
		_revert(piece, from, captured)
		piece.promoted = record["was_promoted"]
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


## True when `side` has at least one legal move or drop (one that does not
## leave its own king in check).
func has_any_legal_move(side: int) -> bool:
	for piece in pieces:
		if piece.side == side and not legal_destinations(piece).is_empty():
			return true
	for piece in hand_of(side):
		if not legal_drop_destinations(piece).is_empty():
			return true
	return false


## True when a capture by `side` enters that side's hand: only a Shogi side
## captures into a hand. A Xiangqi/大肥鱼 side removes captures permanently.
func _captures_into_hand(side: int) -> bool:
	return army_of(side) == Army.Type.SHOGI


## Moves a just-captured piece into `captor`'s hand: unpromoted, re-owned to the
## captor, and marked off-board (column/row 0).
func _add_to_hand(captured: Piece, captor: int) -> void:
	captured.unpromote()
	captured.side = captor
	captured.column = 0
	captured.row = 0
	hand_of(captor).append(captured)


## Removes `piece` from whichever hand holds it. The caller restores its side,
## position, and board membership.
func _remove_from_hand(piece: Piece) -> void:
	hand_of(piece.side).erase(piece)


## True when a held `piece` may drop onto the point (column, row): the point is
## on the board and empty, and the piece is not a pawn/lance dropped onto the
## enemy's back rank, a knight dropped onto the enemy's last two ranks, or a
## captured 兵 dropped onto the far half (a dropped 兵 stays behind the river).
## Drops are always unpromoted.
func can_drop(piece: Piece, column: int, row: int) -> bool:
	if piece == null or not hand_of(piece.side).has(piece):
		return false
	if not Board.in_bounds(column, row):
		return false
	if piece_at(column, row) != null:
		return false
	match piece.kind:
		Piece.Kind.SHOGI_PAWN, Piece.Kind.SHOGI_LANCE:
			if row == Board.enemy_back_rank(piece.side):
				return false
		Piece.Kind.SHOGI_KNIGHT:
			if Board.is_enemy_last_two_ranks(piece.side, row):
				return false
		Piece.Kind.XIANGQI_SOLDIER:
			if not Board.is_on_own_side(piece.side, row):
				return false
	return true


## Every point a held `piece` may legally drop onto: an unoccupied point within
## the drop rules that does not leave the dropper's own king in check. Empty
## when `piece` is not in hand.
func legal_drop_destinations(piece: Piece) -> Array[Vector2i]:
	if piece == null or not hand_of(piece.side).has(piece):
		return []
	var result: Array[Vector2i] = []
	for column in range(1, Board.COLUMNS + 1):
		for row in range(1, Board.ROWS + 1):
			if not can_drop(piece, column, row):
				continue
			if _drop_leaves_king_in_check(piece, column, row):
				continue
			result.append(Vector2i(column, row))
	return result


## Drops a held `piece` onto the empty point (column, row) when it is the side
## to move, the match is ongoing, and the point is a legal drop destination.
## Records the drop for undo and passes the turn. Returns true on success.
func drop(piece: Piece, column: int, row: int) -> bool:
	if piece == null or piece.side != side_to_move:
		return false
	if winner != 0:
		return false
	if not legal_drop_destinations(piece).has(Vector2i(column, row)):
		return false
	hand_of(piece.side).erase(piece)
	piece.column = column
	piece.row = row
	pieces.append(piece)
	_pieces_by_point[Vector2i(column, row)] = piece
	_history.append({
		"piece": piece,
		"drop": true,
	})
	side_to_move = other_side(side_to_move)
	return true


## True when placing `piece` at (column, row) would leave its side's own king in
## check (a drop may never do so). Simulates the drop and restores the hand.
func _drop_leaves_king_in_check(piece: Piece, column: int, row: int) -> bool:
	hand_of(piece.side).erase(piece)
	piece.column = column
	piece.row = row
	pieces.append(piece)
	_pieces_by_point[Vector2i(column, row)] = piece
	var in_check := is_in_check(piece.side)
	_pieces_by_point.erase(Vector2i(column, row))
	pieces.erase(piece)
	piece.column = 0
	piece.row = 0
	hand_of(piece.side).append(piece)
	return in_check


## Returns a dropped piece to the hand, clearing its board point.
func _undrop(piece: Piece) -> void:
	_pieces_by_point.erase(Vector2i(piece.column, piece.row))
	pieces.erase(piece)
	piece.column = 0
	piece.row = 0
	hand_of(piece.side).append(piece)


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
