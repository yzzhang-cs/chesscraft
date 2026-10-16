extends Node2D
## Main scene root. Shows the army-select menu, then hosts the board view for
## the started match. Side 1 always moves first (held in Match).

@onready var board_view: BoardView = $BoardView
@onready var menu_view: MenuView = $MenuView


func _ready() -> void:
	menu_view.started.connect(_on_match_started)


func _on_match_started(side1_army: Army.Type, side2_army: Army.Type) -> void:
	board_view.match = Match.new(side1_army, side2_army)
	board_view.queue_redraw()
	menu_view.queue_free()
