class_name Controller
extends RefCounted
## Base for the per-side controllers: the human PlayerController and the
## AIController. Pure model -- no Node/scene dependency -- holding the side it
## drives and the apply-move seam (the Match, the rules engine, through which
## every move and drop is applied). A remote controller can later sit where
## these two sit.

## Emitted after this controller applies a move or drop, so the caller can
## refresh status and drive the next turn.
signal move_made

## The side this controller drives: 1 (first mover) or 2 (second mover).
var side: int

## The match (the rules engine) the controller reads and applies moves through.
var rules: Match


func _init(side: int, match: Match) -> void:
	self.side = side
	self.rules = match


## Applies a move of `piece` to `point` through the rules engine, optionally
## promoting, and emits `move_made` on success. Returns true when applied.
func apply_move(piece: Piece, point: Vector2i, promote: bool = false) -> bool:
	if rules.move(piece, point.x, point.y, promote):
		move_made.emit()
		return true
	return false


## Applies a drop of a held `piece` onto `point` through the rules engine, and
## emits `move_made` on success. Returns true when applied.
func apply_drop(piece: Piece, point: Vector2i) -> bool:
	if rules.drop(piece, point.x, point.y):
		move_made.emit()
		return true
	return false
