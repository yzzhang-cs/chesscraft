extends SceneTree
## Headless test for the PlayerController: the human's click flow -- selecting a
## piece and moving it, selecting a hand piece and dropping it, and the optional
## promotion prompt -- runs through the controller seam with no board view.
##
## Run with:
##   godot_console --headless --path . --script res://tests/player_controller_test.gd


var _moves := 0
var _promotion_piece: Piece
var _promotion_point: Vector2i


func _initialize() -> void:
	var failures: Array[String] = []

	_select_and_move(failures)
	_drop_flow(failures)
	_promotion_flow(failures)
	_selection_ignores_opponent(failures)

	if failures.is_empty():
		print("player_controller_test=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("player_controller_test=FAIL %s" % failure)
		quit(1)


func _on_move() -> void:
	_moves += 1


func _on_promotion_requested(piece: Piece, point: Vector2i) -> void:
	_promotion_piece = piece
	_promotion_point = point


func _place(m: Match, side: int, kind: Piece.Kind, column: int, row: int) -> Piece:
	var piece := Piece.new(side, Army.Type.SHOGI, kind, column, row)
	m.place(piece)
	return piece


## Clicking a piece selects it and highlights its legal moves; clicking a legal
## destination applies the move and emits move_made.
func _select_and_move(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	var pc := PlayerController.new(1, m)
	_moves = 0
	pc.move_made.connect(_on_move)

	pc.handle_point(Vector2i(1, 1))
	if pc.selected == null:
		failures.append("select: clicking the chariot should select it")
		return
	if pc.legal.is_empty():
		failures.append("select: the chariot should have legal destinations")
		return

	pc.handle_point(Vector2i(1, 2))
	if m.piece_at(1, 2) == null:
		failures.append("select: the chariot should stand on (1,2)")
	if m.side_to_move != 2:
		failures.append("select: the turn should pass to Side 2")
	if _moves != 1:
		failures.append("select: move_made should fire once, got %d" % _moves)
	if pc.selected != null:
		failures.append("select: the selection should clear after the move")


## Clicking a hand piece selects it for a drop; clicking an empty point drops it.
func _drop_flow(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.SHOGI, Army.Type.SHOGI)
	m.clear()
	var pawn := Piece.new(1, Army.Type.SHOGI, Piece.Kind.SHOGI_PAWN, 0, 0)
	m.hand_of(1).append(pawn)
	var pc := PlayerController.new(1, m)
	_moves = 0
	pc.move_made.connect(_on_move)

	pc.handle_hand(pawn)
	if pc.selected_hand != pawn:
		failures.append("drop: clicking the hand pawn should select it")
		return
	if pc.drop_legal.is_empty():
		failures.append("drop: the pawn should have legal drop destinations")
		return

	pc.handle_point(Vector2i(5, 3))
	if m.piece_at(5, 3) != pawn:
		failures.append("drop: the pawn should drop onto (5,3)")
	if not m.hand_of(1).is_empty():
		failures.append("drop: the hand should empty after the drop")
	if m.side_to_move != 2:
		failures.append("drop: the turn should pass to Side 2")
	if _moves != 1:
		failures.append("drop: move_made should fire once, got %d" % _moves)
	if pc.selected_hand != null:
		failures.append("drop: the hand selection should clear after the drop")


## A move that may optionally promote prompts first, then applies on the answer.
func _promotion_flow(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.SHOGI, Army.Type.SHOGI)
	m.clear()
	_place(m, 1, Piece.Kind.SHOGI_KING, 5, 1)
	var silver := _place(m, 1, Piece.Kind.SHOGI_SILVER, 5, 7)
	_place(m, 2, Piece.Kind.SHOGI_KING, 5, 9)
	var pc := PlayerController.new(1, m)
	_promotion_piece = null
	_promotion_point = Vector2i.ZERO
	_moves = 0
	pc.move_made.connect(_on_move)
	pc.promotion_requested.connect(_on_promotion_requested)

	pc.handle_point(Vector2i(5, 7))
	pc.handle_point(Vector2i(5, 8))
	if _promotion_piece != silver:
		failures.append("promote: a promotion prompt should be requested for the silver")
		return
	if _promotion_point != Vector2i(5, 8):
		failures.append("promote: the prompt should carry the destination (5,8)")
	if _moves != 0:
		failures.append("promote: no move should apply until the prompt is answered")
		return

	pc.answer_promotion(true)
	if not silver.promoted:
		failures.append("promote: answering promote should promote the silver")
	if m.piece_at(5, 8) != silver:
		failures.append("promote: the silver should stand on (5,8)")
	if _moves != 1:
		failures.append("promote: move_made should fire once after the answer, got %d" % _moves)


## Clicking an opponent's piece while this side is to move does not select it.
func _selection_ignores_opponent(failures: Array[String]) -> void:
	var m := Match.new(Army.Type.XIANGQI, Army.Type.XIANGQI)
	var pc := PlayerController.new(1, m)
	pc.handle_point(Vector2i(9, 10))
	if pc.selected != null:
		failures.append("opponent: clicking an enemy piece must not select it")
