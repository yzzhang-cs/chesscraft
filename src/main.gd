extends Node2D
## Main scene root. Shows the army-select menu, then hosts the board view for
## the started match with a turn indicator. Side 1 always moves first (held in
## Match).

@onready var board_view: BoardView = $BoardView
@onready var menu_view: MenuView = $MenuView

## The "Side N to move" banner, shown once a match starts.
var _turn_label: Label


func _ready() -> void:
	menu_view.started.connect(_on_match_started)


func _on_match_started(side1_army: Army.Type, side2_army: Army.Type) -> void:
	board_view.match = Match.new(side1_army, side2_army)
	board_view.move_made.connect(_refresh_turn)
	_turn_label = Label.new()
	_turn_label.position = Vector2(12.0, 10.0)
	_turn_label.add_theme_font_size_override("font_size", 20)
	add_child(_turn_label)
	_refresh_turn()
	board_view.queue_redraw()
	menu_view.queue_free()


## Shows whose turn it is. Called on match start and after every move.
func _refresh_turn() -> void:
	_turn_label.text = "Side %d to move" % board_view.match.side_to_move
