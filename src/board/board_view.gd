class_name BoardView
extends Node2D
## Draws the board: grid lines, the river, both palaces, and (once a match is
## set) every piece. Xiangqi pieces render as circles with a red/black Chinese
## glyph; Shogi pieces render as pentagons pointing at the opponent with
## Japanese glyphs. Reads geometry from the pure `Board` model and state from
## the pure `Match` model.
##
## Also handles click-to-move: clicking a piece selects it and highlights its
## legal destinations; clicking a highlighted point applies the move through the
## Match and emits `move_made`.
##
## Point (column, row) maps to screen space with column 1 on the left and
## row 1 at the bottom (Side 1's back rank).


## Distance, in pixels, between adjacent points.
const POINT_SPACING := 64.0

## Empty margin around the outermost points (left and right edges).
const MARGIN := 64.0

## Top edge of the board, in pixels. Grown past MARGIN so Side 2's hand tray
## fits above the board.
const TOP_MARGIN := 124.0

const BOARD_FILL := Color(0.93, 0.82, 0.62)
const RIVER_FILL := Color(0.72, 0.82, 0.90, 0.55)
const LINE_COLOR := Color(0.12, 0.10, 0.08)
const LINE_WIDTH := 2.0

const XIANGQI_PIECE_RADIUS := 26.0
const XIANGQI_PIECE_FILL := Color(0.98, 0.94, 0.80)
const XIANGQI_PIECE_BORDER := Color(0.15, 0.12, 0.09)
const RED_GLYPH := Color(0.80, 0.10, 0.10)
const BLACK_GLYPH := Color(0.08, 0.08, 0.08)

const SHOGI_PIECE_RADIUS := 26.0
const SHOGI_PIECE_FILL := Color(0.98, 0.94, 0.80)
const SHOGI_PIECE_BORDER := Color(0.15, 0.12, 0.09)
const SHOGI_GLYPH := Color(0.08, 0.08, 0.08)

const SELECT_COLOR := Color(0.20, 0.45, 0.90)
const LEGAL_COLOR := Color(0.10, 0.55, 0.20)
const CAPTURE_COLOR := Color(0.85, 0.15, 0.10)
const HIGHLIGHT_WIDTH := 3.0

## Hand trays: one row of held-piece tokens per side. Side 1's tray sits below
## the board, Side 2's above it; both always show their side's captured pieces
## awaiting a drop, regardless of whose turn it is.
const HAND_X := 64.0
const HAND_Y_BOTTOM := 760.0
const HAND_Y_TOP := 64.0
const HAND_SPACING := 48.0
const HAND_RADIUS := 20.0


## Emitted after a move is applied, so the caller can refresh a turn indicator.
signal move_made

## The match whose pieces to draw, or null to draw only the empty board.
var match: Match

## The currently selected piece, or null.
var selected: Piece

## The selected piece's legal destinations, drawn as highlights.
var _legal: Array[Vector2i] = []

## The selected hand piece (awaiting a drop), or null.
var selected_hand: Piece

## The selected hand piece's legal drop destinations, drawn as highlights.
var _drop_legal: Array[Vector2i] = []

## The move awaiting a promotion answer while the accept/decline dialog is open.
var _pending_piece: Piece
var _pending_point: Vector2i

## The accept/decline dialog for an optional promotion, open while the player
## decides. Tracked so it can be closed when the match is reset or replaced.
var _promotion_dialog: ConfirmationDialog

var _font: Font


## Screen position of a board point.
func point_position(column: int, row: int) -> Vector2:
	return Vector2(
		MARGIN + float(column - 1) * POINT_SPACING,
		TOP_MARGIN + float(Board.ROWS - row) * POINT_SPACING
	)


func _draw() -> void:
	_draw_background()
	_draw_river()
	_draw_grid()
	_draw_palaces()
	_draw_pieces()
	_draw_highlights()
	_draw_hand()


func _draw_background() -> void:
	var top_left := point_position(1, Board.ROWS)
	var bottom_right := point_position(Board.COLUMNS, 1)
	draw_rect(Rect2(top_left, bottom_right - top_left), BOARD_FILL, true)


func _draw_river() -> void:
	# The river is the band between rows 5 and 6. Its banks are the row-5 and
	# row-6 grid lines; the fill marks the gap the pieces cannot occupy.
	var top_left := point_position(1, Board.RIVER_ROW_ABOVE)
	var bottom_right := point_position(Board.COLUMNS, Board.RIVER_ROW_BELOW)
	draw_rect(Rect2(top_left, bottom_right - top_left), RIVER_FILL, true)


func _draw_grid() -> void:
	# Horizontal lines: one per row.
	for row in range(1, Board.ROWS + 1):
		var left := point_position(1, row)
		var right := point_position(Board.COLUMNS, row)
		draw_line(left, right, LINE_COLOR, LINE_WIDTH)

	# Vertical lines: the border columns run full height; the inner columns
	# are broken by the river, as on a real Xiangqi board.
	for column in range(1, Board.COLUMNS + 1):
		if column == 1 or column == Board.COLUMNS:
			_draw_vertical(column, 1, Board.ROWS)
		else:
			_draw_vertical(column, 1, Board.RIVER_ROW_BELOW)
			_draw_vertical(column, Board.RIVER_ROW_ABOVE, Board.ROWS)


func _draw_vertical(column: int, row_from: int, row_to: int) -> void:
	var top := point_position(column, row_to)
	var bottom := point_position(column, row_from)
	draw_line(top, bottom, LINE_COLOR, LINE_WIDTH)


func _draw_palaces() -> void:
	_draw_palace_diagonals(Board.PALACE_SIDE1_ROW_MIN, Board.PALACE_SIDE1_ROW_MAX)
	_draw_palace_diagonals(Board.PALACE_SIDE2_ROW_MIN, Board.PALACE_SIDE2_ROW_MAX)


## Draws the X across a palace: two diagonals between opposite corners.
func _draw_palace_diagonals(row_min: int, row_max: int) -> void:
	var col_min := Board.PALACE_COL_MIN
	var col_max := Board.PALACE_COL_MAX
	draw_line(point_position(col_min, row_min), point_position(col_max, row_max), LINE_COLOR, LINE_WIDTH)
	draw_line(point_position(col_max, row_min), point_position(col_min, row_max), LINE_COLOR, LINE_WIDTH)


func _draw_pieces() -> void:
	if match == null:
		return
	for piece in match.pieces:
		_draw_piece(piece)


## Draws the selected piece's ring and its legal destinations: a dot on empty
## points, a ring around an enemy piece that can be captured.
func _draw_highlights() -> void:
	if match == null:
		return
	if selected != null:
		_draw_ring(point_position(selected.column, selected.row), SELECT_COLOR)
	for dest in _legal:
		var center := point_position(dest.x, dest.y)
		if match.piece_at(dest.x, dest.y) != null:
			_draw_ring(center, CAPTURE_COLOR)
		else:
			draw_circle(center, 8.0, LEGAL_COLOR)


## Draws each side's held pieces in its own hand tray (Side 1 below the board,
## Side 2 above it), each as a pentagon glyph token; the selected hand piece is
## ringed. Both trays draw every frame, so a side's captures stay visible out of
## turn.
func _draw_hand() -> void:
	if match == null:
		return
	_draw_hand_tray(1)
	_draw_hand_tray(2)


func _draw_hand_tray(side: int) -> void:
	var hand := match.hand_of(side)
	for i in range(hand.size()):
		var center := _hand_token_position(side, i)
		_draw_pentagon(center, HAND_RADIUS, side == 1, SHOGI_PIECE_FILL, SHOGI_PIECE_BORDER)
		_draw_shogi_glyph(center, hand[i].glyph(), SHOGI_GLYPH, 12)
		if selected_hand == hand[i]:
			_draw_ring(center, SELECT_COLOR, HAND_RADIUS)


## Screen center of the `index`-th token in `side`'s hand tray, laid out left to
## right in one row. Side 1's row is below the board, Side 2's above it.
func _hand_token_position(side: int, index: int) -> Vector2:
	var y := HAND_Y_BOTTOM if side == 1 else HAND_Y_TOP
	return Vector2(HAND_X + float(index) * HAND_SPACING, y)


## The side-to-move's held piece whose token is under `local`, or null. Only the
## mover's own tray is selectable for a drop; the opponent's tray is display-only.
func _hand_token_at(local: Vector2) -> Piece:
	if match == null:
		return null
	return _tray_token_at(local, match.side_to_move)


## The held piece in `side`'s tray whose token is under `local`, or null.
func _tray_token_at(local: Vector2, side: int) -> Piece:
	if match == null:
		return null
	var hand := match.hand_of(side)
	for i in range(hand.size()):
		if local.distance_to(_hand_token_position(side, i)) <= HAND_RADIUS + 4.0:
			return hand[i]
	return null


## True when `local` is over any hand token of either side. Used to swallow clicks
## on the display-only opponent tray so they don't leak into a board click.
func _over_any_hand_token(local: Vector2) -> bool:
	if match == null:
		return false
	return _tray_token_at(local, 1) != null or _tray_token_at(local, 2) != null


func _draw_ring(center: Vector2, color: Color, radius: float = XIANGQI_PIECE_RADIUS) -> void:
	draw_arc(center, radius + 4.0, 0.0, TAU, 48, color, HIGHLIGHT_WIDTH)


func _unhandled_input(event: InputEvent) -> void:
	if match == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := get_local_mouse_position()
		var hand_piece := _hand_token_at(local)
		if hand_piece != null:
			_handle_hand_click(hand_piece)
		elif _over_any_hand_token(local):
			return
		else:
			var point := _nearest_point(local)
			if point == Vector2i.ZERO:
				return
			_handle_click(point)
		queue_redraw()


## The board point under a screen position, or Vector2i.ZERO when the position
## is not near any point.
func _nearest_point(local: Vector2) -> Vector2i:
	var column := int(round((local.x - MARGIN) / POINT_SPACING)) + 1
	var row := Board.ROWS - int(round((local.y - TOP_MARGIN) / POINT_SPACING))
	if not Board.in_bounds(column, row):
		return Vector2i.ZERO
	if local.distance_to(point_position(column, row)) > POINT_SPACING * 0.45:
		return Vector2i.ZERO
	return Vector2i(column, row)


## Selects a piece, applies a move or drop onto a highlighted point, or clears
## the selection. Only the side to move's pieces are selectable.
func _handle_click(point: Vector2i) -> void:
	if match.winner != 0:
		return
	if selected_hand != null:
		if _drop_legal.has(point):
			_apply_drop(selected_hand, point)
			return
		_clear_hand_selection()
	var piece := match.piece_at(point.x, point.y)
	if selected != null:
		if _legal.has(point):
			_try_move(selected, point)
			return
		selected = null
		_legal = []
		if piece != null and piece.side == match.side_to_move:
			selected = piece
			_legal = match.legal_destinations(piece)
		return
	if piece != null and piece.side == match.side_to_move:
		selected = piece
		_legal = match.legal_destinations(piece)


## Selects a hand piece (or deselects it when clicked again), highlighting its
## legal drop destinations on the board.
func _handle_hand_click(piece: Piece) -> void:
	if match.winner != 0:
		return
	if selected_hand == piece:
		_clear_hand_selection()
		return
	selected_hand = piece
	selected = null
	_legal = []
	_drop_legal = match.legal_drop_destinations(piece)


## Clears the selected hand piece and its drop highlights.
func _clear_hand_selection() -> void:
	selected_hand = null
	_drop_legal = []


## Applies the move to `point`, promoting when the move is forced or the player
## accepted the optional promotion prompt.
func _try_move(piece: Piece, point: Vector2i) -> void:
	if match.must_promote(piece, point.y):
		_apply_move(piece, point, true)
	elif match.can_promote(piece, point.y):
		_ask_promotion(piece, point)
	else:
		_apply_move(piece, point, false)


## Performs the move and clears the selection, emitting `move_made` on success.
func _apply_move(piece: Piece, point: Vector2i, promote: bool) -> void:
	if self.match.move(piece, point.x, point.y, promote):
		selected = null
		_legal = []
		_clear_hand_selection()
		move_made.emit()
	queue_redraw()


## Drops the selected hand piece onto `point`, clearing the selection and
## emitting `move_made` on success.
func _apply_drop(piece: Piece, point: Vector2i) -> void:
	if self.match.drop(piece, point.x, point.y):
		_clear_hand_selection()
		move_made.emit()
	queue_redraw()


## Pops an accept/decline dialog for an optional promotion.
func _ask_promotion(piece: Piece, point: Vector2i) -> void:
	_pending_piece = piece
	_pending_point = point
	_promotion_dialog = ConfirmationDialog.new()
	_promotion_dialog.title = "Promote?"
	_promotion_dialog.dialog_text = "Promote %s to %s?" % [piece.glyph(), Piece.promoted_glyph(piece.kind)]
	_promotion_dialog.ok_button_text = "Promote"
	_promotion_dialog.cancel_button_text = "Decline"
	_promotion_dialog.confirmed.connect(_on_promotion_confirmed)
	_promotion_dialog.canceled.connect(_on_promotion_declined)
	add_child(_promotion_dialog)
	_promotion_dialog.popup_centered()


func _on_promotion_confirmed() -> void:
	_finish_promotion(true)


func _on_promotion_declined() -> void:
	_finish_promotion(false)


func _finish_promotion(promote: bool) -> void:
	if _pending_piece == null:
		return
	var piece := _pending_piece
	var point := _pending_point
	_pending_piece = null
	_pending_point = Vector2i.ZERO
	_close_promotion_dialog()
	_apply_move(piece, point, promote)


## Cancels a pending promotion without applying the move, closing its prompt.
## Called when the match is reset or replaced so a stale answer cannot apply to
## the new position.
func cancel_promotion() -> void:
	_pending_piece = null
	_pending_point = Vector2i.ZERO
	_close_promotion_dialog()


## Frees and forgets the promotion prompt, if one is open.
func _close_promotion_dialog() -> void:
	if _promotion_dialog != null:
		_promotion_dialog.queue_free()
		_promotion_dialog = null


## Clears any selection and pending promotion, so stale highlights and prompts
## do not survive undo, a move, a restart, or a new match.
func clear_selection() -> void:
	selected = null
	_legal = []
	_clear_hand_selection()
	cancel_promotion()


## The shape comes from the owning side's army, so a Xiangqi piece captured and
## re-dropped by a Shogi side would render as a pentagon.
func _draw_piece(piece: Piece) -> void:
	var center := point_position(piece.column, piece.row)
	if match.army_of(piece.side) == Army.Type.SHOGI:
		_draw_shogi_piece(center, piece)
	else:
		_draw_xiangqi_piece(center, piece)


func _draw_xiangqi_piece(center: Vector2, piece: Piece) -> void:
	draw_circle(center, XIANGQI_PIECE_RADIUS, XIANGQI_PIECE_FILL)
	draw_arc(center, XIANGQI_PIECE_RADIUS, 0.0, TAU, 64, XIANGQI_PIECE_BORDER, LINE_WIDTH)
	var color := RED_GLYPH if piece.side == 1 else BLACK_GLYPH
	_draw_glyph(center, piece.glyph(), color, 32)


func _draw_shogi_piece(center: Vector2, piece: Piece) -> void:
	_draw_pentagon(center, SHOGI_PIECE_RADIUS, piece.side == 1, SHOGI_PIECE_FILL, SHOGI_PIECE_BORDER)
	_draw_shogi_glyph(center, piece.glyph(), SHOGI_GLYPH, 18)


## A pentagon whose point faces the opponent: upward for Side 1 (which sits at
## the bottom and advances toward higher rows), downward for Side 2.
func _draw_pentagon(center: Vector2, radius: float, points_up: bool, fill: Color, border: Color) -> void:
	var flip := 1.0 if points_up else -1.0
	var local := [
		Vector2(0.0, -radius),
		Vector2(-radius, -radius * 0.15),
		Vector2(-radius * 0.62, radius),
		Vector2(radius * 0.62, radius),
		Vector2(radius, -radius * 0.15),
	]
	var points := PackedVector2Array()
	for point in local:
		points.append(center + Vector2(point.x, point.y * flip))
	draw_colored_polygon(points, fill)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, border, LINE_WIDTH)


## Shogi glyphs are two characters stacked vertically, as on a real piece; a
## single-character glyph (the promoted pawn と) is centered instead.
func _draw_shogi_glyph(center: Vector2, glyph: String, color: Color, font_size: int) -> void:
	if glyph.length() == 1:
		_draw_glyph(center, glyph, color, font_size)
		return
	var gap := float(font_size) * 0.62
	_draw_glyph(center + Vector2(0.0, -gap / 2.0), glyph.substr(0, 1), color, font_size)
	_draw_glyph(center + Vector2(0.0, gap / 2.0), glyph.substr(1, 1), color, font_size)


## Draws a single string centered on `center`.
func _draw_glyph(center: Vector2, text: String, color: Color, font_size: int) -> void:
	var font := _piece_font()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := Vector2(
		center.x - width / 2.0,
		center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## A lazily built system font that covers the Chinese and Japanese glyphs used
## by all three armies. Falls back across common CJK families so pieces render
## on machines with different font sets.
func _piece_font() -> Font:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = PackedStringArray([
			"Microsoft YaHei",
			"Noto Sans CJK SC",
			"Noto Sans SC",
			"SimSun",
			"Yu Gothic UI",
			"MS Gothic",
			"Meiryo",
		])
	return _font
