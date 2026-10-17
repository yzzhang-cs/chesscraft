extends Node2D
## Main scene root. Shows the army-select menu, then hosts the board view for
## the started match with a turn indicator, a check flag, a win banner, and
## Undo / Restart / New match controls. Each side is driven by a controller
## built from the menu's choices: a PlayerController for a human side, an
## AIController for an AI side. Side 1 always moves first (held in Match). An AI
## side replies after a short delay, and AI-vs-AI chains one AI after another.
## Restart resets the current match to its opening; New match returns to the
## army-select menu.

## The delay before an AI side replies, so a human can see their move land.
const AI_DELAY := 0.7

@onready var board_view: BoardView = $BoardView
@onready var menu_view: MenuView = $MenuView

## The "Side N to move" banner, shown once a match starts.
var _turn_label: Label

## The win/lose banner, shown once the match ends.
var _win_label: Label

## Reverts the last move (single-ply in two-human, two-ply in human-vs-AI).
var _undo_button: Button

## Resets the current match to its opening position for the same two armies.
var _restart_button: Button

## Returns to the army-select menu to start a fresh match.
var _new_match_button: Button

## The per-side controllers, keyed by side (1 or 2).
var _controllers: Dictionary = {}

## The move_made callables bound to each controller, kept so they can be
## disconnected when the match is replaced.
var _move_made_callables: Dictionary = {}

## True when either side is an AI.
var _has_ai := false

## The human's side in a human-vs-AI match, or 0 when not human-vs-AI (two-human
## or AI-vs-AI).
var _human_side := 0

## How many human moves are currently on the undo stack (human-vs-AI only).
var _human_plies := 0

## The one-shot timer that paces an AI's reply.
var _ai_timer: Timer


func _ready() -> void:
	menu_view.started.connect(_on_match_started)
	_ai_timer = Timer.new()
	_ai_timer.one_shot = true
	_ai_timer.wait_time = AI_DELAY
	_ai_timer.timeout.connect(_on_ai_timer_timeout)
	add_child(_ai_timer)


func _on_match_started(side1_army: Army.Type, side2_army: Army.Type, side1_ai: bool, side2_ai: bool) -> void:
	var match := Match.new(side1_army, side2_army)
	board_view.match = match
	_controllers = {
		1: _make_controller(1, match, side1_ai),
		2: _make_controller(2, match, side2_ai),
	}
	board_view.set_controllers(_controllers)
	_connect_controllers()
	_has_ai = side1_ai or side2_ai
	_human_side = _resolve_human_side(side1_ai, side2_ai)
	_human_plies = 0
	_build_match_controls()
	menu_view.hide()
	_on_move_applied()


func _make_controller(side: int, match: Match, is_ai: bool) -> Controller:
	if is_ai:
		return AIController.new(side, match)
	return PlayerController.new(side, match)


## The human's side when exactly one side is an AI, else 0.
func _resolve_human_side(side1_ai: bool, side2_ai: bool) -> int:
	if side1_ai == side2_ai:
		return 0
	return 2 if side1_ai else 1


func _connect_controllers() -> void:
	for side in _controllers:
		var callable := _on_controller_moved.bind(side)
		_move_made_callables[side] = callable
		_controllers[side].move_made.connect(callable)


func _disconnect_controllers() -> void:
	for side in _move_made_callables:
		if _controllers.has(side):
			_controllers[side].move_made.disconnect(_move_made_callables[side])
	_move_made_callables.clear()


## Runs after any controller applies a move: count a human ply, refresh the
## status, and schedule the next AI move when it is now an AI's turn.
func _on_controller_moved(side: int) -> void:
	if side == _human_side:
		_human_plies += 1
	_on_move_applied()


## Refreshes the status and repaints, then schedules the AI when an AI side is
## to move. Called on match start and after every move.
func _on_move_applied() -> void:
	_refresh_status()
	board_view.queue_redraw()
	if board_view.match.winner != 0:
		return
	_schedule_ai_if_needed()


## Starts the AI's reply timer when the side to move is an AI.
func _schedule_ai_if_needed() -> void:
	var controller: Controller = _controllers.get(board_view.match.side_to_move)
	if controller is AIController:
		_ai_timer.start()


func _on_ai_timer_timeout() -> void:
	var controller: Controller = _controllers.get(board_view.match.side_to_move)
	if controller is AIController:
		controller.act()


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


## Reverts one ply in two-human matches and two plies (the AI's reply plus the
## human's move) in human-vs-AI matches. AI-vs-AI matches have no undo.
func _on_undo_pressed() -> void:
	var m := board_view.match
	if _human_side == 0:
		if m.undo():
			_refresh_board()
		return
	if _human_plies > 0 and m.side_to_move == _human_side:
		m.undo()  # the AI's reply
		m.undo()  # the human's move
		_human_plies -= 1
		_refresh_board()


## Resets the match to its opening position, clearing any selection and the win
## banner so the same two armies start fresh with Side 1 to move.
func _on_restart_pressed() -> void:
	_ai_timer.stop()
	_human_plies = 0
	board_view.match.restart()
	_refresh_board()
	_schedule_ai_if_needed()


## Clears every human controller's selection and any open promotion prompt.
func _clear_selections() -> void:
	for controller in _controllers.values():
		if controller is PlayerController:
			controller.clear_selection()
	board_view.cancel_promotion()


## Clears selections, refreshes the status text, and repaints the board after a
## state change (undo or restart).
func _refresh_board() -> void:
	_clear_selections()
	_refresh_status()
	board_view.queue_redraw()


## Abandons the current match and returns to the army-select menu.
func _on_new_match_pressed() -> void:
	_ai_timer.stop()
	_teardown_match_controls()
	_disconnect_controllers()
	_clear_selections()
	board_view.match = null
	board_view.set_controllers({})
	_controllers = {}
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
	_undo_button.disabled = not _undo_enabled()


## Undo is single-ply in two-human matches, disabled in AI-vs-AI, and two-ply in
## human-vs-AI (enabled only when it is the human's turn and they have moved).
func _undo_enabled() -> bool:
	var m := board_view.match
	if not _has_ai:
		return m.can_undo()
	if _human_side == 0:
		return false
	return _human_plies > 0 and m.side_to_move == _human_side and m.winner == 0


## The win banner text for a finished match.
func _win_text(m: Match) -> String:
	if m.end_reason == Match.REASON_CHECKMATE:
		return "Checkmate — Side %d wins" % m.winner
	return "Side %d has no legal move — Side %d wins" % [m.other_side(m.winner), m.winner]
