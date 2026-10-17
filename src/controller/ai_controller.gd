class_name AIController
extends Controller
## The greedy one-ply AI: on its turn it enumerates every legal move and Shogi
## drop, scores each by the value of the captured piece (promoted values
## included), prefers a move that gives check, and breaks ties randomly. Optional
## Shogi promotion is always taken. Pure model -- no Node dependency -- and
## seeded for reproducible tests.


## Material value of a piece, used to score captures. Kings and generals are
## never captured and have no value (0).
static func value_of(piece: Piece) -> int:
	if piece == null:
		return 0
	match piece.kind:
		Piece.Kind.XIANGQI_SOLDIER:
			return 1
		Piece.Kind.XIANGQI_ADVISOR, Piece.Kind.XIANGQI_ELEPHANT:
			return 2
		Piece.Kind.XIANGQI_HORSE, Piece.Kind.XIANGQI_CANNON:
			return 4
		Piece.Kind.XIANGQI_CHARIOT:
			return 9
		Piece.Kind.SHOGI_PAWN:
			return 6 if piece.promoted else 1
		Piece.Kind.SHOGI_LANCE:
			return 6 if piece.promoted else 3
		Piece.Kind.SHOGI_KNIGHT:
			return 6 if piece.promoted else 4
		Piece.Kind.SHOGI_SILVER:
			return 6 if piece.promoted else 5
		Piece.Kind.SHOGI_GOLD:
			return 6
		Piece.Kind.SHOGI_BISHOP:
			return 11 if piece.promoted else 8
		Piece.Kind.SHOGI_ROOK:
			return 13 if piece.promoted else 10
	return 0


## The seeded generator that makes choices reproducible.
var rng: RandomNumberGenerator


func _init(side: int, match: Match, seed_value: int = 0) -> void:
	super._init(side, match)
	rng = RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value


## Chooses and applies one legal move or drop for this side, returning true when
## a move was applied. Does nothing when it is not this side's turn or the match
## is over.
func act() -> bool:
	if rules.winner != 0 or rules.side_to_move != side:
		return false
	var candidate := _choose()
	if candidate.is_empty():
		return false
	var piece: Piece = candidate["piece"]
	var point: Vector2i = candidate["point"]
	if candidate["drop"]:
		return apply_drop(piece, point)
	return apply_move(piece, point, candidate["promote"])


## The best candidate: highest captured value first, then check, then a random
## choice among the exact ties. Returns an empty dictionary when there is no
## legal move (which should not happen while the match is ongoing).
func _choose() -> Dictionary:
	var best: Array[Dictionary] = []
	var best_value := -1
	var best_check := false
	for candidate in _all_candidates():
		var value: int = candidate["value"]
		var check: bool = candidate["check"]
		if value > best_value or (value == best_value and check and not best_check):
			best = [candidate]
			best_value = value
			best_check = check
		elif value == best_value and check == best_check:
			best.append(candidate)
	if best.is_empty():
		return {}
	return best[rng.randi_range(0, best.size() - 1)]


## Every legal move and drop for this side, each as a candidate dictionary:
## {piece, point, drop, promote, value, check}.
func _all_candidates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for piece in rules.pieces:
		if piece.side != side:
			continue
		var dests := rules.legal_destinations(piece)
		for dest in dests:
			var captured := rules.piece_at(dest.x, dest.y)
			var promote := rules.must_promote(piece, dest.y) or rules.can_promote(piece, dest.y)
			result.append({
				"piece": piece,
				"point": dest,
				"drop": false,
				"promote": promote,
				"value": value_of(captured),
				"check": _move_gives_check(piece, dest, promote),
			})
	for piece in rules.hand_of(side):
		var drop_dests := rules.legal_drop_destinations(piece)
		for dest in drop_dests:
			result.append({
				"piece": piece,
				"point": dest,
				"drop": true,
				"promote": false,
				"value": 0,
				"check": _drop_gives_check(piece, dest),
			})
	return result


## True when applying this move puts the opponent in check. Simulates the move
## through the rules engine and reverts it.
func _move_gives_check(piece: Piece, dest: Vector2i, promote: bool) -> bool:
	if not rules.move(piece, dest.x, dest.y, promote):
		return false
	var check := rules.is_in_check(rules.other_side(side))
	rules.undo()
	return check


## True when applying this drop puts the opponent in check. Simulates the drop
## through the rules engine and reverts it.
func _drop_gives_check(piece: Piece, dest: Vector2i) -> bool:
	if not rules.drop(piece, dest.x, dest.y):
		return false
	var check := rules.is_in_check(rules.other_side(side))
	rules.undo()
	return check
