class_name Match
extends RefCounted
## One complete game between two sides. Holds each side's chosen army and the
## board's pieces, and answers the two questions the presentation asks of the
## rules engine: where a piece may move, and applying a move. Pure model -- no
## Node/scene dependency, so it can be driven headlessly.
##
## Side 1 always moves first; its back rank is row 1. Side 2's back rank is
## row 10.


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


## The piece standing at a board point, or null when the point is empty.
func piece_at(column: int, row: int) -> Piece:
	return _pieces_by_point.get(Vector2i(column, row))


## Removes every piece, leaving an empty board. Used to build test positions
## and (later) to restart a match.
func clear() -> void:
	pieces.clear()
	_pieces_by_point.clear()


## Places `piece` at its own column/row, replacing whatever already stands
## there. The opening setup uses this; tests and (later) Shogi drops will too.
func place(piece: Piece) -> void:
	var existing := piece_at(piece.column, piece.row)
	if existing != null:
		pieces.erase(existing)
	pieces.append(piece)
	_pieces_by_point[Vector2i(piece.column, piece.row)] = piece


## Every board point `piece` may move to under its army's rules, as a set of
## (column, row) points. Turn-agnostic: it does not check whose turn it is.
func legal_destinations(piece: Piece) -> Array[Vector2i]:
	return Moves.destinations(self, piece)


## Moves `piece` to (column, row) when it is the side to move and the point is
## one of its legal destinations. A capture removes the enemy piece. Returns
## true when the move was applied (and the turn passed to the other side).
func move(piece: Piece, column: int, row: int) -> bool:
	if piece == null or piece.side != side_to_move:
		return false
	if not legal_destinations(piece).has(Vector2i(column, row)):
		return false
	var captured := piece_at(column, row)
	if captured != null:
		_remove(captured)
	_pieces_by_point.erase(Vector2i(piece.column, piece.row))
	piece.column = column
	piece.row = row
	_pieces_by_point[Vector2i(column, row)] = piece
	side_to_move = 3 - side_to_move  # toggle 1 <-> 2
	return true


func _remove(piece: Piece) -> void:
	pieces.erase(piece)
	_pieces_by_point.erase(Vector2i(piece.column, piece.row))
