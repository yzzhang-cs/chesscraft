extends Node2D
## Main scene root. Shows the army-select menu, then hosts the board view for
## the started match with a turn indicator, a check flag, a win banner, and an
## undo button. Side 1 always moves first (held in Match).

@onready var board_view: BoardView = $BoardView
@onready var menu_view: MenuView = $MenuView

## The "Side N to move" banner, shown once a match starts.
var _turn_label: Label

## The win/lose banner, shown once the match ends.
var _win_label: Label

## Reverts the last move.
var _undo_button: Button


func _ready() -> void:
	menu_view.started.connect(_on_match_started)


func _on_match_started(side1_army: Army.Type, side2_army: Army.Type) -> void:
	board_view.match = Match.new(side1_army, side2_army)
	board_view.move_made.connect(_refresh_status)
	_turn_label = _make_label(Vector2(12.0, 8.0), 18)
	add_child(_turn_label)
	_win_label = _make_label(Vector2(0.0, 32.0), 26)
	_win_label.size = Vector2(640.0, 36.0)
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.add_theme_color_override("font_color", Color(0.55, 0.10, 0.10))
	add_child(_win_label)
	_undo_button = Button.new()
	_undo_button.text = "Undo"
	_undo_button.position = Vector2(12.0, 736.0)
	_undo_button.pressed.connect(_on_undo_pressed)
	add_child(_undo_button)
	_refresh_status()
	board_view.queue_redraw()
	menu_view.queue_free()


func _make_label(pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _on_undo_pressed() -> void:
	if board_view.match.undo():
		board_view.clear_selection()
		_refresh_status()
		board_view.queue_redraw()


## Shows whose turn it is and whether the match is over. Called on match start,
## after every move, and after undo.
func _refresh_status() -> void:
	var m := board_view.match
	if m.winner != 0:
		_turn_label.text = ""
		_win_label.text = _win_text(m)
	else:
		var check := " — check!" if m.is_in_check(m.side_to_move) else ""
		_turn_label.text = "Side %d to move%s" % [m.side_to_move, check]
		_win_label.text = ""
	_undo_button.disabled = not m.can_undo()


## The win banner text for a finished match.
func _win_text(m: Match) -> String:
	if m.end_reason == Match.REASON_CHECKMATE:
		return "Checkmate — Side %d wins" % m.winner
	return "Side %d has no legal move — Side %d wins" % [m.other_side(m.winner), m.winner]
