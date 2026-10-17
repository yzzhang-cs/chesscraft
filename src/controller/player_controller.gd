class_name PlayerController
extends Controller
## The human's controller: owns the selection (board piece or hand piece), the
## move/drop decision, and the promotion-prompt decision. Pure model -- no Node
## dependency -- so the board view becomes render plus input-capture and forwards
## clicks here. The promotion *dialog* is drawn by the view; this controller only
## decides when to prompt and what the answer means.

## Emitted when a move needs an optional-promotion answer, carrying the piece and
## the destination. The view shows the dialog and calls back `answer_promotion`.
signal promotion_requested(piece: Piece, point: Vector2i)

## The selected board piece, or null.
var selected: Piece

## The selected board piece's legal destinations, drawn as highlights.
var legal: Array[Vector2i] = []

## The selected hand piece (awaiting a drop), or null.
var selected_hand: Piece

## The selected hand piece's legal drop destinations, drawn as highlights.
var drop_legal: Array[Vector2i] = []

## The move awaiting a promotion answer, or null/zero while none is pending.
var pending_piece: Piece
var pending_point: Vector2i = Vector2i.ZERO


## Handles a click on board point `point`: selects a piece, applies a move onto a
## highlighted destination, or clears the selection. Only this side's pieces are
## selectable.
func handle_point(point: Vector2i) -> void:
	if rules.winner != 0:
		return
	if selected_hand != null:
		if drop_legal.has(point):
			_do_drop(selected_hand, point)
			return
		clear_hand_selection()
	var piece := rules.piece_at(point.x, point.y)
	if selected != null:
		if legal.has(point):
			try_move(selected, point)
			return
		selected = null
		legal = []
		if piece != null and piece.side == side:
			_select(piece)
		return
	if piece != null and piece.side == side:
		_select(piece)


## Handles a click on a hand token: selects it for a drop, or deselects it when
## clicked again, highlighting its legal drop destinations on the board.
func handle_hand(piece: Piece) -> void:
	if rules.winner != 0:
		return
	if selected_hand == piece:
		clear_hand_selection()
		return
	selected_hand = piece
	selected = null
	legal = []
	drop_legal = rules.legal_drop_destinations(piece)


## Applies a move to `point`, promoting when the move is forced, prompting when
## the promotion is optional, and otherwise moving unpromoted.
func try_move(piece: Piece, point: Vector2i) -> void:
	if rules.must_promote(piece, point.y):
		_do_move(piece, point, true)
	elif rules.can_promote(piece, point.y):
		_request_promotion(piece, point)
	else:
		_do_move(piece, point, false)


## Answers a pending optional-promotion prompt and applies the move.
func answer_promotion(promote: bool) -> void:
	if pending_piece == null:
		return
	var piece := pending_piece
	var point := pending_point
	pending_piece = null
	pending_point = Vector2i.ZERO
	_do_move(piece, point, promote)


## Clears any selection and pending promotion, so stale highlights and prompts
## do not survive undo, a move, a restart, or a new match.
func clear_selection() -> void:
	selected = null
	legal = []
	clear_hand_selection()
	cancel_promotion()


## Cancels a pending promotion without applying the move.
func cancel_promotion() -> void:
	pending_piece = null
	pending_point = Vector2i.ZERO


## Clears the selected hand piece and its drop highlights.
func clear_hand_selection() -> void:
	selected_hand = null
	drop_legal = []


func _select(piece: Piece) -> void:
	selected = piece
	legal = rules.legal_destinations(piece)


func _do_move(piece: Piece, point: Vector2i, promote: bool) -> void:
	if apply_move(piece, point, promote):
		selected = null
		legal = []
		clear_hand_selection()


func _do_drop(piece: Piece, point: Vector2i) -> void:
	if apply_drop(piece, point):
		clear_hand_selection()


func _request_promotion(piece: Piece, point: Vector2i) -> void:
	pending_piece = piece
	pending_point = point
	promotion_requested.emit(piece, point)
