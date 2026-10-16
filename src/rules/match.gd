class_name Match
extends RefCounted
## One complete game between two sides. Holds each side's chosen army and the
## board's opening pieces. Pure model -- no Node/scene dependency, so it can be
## driven headlessly.
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
		_place(Piece.new(1, side1_army, placement["kind"], placement["column"], placement["row"]))
	for placement in Openings.for_army(side2_army, 2):
		_place(Piece.new(2, side2_army, placement["kind"], placement["column"], placement["row"]))


## The army a side is playing.
func army_of(side: int) -> Army.Type:
	return side1_army if side == 1 else side2_army


## The piece standing at a board point, or null when the point is empty.
func piece_at(column: int, row: int) -> Piece:
	return _pieces_by_point.get(Vector2i(column, row))


func _place(piece: Piece) -> void:
	pieces.append(piece)
	_pieces_by_point[Vector2i(piece.column, piece.row)] = piece
