class_name Openings
extends RefCounted
## Opening placement for each army, expressed in owner coordinates and
## translated to absolute board coordinates for a given side.
##
## Owner coordinates are side-agnostic: `file` is 1..9 read from the owner's
## left, and `row` is 1..4 counted from the owner's own back rank (row 1).
## Side 1 sits at the bottom (its row 1 is absolute row 1, owner-left is
## screen-left); Side 2 sits at the top (its row 1 is absolute row 10, and its
## owner-left is screen-right).


## Returns the opening placement for `army` on `side` as an array of
## dictionaries {kind, column, row} in absolute board coordinates.
static func for_army(army: Army.Type, side: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for placement in _owner_placements(army):
		result.append({
			"kind": placement["kind"],
			"column": _absolute_column(placement["file"], side),
			"row": _absolute_row(placement["row"], side),
		})
	return result


## Opening placement in owner coordinates: {kind, file, row}.
static func _owner_placements(army: Army.Type) -> Array[Dictionary]:
	match army:
		Army.Type.XIANGQI:
			return _xiangqi(3, 4)
		Army.Type.BIG_FAT_WHALE:
			return _xiangqi(2, 3)
		Army.Type.SHOGI:
			return _shogi()
	return []


## Xiangqi-style back rank plus cannons and soldiers at the given owner rows.
## The back rank 車馬相仕帥仕相馬車 is palindromic, so owner-left and owner-right
## are interchangeable for it; cannons and soldiers are symmetric about the
## center column.
static func _xiangqi(cannon_row: int, soldier_row: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
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
	for file in range(1, 10):
		result.append({"kind": back_rank[file - 1], "file": file, "row": 1})
	result.append({"kind": Piece.Kind.XIANGQI_CANNON, "file": 2, "row": cannon_row})
	result.append({"kind": Piece.Kind.XIANGQI_CANNON, "file": 8, "row": cannon_row})
	for file in [1, 3, 5, 7, 9]:
		result.append({"kind": Piece.Kind.XIANGQI_SOLDIER, "file": file, "row": soldier_row})
	return result


## Shogi opening: 香桂銀金王金銀桂香 on row 1, 飛車 on the owner's right and
## 角行 on the owner's left on row 2, 歩兵 on all nine files of row 3.
static func _shogi() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
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
	for file in range(1, 10):
		result.append({"kind": back_rank[file - 1], "file": file, "row": 1})
	# 飛車 on the owner's right (file 8), 角行 on the owner's left (file 2).
	result.append({"kind": Piece.Kind.SHOGI_ROOK, "file": 8, "row": 2})
	result.append({"kind": Piece.Kind.SHOGI_BISHOP, "file": 2, "row": 2})
	for file in range(1, 10):
		result.append({"kind": Piece.Kind.SHOGI_PAWN, "file": file, "row": 3})
	return result


## Owner file 1..9 (owner-left to owner-right) to absolute column. For Side 1
## owner-left is screen-left; for Side 2 it is screen-right.
static func _absolute_column(file: int, side: int) -> int:
	return file if side == 1 else (Board.COLUMNS + 1 - file)


## Owner row 1..N (own back rank outward) to absolute row. Side 1's back rank
## is absolute row 1; Side 2's is absolute row 10.
static func _absolute_row(row: int, side: int) -> int:
	return row if side == 1 else (Board.ROWS + 1 - row)
