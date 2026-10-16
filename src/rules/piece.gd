class_name Piece
extends RefCounted
## A single unit on the board belonging to one side, moving by its army's
## rules. Pure model -- no Node/scene dependency.
##
## `army` is the piece's intrinsic army (which rules and glyph set it uses);
## `side` is who owns it (1 or 2). In a cross-game match a piece's army can
## differ from its owner's army (a captured Xiangqi piece re-dropped by Shogi),
## so presentation derives the drawn shape from the owner's army, not this one.


enum Kind {
	# Xiangqi (red/black glyph pairs).
	XIANGQI_GENERAL,
	XIANGQI_ADVISOR,
	XIANGQI_ELEPHANT,
	XIANGQI_HORSE,
	XIANGQI_CHARIOT,
	XIANGQI_CANNON,
	XIANGQI_SOLDIER,
	# Shogi.
	SHOGI_KING,
	SHOGI_ROOK,
	SHOGI_BISHOP,
	SHOGI_GOLD,
	SHOGI_SILVER,
	SHOGI_KNIGHT,
	SHOGI_LANCE,
	SHOGI_PAWN,
}


## The owning side: 1 (first mover) or 2 (second mover).
var side: int

## The piece's intrinsic army: its movement rules and glyph set.
var army: Army.Type

## The piece kind, from Piece.Kind.
var kind: Kind

## Board position, in absolute coordinates (column 1..9, row 1..10).
var column: int
var row: int


func _init(side: int, army: Army.Type, kind: Kind, column: int, row: int) -> void:
	self.side = side
	self.army = army
	self.kind = kind
	self.column = column
	self.row = row


## The glyph drawn on the piece. Xiangqi glyphs are red for Side 1 (the first
## mover) and black for Side 2; Shogi glyphs are two-character Japanese names
## that do not vary with side.
func glyph() -> String:
	match kind:
		Kind.XIANGQI_GENERAL:
			return "帥" if side == 1 else "將"
		Kind.XIANGQI_ADVISOR:
			return "仕" if side == 1 else "士"
		Kind.XIANGQI_ELEPHANT:
			return "相" if side == 1 else "象"
		Kind.XIANGQI_HORSE:
			return "傌" if side == 1 else "馬"
		Kind.XIANGQI_CHARIOT:
			return "俥" if side == 1 else "車"
		Kind.XIANGQI_CANNON:
			return "炮" if side == 1 else "砲"
		Kind.XIANGQI_SOLDIER:
			return "兵" if side == 1 else "卒"
		Kind.SHOGI_KING:
			return "王将"
		Kind.SHOGI_ROOK:
			return "飛車"
		Kind.SHOGI_BISHOP:
			return "角行"
		Kind.SHOGI_GOLD:
			return "金将"
		Kind.SHOGI_SILVER:
			return "銀将"
		Kind.SHOGI_KNIGHT:
			return "桂馬"
		Kind.SHOGI_LANCE:
			return "香車"
		Kind.SHOGI_PAWN:
			return "歩兵"
	return ""
