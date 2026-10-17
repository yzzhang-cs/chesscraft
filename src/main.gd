extends Node2D
## Main scene root. Shows the army-select menu, then hosts the board view for
## the started match with a turn indicator, a check flag, a win banner, and
## Undo / Restart / New match controls. Side 1 always moves first (held in
## Match). Restart resets the current match to its opening; New match returns
## to the army-select menu to start a fresh match.

@onready var board_view: BoardView = $BoardView
@onready var menu_view: MenuView = $MenuView

## The "Side N to move" banner, shown once a match starts.
var _turn_label: Label

## The win/lose banner, shown once the match ends.
var _win_label: Label

## Reverts the last move.
var _undo_button: Button

## Resets the current match to its opening position for the same two armies.
var _restart_button: Button

## Returns to the army-select menu to start a fresh match.
var _new_match_button: Button


func _ready() -> void:
	menu_view.started.connect(_on_match_started)
	board_view.move_made.connect(_refresh_status)


func _on_match_started(side1_army: Army.Type, side2_army: Army.Type) -> void:
	board_view.match = Match.new(side1_army, side2_army)
	_build_match_controls()
	menu_view.hide()
	_refresh_status()
	board_view.queue_redraw()


## Creates the in-match status labels and controls. A new match tears these down
## first (see _teardown_match_controls), so they are built once per match.
func _build_match_controls() -> void:
	_turn_label = _make_label(Vector2(0.0, 8.0), 18)
	_turn_label.size = Vector2(640.0, 20.0)
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_turn_label)
	_win_label = _make_label(Vector2(0.0, 32.0), 26)
	_win_label.size = Vector2(640.0, 36.0)
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.add_theme_color_override("font_color", Color(0.55, 0.10, 0.10))
	add_child(_win_label)
	_undo_button = _make_button("Undo", Vector2(12.0, 796.0), _on_undo_pressed)
	_restart_button = _make_button("Restart", Vector2(92.0, 796.0), _on_restart_pressed)
	_new_match_button = _make_button("New match", Vector2(196.0, 796.0), _on_new_match_pressed)


func _make_label(pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_button(text: String, pos: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.pressed.connect(callback)
	add_child(button)
	return button


func _on_undo_pressed() -> void:
	if board_view.match.undo():
		_refresh_board()


## Resets the match to its opening position, clearing any selection and the win
## banner so the same two armies start fresh with Side 1 to move.
func _on_restart_pressed() -> void:
	board_view.match.restart()
	_refresh_board()


## Clears any board selection, refreshes the status text, and repaints the
## board after a state change.
func _refresh_board() -> void:
	board_view.clear_selection()
	_refresh_status()
	board_view.queue_redraw()


## Abandons the current match and returns to the army-select menu.
func _on_new_match_pressed() -> void:
	_teardown_match_controls()
	board_view.match = null
	board_view.clear_selection()
	board_view.queue_redraw()
	menu_view.show()


## Removes the in-match status labels and controls, discarding the win banner
## and leaving the board empty until the next match starts.
func _teardown_match_controls() -> void:
	for node in [_turn_label, _win_label, _undo_button, _restart_button, _new_match_button]:
		if node != null:
			node.queue_free()
	_turn_label = null
	_win_label = null
	_undo_button = null
	_restart_button = null
	_new_match_button = null


## Shows whose turn it is and whether the match is over. Called on match start,
## after every move, and after undo or restart.
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
