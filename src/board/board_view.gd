class_name BoardView
extends Node2D
## Draws the board: grid lines, the river, both palaces, and (once a match is
## set) every piece. Xiangqi pieces render as circles with a red/black Chinese
## glyph; Shogi pieces render as pentagons pointing at the opponent with
## Japanese glyphs. Reads geometry from the pure `Board` model and state from
## the pure `Match` model.
##
## Also captures clicks and forwards them to the side-to-move's controller: a
## PlayerController owns selection, move/drop, and the promotion decision, while
## an AIController ignores clicks. The view only renders and captures input; it
## never applies moves itself.
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


## The match whose pieces to draw, or null to draw only the empty board.
var match: Match

## The per-side controllers, keyed by side (1 or 2). Set by the main scene.
var controllers: Dictionary = {}

## The promotion-prompt callables bound to each PlayerController, kept so they
## can be disconnected when the controllers are replaced.
var _promotion_callables: Dictionary = {}

## The accept/decline dialog for an optional promotion, open while the player
## decides. Tracked so it can be closed when the match is reset or replaced.
var _promotion_dialog: ConfirmationDialog

## The controller awaiting a promotion answer while the dialog is open.
var _promotion_controller: PlayerController

var _font: Font


## Sets the per-side controllers, wiring the promotion prompt for any human side.
func set_controllers(controllers: Dictionary) -> void:
	for side in _promotion_callables:
		if self.controllers.has(side):
			var old: Controller = self.controllers[side]
			if old is PlayerController:
				old.promotion_requested.disconnect(_promotion_callables[side])
	_promotion_callables.clear()
	self.controllers = controllers
	for side in controllers:
		var controller: Controller = controllers[side]
		if controller is PlayerController:
			var callable: Callable = _on_promotion_requested.bind(controller)
			_promotion_callables[side] = callable
			controller.promotion_requested.connect(callable)


## The side-to-move's controller when it is a human, or null while an AI side is
## to move (clicks are ignored then).
func _current_player_controller() -> PlayerController:
	var controller: Controller = controllers.get(match.side_to_move)
	return controller if controller is PlayerController else null


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


## Draws the human side-to-move's selected piece's ring and its legal
## destinations: a dot on empty points, a ring around an enemy piece that can be
## captured. Reads the selection from the controller.
func _draw_highlights() -> void:
	if match == null:
		return
	var controller := _current_player_controller()
	if controller == null:
		return
	if controller.selected != null:
		_draw_ring(point_position(controller.selected.column, controller.selected.row), SELECT_COLOR)
	for dest in controller.legal:
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
	var controller := _current_player_controller()
	for i in range(hand.size()):
		var center := _hand_token_position(side, i)
		_draw_pentagon(center, HAND_RADIUS, side == 1, SHOGI_PIECE_FILL, SHOGI_PIECE_BORDER)
		_draw_shogi_glyph(center, hand[i].glyph(), SHOGI_GLYPH, 12)
		if controller != null and controller.selected_hand == hand[i]:
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


## Captures a click and forwards it to the side-to-move's human controller.
## While an AI side is to move, clicks are ignored.
func _unhandled_input(event: InputEvent) -> void:
	if match == null:
		return
	var controller := _current_player_controller()
	if controller == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := get_local_mouse_position()
		var hand_piece := _hand_token_at(local)
		if hand_piece != null:
			controller.handle_hand(hand_piece)
		elif _over_any_hand_token(local):
			return
		else:
			var point := _nearest_point(local)
			if point == Vector2i.ZERO:
				return
			controller.handle_point(point)
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


## Shows the accept/decline dialog for an optional promotion, on behalf of the
## controller that requested it.
func _on_promotion_requested(piece: Piece, point: Vector2i, controller: PlayerController) -> void:
	_promotion_controller = controller
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
	if _promotion_controller == null:
		return
	var controller := _promotion_controller
	_promotion_controller = null
	_close_promotion_dialog()
	controller.answer_promotion(promote)


## Cancels any pending promotion prompt without applying the move, closing its
## dialog. Called when the match is reset or replaced so a stale answer cannot
## apply to the new position.
func cancel_promotion() -> void:
	_promotion_controller = null
	_close_promotion_dialog()


## Frees and forgets the promotion prompt, if one is open.
func _close_promotion_dialog() -> void:
	if _promotion_dialog != null:
		_promotion_dialog.queue_free()
		_promotion_dialog = null


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
